extends Resource
class_name SpellData

# what a wand shoots on one mouse button
# numeric exports become stats (see StatBlock), so runes/blessings can modify them
@export var projectile_scene: PackedScene
@export var damage: float = 25.0
@export var cooldown: float = 0.5 # seconds between casts (was fire_rate)
@export var shot_count: int = 1
@export var spread: float = 10.0 # random angle in degrees (was firing_inaccuracy)
# effects every projectile of this spell has by default
@export var effects: Array[Effect] = []

const STAT_IGNORE_IN_DISPLAY = []
const STAT_DETAILED = ["spread"]

# projectile stats live on the projectile scene's root, so peek at a throwaway instance
func GetProjectileStats() -> ProjectileStats:
	if projectile_scene == null:
		return null
	var projectile = projectile_scene.instantiate()
	var projectile_stats: ProjectileStats = projectile.get("stats")
	projectile.free()
	return projectile_stats

# spell + projectile base stats, e.g. { damage: 25, cooldown: 0.5, ..., speed: 600, lifetime: 5 }
# base values only - live values with runes/blessings are on SpellCaster.stats
func GetDisplayStats() -> Dictionary[StringName, float]:
	var result := StatBlock.FromResource(self).GetDisplayStats()
	var projectile_stats = GetProjectileStats()
	if projectile_stats:
		result.merge(StatBlock.FromResource(projectile_stats).GetDisplayStats())
	return result
