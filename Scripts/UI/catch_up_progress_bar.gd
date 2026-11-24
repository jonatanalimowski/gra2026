extends Control
class_name catch_up_progress_bar

@onready var catch_up_bar: ProgressBar = %CatchUpValue
@onready var real_bar: ProgressBar = %ActualValue

@export var bar_texture_override: StyleBoxTexture

var tween: Tween = null

func _ready() -> void:
	if bar_texture_override:
		real_bar.add_theme_stylebox_override("fill", bar_texture_override)
	
	SetUp(real_bar.max_value, real_bar.max_value)

#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("Left"):
		#UpdateValue(real_bar.value - 20)
	#if event.is_action_pressed("Right"):
		#UpdateValue(real_bar.value + 20)
	#if event.is_action_pressed("Up"):
		#UpdateValue(real_bar.value, real_bar.max_value + 20)

func SetUp(max_val: float, val: float) -> void:
	catch_up_bar.max_value = max_val
	real_bar.max_value = max_val
	catch_up_bar.value = val
	real_bar.value = val

func UpdateValue(new_val: float, new_max: float = real_bar.max_value) -> void:
	if new_max != real_bar.max_value:
		real_bar.max_value = new_max
		catch_up_bar.max_value = new_max
	new_val = clamp(new_val, 0, new_max)

	if is_equal_approx(new_val, real_bar.value):
		return

	real_bar.value = new_val

	# gained
	if catch_up_bar.value <= new_val:
		if tween and tween.is_running():
			tween.kill()
		catch_up_bar.value = new_val
		return

	# lost
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(0.5)
	tween.tween_property(catch_up_bar, "value", new_val, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
