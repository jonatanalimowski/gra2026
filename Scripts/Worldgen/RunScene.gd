extends Node2D
class_name RunScene

# root of Main.tscn, ends the run on death. floors go on forever: the boss drops an UpgradeShrine
# that starts the next floor (see BossRoom)
const SETTINGS_OVERLAY = preload("res://Scenes/UI/SettingsOverlay.tscn")
const CHARACTER_OVERLAY = preload("res://Scenes/UI/CharacterOverlay.tscn")
@onready var canvas: CanvasLayer = %CanvasLayer
@onready var in_game_ui: Control = %InGameUI

func _ready() -> void:
	Signals.player_died.connect(_on_player_died)
	NodeReferences.in_game_ui = canvas

# esc mid-run = settings, C = character screen, F1 = hide/show the whole hud (screenshots). paused overlays (altar, stats, character)
# handle esc/C themselves, and this node is paused under them so it never opens a second one
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		add_child(SETTINGS_OVERLAY.instantiate())
	elif event.is_action_pressed("Character"):
		get_viewport().set_input_as_handled()
		add_child(CHARACTER_OVERLAY.instantiate())
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		get_viewport().set_input_as_handled()
		in_game_ui.visible = not in_game_ui.visible

func _on_player_died() -> void:
	GameFlow.EndRun(false)
