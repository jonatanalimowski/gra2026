extends Resource
class_name EntityStats

# base values only - at runtime enemies use a StatBlock built from this (see StatBlock.gd)
@export var max_health: float = 100.0
@export var movement_speed: float = 200.0
@export var acceleration: float = 2.0
@export var attack_damage: float = 10.0
