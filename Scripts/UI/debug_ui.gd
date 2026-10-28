extends Control

var label_dict: Dictionary[String, Label]
@onready var hp_label: Label = %HpLabel
@onready var container: VBoxContainer = %DebugList

func _ready() -> void:
	Signals.debug_ui_updated.connect(UpdateDictionary)
	Signals.player_health_changed.connect(_on_player_health_changed)
	# shown together with the dev panel (F6), layer only exists in debug builds
	if DevTools.layer:
		visible = DevTools.layer.visible
		DevTools.layer.visibility_changed.connect(func(): visible = DevTools.layer.visible)

func _on_player_health_changed(current: int, maximum: int) -> void:
	hp_label.text = "HP: %d/%d" % [current, maximum]

func UpdateDictionary(string_label: Dictionary) -> void:
	label_dict[string_label.keys()[0]] = string_label.values()[0]
	UpdateDebugUI()

# hp_label stays, the rest is rebuilt from label_dict
func UpdateDebugUI():
	for element in container.get_children():
		if element != hp_label:
			container.remove_child(element)
	for key in label_dict:
		container.add_child(label_dict[key])
