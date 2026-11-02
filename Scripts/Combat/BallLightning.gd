extends Node2D
class_name BallLightning

# Ball Lightning heavy: a slow orb that pulses every `interval`, Shocking and hurting enemies in range.
# walls stop it. set the vars before add_child
var direction: Vector2 = Vector2.RIGHT
var speed: float = 60.0
var lifetime: float = 3.5
var interval: float = 0.4
var radius: float = 55.0
var damage: float = 5.0
var source: Node2D
var status: StatusEffect

var age: float = 0.0
var pulse_timer: float = 0.0
var flash: float = 0.0

func _ready() -> void:
	z_index = 5

func _physics_process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	# stop at walls (world layer) instead of flying through them
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * speed * delta * 2.0, BaseProjectile.LAYER_WORLD)
	if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		global_position += direction * speed * delta
	pulse_timer -= delta
	if pulse_timer <= 0.0:
		pulse_timer = interval
		Pulse()
	flash = maxf(flash - delta * 4.0, 0.0)
	queue_redraw()

func Pulse() -> void:
	flash = 1.0
	var valid_source = source if is_instance_valid(source) else null
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.is_dead or enemy.global_position.distance_to(global_position) > radius:
			continue
		var info = DamageInfo.new(damage, valid_source)
		info.element = &"shock"
		info.is_arc = true # its own zaps don't discharge the Shock it applies
		info.target = enemy
		enemy.TakeDamage(info)
		if status and not enemy.is_dead:
			enemy.ApplyStatus(status, valid_source)

func _draw() -> void:
	var wobble = sin(age * 20.0)
	draw_circle(Vector2.ZERO, 7.0 + wobble, Color(1.0, 0.95, 0.4, 0.35))
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 1.0, 0.8))
	if flash > 0.0:
		draw_arc(Vector2.ZERO, radius * (1.0 - flash * 0.3), 0, TAU, 32, Color(1.0, 0.9, 0.3, flash * 0.6), 1.0)
