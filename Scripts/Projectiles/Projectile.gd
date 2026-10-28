extends CharacterBody2D
class_name BaseProjectile

# Collisions
const LAYER_PLAYER = 1
const LAYER_WORLD = 2
const LAYER_PROJECTILE = 4
const LAYER_ENEMY = 8

# Projectile params
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var stats: ProjectileStats # shared resource, read only

enum Team {PLAYER, ENEMY}

# set by whoever spawns the projectile (see SpellCaster)
var caster: Node2D
var team: Team = Team.ENEMY # decides what it can hit, see SetupCollisions
var damage: float = -1.0 # -1 = use stats.damage
var effects: Array[Effect] = []

# per-projectile data for effects, e.g. bounces left. key = the effect resource
var effect_state: Dictionary = {}
# true once an effect kept the projectile alive during the current hit, so a second
# keep-alive effect (pierce + ricochet) doesn't also spend a charge on the same hit
var survived_hit: bool = false

# Variables
var direction: Vector2 = Vector2.UP

func _ready() -> void:
	if damage < 0:
		damage = stats.damage
	SetupCollisions()
	sprite.play("moving")
	get_tree().create_timer(stats.lifetime).timeout.connect(queue_free)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	for effect in effects:
		effect.OnProjectileSpawned(self)

func SetupCollisions():
	collision_layer = LAYER_PROJECTILE
	collision_mask = 0
	collision_mask |= LAYER_WORLD
	if team == Team.PLAYER:
		collision_mask |= LAYER_ENEMY
	elif team == Team.ENEMY:
		collision_mask |= LAYER_PLAYER

func SetDirection(new_direction: Vector2) -> void:
	direction = new_direction
	rotation = direction.angle() + PI/2

func _physics_process(delta: float) -> void:
	var collision = move_and_collide(direction * stats.speed * delta)
	if collision:
		HandleCollision(collision)

func HandleCollision(collision: KinematicCollision2D) -> void:
	var body = collision.get_collider()

	# dodged (e.g. player dashing): fly through instead of disappearing
	if body.has_method("IsDodging") and body.IsDodging():
		add_collision_exception_with(body)
		return

	if body.has_method("TakeDamage"):
		# caster may have died while the projectile was in flight
		var source = caster if is_instance_valid(caster) else null
		var info = DamageInfo.new(damage, source)
		info.knockback = direction * stats.knockback_force
		for effect in effects:
			effect.ModifyDamage(self, info)
		body.TakeDamage(info)

		# every effect gets the hook (explosions, lifesteal...), even after one kept us alive
		survived_hit = false
		for effect in effects:
			if effect.OnHitTarget(self, body, info):
				survived_hit = true
		if survived_hit:
			# don't collide with the same body again next frame
			add_collision_exception_with(body)
			return
		queue_free()

	elif ("collision_layer" in body and body.collision_layer == LAYER_WORLD) or body is TileMapLayer:
		survived_hit = false
		for effect in effects:
			if effect.OnHitWall(self, collision):
				survived_hit = true
		if not survived_hit:
			queue_free()
