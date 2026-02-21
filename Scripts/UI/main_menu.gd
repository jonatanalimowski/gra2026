extends Control
@export var start_scene: PackedScene
@onready var start_button = $MarginContainer/VBoxContainer/Start
@onready var quit_button = $MarginContainer/VBoxContainer/Quit

func _ready() -> void:
	ConnectSignals()

func ConnectSignals():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	if start_scene:
		get_tree().change_scene_to_packed(start_scene)

func _on_quit_pressed():
	get_tree().quit()
