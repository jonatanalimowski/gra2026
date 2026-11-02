extends Effect
class_name NthHitCritEffect

# Tempest: every nth hit of the caster is a guaranteed crit (counted on the caster, any projectile)
@export var every_nth: int = 10
@export var crit_multiplier: float = 2.0

func ModifyDamage(projectile: BaseProjectile, info: DamageInfo) -> void:
	if not is_instance_valid(projectile.caster) or info.is_critical:
		return
	var key = StringName("crit_count_%d" % absi(get_instance_id()))
	var hits: int = projectile.caster.get_meta(key, 0) + 1
	projectile.caster.set_meta(key, hits)
	if hits % every_nth == 0:
		info.is_critical = true
		info.amount *= projectile.crit_multiplier if projectile.crit_multiplier > 1.0 else crit_multiplier
