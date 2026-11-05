extends Control

@onready var xp_label = %XpLabel
@onready var enemies_label = %EnemiesLabel
@onready var floor_label = %FloorLabel
@onready var ok_button = %OkButton


func _ready() -> void:
	ok_button.pressed.connect(GoToMainMenu)
	xp_label.text = "Experience collected: %d" % RunState.collected_experience
	enemies_label.text = "Enemies slain: %d" % RunState.enemies_killed
	floor_label.text = "Floor reached: %d" % RunState.floor_number

func GoToMainMenu() -> void:
	GameFlow.GoToMainMenu()
