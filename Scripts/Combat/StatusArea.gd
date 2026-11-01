extends Area2D
class_name StatusArea

# one circle on the floor that keeps applying status_effects to whoever stands in it.
# a small warning circle blinks first, Spawn() then opens the real area
const REAPPLY_INTERVAL: float = 0.25
const WARNING_RADIUS_RATIO: float = 0.35
const OPEN_TIME: float = 0.12
const FADE_TIME: float = 0.4

@onready var shape: CollisionShape2D = $CollisionShape2D
# @onready var vfx: AnimatedSprite2D = $AnimatedSprite2D

@export var lifetime: float = 2.0
@export var affects_player: bool = true
@export var affects_enemies: bool = true
@export var status_effects: Array[StatusEffect] = []

# time between the warning circle appearing and the real effect area
@export var telegraph_time: float = 0.4
@export var telegraph_color: Color = Color(0.4, 0.5, 0.3, 0.3)
@export var area_color: Color = Color(0.4, 0.8, 0.2, 0.35)

var duration_multiplier: float = 1
var strength_multiplier: float = 1

var radius: float = 48.0
var source: Node2D

var is_active: bool = false
var time_left: float = 0.0
var reapply_timer: float = 0.0
var draw_radius: float = 0.0
var blink_tween: Tween

# call before add_child
func Setup(area_radius: float, area_source: Node2D, strength: float = 1.0, duration: float = 1.0) -> void:
	radius = area_radius
	source = area_source
	strength_multiplier = strength
	duration_multiplier = duration

func _ready() -> void:
	collision_layer = 0
	collision_mask = BaseProjectile.LAYER_PLAYER | BaseProjectile.LAYER_ENEMY
	var circle = CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle

	time_left = telegraph_time
	SetDrawRadius(radius * WARNING_RADIUS_RATIO)
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(self, "modulate:a", 0.4, 0.05)
	blink_tween.tween_property(self, "modulate:a", 1.0, 0.05)

func _physics_process(delta: float) -> void:
	time_left -= delta
	if not is_active:
		if time_left <= 0.0:
			Spawn()
		return

	if time_left <= 0.0:
		queue_free()
		return

	reapply_timer -= delta
	if reapply_timer <= 0.0:
		reapply_timer = REAPPLY_INTERVAL
		ApplyToOverlapping()

func _draw() -> void:
	var color = area_color if is_active else telegraph_color
	draw_circle(Vector2.ZERO, draw_radius, color)
	draw_arc(Vector2.ZERO, draw_radius, 0, TAU, 32, Color(color, 0.9), 1.0)

func SetDrawRadius(value: float) -> void:
	draw_radius = value
	queue_redraw()

# the warning is over: grow to full size, start affecting bodies, fade out at the end
func Spawn() -> void:
	is_active = true
	time_left = lifetime
	blink_tween.kill()
	modulate.a = 1.0
	var tween = create_tween()
	tween.tween_method(SetDrawRadius, draw_radius, radius, OPEN_TIME)
	tween.tween_interval(maxf(lifetime - OPEN_TIME - FADE_TIME, 0.0))
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)

func ApplyToOverlapping() -> void:
	# the caster may have died since, don't hand out a freed node
	var valid_source: Node2D = source if is_instance_valid(source) else null
	for body in get_overlapping_bodies():
		if not body.has_method("ApplyStatus"):
			continue
		if body is Player and not affects_player:
			continue
		if body is Entity and not affects_enemies:
			continue
		for effect in status_effects:
			body.ApplyStatus(effect, valid_source, strength_multiplier, duration_multiplier)
