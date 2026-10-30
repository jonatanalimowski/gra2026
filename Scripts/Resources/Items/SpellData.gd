extends Resource
class_name SpellData

# what a wand shoots on one mouse button
# numeric exports become stats (see StatBlock), so runes/blessings can modify them
@export var projectile_scene: PackedScene
@export var damage: float = 25.0
@export var cooldown: float = 0.5 # seconds between casts (was fire_rate)
@export var shot_count: int = 1
@export var spread: float = 10.0 # random angle in degrees (was firing_inaccuracy)
@export var projectile_speed: float = 1.0 # multiplier on the projectile's own speed
@export var crit_chance: float = 0.0 # 0.1 = 10% per hit
@export var crit_multiplier: float = 2.0
@export var mana_cost: float = 0.0 # paid by the player on cast, enemies ignore it
# effects every projectile of this spell has by default
@export var effects: Array[Effect] = []

const STAT_IGNORE_IN_DISPLAY = []
const STAT_DETAILED = ["spread", "crit_multiplier"]
# card sections, stats not listed land in "Other". covers projectile stats too
const STAT_GROUPS = {
	"Offense": ["damage", "crit_chance", "crit_multiplier", "knockback_force"],
	"Casting": ["mana_cost", "cooldown", "shot_count", "spread"],
	"Projectile": ["projectile_speed", "speed", "lifetime"],
}

# what one cast does. stats = the caster's live StatBlock (runes, pacts applied)
# override in a subclass for spells that aren't plain projectiles (blast at the cursor, beam...)
func Cast(caster: Node2D, stats: StatBlock, direction: Vector2, spawn_pos: Vector2, all_effects: Array[Effect]) -> void:
	var spread_deg = stats.GetStat(&"spread")
	for i in int(stats.GetStat(&"shot_count")):
		var projectile = projectile_scene.instantiate() as BaseProjectile
		projectile.caster = caster
		# same spell can be fired by either side, the caster decides what it hits
		projectile.team = BaseProjectile.Team.PLAYER if caster.is_in_group("player") else BaseProjectile.Team.ENEMY
		projectile.damage = stats.GetStat(&"damage")
		projectile.speed_multiplier = stats.GetStat(&"projectile_speed")
		projectile.crit_chance = stats.GetStat(&"crit_chance")
		projectile.crit_multiplier = stats.GetStat(&"crit_multiplier")
		projectile.effects = all_effects
		projectile.global_position = spawn_pos
		projectile.SetDirection(direction.rotated(deg_to_rad(randf_range(-spread_deg, spread_deg))))
		# projectiles belong to the current scene, so they get removed with it
		caster.get_tree().current_scene.add_child(projectile)

# projectile stats live on the projectile scene's root, so peek at a throwaway instance
func GetProjectileStats() -> ProjectileStats:
	if projectile_scene == null:
		return null
	var projectile = projectile_scene.instantiate()
	var projectile_stats: ProjectileStats = projectile.get("stats")
	projectile.free()
	return projectile_stats

# spell + projectile base stats split into STAT_GROUPS:
# { "Offense": { damage: 25, ... }, "Casting": { cooldown: 0.5, ... }, "Projectile": { speed: 600, ... } }
# base values only - live values with runes/blessings are on SpellCaster.stats
func GetDisplayStats() -> Dictionary[String, Dictionary]:
	var flat := StatBlock.FromResource(self).GetDisplayStats()
	var projectile_stats = GetProjectileStats()
	if projectile_stats:
		flat.merge(StatBlock.FromResource(projectile_stats).GetDisplayStats())
	if flat.get(&"mana_cost", 0.0) == 0.0:
		flat.erase(&"mana_cost") # free spells don't need the line

	var groups: Dictionary[String, Dictionary] = {}
	for group_name in STAT_GROUPS:
		for stat_name in STAT_GROUPS[group_name]:
			if flat.has(stat_name):
				if not groups.has(group_name):
					groups[group_name] = {}
				groups[group_name][stat_name] = flat[stat_name]
				flat.erase(stat_name)
	if not flat.is_empty():
		groups["Other"] = flat
	return groups
