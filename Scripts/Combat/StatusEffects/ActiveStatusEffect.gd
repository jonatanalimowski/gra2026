extends RefCounted
class_name ActiveStatusEffect

# one status on one target, the runtime half of a StatusEffect
var effect: StatusEffect
var source: Node2D # who applied it, can be freed while this is still running
var strength: float
var time_left: float
var interval_left: float

func _init(status_effect: StatusEffect, status_source: Node2D, strength_multiplier: float, duration_multiplier: float) -> void:
	effect = status_effect
	source = status_source
	strength = strength_multiplier
	time_left = effect.duration * duration_multiplier
	interval_left = effect.interval

func GetSource() -> Node2D:
	return source if is_instance_valid(source) else null
