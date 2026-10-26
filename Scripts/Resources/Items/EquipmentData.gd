extends ItemData
class_name EquipmentData

# armor, rings and amulets
@export var player_modifiers: Array[StatModifier] = [] # e.g. +20 max_health, x0.9 movement_speed
@export var effects: Array[Effect] = [] # added to every spell the player casts, e.g. vampirism
