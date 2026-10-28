extends Effect
class_name RicochetEffect

# projectile turns around after hitting an enemy (was the "ricochet" greater perk)
# TODO: redirect towards the nearest other enemy instead of straight back
@export var ricochets: int = 1

func OnProjectileSpawned(projectile: BaseProjectile) -> void:
	# += so the same effect taken twice (stacked pact) adds its charges
	projectile.effect_state[self] = projectile.effect_state.get(self, 0) + ricochets

func OnHitTarget(projectile: BaseProjectile, _target: Node2D, _info: DamageInfo) -> bool:
	if projectile.survived_hit or projectile.effect_state[self] <= 0:
		return false

	projectile.effect_state[self] -= 1
	projectile.SetDirection(projectile.direction.rotated(PI))
	return true
