extends RunEffect
class_name SplinterOnKillEffect

# Splinter: a kill fires bolts from the corpse at the nearest enemies.
# damage = a share of the primary spell's damage, so power upgrades carry over
@export var projectile_scene: PackedScene
@export var count: int = 2
@export var damage_fraction: float = 0.5
@export var radius: float = 220.0

func OnEnemyKilled(enemy: Entity, _info: DamageInfo, _xp: int, _is_elite: bool) -> void:
	var player = NodeReferences.player
	if not is_instance_valid(player) or player.wand == null or player.wand.primary == null:
		return
	var origin = enemy.global_position
	var others: Array = []
	for other in enemy.get_tree().get_nodes_in_group("enemy"):
		if other != enemy and not other.is_dead and other.global_position.distance_to(origin) <= radius:
			others.append(other)
	others.sort_custom(func(a, b): return a.global_position.distance_to(origin) < b.global_position.distance_to(origin))
	var damage = player.wand.primary.stats.GetStat(&"damage") * damage_fraction
	for other in others.slice(0, count):
		var projectile = projectile_scene.instantiate() as BaseProjectile
		projectile.caster = player
		projectile.team = BaseProjectile.Team.PLAYER
		projectile.damage = damage
		projectile.global_position = origin
		projectile.SetDirection(origin.direction_to(other.global_position))
		# Die() runs inside a physics callback
		RunState.world_scene.add_child.call_deferred(projectile)
