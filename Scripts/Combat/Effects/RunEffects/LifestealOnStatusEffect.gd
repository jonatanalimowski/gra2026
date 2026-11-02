extends RunEffect
class_name LifestealOnStatusEffect

# Transfusion (Bleed) / Boiling Blood (Burn): the status's damage heals the player for a share of it
@export var status: StatusEffect
@export var share: float = 0.05

func OnEnemyDamaged(_enemy: Entity, info: DamageInfo, amount: float) -> void:
	var player = NodeReferences.player
	if player and info.status == status and amount > 0.0:
		player.health.Heal(amount * share, false)
