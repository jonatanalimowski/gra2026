extends Resource
class_name WeaponStats

@export var has_magazine: bool = false
@export var fire_rate: float = 0.5
@export var shots_in_chamber: int = 1
@export var reload_time: int = 2
@export var shot_count: int = 1
@export var firing_offset: float = 10 #inaccuracy in angles
@export var damage = 25

var shots_left: int = 1
