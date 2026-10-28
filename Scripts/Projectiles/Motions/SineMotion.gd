extends ProjectileMotion
class_name SineMotion

# wavy path around the flight direction
@export var amplitude: float = 12.0 # px to each side
@export var frequency: float = 1.0 # waves per second
@export var random_phase: bool = true # start each shot at a random point of the wave

func OnSpawned(projectile: BaseProjectile) -> void:
	projectile.motion_state.phase = randf() * TAU if random_phase else 0.0

func GetVelocity(projectile: BaseProjectile, _delta: float) -> Vector2:
	var w = TAU * frequency
	var forward = projectile.direction * projectile.GetSpeed()
	# derivative of amplitude * sin(w * age), so the side offset itself is a sine
	var phase: float = projectile.motion_state.phase
	var side = projectile.direction.orthogonal() * amplitude * w * cos(w * projectile.age + phase)
	return forward + side
