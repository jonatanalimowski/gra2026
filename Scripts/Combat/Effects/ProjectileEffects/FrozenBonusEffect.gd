extends Effect
class_name FrozenBonusEffect

# Glacier: the first hit on a Frozen enemy (per freeze) deals x multiplier
@export var multiplier: float = 2.0

func ModifyDamage(_projectile: BaseProjectile, info: DamageInfo) -> void:
	var target = info.target
	if not (target is Entity) or not target.IsFrozen():
		return
	if target.get_meta(&"glacier_freeze", -1) == target.freeze_count:
		return
	target.set_meta(&"glacier_freeze", target.freeze_count)
	info.amount *= multiplier
	info.is_critical = true # gold number, reads as the payoff
