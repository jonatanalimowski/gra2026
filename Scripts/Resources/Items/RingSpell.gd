extends SpellData
class_name RingSpell

# shot_count projectiles spaced evenly around the caster, first one toward the aim.
# spread = random jitter per projectile (curses can loosen the ring)
func Cast(caster: Node2D, stats: StatBlock, direction: Vector2, spawn_pos: Vector2, all_effects: Array[Effect]) -> void:
	var count = maxi(int(stats.GetStat(&"shot_count")), 1)
	var spread_deg = stats.GetStat(&"spread")
	for i in count:
		var angle = TAU * i / count + deg_to_rad(randf_range(-spread_deg, spread_deg))
		var projectile = projectile_scene.instantiate() as BaseProjectile
		projectile.caster = caster
		projectile.team = BaseProjectile.Team.PLAYER if caster.is_in_group("player") else BaseProjectile.Team.ENEMY
		projectile.damage = stats.GetStat(&"damage")
		projectile.speed_multiplier = stats.GetStat(&"projectile_speed")
		projectile.crit_chance = stats.GetStat(&"crit_chance")
		projectile.crit_multiplier = stats.GetStat(&"crit_multiplier")
		projectile.effects = all_effects
		projectile.global_position = spawn_pos
		projectile.SetDirection(direction.rotated(angle))
		RunState.world_scene.add_child(projectile)
