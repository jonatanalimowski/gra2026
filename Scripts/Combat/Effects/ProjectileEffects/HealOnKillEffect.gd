extends Effect
class_name HealOnKillEffect

# a hit that kills heals the caster (Hemoclast: 1 HP per saw kill)
@export var heal: float = 1.0

func OnHitTarget(projectile: BaseProjectile, target: Node2D, _info: DamageInfo) -> bool:
	if target.get("is_dead") and projectile.caster is Player and is_instance_valid(projectile.caster):
		projectile.caster.health.Heal(heal, false)
	return false
