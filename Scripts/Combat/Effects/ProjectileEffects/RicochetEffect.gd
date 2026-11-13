extends Effect
class_name RicochetEffect

# projectile turns around after hitting an enemy (was the "ricochet" greater perk)
# TODO: redirect towards the nearest other enemy instead of straight back
@export var ricochets: int = 1
@export var max_ricochet_range: float = 600
@export var after_ricochet_effects: Array[Effect]

func OnProjectileSpawned(projectile: BaseProjectile) -> void:
	# += so the same effect taken twice (stacked pact) adds its charges
	projectile.effect_state[self] = projectile.effect_state.get(self, 0) + ricochets

func OnHitTarget(projectile: BaseProjectile, target: Node2D, _info: DamageInfo) -> bool:
	if projectile.survived_hit or projectile.effect_state[self] <= 0:
		return false
	
	var next_target = FindTarget(projectile, target)
	if not IsValidTarget(next_target):
		return false
	
	projectile.effect_state[self] -= 1
	var new_direction = (next_target.global_position - projectile.global_position).normalized()
	for e in after_ricochet_effects:
		if e not in projectile.effects:
			projectile.effects.append(e)
	
	projectile.SetDirection(new_direction)
	projectile.age = 0.0
	
	return true

func FindTarget(projectile: BaseProjectile, exclude_target: Node2D = null) -> Node2D:
	var group = &"enemy" if projectile.team == BaseProjectile.Team.PLAYER else &"player"
	var best: Node2D = null
	var best_dist = max_ricochet_range
	
	for candidate in projectile.get_tree().get_nodes_in_group(group):
		if candidate == exclude_target:
			continue
		var dist = candidate.global_position.distance_to(projectile.global_position)
		if dist > best_dist:
			continue
		
		best = candidate
		best_dist = dist
	
	return best

func IsValidTarget(target) -> bool:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return false
	return true # projectile.global_position.distance_to(target.global_position) <= 180 * 1.5
