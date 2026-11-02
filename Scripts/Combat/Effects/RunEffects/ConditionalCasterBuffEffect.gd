extends RunEffect
class_name ConditionalCasterBuffEffect

# spell modifiers on every wand caster while a condition holds, checked every frame (Capacitor:
# +20% fire rate above 50 mana). per caster, so a rebuilt heavy picks it up too
enum Condition { MANA_ABOVE, HEALTH_BELOW, HAS_STATUS }
@export var condition: Condition = Condition.MANA_ABOVE
@export var threshold: float = 50.0 # mana, or HP share for HEALTH_BELOW (0.5 = 50%)
@export var status: StatusEffect
@export var modifiers: Array[StatModifier] = []

func IsActive(player: Player) -> bool:
	match condition:
		Condition.MANA_ABOVE:
			return player.mana > threshold
		Condition.HEALTH_BELOW:
			return player.health.current < player.health.maximum * threshold
		Condition.HAS_STATUS:
			return status != null and player.status_holder.Has(status)
	return false

func OnProcess(player: Player, _delta: float) -> void:
	var active = IsActive(player)
	var applied: Dictionary = RunState.run_effect_state.get_or_add(self, {})
	for caster in player.wand.GetCasters():
		if applied.get(caster, false) == active:
			continue
		applied[caster] = active
		caster.stats.RemoveModifiersFrom(self)
		if active:
			for modifier in modifiers:
				caster.stats.AddModifier(modifier, self)

func OnRemoved(player: Player) -> void:
	if player and player.wand:
		for caster in player.wand.GetCasters():
			caster.stats.RemoveModifiersFrom(self)
	RunState.run_effect_state.erase(self)

# the wand is rebuilt every floor, old casters are gone
func OnAdded(_player: Player) -> void:
	RunState.run_effect_state.erase(self)
