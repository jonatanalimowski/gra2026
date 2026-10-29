extends Node

# player preferences saved to user://settings.cfg (MetaProgress is game progress, this is just options).
# volumes are linear 0-1 per audio bus, buses live in default_bus_layout.tres
const SAVE_PATH = "user://settings.cfg"
const DEFAULT_VOLUMES: Dictionary[StringName, float] = {
	&"Master": 1.0,
	&"Music": 0.8,
	&"SFX": 0.7,
	&"UI": 0.7,
}

func _ready() -> void:
	Load()

func GetVolume(bus: StringName) -> float:
	var index = AudioServer.get_bus_index(bus)
	if AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))

func SetVolume(bus: StringName, linear: float) -> void:
	var index = AudioServer.get_bus_index(bus)
	if index < 0:
		push_warning("no audio bus %s" % bus)
		return
	# linear_to_db(0) is -inf, mute instead
	AudioServer.set_bus_mute(index, linear <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))

func Save() -> void:
	var cfg = ConfigFile.new()
	for bus in DEFAULT_VOLUMES:
		cfg.set_value("volume", bus, GetVolume(bus))
	cfg.save(SAVE_PATH)

func Load() -> void:
	var cfg = ConfigFile.new()
	cfg.load(SAVE_PATH) # no save yet = every get_value falls back to the default
	for bus in DEFAULT_VOLUMES:
		SetVolume(bus, cfg.get_value("volume", bus, DEFAULT_VOLUMES[bus]))
