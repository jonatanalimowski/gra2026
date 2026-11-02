extends Node
class_name StatusEffectHolder

# child of the player or an enemy, runs the statuses on it. the parent needs stats, is_dead, TakeDamage.
# counts down with delta, so statuses pause with the game and disappear with their target
signal status_added(status: ActiveStatusEffect)
signal status_removed(status: ActiveStatusEffect)
# a status already on the target was applied again (refreshed and/or stacked)
signal status_changed(status: ActiveStatusEffect)

var active: Array[ActiveStatusEffect] = []
@onready var target = get_parent()

# getting the same effect again refreshes it and adds stacks up to max_stacks (1 = refresh only,
# so overlapping poison circles don't multiply). the tick timer keeps running, or standing in a cloud would stop the ticks
func Apply(effect: StatusEffect, source: Node2D, strength: float = 1.0, duration_multiplier: float = 1.0, stacks: int = 1) -> void:
	# Warded affix / Kindled Halls: immune to one school's statuses
	if effect.ward_group != &"" and target.get("ward_group") == effect.ward_group:
		return
	if IsTweakable():
		duration_multiplier *= RunState.GetStatusDurationMultiplier(effect)
		stacks += RunState.GetStatusExtraApplication(effect)
	var new_status := ActiveStatusEffect.new(effect, source, strength, duration_multiplier, stacks, GetMaxStacks(effect))
	var status := GetStatus(effect)
	if status:
		status.time_left = maxf(status.time_left, new_status.time_left)
		status.strength = maxf(status.strength, strength)
		status.source = source
		var new_stacks = mini(status.stacks + stacks, maxi(GetMaxStacks(effect), 1))
		if new_stacks != status.stacks:
			status.stacks = new_stacks
			ApplyModifiers(status)
		status_changed.emit(status)
		return

	active.append(new_status)
	ApplyModifiers(new_status)
	status_added.emit(new_status)

func Remove(status: ActiveStatusEffect) -> void:
	if status not in active:
		return
	target.stats.RemoveModifiersFrom(status)
	active.erase(status)
	status_removed.emit(status)

func RemoveEffect(effect: StatusEffect) -> void:
	var status := GetStatus(effect)
	if status:
		Remove(status)

# the status is the source, so a stack change can take back exactly its old modifiers
func ApplyModifiers(status: ActiveStatusEffect) -> void:
	target.stats.RemoveModifiersFrom(status)
	for modifier in status.BuildModifiers():
		if target.stats.HasStat(modifier.stat):
			target.stats.AddModifier(modifier, status)

# 0 = full HP, 0.7 = 70% missing (Bleed, Frenzy)
static func GetPlayerMissingHealth() -> float:
	var player = NodeReferences.player
	if player == null or player.health == null or player.health.maximum <= 0:
		return 0.0
	return 1.0 - player.health.current / player.health.maximum

# glyphs (StatusTweak) only change statuses on enemies, the player's own Burn (Smolder) stays as written
func IsTweakable() -> bool:
	return target.is_in_group("enemy")

func GetMaxStacks(effect: StatusEffect) -> int:
	var extra = RunState.GetStatusExtraStacks(effect) if IsTweakable() else 0
	return effect.max_stacks + extra

func GetStatus(effect: StatusEffect) -> ActiveStatusEffect:
	for status in active:
		if status.effect == effect:
			return status
	return null

func Has(effect: StatusEffect) -> bool:
	return GetStatus(effect) != null

func GetStacks(effect: StatusEffect) -> int:
	var status := GetStatus(effect)
	return status.stacks if status else 0

# for effects that look at a hit target (ModifyDamage etc.): false/0 for anything without statuses
static func TargetHas(target: Node, effect: StatusEffect) -> bool:
	return TargetStacks(target, effect) > 0

static func TargetStacks(target: Node, effect: StatusEffect) -> int:
	if not is_instance_valid(target) or not ("status_holder" in target) or target.status_holder == null:
		return 0
	return target.status_holder.GetStacks(effect)

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

# no sprite flash here: a flash means "you hit it". the target shows ticks its own way
# (enemies: small damage number in the status color)
func Tick(status: ActiveStatusEffect) -> void:
	var effect := status.effect
	if effect.damage > 0.0:
		var amount := effect.damage * status.strength * status.stacks
		if effect.scales_with_missing_hp:
			amount *= 1.0 + GetPlayerMissingHealth()
		var info := DamageInfo.new(amount, status.GetSource())
		info.element = effect.element
		info.is_periodic = true
		info.status = effect
		target.TakeDamage(info)
