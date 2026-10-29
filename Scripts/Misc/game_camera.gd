extends Camera2D

var debug_zoom = true;

# screen shake: trauma 0-1 goes up on AddTrauma and decays, offset = trauma^2 so small hits stay subtle
@export var max_shake_offset: float = 8.0
@export var trauma_decay: float = 1.5 # per second
@export var shake_speed: float = 30.0 # noise scroll speed, higher = more jittery
var trauma: float = 0.0
var noise_time: float = 0.0
var noise := FastNoiseLite.new()

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 1.0
	Signals.screen_shake.connect(AddTrauma)

func AddTrauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)

func _process(delta: float) -> void:
	if trauma <= 0.0:
		return
	trauma = maxf(trauma - trauma_decay * delta, 0.0)
	noise_time += delta * shake_speed
	var strength = trauma * trauma * max_shake_offset
	# offset doesn't fight position smoothing, unlike moving the camera itself
	offset = Vector2(noise.get_noise_2d(noise_time, 0.0), noise.get_noise_2d(0.0, noise_time)) * strength

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
		
