extends CanvasLayer

@onready var color_rect: ColorRect = %ColorRect

func _ready() -> void:
	if color_rect:
		color_rect.color.a = 0.0
		color_rect.visible = false

# Fades the screen to black, executes a callback (like changing scenes), then fades back in
func transition_to(target_scene: PackedScene) -> void:
	if !color_rect:
		color_rect = %ColorRect
	color_rect.visible = true
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "color:a", 1.0, 0.4)
	
	await tween.finished
	get_tree().change_scene_to_packed(target_scene)
	
	var tween_in = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_in.tween_property(color_rect, "color:a", 0.0, 0.4)
	
	await tween_in.finished
	color_rect.visible = false
