extends ItemData
class_name AltarPact

# a run-wide buff + curse offered at an altar. name/icon come from ItemData (display_name, icon)

#buff_half
@export_multiline var buff_description: String = ""
@export var player_modifiers: Array[StatModifier] = []
@export var effects: Array[Effect] = [] #projectile hooks
@export var run_effects: Array[RunEffect] = [] #event hooks (on kill etc.)

#curse_half
@export_multiline var curse_description: String = ""
@export var curse_player_modifiers: Array[StatModifier] = []
@export var curse_effects: Array[Effect] = []
@export var curse_run_effects: Array[RunEffect] = []
@export var enemy_modifiers: Array[StatModifier] = []

#pool settings
@export var weight: float = 1.0
@export var min_floor: int = 1

func GetDescription() -> String:
	return "%s\n\nCURSE: %s" % [buff_description, curse_description]
