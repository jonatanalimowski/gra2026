extends SpellData
class_name StatusAreaSpell

# drops a cloud of StatusArea circles around the player instead of shooting. enemy spell for now,
# a player version would aim at the cursor. numeric exports become stats, so elites and pacts can change them.
# the inherited damage stat is the status strength multiplier here (1 = as written in the StatusEffect),
# that way floor scaling and elites make the poison stronger with no extra code
@export var area_scene: PackedScene
@export var area_count: int = 6
@export var area_radius: float = 20.0
@export var cloud_radius: float = 60.0 # max distance of a circle from the center
@export var status_duration: float = 1.0 # multiplier on the StatusEffect's duration

func Cast(caster: Node2D, stats: StatBlock, _direction: Vector2, _spawn_pos: Vector2, _all_effects: Array[Effect]) -> void:
	var player = NodeReferences.player
	if not player:
		return
	var center: Vector2 = player.global_position
	for i in int(stats.GetStat(&"area_count")):
		var area = area_scene.instantiate() as StatusArea
		area.Setup(stats.GetStat(&"area_radius"), caster, stats.GetStat(&"damage"), stats.GetStat(&"status_duration"))
		# the first circle lands right on the player, so standing still is never safe
		var offset = Vector2.ZERO
		if i > 0:
			# sqrt spreads them evenly over the disc, plain randf would bunch them in the middle
			offset = Vector2.from_angle(randf() * TAU) * stats.GetStat(&"cloud_radius") * sqrt(randf())
		area.global_position = center + offset
		caster.get_tree().current_scene.add_child(area)
