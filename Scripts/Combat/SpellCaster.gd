extends RefCounted
class_name SpellCaster

# runtime version of a SpellData: its own stats (with rune modifiers), effects and cooldown
var spell: SpellData
var stats: StatBlock
var effects: Array[Effect] = []
var cooldown_left: float = 0.0

func _init(spell_data: SpellData, runes: Array[RuneData]) -> void:
	spell = spell_data
	stats = StatBlock.FromResource(spell)
	effects.append_array(spell.effects)
	for rune in runes:
		for modifier in rune.spell_modifiers:
			stats.AddModifier(modifier, rune)
		effects.append_array(rune.effects)

func Tick(delta: float) -> void:
	cooldown_left = max(cooldown_left - delta, 0.0)

func IsReady() -> bool:
	return cooldown_left <= 0

# extra_effects come from the caster (equipment, blessings)
func TryCast(caster: Node2D, direction: Vector2, spawn_pos: Vector2, extra_effects: Array[Effect]) -> bool:
	if not IsReady():
		return false

	var all_effects: Array[Effect] = []
	all_effects.append_array(effects)
	all_effects.append_array(extra_effects)

	var spread = stats.GetStat(&"spread")
	for i in int(stats.GetStat(&"shot_count")):
		var projectile = spell.projectile_scene.instantiate() as BaseProjectile
		projectile.caster = caster
		projectile.damage = stats.GetStat(&"damage")
		projectile.effects = all_effects
		projectile.global_position = spawn_pos
		projectile.SetDirection(direction.rotated(deg_to_rad(randf_range(-spread, spread))))
		# projectiles belong to the current scene, so they get removed with it
		caster.get_tree().current_scene.add_child(projectile)

	cooldown_left = stats.GetStat(&"cooldown")
	return true
