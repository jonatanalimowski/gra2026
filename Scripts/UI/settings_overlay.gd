extends CanvasLayer
class_name SettingsOverlay

# volume sliders, values live in the Settings autoload and are saved on close.
# pauses the game while open. usage:
#   var overlay = SETTINGS_OVERLAY.instantiate()
#   add_child(overlay)
#   overlay.closed.connect(_on_closed) # optional
@onready var leave_button: Button = %LeaveButton

# audio bus -> its slider
@onready var sliders: Dictionary[StringName, HSlider] = {
	&"Master": %MasterSlider,
	&"Music": %MusicSlider,
	&"SFX": %SfxSlider,
	&"UI": %UiSlider,
}
# played when a slider is let go, so you hear the new volume
const PREVIEW_SOUNDS: Dictionary[StringName, StringName] = {
	&"Master": &"ui/select",
	&"SFX": &"projectile/hit_enemy",
	&"UI": &"ui/select",
}

signal closed
@onready var player_additional_healthbar_checkbutton: CheckButton = %PlayerAdditionalHealthbar
@onready var enemy_additional_healthbar_checkbutton: CheckButton = %EnemyAdditionalHealthbar

var was_paused: bool = false # opened over another paused screen -> keep it paused

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	leave_button.pressed.connect(Close)
	for bus in sliders:
		var slider := sliders[bus]
		slider.value = Settings.GetVolume(bus)
		slider.value_changed.connect(func(value): Settings.SetVolume(bus, value))
		slider.drag_ended.connect(func(_changed): _on_slider_released(bus))
	
	player_additional_healthbar_checkbutton.button_pressed = Settings.show_health_above_player
	enemy_additional_healthbar_checkbutton.button_pressed = Settings.show_health_above_enemies
	player_additional_healthbar_checkbutton.toggled.connect(func(is_on: bool): Settings.TogglePlayerBars(is_on))
	enemy_additional_healthbar_checkbutton.toggled.connect(func(is_on: bool): Settings.ToggleEnemyBars(is_on))
	was_paused = get_tree().paused
	get_tree().paused = true

func _on_slider_released(bus: StringName) -> void:
	if PREVIEW_SOUNDS.has(bus):
		Sfx.Play(PREVIEW_SOUNDS[bus])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Close()

func Close() -> void:
	Settings.Save()
	get_tree().paused = was_paused
	closed.emit()
	queue_free()
