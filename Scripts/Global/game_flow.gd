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

func StartRun(loadout: Loadout) -> void:
	RunState.Begin(loadout)
	get_tree().change_scene_to_file(RUN_SCENE)

# same loadout, fresh run (Ctrl+R)
func RestartRun() -> void:
	StartRun(RunState.loadout)

func EndRun(victory: bool) -> void:
	RunState.Finish(victory)
	GoToLoadout()
