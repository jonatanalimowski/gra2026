extends Node

# Funkcja tworząca czerwony kwadrat
func draw_marker(pos: Vector2, color = Color.RED, size: float = 45.0, duration: float = 15.0):
	var rect = ColorRect.new()
	rect.color = color
	rect.size = Vector2(size, size)
	rect.position = pos - (rect.size / 2.0)
	get_tree().root.add_child(rect)
	
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		rect.queue_free()
