extends Node
class_name EntityCorpse

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("corpses")

# a corpse is the last frame of a death animation
func SpawnCorpse(spawn_pos: Vector2, sprite_frames: SpriteFrames):
	self.global_position = spawn_pos
	animated_sprite.sprite_frames = sprite_frames
	PlayDeathAnimation()

func PlayDeathAnimation():
	if animated_sprite.sprite_frames.has_animation("die"):
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.play("die")

func _on_animation_finished():
	animated_sprite.stop()
	animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("die") - 1
	
	# removes the corpse after 60 seconds
	#get_tree().create_timer(60.0).timeout.connect(queue_free)
