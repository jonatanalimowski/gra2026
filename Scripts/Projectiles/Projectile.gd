extends CharacterBody2D
class_name BaseProjectile

# Collisions
const LAYER_PLAYER = 1
const LAYER_WORLD = 2
const LAYER_PROJECTILE = 4
const LAYER_ENEMY = 8

# Projectile params
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var stats: ProjectileStats

# Perks
# ID list:
# "bounce_walls"
# "ricochet"
# "projectile+1"
# "pierce"

var greater_perks: Dictionary[String, WeaponPerk]

# Variables
var direction: Vector2 = Vector2.UP
var wall_bounces: int = 0
var pierce_count: int = 0
var ricochet_count: int = 0

func _ready() -> void:
	SetupCollisions()
	SetUpPerks()
	sprite.play("moving")
	get_tree().create_timer(stats.lifetime).timeout.connect(queue_free)

func SetUpPerks():
	for id in greater_perks:
		if greater_perks[id] != null:
			var perk: WeaponPerk = greater_perks[id]
			
			if id == "bounce_walls":
				wall_bounces = perk.effect_count
				continue
			if id == "pierce":
				pierce_count = perk.effect_count
				continue
			if id == "ricochet":
				ricochet_count = perk.effect_count
				continue

func SetupCollisions():
	collision_layer = LAYER_PROJECTILE
	collision_mask = 0
	collision_mask |= LAYER_WORLD
	if stats.current_team == stats.team.PLAYER:
		collision_mask |= LAYER_ENEMY
	elif stats.current_team == stats.team.ENEMY:
		collision_mask |= LAYER_PLAYER

func _physics_process(delta: float) -> void:
	ProcessProjectileMovement(delta)
	var collision = move_and_collide(direction * stats.speed * delta)
	if collision:
		HandleCollision(collision)

func ProcessProjectileMovement(delta: float):
	position += direction*stats.speed*delta


func HandleCollision(collision: KinematicCollision2D) -> void:
	var body = collision.get_collider()
	
	if body.has_method("TakeDamage"):
		if pierce_count > 0:
			body.TakeDamage(stats.damage)
			pierce_count -= 1
			return
		
		if ricochet_count > 0:
			direction = direction.rotated(PI)
			ricochet_count -= 1
			return
		
		body.TakeDamage(stats.damage)
		queue_free()
	
	elif ("collision_layer" in body and body.collision_layer == LAYER_WORLD) or body is TileMapLayer:
		if wall_bounces > 0:
			# calculates bounce direction
			var normal = collision.get_normal()
			direction = direction.bounce(normal)
			rotation = direction.angle() + PI/2
			wall_bounces -= 1
			return
			
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	queue_free()

func HasPerk(id: String):
	if greater_perks[id] != null:
		return true
	else:
		return false
