extends RunEffect
class_name KillAreaEffect

# a StatusArea where an enemy dies (Scorched Earth curse: a burning patch that hurts the player)
@export var area_scene: PackedScene
@export var area_radius: float = 16.0
@export_range(0.0, 1.0) var chance: float = 1.0
@export var strength: float = 1.0

func OnEnemyKilled(enemy: Entity, _info: DamageInfo, _xp: int, _is_elite: bool) -> void:
	if area_scene == null or randf() > chance:
		return
	var area = area_scene.instantiate() as StatusArea
	area.Setup(area_radius, null, strength)
	area.global_position = enemy.global_position
	enemy.get_tree().current_scene.add_child.call_deferred(area)
