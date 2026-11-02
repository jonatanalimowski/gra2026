extends SpellData
class_name BallLightningSpell

# Ball Lightning heavy: no projectile, spawns a BallLightning that drifts toward the cursor.
# damage = per pulse. numeric exports are stats
@export var orb_speed: float = 60.0
@export var orb_lifetime: float = 3.5
@export var pulse_interval: float = 0.4
@export var pulse_radius: float = 55.0
@export var status: StatusEffect

func Cast(caster: Node2D, stats: StatBlock, direction: Vector2, spawn_pos: Vector2, _all_effects: Array[Effect]) -> void:
	var orb = BallLightning.new()
	orb.direction = direction
	orb.speed = stats.GetStat(&"orb_speed")
	orb.lifetime = stats.GetStat(&"orb_lifetime")
	orb.interval = stats.GetStat(&"pulse_interval")
	orb.radius = stats.GetStat(&"pulse_radius")
	orb.damage = stats.GetStat(&"damage")
	orb.source = caster
	orb.status = status
	orb.global_position = spawn_pos
	caster.get_tree().current_scene.add_child(orb)
