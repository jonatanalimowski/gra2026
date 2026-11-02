extends Node
class_name EntityCorpse

# not @onready: SpawnCorpse runs before the corpse is in the tree (Entity.Die adds it deferred)
var animated_sprite: AnimatedSprite2D

func _ready() -> void:
	add_to_group("corpses")

# a corpse is the last frame of a death animation. local_pos = position in the parent it will be added to
func SpawnCorpse(local_pos: Vector2, source_sprite: AnimatedSprite2D, offset: Vector2, scale: Vector2):
	animated_sprite = $AnimatedSprite2D
	self.position = local_pos
	animated_sprite.sprite_frames = source_sprite.sprite_frames
	animated_sprite.centered = source_sprite.centered
	animated_sprite.flip_h = source_sprite.flip_h
	animated_sprite.offset = offset
	animated_sprite.scale = scale
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
