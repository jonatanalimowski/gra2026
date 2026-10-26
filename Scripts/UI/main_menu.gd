extends Control
@onready var start_button = $MarginContainer/VBoxContainer/Start
@onready var quit_button = $MarginContainer/VBoxContainer/Quit

func _ready() -> void:
	ConnectSignals()

func ConnectSignals():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	GameFlow.GoToLoadout()

func _on_quit_pressed():
	get_tree().quit()
