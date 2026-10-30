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
var speed_multiplier: float = 1.0 # spell's projectile_speed stat (curses, blessings)
var crit_chance: float = 0.0 # rolled on every hit, 0.1 = 10%
var crit_multiplier: float = 2.0
var effects: Array[Effect] = []
var motion: ProjectileMotion # null = stats.motion, set by the spawner to override the path
var motion_state: Dictionary = {} # per-projectile values the motion rolls in OnSpawned

# per-projectile data for effects, e.g. bounces left. key = the effect resource
var effect_state: Dictionary = {}
# true once an effect kept the projectile alive during the current hit, so a second
# keep-alive effect (pierce + ricochet) doesn't also spend a charge on the same hit
var survived_hit: bool = false

# Variables
var direction: Vector2 = Vector2.UP # base heading, motions build their path around it
var age: float = 0.0 # seconds alive, motions use it to compute the path

func _ready() -> void:
	if damage < 0:
		damage = stats.damage
	if motion == null:
		motion = stats.motion if stats.motion else ProjectileMotion.new()
	motion.OnSpawned(self)
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

# motions use this instead of stats.speed, so speed modifiers work on every path
func GetSpeed() -> float:
	return stats.speed * speed_multiplier

func SetDirection(new_direction: Vector2) -> void:
	direction = new_direction
	rotation = direction.angle() + PI/2

func _physics_process(delta: float) -> void:
	age += delta
	for effect in effects:
		effect.OnPhysicsProcess(self, delta)
	var move_velocity = motion.GetVelocity(self, delta)
	# face where it's actually going (curved paths)
	if move_velocity != Vector2.ZERO:
		rotation = move_velocity.angle() + PI/2
	var collision = move_and_collide(move_velocity * delta)
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
		# crit before the effects, so they see the final hit (vampirism heals off it)
		if randf() < crit_chance:
			info.is_critical = true
			info.amount *= crit_multiplier
		for effect in effects:
			effect.ModifyDamage(self, info)
		body.TakeDamage(info)
		# the player has its own hurt sound (Sfx listens to player_damaged)
		if team == Team.PLAYER:
			Sfx.Play(&"projectile/hit_enemy", -16.0)

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
		if survived_hit:
			pass
			#Sfx.Play(&"projectile/bounce", -10.0)
		else:
			#Sfx.Play(&"projectile/hit_wall", -20.0)
			queue_free()
