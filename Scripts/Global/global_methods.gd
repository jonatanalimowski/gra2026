extends Node

# makes a sprite flash with a chosen color and duration
func FlashSprite(visual_node: CanvasItem, duration: float = 0.2, color: Color = Color.RED) -> void:
	if not visual_node:
		return

	var tween = create_tween()
	
	tween.tween_property(visual_node, "modulate", color, duration / 2.0)
	tween.tween_property(visual_node, "modulate", Color.WHITE, duration / 2.0)
