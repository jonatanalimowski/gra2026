extends Camera2D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ScrollUp"):
		zoom += Vector2(0.1, 0.1)
	if event.is_action_pressed("ScrollDown"):
		zoom -= Vector2(0.1, 0.1)
