extends Effect
class_name BounceEffect

# projectile bounces off walls
@export var bounces: int = 1

func OnProjectileSpawned(projectile: BaseProjectile) -> void:
	# += so the same effect taken twice (stacked pact) adds its charges
	projectile.effect_state[self] = projectile.effect_state.get(self, 0) + bounces

func OnHitWall(projectile: BaseProjectile, collision: KinematicCollision2D) -> bool:
	if projectile.survived_hit or projectile.effect_state[self] <= 0:
		return false

	projectile.effect_state[self] -= 1
	projectile.SetDirection(projectile.direction.bounce(collision.get_normal()))
	return true
