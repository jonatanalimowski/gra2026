extends Area2D
class_name Explosion

# AoE hit on both teams after a short telegraph (flashing circle on the floor).
# used by ExplodeOnKillEffect, later bombs / fireball impacts / boss slams
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var vfx: AnimatedSprite2D = $AnimatedSprite2D
@export var knockback_force: float = 250.0
@export var hits_player: bool = true
@export var hits_enemies: bool = true
# time between the warning circle appearing and the damage, so it's dodgeable
@export var telegraph_time: float = 0.4
@export var telegraph_color: Color = Color(1.0, 0.35, 0.1, 0.35)

var damage: float = 10.0
var radius: float = 48.0
var source: Node2D

func Setup(dmg: float, explosion_radius: float, damage_source: Node2D = null) -> void:
	damage = dmg
	radius = explosion_radius
	source = damage_source

func _ready() -> void:
	collision_layer = 0
	collision_mask = BaseProjectile.LAYER_PLAYER | BaseProjectile.LAYER_ENEMY
	var circle = CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	vfx.visible = false

	Sfx.Play(&"explosion/telegraph", -10.0)
	# blink the warning circle, then hit
	var tween = create_tween().set_loops(int(telegraph_time / 0.1))
	tween.tween_property(self, "modulate:a", 0.4, 0.05)
	tween.tween_property(self, "modulate:a", 1.0, 0.05)
	await get_tree().create_timer(telegraph_time, false).timeout
	tween.kill()
	modulate.a = 1.0
	Explode()

func _draw() -> void:
	if not vfx.visible:
		draw_circle(Vector2.ZERO, radius, telegraph_color)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(telegraph_color, 0.9), 1.0)

func Explode() -> void:
	# source may have died since (exploding corpse), don't hand out a freed node
	if not is_instance_valid(source):
		source = null

	for body in get_overlapping_bodies():
		if not body.has_method("TakeDamage"):
			continue
		if body is Player and not hits_player:
			continue
		if body is Entity and not hits_enemies:
			continue
		var info = DamageInfo.new(damage, source)
		info.element = &"explosion"
		info.knockback = (body.global_position - global_position).normalized() * knockback_force
		body.TakeDamage(info)

	Sfx.Play(&"explosion/explosion", -10)
	vfx.visible = true
	queue_redraw()
	# the vfx frames are 72px, scale them to the hit area
	vfx.scale = Vector2.ONE * (radius * 2.0 / 72.0)
	vfx.play("explode")
	await vfx.animation_finished
	queue_free()
