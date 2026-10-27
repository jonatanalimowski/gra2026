extends Resource
class_name Effect

# Base class for anything that changes HOW things behave (not just numbers - that's StatModifier).
# Runes, rings/amulets and blessings hold a list of effects. Every projectile gets the effects of
# its spell, its wand's runes and the player's equipment, and calls these hooks at the right moment.
# Override only the hooks you need, e.g. Burn -> OnHitTarget, Split -> OnProjectileSpawned.
#
# Effect resources are shared between projectiles, so per-projectile data (bounces left etc.)
# goes in projectile.effect_state[self], never in a variable on the effect.

func OnProjectileSpawned(_projectile: BaseProjectile) -> void:
	pass

# change the hit before it lands (crits, elements, damage bonuses)
func ModifyDamage(_projectile: BaseProjectile, _info: DamageInfo) -> void:
	pass

# called after damage was dealt. return true to keep the projectile alive
func OnHitTarget(_projectile: BaseProjectile, _target: Node2D, _info: DamageInfo) -> bool:
	return false

# return true to keep the projectile alive
func OnHitWall(_projectile: BaseProjectile, _collision: KinematicCollision2D) -> bool:
	return false
