extends Effect
class_name PierceEffect

# projectile flies through enemies (was the "pierce" greater perk)
@export var pierces: int = 1

func OnProjectileSpawned(projectile: BaseProjectile) -> void:
	projectile.effect_state[self] = pierces

func OnHitTarget(projectile: BaseProjectile, _target: Node2D, _info: DamageInfo) -> bool:
	if projectile.survived_hit or projectile.effect_state[self] <= 0:
		return false

	projectile.effect_state[self] -= 1
	return true
