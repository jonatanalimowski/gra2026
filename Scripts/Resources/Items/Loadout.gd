extends Resource
class_name Loadout

# what the player takes into a run. empty slots are allowed
@export var wand: WandData
@export var scroll: ScrollData # empty = default dash
@export var armor: EquipmentData
@export var accessories: Array[EquipmentData] = []
@export var skill_mods: EquipmentData

func AddStatModFromSkill(stat_mod: StatModifier):
	skill_mods.player_modifiers.append(stat_mod)

func GetEquipment() -> Array[EquipmentData]:
	var equipment: Array[EquipmentData] = []
	if armor:
		equipment.append(armor)
	if skill_mods:
		equipment.append(skill_mods)
	equipment.append_array(accessories)
	return equipment
