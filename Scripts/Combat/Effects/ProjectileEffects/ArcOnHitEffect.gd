extends Effect
class_name ArcOnHitEffect

# Forked Lightning evolution: every hit also arcs from the target like a Shock discharge
@export var share: float = 1.0 # of the hit, ChainArc then takes its own 50%

func OnHitTarget(_projectile: BaseProjectile, target: Node2D, info: DamageInfo) -> bool:
	if target is Entity:
		ChainArc.Discharge(target, info.amount * share)
	return false
