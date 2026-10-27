extends Node

# Data of the current run. Reset when a new run starts, survives scene changes during the run
# (e.g. moving to the next floor). Permanent progress (unlocks, materials, skill tree) will live
# in a separate save-backed MetaProgress autoload.

var loadout: Loadout
var floor_number: int = 1
var is_run_active: bool = false
# every floor layout comes from this. kept on Ctrl+R, so a restart replays the same floors
var run_seed: int = randi()

# run-wide buffs/curses picked up during the run (altars, later blessings).
# the player applies these on spawn, enemies apply enemy_modifiers on spawn
var pacts: Array[AltarPact] = [] # what was taken (HUD, offer pool)
var player_modifiers: Array[StatModifier] = []
var effects: Array[Effect] = []
var run_effects: Array[RunEffect] = []
var enemy_modifiers: Array[StatModifier] = []
var run_effect_state: Dictionary = {} # per-run data for RunEffects, key = effect
signal pact_added(pact: AltarPact)

func _ready() -> void:
	Signals.enemy_killed.connect(_on_enemy_killed)
	Signals.player_damaged.connect(_on_player_damaged)
	Signals.room_cleared.connect(_on_room_cleared)

# no is_run_active check: the lists are empty outside a run, and Main.tscn started
# from the editor never calls Begin()
func _on_enemy_killed(enemy: Entity, info: DamageInfo) -> void:
	for e in run_effects:
		e.OnEnemyKilled(enemy, info)

func _on_player_damaged(info: DamageInfo) -> void:
	for e in run_effects:
		e.OnPlayerDamaged(NodeReferences.player, info)

func _on_room_cleared() -> void:
	for e in run_effects:
		e.OnRoomCleared()

func AddPact(pact: AltarPact) -> void:
	pacts.append(pact)
	player_modifiers.append_array(pact.player_modifiers)
	player_modifiers.append_array(pact.curse_player_modifiers)
	effects.append_array(pact.effects)
	effects.append_array(pact.curse_effects)
	run_effects.append_array(pact.run_effects)
	run_effects.append_array(pact.curse_run_effects)
	enemy_modifiers.append_array(pact.enemy_modifiers)
	pact_added.emit(pact)

func Begin(new_loadout: Loadout, seed_value: int = 0) -> void:
	loadout = new_loadout
	run_seed = seed_value if seed_value != 0 else randi()
	floor_number = 1
	player_modifiers.clear()
	effects.clear()
	pacts.clear()
	run_effects.clear()
	enemy_modifiers.clear()
	run_effect_state.clear()
	is_run_active = true

func GetFloorSeed() -> int:
	return hash([run_seed, floor_number])

func Finish(_victory: bool) -> void:
	# TODO: hand collected materials/xp over to MetaProgress here
	is_run_active = false
