extends Marker2D
@onready var label = $Label

func display(value: int, target_position: Vector2, is_critical: bool = false):
	label.text = str(value)
	position = target_position
	scale = Vector2(0.75, 0.75)
	if is_critical:
		label.modulate = Color.GOLD
		label.text += "!"
		scale = Vector2(1, 1)
	else:
		label.modulate = Color.WHITE

	var spread_horizontal = randf_range(-75, 75)
	var spread_vertical = randf_range(-25, -65)
	var target_pos = position + Vector2(spread_horizontal, spread_vertical)
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(self, "position", target_pos, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.7).set_delay(0.3)
	
	var scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", scale * 1.2, 0.1)
	scale_tween.tween_property(self, "scale", scale, 0.1)

	tween.finished.connect(queue_free)
