extends RunEffect
class_name FreezeSpreadEffect

# Absolute Zero: freezing an enemy gives a status to every enemy nearby (2 Chill, can chain freezes)
@export var status: StatusEffect
@export var stacks: int = 2
@export var radius: float = 80.0

func OnEnemyFrozen(enemy: Entity) -> void:
	if status == null or not is_instance_valid(enemy):
		return
	for other in enemy.get_tree().get_nodes_in_group("enemy"):
		if other != enemy and not other.is_dead and other.global_position.distance_to(enemy.global_position) < radius:
			# deferred: we're inside the first enemy's Freeze, this could freeze the next one right away
			other.ApplyStatus.call_deferred(status, NodeReferences.player, 1.0, 1.0, stacks)
