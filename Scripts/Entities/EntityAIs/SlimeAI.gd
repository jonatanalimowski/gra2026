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

enum state {MOVE, STOP}
var current_state: state = state.STOP

func _ready() -> void:
	jump_frequency_variation = randf_range(-0.5, 0.5)

func _process(delta: float) -> void:
	if not ParentEntity:
		return
	UpdateBehavior(delta)

func UpdateBehavior(delta: float) -> void:
	timer += delta
	if timer >= jump_frequency + jump_frequency_variation:
		if current_state == state.STOP:
			ParentEntity.Stop()
			current_state = state.MOVE
			timer = 0
			jump_frequency_variation = randf_range(-0.5, 0.5)
		else:
			var general_player_direction: Vector2
			var random_direction = Vector2.from_angle(randf() * TAU)
			if NodeReferences.player:
				general_player_direction = (NodeReferences.player.global_position - ParentEntity.global_position).normalized()
				var offset = randf_range(-movement_direction_offset, movement_direction_offset)
				general_player_direction = general_player_direction.rotated(deg_to_rad(offset))
			else:
				general_player_direction = random_direction
			ParentEntity.Jump(general_player_direction, jump_duration)
			current_state = state.STOP
			timer = 0
