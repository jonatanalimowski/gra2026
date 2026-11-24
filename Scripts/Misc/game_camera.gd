extends Camera2D

# sub-pixel camera: the world renders at a whole-pixel camera position (crisp pixels) and the rounded-away
# fraction shifts the upscaled image at screen resolution (PixelViewport), so scrolling and settling stay smooth.
# follows the player's interpolated position every rendered frame (physics interpolation is on), so it
# doesn't step at 60 Hz on faster monitors. the camera is top_level, it doesn't inherit the player's transform

var debug_zoom = false;
var can_zoom_camera = true;

# screen shake: trauma 0-1 goes up on AddTrauma and decays, offset = trauma^2 so small hits stay subtle
@export var max_shake_offset: float = 8.0
@export var trauma_decay: float = 1.5 # per second
@export var shake_speed: float = 30.0 # noise scroll speed, higher = more jittery
@export var follow_speed: float = 20.0 # higher = tighter follow

var last_player_zoom: Vector2
var trauma: float = 0.0
var noise_time: float = 0.0
var noise := FastNoiseLite.new()
var camera_twink: Tween
var target: Node2D
var pixel_viewport: PixelViewport
var smooth_position: Vector2 # unrounded camera position, before shake
var shake_offset: Vector2
# target position at the last two physics ticks, lerped by the interpolation fraction each frame
var target_previous: Vector2
var target_current: Vector2

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 1.0
	target = get_parent()
	pixel_viewport = get_viewport().get_parent() as PixelViewport
	top_level = true
	# moved every frame below, so the engine shouldn't interpolate it again
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	process_callback = Camera2D.CAMERA2D_PROCESS_IDLE
	position_smoothing_enabled = false
	process_physics_priority = 100 # read the target after it moved this tick
	target_previous = target.global_position
	target_current = target_previous
	smooth_position = target_previous
	UpdatePosition()
	Signals.screen_shake.connect(AddTrauma)
	Signals.boss_spawned.connect(_on_boss_spawned)
	Signals.boss_defeated.connect(_on_boss_defeated)
	Signals.player_damaged.connect(_on_player_damaged)

func _on_player_damaged(_info: DamageInfo):
	AddTrauma(0.5)

func AddTrauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		return
	target_previous = target_current
	target_current = target.global_position

func _process(delta: float) -> void:
	UpdateShake(delta)
	var target_pos := target_previous.lerp(target_current, Engine.get_physics_interpolation_fraction())
	# where the player sprite actually gets drawn, so the camera settles exactly on it (no last-pixel hop)
	target_pos = SnapToPixel(target_pos)
	smooth_position = smooth_position.lerp(target_pos, 1.0 - exp(-follow_speed * delta))
	UpdatePosition()

# shake is added before rounding, so it's sub-pixel smooth too
func UpdateShake(delta: float) -> void:
	if trauma <= 0.0:
		shake_offset = Vector2.ZERO
		return
	trauma = maxf(trauma - trauma_decay * delta, 0.0)
	noise_time += delta * shake_speed
	var strength = trauma * trauma * max_shake_offset
	shake_offset = Vector2(noise.get_noise_2d(noise_time, 0.0), noise.get_noise_2d(0.0, noise_time)) * strength

func UpdatePosition() -> void:
	var exact := smooth_position + shake_offset
	var rounded := SnapToPixel(exact)
	global_position = rounded
	force_update_scroll() # apply this frame, the container offset below is for this frame too
	if pixel_viewport:
		pixel_viewport.SetSubpixelOffset((exact - rounded) * zoom)

# nearest point on the viewport pixel grid (1 world pixel = zoom viewport pixels)
func SnapToPixel(pos: Vector2) -> Vector2:
	return (pos * zoom).round() / zoom

func _on_boss_spawned(_hp_value: int):
	if camera_twink:
		camera_twink.kill()
	
	camera_twink = create_tween()
	camera_twink.tween_property(self, "zoom", Vector2(1, 1), 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	last_player_zoom = zoom
	can_zoom_camera = false

func _on_boss_defeated():
	if camera_twink:
		camera_twink.kill()

	camera_twink = create_tween()
	camera_twink.tween_property(self, "zoom", last_player_zoom, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	can_zoom_camera = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ScrollUp"):
		var new_zoom = zoom + Vector2(1, 1)
		if ((new_zoom > Vector2(3, 3) and debug_zoom == false) or can_zoom_camera == false):
			return
		else:
			zoom = new_zoom.floor()
	if event.is_action_pressed("ScrollDown"):
		var new_zoom = zoom - Vector2(1, 1)
		if ((new_zoom < Vector2(1, 1) and debug_zoom == false) or can_zoom_camera == false):
			return
		else:
			zoom = new_zoom.floor()
		
