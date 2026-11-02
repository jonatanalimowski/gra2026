extends Node2D
class_name NovaRing

# expanding, fading ring for NovaSpell. frees itself
const TIME: float = 0.3

var radius: float = 90.0
var color: Color = Color(0.6, 0.85, 1.0)
var progress: float = 0.0

func _ready() -> void:
	z_index = 4
	var tween = create_tween()
	tween.tween_property(self, "progress", 1.0, TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var r = radius * progress
	var alpha = 1.0 - progress
	draw_circle(Vector2.ZERO, r, Color(color, 0.15 * alpha))
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(color, alpha), 2.0)
