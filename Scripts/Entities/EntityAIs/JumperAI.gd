extends Node
class_name JumperAI

# jumps towards the player, every few jumps does a telegraphed "super jump"
# tune it per enemy in the inspector
@onready var ParentEntity: Entity = get_parent()
@export var jump_frequency: float = 0.5
@export var max_frequency_variation: float = 1.0 # random extra wait between jumps
@export var jump_duration: float = 0.5
@export var movement_direction_offset: float = 45.0
@export var jumps_between_super: int = 3
@export var super_jump_duration_multiplier: float = 1.5
@export var super_jump_speed_multiplier: float = 2.5
@export var telegraph_color: Color = Color.AQUAMARINE
@export var telegraph_duration: float = 0.6
# if true the enemy jumps randomly when it can't see the player
@export var needs_line_of_sight: bool = true

var timer: float = 0.0
var jump_frequency_variation: float

#Move()
#Stop()
#TakeDamage()
#Die()

enum State { NORMAL_JUMP, SUPER_JUMP, IDLE }
var state: State = State.IDLE
var jump_counter = 0

# elite: every landing sends a ring of slow projectiles
@export var elite_ring_count: int = 6
@export var elite_ring_speed: float = 0.45
@export var elite_ring_scene: PackedScene = preload("res://Scenes/ProjectileScenes/EnemyShooterProjectile.tscn")

func _ready() -> void:
	jump_frequency_variation = randf_range(0, max_frequency_variation)
	ParentEntity.landed.connect(_on_landed)

func _on_landed() -> void:
	if not ParentEntity.is_elite or ParentEntity.is_dead:
		return
	var offset = randf() * TAU
	for i in elite_ring_count:
		var projectile = elite_ring_scene.instantiate() as BaseProjectile
		projectile.caster = ParentEntity
		projectile.team = BaseProjectile.Team.ENEMY
		projectile.damage = ParentEntity.stats.GetStat(&"attack_damage") * 0.5
		projectile.speed_multiplier = elite_ring_speed
		projectile.global_position = ParentEntity.global_position
		projectile.SetDirection(Vector2.from_angle(offset + TAU * i / elite_ring_count))
		get_tree().current_scene.add_child(projectile)

func _process(delta: float) -> void:
	if not ParentEntity or ParentEntity.IsStunned(): return

	timer += delta
	if timer >= jump_frequency + jump_frequency_variation:
		execute_behavior()

func execute_behavior() -> void:
	timer = 0.0
	jump_frequency_variation = randf_range(0, max_frequency_variation)

	if jump_counter == jumps_between_super and state == State.NORMAL_JUMP:
		state = State.SUPER_JUMP

	if jump_counter == jumps_between_super and state == State.IDLE:
		GlobalMethods.FlashSprite(ParentEntity.sprite, telegraph_duration, telegraph_color)
		# the super jump comes at the next behavior tick, not when the flash ends
		ParentEntity.ShowTelegraphMark(jump_frequency + jump_frequency_variation)

	var move_speed = ParentEntity.stats.GetStat(&"movement_speed")
	match state:
		State.NORMAL_JUMP:
			var direction = get_direction_to_player()
			ParentEntity.sprite.flip_h = direction.x < 0
			ParentEntity.Jump(direction, jump_duration, move_speed)
			Sfx.Play(&"enemy/slime_jump", -16.0)
			state = State.IDLE
			jump_counter += 1
		State.IDLE:
			ParentEntity.Stop()
			state = State.NORMAL_JUMP
		State.SUPER_JUMP:
			var direction = get_direction_to_player(false)
			ParentEntity.sprite.flip_h = direction.x < 0
			ParentEntity.Jump(direction, jump_duration * super_jump_duration_multiplier, move_speed * super_jump_speed_multiplier)
			Sfx.Play(&"enemy/slime_jump", -6)
			state = State.IDLE
			jump_counter = 0

func get_direction_to_player(with_random_offset: bool = true) -> Vector2:
	var can_find_player = ParentEntity.CanSeePlayer() if needs_line_of_sight else NodeReferences.player != null
	if not can_find_player:
		return Vector2.from_angle(randf() * TAU)

	var dir = ParentEntity.global_position.direction_to(NodeReferences.player.global_position)
	var offset
	if with_random_offset:
		offset = deg_to_rad(randf_range(-movement_direction_offset, movement_direction_offset))
	else:
		offset = 0

	return dir.rotated(offset)
