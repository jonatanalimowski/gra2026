extends ProjectileMotion
class_name RandomMotion

# unpredictable wiggle: a few sines with random frequencies/phases added together.
# the shape is rolled once per projectile, after that it's a fixed function of age
@export var strength: float = 15.0 # rough px of sideways wander
@export var wave_count: int = 3
@export var min_frequency: float = 0.5 # waves per second
@export var max_frequency: float = 2.5

func OnSpawned(projectile: BaseProjectile) -> void:
	var waves: Array[Dictionary] = []
	for i in wave_count:
		var amp = randf_range(0.3, 1.0) * strength / wave_count
		if randf() < 0.5:
			amp = -amp
		waves.append({
			amp = amp,
			w = TAU * randf_range(min_frequency, max_frequency),
			phase = randf() * TAU,
		})
	projectile.motion_state.waves = waves

func GetVelocity(projectile: BaseProjectile, _delta: float) -> Vector2:
	var forward = projectile.direction * projectile.GetSpeed()
	# derivative of sum(amp * sin(w * age + phase)), so the side offset is that sum
	var side_speed := 0.0
	for wave in projectile.motion_state.waves:
		side_speed += wave.amp * wave.w * cos(wave.w * projectile.age + wave.phase)
	return forward + projectile.direction.orthogonal() * side_speed
