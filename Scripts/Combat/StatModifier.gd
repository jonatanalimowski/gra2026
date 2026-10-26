extends Resource
class_name StatModifier

# a single change to one stat, e.g. armor giving +20 max_health or a rune giving x1.5 damage
# final value = (base + all flat values) * all multipliers
@export var stat: StringName = &"damage"
@export var flat: float = 0.0
@export var multiplier: float = 1.0
