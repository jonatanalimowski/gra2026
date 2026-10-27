extends Node
class_name JumperAI

# jumps towards the player, every few jumps does a telegraphed "super jump"
# used by the slime and the first boss (was SlimeAI and Boss1AI) - tune it per enemy in the inspector
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

func _ready() -> void:
	jump_frequency_variation = randf_range(0, max_frequency_variation)

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

	var move_speed = ParentEntity.stats.GetStat(&"movement_speed")
	match state:
		State.NORMAL_JUMP:
			var direction = get_direction_to_player()
			ParentEntity.Jump(direction, jump_duration, move_speed)
			state = State.IDLE
			jump_counter += 1
		State.IDLE:
			ParentEntity.Stop()
			state = State.NORMAL_JUMP
		State.SUPER_JUMP:
			var direction = get_direction_to_player(false)
			ParentEntity.Jump(direction, jump_duration * super_jump_duration_multiplier, move_speed * super_jump_speed_multiplier)
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
