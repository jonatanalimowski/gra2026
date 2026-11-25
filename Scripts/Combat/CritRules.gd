extends RefCounted
class_name CritRules

# every player crit goes through here, so keystones like Sudden Strike can change the rules in one place
const FIRST_STRIKE_FLAG = &"first_strike"
# Sudden Strike: each 1% crit chance adds +0.02x to the first strike's crit multiplier
const FIRST_STRIKE_CONVERSION: float = 2.0

static func IsFirstStrike() -> bool:
	return RunState.HasFlag(FIRST_STRIKE_FLAG)

# forced crits (Tempest, Arcane Rhythm, Superconductor, Overload arcs) are off under Sudden Strike
static func CanForceCrit() -> bool:
	return not IsFirstStrike()

# a direct hit (projectile, nova). enemy hits always roll normally.
# Sudden Strike: the first direct player hit on each enemy crits, every later hit can't
static func ApplyHitCrit(info: DamageInfo, target: Node, chance: float, multiplier: float, from_player: bool) -> void:
	if not from_player or not IsFirstStrike():
		if randf() < chance:
			info.is_critical = true
			info.amount *= multiplier
		return
	if not (target is Entity) or target.struck_by_player:
		return
	target.struck_by_player = true
	info.is_critical = true
	info.amount *= multiplier + chance * FIRST_STRIKE_CONVERSION
