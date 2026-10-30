extends Node

# Data of the current run. Reset when a new run starts, survives scene changes during the run
# (e.g. moving to the next floor). Permanent progress (unlocks, materials, skill tree) will live
# in a separate save-backed MetaProgress autoload.

var loadout: Loadout
var floor_number: int = 1
var is_run_active: bool = false
# every floor layout comes from this. kept on Ctrl+R, so a restart replays the same floors
var run_seed: int = randi()

# run-wide blessings/curses picked up during the run (altar pacts, later oaths).
# halves is the one source of truth: the player and enemies apply every active half on spawn
# and listen to half_added / half_removed for live changes
var pacts: Array[AltarPact] = [] # what was taken (HUD, offer pool), a stacking pact once per stack
var halves: Array[PactHalf] = [] # active blessings + curses, a stacked half once per stack
var cleansed_curses: Array[Curse] = []
var run_effect_state: Dictionary = {} # per-run data for RunEffects, key = effect
signal pact_added(pact: AltarPact)
signal half_added(half: PactHalf)
signal half_removed(half: PactHalf)
signal curse_cleansed(curse: Curse)

func _ready() -> void:
	Signals.enemy_killed.connect(_on_enemy_killed)
	Signals.player_damaged.connect(_on_player_damaged)
	Signals.room_cleared.connect(_on_room_cleared)

# no is_run_active check: the lists are empty outside a run, and Main.tscn started
# from the editor never calls Begin()
func _on_enemy_killed(enemy: Entity, info: DamageInfo) -> void:
	for e in GetRunEffects():
		e.OnEnemyKilled(enemy, info)

func _on_player_damaged(info: DamageInfo) -> void:
	for e in GetRunEffects():
		e.OnPlayerDamaged(NodeReferences.player, info)

func _on_room_cleared() -> void:
	for e in GetRunEffects():
		e.OnRoomCleared()

# a copy, so an effect can cleanse a curse (trials) while we loop
func GetRunEffects() -> Array[RunEffect]:
	var result: Array[RunEffect] = []
	for half in halves:
		result.append_array(half.run_effects)
	return result

func AddPact(pact: AltarPact) -> void:
	pacts.append(pact)
	if pact.blessing:
		AddHalf(pact.blessing, pact.is_stacking)
	if pact.curse:
		AddHalf(pact.curse, pact.is_stacking)
	pact_added.emit(pact)

func GetStackCount(pact: AltarPact) -> int:
	return pacts.count(pact)

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

func HasFlag(flag: StringName) -> bool:
	for half in halves:
		if flag in half.flags:
			return true
	return false

func Begin(new_loadout: Loadout, seed_value: int = 0) -> void:
	loadout = new_loadout
	run_seed = seed_value if seed_value != 0 else randi()
	floor_number = 1
	pacts.clear()
	halves.clear()
	cleansed_curses.clear()
	run_effect_state.clear()
	is_run_active = true

# base comes from the altar, bonuses from wherever they live (meta now, run blessings later)
func GetPactOfferCount(base: int) -> int:
	return base + MetaProgress.altar_offer_bonus

# enemy (and boss) scaling per floor past the first, linear: floor 3 = +40% hp, +20% damage
const ENEMY_HEALTH_PER_FLOOR: float = 0.2
const ENEMY_DAMAGE_PER_FLOOR: float = 0.1

func GetEnemyHealthScale() -> float:
	return 1.0 + ENEMY_HEALTH_PER_FLOOR * (floor_number - 1)

func GetEnemyDamageScale() -> float:
	return 1.0 + ENEMY_DAMAGE_PER_FLOOR * (floor_number - 1)

# max_health, contact damage and spell damage. new each call, source = RunState
func GetFloorScalingModifiers() -> Array[StatModifier]:
	var result: Array[StatModifier] = []
	for entry in [[&"max_health", GetEnemyHealthScale()], [&"attack_damage", GetEnemyDamageScale()], [&"damage", GetEnemyDamageScale()]]:
		var modifier := StatModifier.new()
		modifier.stat = entry[0]
		modifier.multiplier = entry[1]
		result.append(modifier)
	return result

func GetFloorSeed() -> int:
	return hash([run_seed, floor_number])

func Finish(_victory: bool) -> void:
	# TODO: hand collected materials/xp over to MetaProgress here
	is_run_active = false
