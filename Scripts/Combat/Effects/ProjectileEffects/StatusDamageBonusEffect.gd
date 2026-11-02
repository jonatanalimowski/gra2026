extends Effect
class_name StatusDamageBonusEffect

# hits on a target with the status deal more (Searing: Burning x1.2, Fracture: Frozen x1.3)
@export var status: StatusEffect
@export var multiplier: float = 1.2
# true = look at the caster instead of the target (Lifeblood: +20% while Empowered)
@export var check_caster: bool = false

func ModifyDamage(projectile: BaseProjectile, info: DamageInfo) -> void:
	var who = projectile.caster if check_caster and projectile else info.target
	if status and StatusEffectHolder.TargetHas(who, status):
		info.amount *= multiplier
