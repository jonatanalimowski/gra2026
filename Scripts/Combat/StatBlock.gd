extends RefCounted
class_name StatBlock

# Runtime stats of the player, an enemy or a spell.
# Base values are copied from a stats Resource (PlayerStats, EntityStats, SpellData) so the
# .tres file is never modified. Everything that changes stats (armor, runes, blessings, altars,
# skill tree) adds a StatModifier together with its source, and can later be removed by that source.

signal stat_changed(stat_name: StringName, value: float)

var hidden_stats: Array = [] # not shown in the HUD
var detailed_stats: Array = [] # only shown in the HUD after pressing Tab

var _base: Dictionary[StringName, float] = {}
var _modifiers: Array[Dictionary] = [] # [{ "modifier": StatModifier, "source": Object }]

# copies every exported int/float of the resource as a base stat
static func FromResource(resource: Resource) -> StatBlock:
	var block := StatBlock.new()
	for prop in resource.get_property_list():
		var is_exported_script_var = prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and prop.usage & PROPERTY_USAGE_STORAGE
		if is_exported_script_var and prop.type in [TYPE_FLOAT, TYPE_INT]:
			block._base[prop.name] = float(resource.get(prop.name))

	var constants = resource.get_script().get_script_constant_map()
	block.hidden_stats = constants.get("STAT_IGNORE_IN_DISPLAY", [])
	block.detailed_stats = constants.get("STAT_DETAILED", [])
	return block

func GetStat(stat_name: StringName) -> float:
	if not _base.has(stat_name):
		push_warning("NO STAT CALLED: " + stat_name)
		return 0.0

	var flat := 0.0
	var multiplier := 1.0
	for entry in _modifiers:
		var modifier: StatModifier = entry.modifier
		if modifier.stat == stat_name:
			flat += modifier.flat
			multiplier *= modifier.multiplier
	return (_base[stat_name] + flat) * multiplier

func HasStat(stat_name: StringName) -> bool:
	return _base.has(stat_name)

func GetStatNames() -> Array:
	return _base.keys()

# current values without hidden stats, in declaration order (for tooltips/cards)
func GetDisplayStats() -> Dictionary[StringName, float]:
	var result: Dictionary[StringName, float] = {}
	for stat_name in _base:
		if stat_name not in hidden_stats:
			result[stat_name] = GetStat(stat_name)
	return result

# stats stored as fractions/multipliers, shown as "Crit Chance: 10%" / "Crit Multiplier: x2"
const PERCENT_STATS = ["crit_chance", "projectile_speed"]
const MULTIPLIER_STATS = ["crit_multiplier"]

# "Shot Count: 2", "Cooldown: 0.5" - shared by the HUD and tooltips
static func FormatStat(stat_name: String, value: float) -> String:
	if stat_name in PERCENT_STATS:
		return "%s: %d%%" % [stat_name.capitalize(), roundi(value * 100)]
	if stat_name in MULTIPLIER_STATS:
		return "%s: x%s" % [stat_name.capitalize(), str(snappedf(value, 0.01))]
	var value_text = str(int(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value
	return "%s: %s" % [stat_name.capitalize(), value_text]

func AddModifier(modifier: StatModifier, source: Object) -> void:
	_modifiers.append({ "modifier": modifier, "source": source })
	stat_changed.emit(modifier.stat, GetStat(modifier.stat))

# removes every modifier added by the source, e.g. all buffs of an altar when the floor ends
func RemoveModifiersFrom(source: Object) -> void:
	var changed_stats: Array[StringName] = []
	for entry in _modifiers.duplicate():
		if entry.source == source:
			_modifiers.erase(entry)
			changed_stats.append(entry.modifier.stat)

	for stat_name in changed_stats:
		stat_changed.emit(stat_name, GetStat(stat_name))
