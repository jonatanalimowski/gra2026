extends RunEffect
class_name StatusSpreadOnKillEffect

# Wildfire: an enemy dying with the status passes its stacks to the nearest enemy in range
@export var status: StatusEffect
@export var radius: float = 120.0

func OnEnemyKilled(enemy: Entity, _info: DamageInfo, _xp: int, _is_elite: bool) -> void:
	var stacks = StatusEffectHolder.TargetStacks(enemy, status)
	if status == null or stacks <= 0:
		return
	var nearest: Entity = null
	var best = radius
	for other in enemy.get_tree().get_nodes_in_group("enemy"):
		if other == enemy or other.is_dead:
			continue
		var distance = other.global_position.distance_to(enemy.global_position)
		if distance < best:
			best = distance
			nearest = other
	if nearest:
		nearest.ApplyStatus(status, NodeReferences.player, 1.0, 1.0, stacks)
