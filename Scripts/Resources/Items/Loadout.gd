extends Resource
class_name Loadout

# what the player takes into a run. empty slots are allowed
@export var wand: WandData
@export var scroll: ScrollData # empty = default dash
@export var armor: EquipmentData
@export var accessories: Array[EquipmentData] = []
# filled by SkillManager.CollectRewards at run start, never saved or edited by hand
@export var skill_mods: EquipmentData
@export var extra_runes: Array[RuneData] = [] # skill-tree runes on top of the wand's own
@export var schools: Array[School.Kind] = [] # filled by CollectRewards: schools whose pacts can be offered

func GetEquipment() -> Array[EquipmentData]:
	var equipment: Array[EquipmentData] = []
	if armor:
		equipment.append(armor)
	if skill_mods:
		equipment.append(skill_mods)
	equipment.append_array(accessories)
	return equipment
