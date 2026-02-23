extends Resource
class_name PlayerStats

@export var max_health: float = 100.0
@export var movement_speed: float = 100.0
@export var acceleration: float = 3000.0
@export var dash_distance: float = 25.0
@export var dash_speed: float = 300.0
@export var dash_cooldown: float = 1.0
@export var friction: float = 5000.0

const STAT_IGNORE_IN_DISPLAY = ["friction", "acceleration", "current_health", "max_health"]
const STAT_DETAILED = ["dash_distance", "dash_speed", "dash_cooldown"]

var current_health: float

func update_stat(stat_name: String, value: float) -> void:
	if stat_name in self:
		set(stat_name, value)
		Signals.player_stat_changed.emit(stat_name, value)
	else:
		print("NO STAT CALLED: " + stat_name)
