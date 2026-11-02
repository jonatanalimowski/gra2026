extends SpellData
class_name NovaSpell

# Glacial Nova: no projectile, a ring around the caster that hits everything in range at once:
# damage + knockback + a status. numeric exports become stats (pacts can grow the radius)
@export var radius: float = 90.0
@export var knockback: float = 260.0
@export var status: StatusEffect
@export var status_stacks: int = 3
@export var ring_color: Color = Color(0.6, 0.85, 1.0)

func Cast(caster: Node2D, stats: StatBlock, _direction: Vector2, _spawn_pos: Vector2, _all_effects: Array[Effect]) -> void:
	var nova_radius = stats.GetStat(&"radius")
	var center = caster.global_position
	var group = "enemy" if caster.is_in_group("player") else "player"
	for body in caster.get_tree().get_nodes_in_group(group):
		if not body.has_method("TakeDamage") or body.get("is_dead"):
			continue
		var offset: Vector2 = body.global_position - center
		if offset.length() > nova_radius:
			continue
		var info = DamageInfo.new(stats.GetStat(&"damage"), caster)
		info.element = &"frost"
		info.knockback = offset.normalized() * stats.GetStat(&"knockback")
		info.target = body
		if randf() < stats.GetStat(&"crit_chance"):
			info.is_critical = true
			info.amount *= stats.GetStat(&"crit_multiplier")
		body.TakeDamage(info)
		if status and body.has_method("ApplyStatus"):
			body.ApplyStatus(status, caster, 1.0, 1.0, status_stacks)

	var vfx = NovaRing.new()
	vfx.radius = nova_radius
	vfx.color = ring_color
	vfx.global_position = center
	caster.get_tree().current_scene.add_child(vfx)
	Signals.screen_shake.emit(0.25)
