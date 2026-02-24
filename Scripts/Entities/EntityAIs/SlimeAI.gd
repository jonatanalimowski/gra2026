extends Node
class_name SlimeAI

@onready var ParentEntity: Entity = get_parent()
var timer: float = 0.0
var jump_frequency: float = 0.5
var jump_frequency_variation: float
var jump_duration: float = 0.5
var movement_direction_offset: float = 45.0
#Move()
#Stop()
#TakeDamage()
#Die()

enum State { NORMAL_JUMP, SUPER_JUMP, IDLE } # Lepiej: Czekam / Przygotowuje skok
var state: State = State.IDLE
var jump_counter = 0
var jumps_between_super = 3
func _ready() -> void:
	jump_frequency_variation = randf_range(-0.5, 0.5)

func _process(delta: float) -> void:
	if not ParentEntity: return
	
	timer += delta
	if timer >= jump_frequency + jump_frequency_variation:
		execute_behavior()

func execute_behavior() -> void:
	timer = 0.0
	jump_frequency_variation = randf_range(0, 1)
	
	if jump_counter == jumps_between_super and state == State.NORMAL_JUMP:
		state = State.SUPER_JUMP
	
	if jump_counter == jumps_between_super and state == State.IDLE:
		GlobalMethods.FlashSprite(ParentEntity.sprite, 0.6, Color.AQUAMARINE)
	
	match state:
		State.NORMAL_JUMP:
			var direction = get_direction_to_player()
			ParentEntity.Jump(direction, jump_duration)
			state = State.IDLE
			jump_counter += 1
		State.IDLE:
			ParentEntity.Stop()
			state = State.NORMAL_JUMP
		State.SUPER_JUMP:
			var direction = get_direction_to_player(false)
			ParentEntity.Jump(direction, jump_duration * 1.5, ParentEntity.stats.movement_speed * 2.5)
			state = State.IDLE
			jump_counter = 0

func get_direction_to_player(with_random_offset: bool = true) -> Vector2:
	if not NodeReferences.player:
		return Vector2.from_angle(randf() * TAU)
	
	var dir = ParentEntity.global_position.direction_to(NodeReferences.player.global_position)
	var offset
	if with_random_offset:
		offset = deg_to_rad(randf_range(-movement_direction_offset, movement_direction_offset))
	else:
		offset = 0
	
	return dir.rotated(offset)
