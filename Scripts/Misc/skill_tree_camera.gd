extends Camera2D

# drag with LMB to pan, mouse wheel zooms toward the cursor (smooth, not integer steps: the tree isn't in a low res viewport)
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_step: float = 1.15 # multiplier per wheel tick
@export var zoom_smoothing: float = 12.0 # higher = snappier

var is_dragging: bool = false
var target_zoom: float = 1.0
var zoom_anchor: Vector2 # screen point that stays fixed while zooming (the mouse when the wheel turned)

func _ready() -> void:
	target_zoom = clampf(zoom.x, min_zoom, max_zoom)
	zoom = Vector2.ONE * target_zoom

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
		elif event.pressed and event.is_action("ScrollUp"):
			SetTargetZoom(target_zoom * zoom_step, event.position)
		elif event.pressed and event.is_action("ScrollDown"):
			SetTargetZoom(target_zoom / zoom_step, event.position)

	elif event is InputEventMouseMotion and is_dragging:
		position -= event.relative / zoom

func SetTargetZoom(value: float, screen_point: Vector2) -> void:
	target_zoom = clampf(value, min_zoom, max_zoom)
	zoom_anchor = screen_point

func _process(delta: float) -> void:
	if is_equal_approx(zoom.x, target_zoom):
		return
	var new_zoom = lerpf(zoom.x, target_zoom, 1.0 - exp(-zoom_smoothing * delta))
	if absf(new_zoom - target_zoom) < 0.001:
		new_zoom = target_zoom
	# keep the world point under the anchor in place: world = position + (screen - center) / zoom
	var from_center = zoom_anchor - get_viewport_rect().size / 2
	position += from_center / zoom.x - from_center / new_zoom
	zoom = Vector2.ONE * new_zoom
