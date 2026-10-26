extends Effect
class_name BounceEffect

# projectile bounces off walls
@export var bounces: int = 1

func OnProjectileSpawned(projectile: BaseProjectile) -> void:
	projectile.effect_state[self] = bounces

func OnHitWall(projectile: BaseProjectile, collision: KinematicCollision2D) -> bool:
	if projectile.effect_state[self] <= 0:
		return false

	projectile.effect_state[self] -= 1
	projectile.SetDirection(projectile.direction.bounce(collision.get_normal()))
	return true
