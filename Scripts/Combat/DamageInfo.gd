extends RefCounted
class_name DamageInfo

# everything TakeDamage() needs to know about a hit
# effects can change it before it lands (crits, elements) or read it after (vampirism)
var amount: float
var source: Node2D # who caused the damage (the player for player spells, the enemy for melee)
var is_critical: bool = false
var knockback: Vector2 = Vector2.ZERO # direction * force, zero = no push
var element: StringName = &""
var is_periodic: bool = false # status tick (poison): still real damage, but no hit flash / sound / vignette
var status: StatusEffect # the status that ticked, null for hits
var target: Node2D # who gets hit, set by Projectile before ModifyDamage so effects can read its statuses
var is_arc: bool = false # Shock discharge arc: doesn't discharge Shock again or trigger on-hit effects

func _init(damage_amount: float, damage_source: Node2D = null) -> void:
	amount = damage_amount
	source = damage_source
