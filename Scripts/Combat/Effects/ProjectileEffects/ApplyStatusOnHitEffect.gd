extends Effect
class_name ApplyStatusOnHitEffect

# hits apply a status (Kindle = 1 Burn, Rime Bolt = 1 Chill...). to check a target's statuses from
# another effect's ModifyDamage, use StatusEffectHolder.TargetHas / TargetStacks
@export var status: StatusEffect
@export var stacks: int = 1
@export_range(0.0, 1.0) var chance: float = 1.0
# only every nth hit applies it (Static). counted per caster, so it works with any projectile
@export var every_nth: int = 1
# each active half with this flag lowers every_nth by 1 (Static Field glyph), never below 1
@export var every_nth_flag: StringName = &""
# Glacier Lance: only the first enemy each projectile hits
@export var first_hit_only: bool = false
@export var strength: float = 1.0 # tick damage multiplier
@export var duration_multiplier: float = 1.0

func OnHitTarget(projectile: BaseProjectile, target: Node2D, _info: DamageInfo) -> bool:
	if not status or not is_instance_valid(target) or not target.has_method("ApplyStatus"):
		return false
	if first_hit_only:
		if projectile.effect_state.get(self, false):
			return false
		projectile.effect_state[self] = true
	var nth = every_nth
	if every_nth_flag != &"":
		nth = maxi(nth - RunState.CountFlag(every_nth_flag), 1)
	if nth > 1 and is_instance_valid(projectile.caster):
		var key = StringName("hit_count_%d" % absi(get_instance_id()))
		var hits: int = projectile.caster.get_meta(key, 0) + 1
		projectile.caster.set_meta(key, hits)
		if hits % nth != 0:
			return false
	if chance < 1.0 and randf() >= chance:
		return false
	var source = projectile.caster if is_instance_valid(projectile.caster) else null
	target.ApplyStatus(status, source, strength, duration_multiplier, stacks)
	return false
