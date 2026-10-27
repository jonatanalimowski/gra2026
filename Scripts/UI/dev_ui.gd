extends Control

# cheat toggles, shown/hidden by the DevTools autoload
@onready var invincible_button: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/InvincibleButton
@onready var infinite_floors_button: CheckButton = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/InfiniteFloorsButton

func _ready() -> void:
	invincible_button.button_pressed = DevTools.invincible
	infinite_floors_button.button_pressed = DevTools.infinite_floors
	invincible_button.toggled.connect(_on_invincible_toggled)
	infinite_floors_button.toggled.connect(_on_infinite_floors_toggled)
	# don't let space/enter flip a toggle while playing
	invincible_button.focus_mode = Control.FOCUS_NONE
	infinite_floors_button.focus_mode = Control.FOCUS_NONE

func _on_invincible_toggled(on: bool) -> void:
	DevTools.invincible = on

func _on_infinite_floors_toggled(on: bool) -> void:
	DevTools.infinite_floors = on
