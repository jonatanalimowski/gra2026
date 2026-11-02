extends RunEffect
class_name ManaShieldEffect

# Hoarfrost: every mana_per_charge mana collected gives a shield charge (blocks one hit),
# a blocked hit gives the attacker a status
@export var mana_per_charge: float = 30.0
@export var attacker_status: StatusEffect
@export var attacker_stacks: int = 2

func OnOrbCollected(player: Player, _orb: ManaOrb, mana: float) -> void:
	if player == null:
		return
	var stored: float = RunState.run_effect_state.get(self, 0.0) + mana
	while stored >= mana_per_charge:
		stored -= mana_per_charge
		player.AddShield(1)
	RunState.run_effect_state[self] = stored

func OnHitBlocked(player: Player, info: DamageInfo) -> void:
	var attacker = info.source
	if attacker_status and is_instance_valid(attacker) and attacker is Entity:
		attacker.ApplyStatus(attacker_status, player, 1.0, 1.0, attacker_stacks)

func OnRemoved(player: Player) -> void:
	RunState.run_effect_state.erase(self)
	if player:
		player.AddShield(-Player.MAX_SHIELD_CHARGES)
