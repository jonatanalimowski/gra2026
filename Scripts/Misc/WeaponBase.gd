extends Node
class_name Weapon

# Weapon Params
@export var projectile: PackedScene
@export var stats: WeaponStats
@export var name_text: String = "Unnamed Weapon"
@export var description_text: String = "A weapon made for attacking your enemies" 
@export var icon: Texture2D

# Perks
@export var greater_perks: Dictionary[String, WeaponPerk] = {
	"bounce_walls": null,
	"ricochet": null,
	"projectile+1": null,
	"pierce": null
}
@export var lesser_perks: Array[WeaponPerk] = []

# Variables
var can_shoot: bool = true

func AddPerk(perk: WeaponPerk):
	if perk.type == perk.PerkType.GREATER:
		if greater_perks[perk.effect_id] == null:
			greater_perks[perk.effect_id] = perk
		else:
			print("Too many perks! can't equip")
	else:
		lesser_perks.append(perk)

func Shoot(direction: Vector2, spawn_pos: Vector2):
	
	# Configures Lesser Perks
	var damage = stats.damage
	var shot_count = stats.shot_count
	var firing_inaccuracy = stats.firing_inaccuracy
	var fire_rate = stats.fire_rate
	for perk in lesser_perks:
		match perk.stat_to_change:
			"damage":
				damage += perk.flat_addition
				damage *= perk.multiplier
			"shot_count":
				shot_count += perk.flat_addition
			"firing_innacuracy":
				firing_inaccuracy += perk.flat_addition
				firing_inaccuracy /= perk.multiplier
			"fire_rate":
				fire_rate -= perk.flat_addition
				fire_rate /= perk.multiplier

	if can_shoot == false: return
	else:
		for i in stats.shot_count:
			if stats.shots_left > 0:
				# Sets projectile params and instantiates
				var instantiated_projectile = projectile.instantiate() as BaseProjectile
				instantiated_projectile.greater_perks = self.greater_perks
				instantiated_projectile.stats.damage = stats.damage
				instantiated_projectile.global_position = spawn_pos
				
				# Calculates velocity and adds to scene
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
