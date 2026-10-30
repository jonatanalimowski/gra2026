extends Effect
class_name HomingEffect

# steers the projectile toward the nearest target. only turns projectile.direction,
# so it works with any motion (a sine shot wiggles around the homing heading) and bounces
@export var turn_speed: float = 240.0 # degrees per second, higher = tighter turns
@export var seek_range: float = 180.0 # px, how far it looks for a target
@export var seek_angle: float = 100.0 # only locks targets within this many degrees of its heading
@export var start_delay: float = 0.08 # s of straight flight before it starts steering
@export var search_interval: float = 0.1 # s between target searches while it has none

func OnProjectileSpawned(projectile: BaseProjectile) -> void:
	projectile.effect_state[self] = {target = null, next_search = start_delay, hit = []}

func OnPhysicsProcess(projectile: BaseProjectile, delta: float) -> void:
	if projectile.age < start_delay:
		return
	var state: Dictionary = projectile.effect_state[self]
	if not IsValidTarget(projectile, state.target, state.hit):
		state.target = null
		if projectile.age >= state.next_search:
			state.target = FindTarget(projectile, state.hit)
			state.next_search = projectile.age + search_interval
	if state.target == null:
		return

	var to_target = projectile.global_position.direction_to(state.target.global_position)
	var max_turn = deg_to_rad(turn_speed) * delta
	var angle = clampf(projectile.direction.angle_to(to_target), -max_turn, max_turn)
	projectile.direction = projectile.direction.rotated(angle)

# after a hit (pierce/ricochet kept it alive) go for someone else
func OnHitTarget(projectile: BaseProjectile, target: Node2D, _info: DamageInfo) -> bool:
	var state: Dictionary = projectile.effect_state[self]
	state.hit.append(target)
	state.target = null
	return false

func FindTarget(projectile: BaseProjectile, hit: Array) -> Node2D:
	var group = &"enemy" if projectile.team == BaseProjectile.Team.PLAYER else &"player"
	var best: Node2D = null
	var best_dist = seek_range
	for candidate in projectile.get_tree().get_nodes_in_group(group):
		if candidate in hit:
			continue
		var offset = candidate.global_position - projectile.global_position
		var dist = offset.length()
		if dist > best_dist:
			continue
		if absf(projectile.direction.angle_to(offset)) > deg_to_rad(seek_angle):
			continue
		best = candidate
		best_dist = dist
	return best

# keeps the lock until the target dies or gets well out of range (no cone check, so it can turn back)
func IsValidTarget(projectile: BaseProjectile, target, hit: Array) -> bool:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return false
	if target in hit:
		return false
	return projectile.global_position.distance_to(target.global_position) <= seek_range * 1.5
