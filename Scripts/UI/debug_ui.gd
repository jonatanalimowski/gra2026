extends Control

var label_dict: Dictionary[String, Label]
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HpLabel
@onready var container: VBoxContainer = $MarginContainer/VBoxContainer

func _ready() -> void:
	Signals.debug_ui_updated.connect(UpdateDictionary)

func _process(delta: float) -> void:
	pass

func UpdateDictionary(string_label: Dictionary) -> void:
	label_dict[string_label.keys()[0]] = string_label.values()[0]
	UpdateDebugUI()

func UpdateDebugUI():
	for element in container.get_children():
		element.queue_free()
	for key in label_dict:
		container.add_child(label_dict[key])
