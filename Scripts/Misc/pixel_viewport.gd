extends SubViewportContainer
class_name PixelViewport

# the world renders at screen size / pixel_scale (stretch is off, sized here) plus a spare game pixel on
# each side, so the camera can shift the upscaled image by less than one game pixel (SetSubpixelOffset)
# without showing an empty edge. pixels stay crisp, scrolling gets screen-pixel smooth (game_camera.gd)

@export var pixel_scale: int = 4
const MARGIN: int = 1 # spare game pixels on each side

@onready var viewport: SubViewport = $SubViewport

var screen_size: Vector2

func _ready() -> void:
	stretch = false
	get_viewport().size_changed.connect(Resize)
	Resize()

func Resize() -> void:
	screen_size = get_viewport_rect().size
	var game_size := Vector2i((screen_size / pixel_scale).ceil()) + Vector2i.ONE * MARGIN * 2
	# even size, so the camera center sits on a pixel corner and rounding the camera lines up the grid
	game_size += Vector2i(game_size.x % 2, game_size.y % 2)
	viewport.size = game_size
	size = game_size
	scale = Vector2.ONE * pixel_scale
	SetSubpixelOffset(Vector2.ZERO)

# offset = how far (in viewport pixels, -0.5..0.5) the camera's real position is from the rounded one it rendered at
func SetSubpixelOffset(offset: Vector2) -> void:
	var centered := (screen_size - size * pixel_scale) / 2.0
	position = centered - offset * pixel_scale
