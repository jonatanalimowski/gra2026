extends Node

# Data of the current run. Reset when a new run starts, survives scene changes during the run
# (e.g. moving to the next floor). Permanent progress (unlocks, materials, skill tree) will live
# in a separate save-backed MetaProgress autoload.

var loadout: Loadout
var floor_number: int = 1
var is_run_active: bool = false

# run-wide buffs picked up during the run (blessings, altars). the player applies these on spawn
var player_modifiers: Array[StatModifier] = []
var effects: Array[Effect] = []

func Begin(new_loadout: Loadout) -> void:
	loadout = new_loadout
	floor_number = 1
	player_modifiers.clear()
	effects.clear()
	is_run_active = true

func Finish(_victory: bool) -> void:
	# TODO: hand collected materials/xp over to MetaProgress here
	is_run_active = false
