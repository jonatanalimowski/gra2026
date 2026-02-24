extends Area2D
class_name BaseProjectile

# Collisions
const LAYER_PLAYER = 1
const LAYER_WORLD = 2
const LAYER_PROJECTILE = 4
const LAYER_ENEMY = 8

# Projectile params
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var raycast: RayCast2D = $RayCast2D
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
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
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
	raycast.hit_from_inside = true
	collision_layer = LAYER_PROJECTILE
	collision_mask = 0
	collision_mask |= LAYER_WORLD
	raycast.collision_mask = 0
	raycast.collision_mask |= LAYER_WORLD
	if stats.current_team == stats.team.PLAYER:
		raycast.collision_mask |= LAYER_ENEMY
		collision_mask |= LAYER_ENEMY
	elif stats.current_team == stats.team.ENEMY:
		collision_mask |= LAYER_PLAYER
		raycast.collision_mask |= LAYER_PLAYER

func _process(delta: float) -> void:
	ProcessProjectileMovement(delta)

func ProcessProjectileMovement(delta: float):
	position += direction*stats.speed*delta

func _on_body_entered(body: Node2D) -> void:
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
			raycast.force_raycast_update()
			var normal = raycast.get_collision_normal()
			if normal == Vector2.ZERO:
				direction = -direction
			else:
				direction = direction.bounce(normal)
				rotation = direction.angle() + PI/2
			
			# rest
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
