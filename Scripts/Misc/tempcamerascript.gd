extends Camera2D

var debug_zoom = true;

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ScrollUp"):
		var new_zoom = zoom + Vector2(0.1, 0.1)
		if (new_zoom > Vector2(2.5, 2.5)):
			return
		else:
			zoom = new_zoom
	if event.is_action_pressed("ScrollDown"):
		var new_zoom = zoom - Vector2(0.1, 0.1)
		if (new_zoom < Vector2(1.6, 1.6) and debug_zoom == false):
			return
		else:
			zoom = new_zoom
		
