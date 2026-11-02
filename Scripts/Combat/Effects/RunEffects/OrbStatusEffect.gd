extends RunEffect
class_name OrbStatusEffect

# Ember Motes: mana orbs flying to the player apply a status to enemies they pass through,
# once per enemy per orb
@export var status: StatusEffect
@export var stacks: int = 1
@export var hit_radius: float = 12.0

func OnOrbProcess(orb: ManaOrb, _delta: float) -> void:
	if status == null or orb.age < orb.scatter_time:
		return
	var hit: Array = orb.effect_state.get_or_add(self, [])
	for enemy in orb.get_tree().get_nodes_in_group("enemy"):
		if enemy in hit or enemy.is_dead:
			continue
		if enemy.global_position.distance_to(orb.global_position) < hit_radius * enemy.scale.x:
			hit.append(enemy)
			enemy.ApplyStatus(status, NodeReferences.player, 1.0, 1.0, stacks)
