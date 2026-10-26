extends Resource
class_name ItemData

# base for everything the player can own/equip: wands, runes, armor, accessories, scrolls
# ChoiceCard, the loadout screen and later the forge only need these fields
@export var id: StringName = &""
@export var display_name: String = "Unnamed Item"
@export_multiline var description: String = ""
@export var icon: Texture2D
