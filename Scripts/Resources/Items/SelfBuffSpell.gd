extends SpellData
class_name SelfBuffSpell

# no projectile: puts a status on the caster (Haste = shared starting heavy of every wand).
# the status' modifiers on spell stats (cooldown...) reach the wand casters, see StatusEffectHolder.ApplyModifiers
@export var status: StatusEffect
@export var status_stacks: int = 1

func Cast(caster: Node2D, _stats: StatBlock, _direction: Vector2, _spawn_pos: Vector2, _all_effects: Array[Effect]) -> void:
	# straight to the holder: Player.ApplyStatus refuses statuses mid-dash, and this one is paid for
	var holder = caster.get("status_holder")
	if status and holder:
		holder.Apply(status, caster, 1.0, 1.0, status_stacks)
	GlobalMethods.FlashSprite(caster.get("sprite"), 0.15, status.color if status else Color.WHITE)

# only casting stats mean anything here, damage/spread/crit would just be noise on the card
func GetDisplayStats() -> Dictionary[String, Dictionary]:
	var flat := StatBlock.FromResource(self).GetDisplayStats()
	var casting := {}
	for stat_name in [&"mana_cost", &"cooldown"]:
		if flat.has(stat_name):
			casting[stat_name] = flat[stat_name]
	var groups: Dictionary[String, Dictionary] = {}
	groups["Casting"] = casting
	return groups
