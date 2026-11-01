extends Node2D
class_name SpawnTelegraph

# small blinking circle on the floor where an enemy is about to appear. EnemyRoom frees it
const RADIUS: float = 10.0
const COLOR: Color = Color(1.0, 0.2, 0.15, 0.45)

func _ready() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(self, "modulate:a", 0.4, 0.1)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 24, Color(COLOR, 0.9), 1.0)
