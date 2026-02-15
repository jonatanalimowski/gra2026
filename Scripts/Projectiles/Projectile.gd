extends Area2D
class_name BaseProjectile

#collisions
const LAYER_PLAYER = 1
const LAYER_WORLD = 2
const LAYER_PROJECTILE = 4
const LAYER_ENEMY = 8

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var stats: ProjectileStats
var direction: Vector2 = Vector2.UP

func _ready() -> void:
	SetupCollisions()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	sprite.play("moving")
	get_tree().create_timer(stats.lifetime).timeout.connect(queue_free)

func SetupCollisions():
	collision_layer = LAYER_PROJECTILE
	collision_mask = 0
	collision_mask |= LAYER_WORLD
	if stats.current_team == stats.team.PLAYER:
		collision_mask |= LAYER_ENEMY
	elif stats.current_team == stats.team.ENEMY:
		collision_mask |= LAYER_PLAYER

func _process(delta: float) -> void:
	ProcessProjectileMovement(delta)

func ProcessProjectileMovement(delta: float):
	position += direction*stats.speed*delta

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("TakeDamage"):
		body.TakeDamage(stats.damage)
		queue_free()
	else:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	queue_free()
