extends Effect
class_name VampiricSpellEffect

@export_range(0.0, 1.0) var chance: float = 0.15
@export var heal_amount: float = 3.0
@export var tint: Color = Color(1, 0.3, 0.3)

func OnProjectileSpawned(projectile: BaseProjectile) -> void:
	var is_vampiric = randf() < chance
	projectile.effect_state[self] = is_vampiric
	if is_vampiric:
		projectile.sprite.modulate = tint      # player must SEE which shots are vampiric

func OnHitTarget(projectile: BaseProjectile, _target: Node2D, _info: DamageInfo) -> bool:
	if projectile.effect_state.get(self, false) and projectile.caster is Player:
		projectile.caster.health.Heal(heal_amount)
	return false
