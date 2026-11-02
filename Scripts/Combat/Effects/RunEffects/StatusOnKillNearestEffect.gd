extends RunEffect
class_name StatusOnKillNearestEffect

# Conductor: kills Shock the 2 nearest enemies. Galvanic Pulse duo: 1 Shock + heal 1 per kill
@export var status: StatusEffect
@export var count: int = 2
@export var radius: float = 160.0
@export var heal_per_kill: float = 0.0

func OnEnemyKilled(enemy: Entity, _info: DamageInfo) -> void:
	var player = NodeReferences.player
	if heal_per_kill > 0.0 and player:
		player.health.Heal(heal_per_kill, false)
	if status == null:
		return
	var origin = enemy.global_position
	var others: Array = []
	for other in enemy.get_tree().get_nodes_in_group("enemy"):
		if other != enemy and not other.is_dead and other.global_position.distance_to(origin) <= radius:
			others.append(other)
	others.sort_custom(func(a, b): return a.global_position.distance_to(origin) < b.global_position.distance_to(origin))
	for other in others.slice(0, count):
		other.ApplyStatus(status, player)
