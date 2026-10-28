extends Resource
class_name ItemData

# base for everything the player can own/equip: wands, runes, armor, accessories, scrolls
# ChoiceCard, the loadout screen and later the forge only need these fields
@export var id: StringName = &""
@export var display_name: String = "Unnamed Item"
@export_multiline var description: String = ""
@export var icon: Texture2D

# card text. override when the text is built from other fields (AltarPact = buff + curse)
func GetDescription() -> String:
	return description

# same text with bbcode (colors etc.) for RichTextLabels. tooltips use the plain one
func GetRichDescription() -> String:
	return GetDescription()

func GetTagIcons() -> Array[Texture2D]:
	return []

# stats for tooltips, grouped by section title: { "Wand": { rune_slots: 2 }, "Primary": {...} }
# empty = item has no stats to show
func GetDisplayStats() -> Dictionary[String, Dictionary]:
	return {}
