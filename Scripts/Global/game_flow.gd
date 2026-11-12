extends Node

# the only place that changes scenes, so the whole game loop can be read in one file:
# MainMenu -> Loadout (PreRunScreen) -> Run (Main) -> back to Loadout on death/victory
# TODO: put the Hub (NewMainUI) between MainMenu and Loadout once it has a script

const MAIN_MENU_SCENE = preload("res://Scenes/UI/MainMenu.tscn")
const LOADOUT_SCENE = preload("res://Scenes/UI/PreRunScreen.tscn")
const RUN_SCENE = preload("res://Scenes/Misc/Main.tscn")
const POST_RUN_SCENE = preload("res://Scenes/UI/PostRunScreen.tscn")
const DEATH_SCENE = preload("res://Scenes/UI/DeathScreen.tscn")

func GoToMainMenu() -> void:
	get_tree().change_scene_to_packed(MAIN_MENU_SCENE)

func GoToLoadout() -> void:
	get_tree().change_scene_to_packed(LOADOUT_SCENE)

func GoToYouDied() -> void:
	SceneTransition.transition_to(DEATH_SCENE)

func StartRun(loadout: Loadout, run_seed: int = 0) -> void:
	RunState.Begin(loadout, run_seed)
	get_tree().change_scene_to_packed(RUN_SCENE)

func GoToPostRunScene() -> void:
	get_tree().change_scene_to_packed(POST_RUN_SCENE)

# reloads the run scene with floor_number + 1. the player re-applies RunState.loadout and the
# run-wide buffs in _ready, and the generator gets a new floor seed
func NextFloor() -> void:
	RunState.floor_number += 1
	RunState.RollOmens()
	get_tree().change_scene_to_packed(RUN_SCENE)

# same loadout, fresh run (Ctrl+R). new dungeon unless same_seed
func RestartRun(same_seed: bool = false) -> void:
	StartRun(RunState.loadout, RunState.run_seed if same_seed else 0)

func EndRun(victory: bool) -> void:
	RunState.Finish(victory)
	if victory:
		pass
	else:
		GoToYouDied()
