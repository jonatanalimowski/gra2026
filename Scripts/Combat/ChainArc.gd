extends Node2D
class_name ChainArc

# Shock discharge: a jagged line from the discharged enemy to each target, fades out fast.
# Discharge() picks the targets and deals the damage, the node is only the visual
const BASE_TARGETS: int = 2
const BASE_RANGE: float = 120.0
const DAMAGE_SHARE: float = 0.5
const FADE_TIME: float = 0.18
const COLOR: Color = Color(1.0, 0.95, 0.45)
const SHOCK_STATUS = preload("res://Data/Statuses/Shock.tres")
const BURN_STATUS = preload("res://Data/Statuses/Burn.tres")
const CHILL_STATUS = preload("res://Data/Statuses/Chill.tres")

var points: Array[PackedVector2Array] = []

# arcs from `from` to the nearest enemies for DAMAGE_SHARE of the hit. glyphs/tiers/duos:
# Fork +1 target, Long Arc +30% range, Tempest +1 target, Overload = arcs can crit (player's primary crit),
# Superconductor = always crit on Chilled/Frozen, Plasma = 1 Burn, Stormcaller = arcs Shock (chain again)
static func Discharge(from: Entity, hit_amount: float) -> void:
	var count = BASE_TARGETS + RunState.CountFlag(&"fork") + (1 if RunState.HasFlag(&"tempest") else 0)
	var reach = BASE_RANGE * (1.0 + 0.3 * RunState.CountFlag(&"long_arc"))
	var origin = from.global_position
	var candidates: Array = []
	for enemy in from.get_tree().get_nodes_in_group("enemy"):
		if enemy != from and not enemy.is_dead and enemy.global_position.distance_to(origin) <= reach:
			candidates.append(enemy)
	candidates.sort_custom(func(a, b): return a.global_position.distance_to(origin) < b.global_position.distance_to(origin))
	candidates = candidates.slice(0, count)
	if candidates.is_empty():
		return

	var player = NodeReferences.player
	var arc = ChainArc.new()
	for target in candidates:
		arc.points.append(Jagged(origin, target.global_position))
		var info = DamageInfo.new(hit_amount * DAMAGE_SHARE, player)
		info.is_arc = true
		info.element = &"shock"
		info.target = target
		var crit = false
		if RunState.HasFlag(&"superconductor") and (target.status_holder.Has(CHILL_STATUS) or target.IsFrozen()):
			crit = true
		elif RunState.HasFlag(&"overload") and player and player.wand and player.wand.primary:
			crit = randf() < player.wand.primary.stats.GetStat(&"crit_chance")
		if crit:
			info.is_critical = true
			info.amount *= player.wand.primary.stats.GetStat(&"crit_multiplier") if player and player.wand and player.wand.primary else 2.0
		target.TakeDamage(info)
		if not target.is_dead:
			if RunState.HasFlag(&"plasma"):
				target.ApplyStatus(BURN_STATUS, player)
			if RunState.HasFlag(&"stormcaller"):
				target.ApplyStatus(SHOCK_STATUS, player)
	# deferred: we may be inside a physics callback (projectile hit)
	from.get_tree().current_scene.add_child.call_deferred(arc)

static func Jagged(a: Vector2, b: Vector2) -> PackedVector2Array:
	var line = PackedVector2Array([a])
	var normal = (b - a).orthogonal().normalized()
	var steps = maxi(int(a.distance_to(b) / 14.0), 2)
	for i in range(1, steps):
		line.append(a.lerp(b, float(i) / steps) + normal * randf_range(-4, 4))
	line.append(b)
	return line

func _ready() -> void:
	z_index = 6
	Sfx.Play(&"projectile/bounce", -14)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)

func _draw() -> void:
	for line in points:
		draw_polyline(line, Color(COLOR, 0.5), 3.0)
		draw_polyline(line, COLOR, 1.0)
