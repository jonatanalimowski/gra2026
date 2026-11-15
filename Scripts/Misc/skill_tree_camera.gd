extends Camera2D

var is_dragging: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			
	elif event is InputEventMouseMotion and is_dragging:
		position -= event.relative / zoom
