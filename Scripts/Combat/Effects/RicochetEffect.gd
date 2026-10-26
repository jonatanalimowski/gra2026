extends Effect
class_name RicochetEffect

# projectile turns around after hitting an enemy (was the "ricochet" greater perk)
# TODO: redirect towards the nearest other enemy instead of straight back
@export var ricochets: int = 1

func OnProjectileSpawned(projectile: BaseProjectile) -> void:
	projectile.effect_state[self] = ricochets

func OnHitTarget(projectile: BaseProjectile, _target: Node2D, _info: DamageInfo) -> bool:
	if projectile.effect_state[self] <= 0:
		return false

	projectile.effect_state[self] -= 1
	projectile.SetDirection(projectile.direction.rotated(PI))
	return true
