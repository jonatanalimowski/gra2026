extends Resource
class_name PlayerStats

# base values only - at runtime the player uses a StatBlock built from this (see StatBlock.gd)
@export var max_health: float = 100.0
@export var movement_speed: float = 1000.0
@export var acceleration: float = 1000.0
@export var friction: float = 1300

const STAT_IGNORE_IN_DISPLAY = ["friction", "acceleration", "max_health"]
const STAT_DETAILED = []
