extends RefCounted
class_name ActiveStatusEffect

# one status on one target, the runtime half of a StatusEffect
var effect: StatusEffect
var source: Node2D # who applied it, can be freed while this is still running
var strength: float
var stacks: int = 1
var time_left: float
var interval_left: float

func _init(status_effect: StatusEffect, status_source: Node2D, strength_multiplier: float, duration_multiplier: float, stack_count: int = 1, max_stacks: int = -1) -> void:
	effect = status_effect
	source = status_source
	strength = strength_multiplier
	if max_stacks < 0:
		max_stacks = effect.max_stacks
	stacks = clampi(stack_count, 1, maxi(max_stacks, 1))
	time_left = effect.duration * duration_multiplier
	interval_left = effect.interval

func GetSource() -> Node2D:
	return source if is_instance_valid(source) else null

# the effect's modifiers scaled by stacks. new objects every time, the shared .tres ones are never touched
func BuildModifiers() -> Array[StatModifier]:
	var result: Array[StatModifier] = []
	for modifier in effect.modifiers:
		var scaled := StatModifier.new()
		scaled.stat = modifier.stat
		scaled.flat = modifier.flat * stacks
		scaled.multiplier = maxf(1.0 + (modifier.multiplier - 1.0) * stacks, 0.0)
		result.append(scaled)
	return result
