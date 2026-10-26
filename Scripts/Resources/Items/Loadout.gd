extends Resource
class_name Loadout

# what the player takes into a run. empty slots are allowed
@export var wand: WandData
@export var scroll: ScrollData # empty = default dash
@export var armor: EquipmentData
@export var accessories: Array[EquipmentData] = []

func GetEquipment() -> Array[EquipmentData]:
	var equipment: Array[EquipmentData] = []
	if armor:
		equipment.append(armor)
	equipment.append_array(accessories)
	return equipment
