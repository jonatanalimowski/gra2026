extends ItemData
class_name WandData

@export var primary_spell: SpellData # left click
@export var heavy_spell: SpellData # right click, can be empty
@export var rune_slots: int = 2
@export var runes: Array[RuneData] = []
