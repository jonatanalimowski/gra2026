extends RunEffect
class_name StatusOnHealOrbEffect

# Lifeblood: picking up a healing orb gives the player a status (Empowered: +20% damage for 3s,
# the damage part is a StatusDamageBonusEffect with check_caster)
@export var status: StatusEffect

func OnOrbCollected(player: Player, orb: ManaOrb, _mana: float) -> void:
	if player and status and orb and orb.is_healing:
		player.ApplyStatus(status, player)
