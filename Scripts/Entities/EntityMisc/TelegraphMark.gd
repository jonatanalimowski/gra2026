extends Node2D
class_name TelegraphMark

# "!" over an enemy's head while it winds up. drawn upward from its origin, frees itself after Show
const COLOR: Color = Color(1.0, 0.85, 0.1)
const OUTLINE_COLOR: Color = Color.BLACK
const STEM: Rect2 = Rect2(-1, -12, 3, 8)
const DOT: Rect2 = Rect2(-1, -3, 3, 3)
const POP_TIME: float = 0.08

func _ready() -> void:
	# above walls and other enemies
	z_index = 10

func _draw() -> void:
	for rect in [STEM, DOT]:
		draw_rect(rect.grow(1), OUTLINE_COLOR)
	for rect in [STEM, DOT]:
		draw_rect(rect, COLOR)

func Show(duration: float) -> void:
	scale = Vector2.ZERO
	# same size on screen on elites and bosses, which scale their whole entity
	var full_size = Vector2.ONE / get_parent().scale
	var tween = create_tween()
	tween.tween_property(self, "scale", full_size, POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(maxf(duration - POP_TIME, 0.0))
	tween.tween_callback(queue_free)
