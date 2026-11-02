extends Effect
class_name PlayerHealthDamageEffect

# damage from the caster's missing HP: Frenzy (+1% per 2% missing = per_missing 0.5),
# Hemomancer (below 50% HP: x1.3 = below_share 0.5, below_multiplier 1.3)
@export var per_missing: float = 0.0
@export var below_share: float = 0.0
@export var below_multiplier: float = 1.0

func ModifyDamage(projectile: BaseProjectile, info: DamageInfo) -> void:
	if not (projectile.caster is Player):
		return
	var missing = StatusEffectHolder.GetPlayerMissingHealth()
	info.amount *= 1.0 + per_missing * missing
	if below_share > 0.0 and 1.0 - missing < below_share:
		info.amount *= below_multiplier
