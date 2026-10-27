extends Node

# the only place that changes scenes, so the whole game loop can be read in one file:
# MainMenu -> Loadout (PreRunScreen) -> Run (Main) -> back to Loadout on death/victory
# TODO: put the Hub (NewMainUI) between MainMenu and Loadout once it has a script

const MAIN_MENU_SCENE = "res://Scenes/UI/MainMenu.tscn"
const LOADOUT_SCENE = "res://Scenes/UI/PreRunScreen.tscn"
const RUN_SCENE = "res://Scenes/Misc/Main.tscn"

func GoToMainMenu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func GoToLoadout() -> void:
	get_tree().change_scene_to_file(LOADOUT_SCENE)

func StartRun(loadout: Loadout, run_seed: int = 0) -> void:
	RunState.Begin(loadout, run_seed)
	get_tree().change_scene_to_file(RUN_SCENE)

# reloads the run scene with floor_number + 1. the player re-applies RunState.loadout and the
# run-wide buffs in _ready, and the generator gets a new floor seed
func NextFloor() -> void:
	RunState.floor_number += 1
	get_tree().change_scene_to_file(RUN_SCENE)

# same loadout, fresh run (Ctrl+R). new dungeon unless same_seed
func RestartRun(same_seed: bool = false) -> void:
	StartRun(RunState.loadout, RunState.run_seed if same_seed else 0)

func EndRun(victory: bool) -> void:
	RunState.Finish(victory)
	GoToLoadout()
