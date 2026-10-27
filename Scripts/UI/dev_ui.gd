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

	# one-shot actions, built here so the scene doesn't need editing for each new cheat
	var vbox = $PanelContainer/MarginContainer/VBoxContainer
	AddActionButton(vbox, "Altar offer (F7)", _on_altar_offer_pressed)

func AddActionButton(parent: Node, text: String, callback: Callable) -> void:
	var button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)

func _on_invincible_toggled(on: bool) -> void:
	DevTools.invincible = on

func _on_infinite_floors_toggled(on: bool) -> void:
	DevTools.infinite_floors = on

func _on_altar_offer_pressed() -> void:
	if NodeReferences.player and not get_tree().paused:
		DevTools.OpenPactChoice()
