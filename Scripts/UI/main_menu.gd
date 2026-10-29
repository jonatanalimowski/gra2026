extends Control
const SETTINGS_OVERLAY = preload("res://Scenes/UI/SettingsOverlay.tscn")
@onready var start_button = %Start
@onready var quit_button = %Quit
@onready var settings_button = %SettingsButton

func _ready() -> void:
	ConnectSignals()

func ConnectSignals():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func _on_start_pressed():
	GameFlow.GoToLoadout()

func _on_settings_pressed():
	add_child(SETTINGS_OVERLAY.instantiate())

func _on_quit_pressed():
	get_tree().quit()
