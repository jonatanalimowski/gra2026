extends Node

# Data of the current run. Reset when a new run starts, survives scene changes during the run
# (e.g. moving to the next floor). Permanent progress (unlocks, materials, skill tree) will live
# in a separate save-backed MetaProgress autoload.

var loadout: Loadout
var floor_number: int = 1
# per-floor rules (enemy scaling, elite chance, tint), all functions of floor_number
var floor_modifier: FloorModifier = preload("res://Data/Floors/DefaultFloorModifier.tres")
var is_run_active: bool = false
# every floor layout comes from this. kept on Ctrl+R, so a restart replays the same floors
var run_seed: int = randi()

signal on_experience_changed(new_experience)

var collected_experience: int = 0
var enemies_killed: int = 0
var elites_killed: int = 0

# run-wide blessings/curses picked up during the run (altar pacts, later oaths).
# halves is the one source of truth: the player and enemies apply every active half on spawn
# and listen to half_added / half_removed for live changes
var pacts: Array[AltarPact] = [] # what was taken (HUD, offer pool), a stacking pact once per stack
var halves: Array[PactHalf] = [] # active blessings + curses, a stacked half once per stack
var cleansed_curses: Array[Curse] = []
var run_effect_state: Dictionary = {} # per-run data for RunEffects, key = effect
# verb slots: AltarPact.Slot -> the pact in it. a new pact for a filled slot replaces the old one
var slots: Dictionary = {}
# school tiers (Attunement): reached by school points, lost again if points drop (slot replaced)
const ATTUNEMENTS: Array[Attunement] = [
	preload("res://Data/Attunements/PyromancerAttunement.tres"),
	preload("res://Data/Attunements/GlacierAttunement.tres"),
	preload("res://Data/Attunements/InfernoAttunement.tres"),
	preload("res://Data/Attunements/AbsoluteZeroAttunement.tres"),
	preload("res://Data/Attunements/TempestAttunement.tres"),
	preload("res://Data/Attunements/StormcallerAttunement.tres"),
	preload("res://Data/Attunements/HemomancerAttunement.tres"),
	preload("res://Data/Attunements/SanguineAttunement.tres"),
]
const SLOT_PACT_POINTS: int = 2
const GLYPH_POINTS: int = 1

var glyphs: Array[GlyphData] = []
var glyph_pity: float = 0.0
signal glyph_added(glyph: GlyphData)

var duos: Array[DuoData] = []
var evolution: WandEvolution
var deepened_pacts: Array[AltarPact] = []

const AFFIXES: Array[Affix] = [
	preload("res://Data/Affixes/VolatileAffix.tres"),
	preload("res://Data/Affixes/HastedAffix.tres"),
	preload("res://Data/Affixes/WardedAffix.tres"),
	preload("res://Data/Affixes/RegeneratingAffix.tres"),
]
const OMENS: Array[FloorOmen] = [
	preload("res://Data/Omens/SwarmOmen.tres"),
	preload("res://Data/Omens/ChampionsOmen.tres"),
	preload("res://Data/Omens/KindledHallsOmen.tres"),
	preload("res://Data/Omens/SilentHallsOmen.tres"),
	preload("res://Data/Omens/BloodMoonOmen.tres"),
	preload("res://Data/Omens/RestlessDeadOmen.tres"),
]

const DOUBLE_OMEN_FLOOR: int = 8
var omens: Array[FloorOmen] = []
const SCHOOL_WARD_GROUPS := { School.Kind.EMBER: &"ember", School.Kind.FROST: &"frost", School.Kind.STORM: &"storm", School.Kind.BLOOD: &"blood" }
var active_attunements: Array[Attunement] = []
signal pact_added(pact: AltarPact)
signal pact_replaced(old_pact: AltarPact, new_pact: AltarPact)
signal attunement_reached(attunement: Attunement)
signal attunement_lost(attunement: Attunement)
signal half_added(half: PactHalf)
signal half_removed(half: PactHalf)
signal curse_cleansed(curse: Curse)

func _ready() -> void:
	Signals.enemy_killed.connect(_on_enemy_killed)
	Signals.player_damaged.connect(_on_player_damaged)
	Signals.room_cleared.connect(_on_room_cleared)
	Signals.enemy_frozen.connect(func(enemy):
		for e in GetRunEffects(): e.OnEnemyFrozen(enemy))
	Signals.enemy_damaged.connect(func(enemy, info, amount):
		for e in GetRunEffects(): e.OnEnemyDamaged(enemy, info, amount))
	Signals.player_dash_started.connect(func(pos, dir):
		for e in GetRunEffects(): e.OnDashStarted(NodeReferences.player, pos, dir))
	Signals.player_dashed_through.connect(func(enemy):
		for e in GetRunEffects(): e.OnDashedThrough(NodeReferences.player, enemy))
	Signals.player_dash_ended.connect(func(pos):
		for e in GetRunEffects(): e.OnDashEnded(NodeReferences.player, pos))
	Signals.orb_collected.connect(func(orb, mana):
		for e in GetRunEffects(): e.OnOrbCollected(NodeReferences.player, orb, mana))
	Signals.player_hit_blocked.connect(func(info):
		for e in GetRunEffects(): e.OnHitBlocked(NodeReferences.player, info))

# every physics frame from the player (Capacitor, Leak...)
func ProcessEffects(player: Player, delta: float) -> void:
	for e in GetRunEffects():
		e.OnProcess(player, delta)

# called by every flying ManaOrb each physics frame (Ember Motes)
func OrbProcess(orb: ManaOrb, delta: float) -> void:
	for e in GetRunEffects():
		e.OnOrbProcess(orb, delta)

# no is_run_active check: the lists are empty outside a run, and Main.tscn started
# from the editor never calls Begin()
func _on_enemy_killed(enemy: Entity, info: DamageInfo, xp: int, is_elite: bool) -> void:
	for e in GetRunEffects():
		e.OnEnemyKilled(enemy, info, xp, is_elite)
	
	@warning_ignore("narrowing_conversion")
	HandleExperience(xp)
	enemies_killed += 1
	if is_elite:
		elites_killed += 1

func _on_player_damaged(info: DamageInfo) -> void:
	for e in GetRunEffects():
		e.OnPlayerDamaged(NodeReferences.player, info)

func _on_room_cleared() -> void:
	for e in GetRunEffects():
		e.OnRoomCleared()

func HandleExperience(experience_gained: int):
	collected_experience += experience_gained
	on_experience_changed.emit(collected_experience)

# a copy, so an effect can cleanse a curse (trials) while we loop
func GetRunEffects() -> Array[RunEffect]:
	var result: Array[RunEffect] = []
	for half in halves:
		result.append_array(half.run_effects)
	return result

func AddPact(pact: AltarPact) -> void:
	var replaced: AltarPact = pact.GetReplacedPact()
	if replaced:
		ReplacePact(replaced, pact)
	if pact.slot != AltarPact.Slot.NONE:
		slots[pact.slot] = pact
	pacts.append(pact)
	if pact.blessing:
		AddHalf(pact.blessing, pact.is_stacking)
	if pact.curse:
		AddHalf(pact.curse, pact.is_stacking)
	pact_added.emit(pact)
	CheckAttunements()

func ReplacePact(old_pact: AltarPact, new_pact: AltarPact) -> void:
	if old_pact.blessing:
		RemoveHalf(old_pact.blessing)
	if old_pact.rank2_blessing:
		RemoveHalf(old_pact.rank2_blessing)
	deepened_pacts.erase(old_pact)
	if old_pact.curse:
		RemoveHalf(old_pact.curse)
	while old_pact in pacts:
		pacts.erase(old_pact)
	slots.erase(old_pact.slot)
	pact_replaced.emit(old_pact, new_pact)

func GetSlotPact(slot: AltarPact.Slot) -> AltarPact:
	return slots.get(slot)

# slot pact = 2, glyph = 1 per stack
func GetSchoolPoints(school: School.Kind) -> int:
	var points := GetPactSchoolPoints(school)
	for glyph in glyphs:
		if glyph.school == school:
			points += GLYPH_POINTS
	return points

# from slot pacts only: owning a school = having a pact of it (glyphs can only deepen those)
func GetPactSchoolPoints(school: School.Kind) -> int:
	var points := 0
	for pact in slots.values():
		if pact.GetSchool() == school:
			points += SLOT_PACT_POINTS
	return points

func AddGlyph(glyph: GlyphData) -> void:
	glyphs.append(glyph)
	if glyph.blessing:
		AddHalf(glyph.blessing, true)
	glyph_added.emit(glyph)
	CheckAttunements()

# called by GameFlow.NextFloor: last floor's omens go, new ones from floor 2 (2 of them from floor 8)
func RollOmens() -> void:
	for omen in omens:
		RemoveHalf(omen)
	omens.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash([GetFloorSeed(), "omen"])
	var pool = OMENS.filter(func(o): return o.min_floor <= floor_number)
	var count = 2 if floor_number >= DOUBLE_OMEN_FLOOR else (1 if floor_number >= 2 else 0)
	for i in mini(count, pool.size()):
		var omen = pool[rng.randi() % pool.size()]
		pool.erase(omen)
		omens.append(omen)
		AddHalf(omen)

func GetEnemyCountMultiplier() -> float:
	var result := 1.0
	for omen in omens:
		result *= omen.enemy_count_multiplier
	return result

func GetEliteGlyphBonus() -> float:
	var result := 0.0
	for omen in omens:
		result += omen.elite_glyph_bonus
	return result

func GetOmenWardGroup() -> StringName:
	for omen in omens:
		if omen.enemy_ward_group != &"":
			return omen.enemy_ward_group
	return &""

# Warded affix: the school the player leans on most (owned by pact), so it pushes a second school
func GetTopSchoolWardGroup() -> StringName:
	var best := &""
	var best_points := 0
	for school in SCHOOL_WARD_GROUPS:
		var points = GetSchoolPoints(school)
		if GetPactSchoolPoints(school) > 0 and points > best_points:
			best_points = points
			best = SCHOOL_WARD_GROUPS[school]
	return best

func AddDuo(duo: DuoData) -> void:
	duos.append(duo)
	if duo.blessing:
		AddHalf(duo.blessing)

func SetEvolution(new_evolution: WandEvolution) -> void:
	evolution = new_evolution
	if evolution.blessing:
		AddHalf(evolution.blessing)

# rank II: swap the blessing, keep the curse and the slot
func DeepenPact(pact: AltarPact) -> void:
	if pact.rank2_blessing == null or pact in deepened_pacts:
		return
	deepened_pacts.append(pact)
	RemoveHalf(pact.blessing)
	AddHalf(pact.rank2_blessing)

func GetGlyphStacks(glyph: GlyphData) -> int:
	return glyphs.count(glyph)

func CanTakeGlyph(glyph: GlyphData) -> bool:
	return GetGlyphStacks(glyph) < glyph.max_stacks

# how many active halves carry the flag, stacks count (Deep Cold x2, Ice Shards x3...)
func CountFlag(flag: StringName) -> int:
	var count := 0
	for half in halves:
		if flag in half.flags:
			count += 1
	return count

# StatusTweak sums for statuses the player puts on enemies
func GetStatusExtraStacks(effect: StatusEffect) -> int:
	var extra := 0
	for half in halves:
		for tweak in half.status_tweaks:
			if tweak.status == effect:
				extra += tweak.extra_max_stacks
	return extra

func GetStatusExtraApplication(effect: StatusEffect) -> int:
	var extra := 0
	for half in halves:
		for tweak in half.status_tweaks:
			if tweak.status == effect:
				extra += tweak.extra_stacks_per_application
	return extra

func GetStatusDurationMultiplier(effect: StatusEffect) -> float:
	var multiplier := 1.0
	for half in halves:
		for tweak in half.status_tweaks:
			if tweak.status == effect:
				multiplier += tweak.extra_duration
	return multiplier

# after every pact change: reach new tiers, lose tiers whose points are gone (slot replaced)
func CheckAttunements() -> void:
	for attunement in ATTUNEMENTS:
		var has_points = GetSchoolPoints(attunement.school) >= attunement.threshold
		var is_active = attunement in active_attunements
		if has_points and not is_active:
			active_attunements.append(attunement)
			if attunement.blessing:
				AddHalf(attunement.blessing)
			attunement_reached.emit(attunement)
		elif not has_points and is_active:
			active_attunements.erase(attunement)
			if attunement.blessing:
				RemoveHalf(attunement.blessing)
			attunement_lost.emit(attunement)

func GetStackCount(pact: AltarPact) -> int:
	return pacts.count(pact)

func CanTakePact(pact: AltarPact) -> bool:
	return GetStackCount(pact) < pact.GetMaxStacks()

# the half resource is the modifier source. a stacking half is added once per stack and every
# half_added applies it again, so modifiers add up
func AddHalf(half: PactHalf, can_stack: bool = false) -> void:
	if half in halves and not can_stack:
		return
	halves.append(half)
	half_added.emit(half)

# removes every stack, half_removed once per stack (mirrors the adds, e.g. RunEffect.OnRemoved)
func RemoveHalf(half: PactHalf) -> void:
	while half in halves:
		halves.erase(half)
		half_removed.emit(half)

# the single entry point for removing a curse (sanctuary, trials, skill tree...)
func CleanseCurse(curse: Curse) -> bool:
	if curse.binding or curse not in halves:
		return false
	RemoveHalf(curse)
	cleansed_curses.append(curse)
	curse_cleansed.emit(curse)
	return true

func IsActive(half: PactHalf) -> bool:
	return half in halves

func GetActiveCurses() -> Array[Curse]:
	var result: Array[Curse] = []
	for half in halves:
		if half is Curse and half not in result:
			result.append(half)
	return result

# product of the active halves' multipliers, each half counted once even when stacked
func GetEliteChanceMultiplier() -> float:
	var result := 1.0
	var counted: Array[PactHalf] = []
	for half in halves:
		if half in counted:
			continue
		counted.append(half)
		result *= half.elite_chance_multiplier
	return result

func HasFlag(flag: StringName) -> bool:
	for half in halves:
		if flag in half.flags:
			return true
	return false

func Begin(new_loadout: Loadout, seed_value: int = 0) -> void:
	loadout = new_loadout
	run_seed = seed_value if seed_value != 0 else randi()
	floor_number = 1
	collected_experience = 0
	pacts.clear()
	halves.clear()
	cleansed_curses.clear()
	run_effect_state.clear()
	slots.clear()
	active_attunements.clear()
	glyphs.clear()
	glyph_pity = 0.0
	duos.clear()
	evolution = null
	deepened_pacts.clear()
	omens.clear()
	is_run_active = true

# base comes from the altar, bonuses from wherever they live (meta now, run blessings later)
func GetPactOfferCount(base: int) -> int:
	return base + MetaProgress.altar_offer_bonus

func GetFloorSeed() -> int:
	return hash([run_seed, floor_number])

func Finish(_victory: bool) -> void:
	# TODO: hand collected materials/xp over to MetaProgress here
	is_run_active = false
