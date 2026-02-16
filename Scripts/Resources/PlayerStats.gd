extends Resource
class_name PlayerStats

@export var max_health: float = 100.0
@export var movement_speed: float = 200.0
@export var acceleration: float = 3000.0
@export var dash_distance: float = 500.0
@export var dash_speed: float = 1000.0
@export var dash_acceleration: float = 500.0
@export var dash_duration: float = 0.1
@export var dash_cooldown: float = 1.0
@export var friction: float = 5000.0
@export var attack_damage: float = 10.0

var current_health: float
