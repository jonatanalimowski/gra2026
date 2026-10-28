extends Resource
class_name ProjectileMotion

# decides the path a projectile takes. shared resource: don't store per-projectile state here,
# compute from projectile.age instead. per-projectile randomness: roll it in OnSpawned
# into projectile.motion_state, then GetVelocity reads it back.
# build on projectile.direction so bounce/ricochet keep working.
# base class = straight line
func OnSpawned(_projectile: BaseProjectile) -> void:
	pass

func GetVelocity(projectile: BaseProjectile, _delta: float) -> Vector2:
	return projectile.direction * projectile.GetSpeed()
