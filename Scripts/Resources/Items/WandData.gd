extends ItemData
class_name WandData

@export var primary_spell: SpellData # left click
@export var heavy_spell: SpellData # right click, can be empty
@export var rune_slots: int = 2
@export var runes: Array[RuneData] = []

func GetDisplayStats() -> Dictionary[String, Dictionary]:
	var sections: Dictionary[String, Dictionary] = { "Wand": { &"rune_slots": float(rune_slots) } }
	if primary_spell:
		sections["Primary"] = primary_spell.GetDisplayStats()
	if heavy_spell:
		sections["Heavy"] = heavy_spell.GetDisplayStats()
	return sections
