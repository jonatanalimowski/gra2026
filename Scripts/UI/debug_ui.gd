extends Control

var label_dict: Dictionary[String, Label]
@onready var container: VBoxContainer = %DebugList

func _ready() -> void:
	Signals.debug_ui_updated.connect(UpdateDictionary)
	# shown together with the dev panel (F6), layer only exists in debug builds
	if DevTools.layer:
		visible = DevTools.layer.visible
		DevTools.layer.visibility_changed.connect(func(): visible = DevTools.layer.visible)

func UpdateDictionary(string_label: Dictionary) -> void:
	label_dict[string_label.keys()[0]] = string_label.values()[0]
	UpdateDebugUI()

func UpdateDebugUI():
	for element in container.get_children():
		container.remove_child(element)
	for key in label_dict:
		container.add_child(label_dict[key])
