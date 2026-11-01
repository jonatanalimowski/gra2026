extends Node
class_name StatusEffectHolder

# child of the player or an enemy, runs the statuses on it. the parent needs stats, sprite, is_dead, TakeDamage.
# counts down with delta, so statuses pause with the game and disappear with their target
signal status_added(status: ActiveStatusEffect)
signal status_removed(status: ActiveStatusEffect)

var active: Array[ActiveStatusEffect] = []
@onready var target = get_parent()

# getting the same effect again refreshes it instead of stacking, so overlapping circles don't multiply poison.
# the tick timer keeps running, or standing in a cloud would stop the ticks
func Apply(effect: StatusEffect, source: Node2D, strength: float = 1.0, duration_multiplier: float = 1.0) -> void:
	var new_status := ActiveStatusEffect.new(effect, source, strength, duration_multiplier)
	for status in active:
		if status.effect == effect:
			status.time_left = maxf(status.time_left, new_status.time_left)
			status.strength = maxf(status.strength, strength)
			status.source = source
			return

	active.append(new_status)
	for modifier in effect.modifiers:
		if target.stats.HasStat(modifier.stat):
			target.stats.AddModifier(modifier, new_status) # the status is the source, Remove takes back exactly this
	status_added.emit(new_status)

func Remove(status: ActiveStatusEffect) -> void:
	target.stats.RemoveModifiersFrom(status)
	active.erase(status)
	status_removed.emit(status)

func _physics_process(delta: float) -> void:
	# a copy, removing while looping would skip one
	for status in active.duplicate():
		status.time_left -= delta
		if status.effect.interval > 0.0:
			status.interval_left -= delta
			if status.interval_left <= 0.0:
				status.interval_left += status.effect.interval
				Tick(status)
				if target.is_dead:
					return
		if status.time_left <= 0.0:
			Remove(status)

func Tick(status: ActiveStatusEffect) -> void:
	var effect := status.effect
	if effect.damage > 0.0:
		var info := DamageInfo.new(effect.damage * status.strength, status.GetSource())
		info.element = effect.element
		info.is_periodic = true
		target.TakeDamage(info)
	if not target.is_dead:
		GlobalMethods.FlashSprite(target.sprite, 0.2, effect.color)
