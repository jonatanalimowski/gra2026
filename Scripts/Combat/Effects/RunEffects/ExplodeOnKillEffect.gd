extends RunEffect
class_name ExplodeOnKillEffect

@export_range(0.0, 1.0) var chance: float = 0.25
@export var damage: float = 15.0
@export var radius: float = 48.0
@export var explosion_scene: PackedScene

func OnEnemyKilled(enemy: Entity, info: DamageInfo) -> void:
	# an explosion kill can't explode again, otherwise one kill clears the room
	if info and info.element == &"explosion":
		return
	if randf() > chance:
		return
	var explosion = explosion_scene.instantiate()
	explosion.Setup(damage, radius, enemy)
	# harmless to the player unless a curse says otherwise (Volatile Dead)
	explosion.hits_player = RunState.HasFlag(&"kill_explosions_hit_player")
	explosion.global_position = enemy.global_position
	# Die() runs inside a physics callback, adding areas there is not allowed
	enemy.get_tree().current_scene.add_child.call_deferred(explosion)
