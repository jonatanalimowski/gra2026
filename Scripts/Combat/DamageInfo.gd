extends RefCounted
class_name DamageInfo

# everything TakeDamage() needs to know about a hit
# effects can change it before it lands (crits, elements) or read it after (vampirism)
var amount: float
var source: Node2D # who caused the damage (the player for player spells, the enemy for melee)
var is_critical: bool = false
var knockback: Vector2 = Vector2.ZERO # direction * force, zero = no push
var element: StringName = &""

func _init(damage_amount: float, damage_source: Node2D = null) -> void:
	amount = damage_amount
	source = damage_source
