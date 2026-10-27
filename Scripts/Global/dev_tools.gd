extends Node

# dev cheats, toggled from the DevUI panel (F6). lives in an autoload so the flags
# survive scene changes (new floors, restarts). only exists in debug builds
const DEV_UI_SCENE = preload("res://Scenes/UI/DevUI.tscn")

var invincible: bool = false
# killing the boss generates the next floor instead of ending the run
var infinite_floors: bool = false

var layer: CanvasLayer

func _ready() -> void:
	if not OS.is_debug_build():
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = CanvasLayer.new()
	layer.layer = 100
	layer.visible = false
	layer.add_child(DEV_UI_SCENE.instantiate())
	add_child(layer)

func _unhandled_input(event: InputEvent) -> void:
	if layer and event.is_action_pressed("DevMenu"):
		layer.visible = not layer.visible
		get_viewport().set_input_as_handled()
