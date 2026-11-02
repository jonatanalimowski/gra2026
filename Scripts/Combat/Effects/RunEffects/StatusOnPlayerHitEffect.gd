extends RunEffect
class_name StatusOnPlayerHitEffect

# the player gains a status when hit (Smolder curse: 1 Burn). status ticks don't trigger it
@export var status: StatusEffect
@export var stacks: int = 1
@export var strength: float = 1.0

func OnPlayerDamaged(player: Player, info: DamageInfo) -> void:
	if player and status and not info.is_periodic:
		player.ApplyStatus(status, null, strength, 1.0, stacks)
