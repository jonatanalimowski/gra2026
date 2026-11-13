extends Effect
class_name DamageModEffect

@export var flat: int = 0
@export var multiplier: float = 1

func ModifyDamage(_projectile: BaseProjectile, info: DamageInfo) -> void:
	info.amount += flat
	info.amount *= multiplier
