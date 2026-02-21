extends Node
class_name Weapon

@export var projectile: PackedScene
@export var stats: WeaponStats 
var can_shoot: bool = true

func Shoot(direction: Vector2, spawn_pos: Vector2):
	if can_shoot:
		for i in stats.shot_count:
			if stats.shots_left > 0:
				var instantiated_projectile = projectile.instantiate() as BaseProjectile
				instantiated_projectile.stats.damage = stats.damage
				instantiated_projectile.global_position = spawn_pos
				var rotated_dir = direction.rotated(deg_to_rad(randf_range(-stats.firing_inaccuracy, stats.firing_inaccuracy)))
				instantiated_projectile.rotation = rotated_dir.angle() + PI/2
				instantiated_projectile.direction = rotated_dir
				get_tree().get_root().add_child(instantiated_projectile)
			if stats.has_magazine:
				stats.shots_left -= 1
		can_shoot = false
		get_tree().create_timer(stats.fire_rate).timeout.connect(func(): can_shoot = true)

func Reload():
	stats.shots_left =  stats.shots_in_chamber
	pass

func GetStats() -> Dictionary[String, float]:
	return stats.GetStatsAsDict()
