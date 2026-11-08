extends RunEffect
class_name ShatterEffect

# Shatter: an enemy that freezes bursts into shards (player projectiles flying outward).
# shards that Chill can freeze the next enemy, so packs chain. Freeze immunity keeps it finite
@export var shard_count: int = 6
@export var shard_damage: float = 10.0
@export var projectile_scene: PackedScene
@export var shard_effects: Array[Effect] = [] # e.g. 1 Chill on hit
const EXTRA_SHARDS_PER_GLYPH: int = 3 # Ice Shards glyph

func OnEnemyKilled(enemy: Entity, _damage_info: DamageInfo, _xp: int, _is_elite: bool) -> void:
	var player = NodeReferences.player
	if player == null or projectile_scene == null or not is_instance_valid(enemy):
		return
	var offset = randf() * TAU
	var count = shard_count + EXTRA_SHARDS_PER_GLYPH * RunState.CountFlag(&"extra_shards")
	for i in count:
		var shard = projectile_scene.instantiate() as BaseProjectile
		shard.caster = player
		shard.team = BaseProjectile.Team.PLAYER
		shard.damage = shard_damage
		shard.motion = ProjectileMotion.new() # straight, whatever the scene's own motion is
		shard.effects = shard_effects
		shard.global_position = enemy.global_position
		shard.SetDirection(Vector2.from_angle(offset + TAU * i / count))
		# born inside the frozen enemy, don't hit it
		shard.add_collision_exception_with(enemy)
		enemy.get_tree().current_scene.add_child.call_deferred(shard)
