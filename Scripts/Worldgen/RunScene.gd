extends Node2D
class_name RunScene

# root of Main.tscn, ends the run on death. floors go on forever: the boss drops an UpgradeShrine
# that starts the next floor (see BossRoom)
const SETTINGS_OVERLAY = preload("res://Scenes/UI/SettingsOverlay.tscn")

func _ready() -> void:
	Signals.player_died.connect(_on_player_died)

# esc mid-run = settings. paused overlays (altar, stats) handle esc themselves
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		add_child(SETTINGS_OVERLAY.instantiate())

func _on_player_died() -> void:
	GameFlow.EndRun(false)
