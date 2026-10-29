extends Node

# plays the sounds in assets/sounds/sfx/ by name: Sfx.Play(&"player/hurt") picks one of
# player/hurt_1.wav, _2, _3... at a slightly random pitch. ui/* goes to the UI bus, the rest to SFX.
# global events (kills, hurt, pacts, buttons) are hooked up here, one-off sounds are played where they happen
const SOUND_DIR = "res://assets/sounds/sfx/"
const MAX_VARIANTS = 8
# copies of one sound playing at once, extra plays cut the oldest (fast wands, swarms)
const MAX_POLYPHONY = 4
# AudioStreamRandomizer pitch range, 1.1 = up to 10% higher/lower
const PITCH_VARIATION = 1.1
const UI_PITCH_VARIATION = 1.03

var players: Dictionary = {} # StringName -> AudioStreamPlayer (null = sound has no files)

func _ready() -> void:
	# ui sounds have to play in paused menus
	process_mode = Node.PROCESS_MODE_ALWAYS
	Signals.enemy_killed.connect(_on_enemy_killed)
	Signals.player_damaged.connect(func(_info): Play(&"player/hurt", -12))
	Signals.player_died.connect(func(): Play(&"player/death", -12))
	Signals.room_cleared.connect(func(): Play(&"world/room_clear", -10))
	RunState.pact_added.connect(func(_pact): Play(&"altar/pact_take", -6))
	RunState.curse_cleansed.connect(func(_curse): Play(&"altar/cleanse"), -6)
	# every button in the game clicks, no per-scene setup
	get_tree().node_added.connect(_on_node_added)

func Play(sound: StringName, volume_db: float = 0.0) -> void:
	if not players.has(sound):
		players[sound] = MakePlayer(sound)
	var player: AudioStreamPlayer = players[sound]
	if player == null:
		return
	player.volume_db = volume_db
	player.play() # with max_polyphony this adds a voice instead of restarting

func MakePlayer(sound: StringName) -> AudioStreamPlayer:
	var is_ui = sound.begins_with("ui/")
	var randomizer = AudioStreamRandomizer.new()
	randomizer.random_pitch = UI_PITCH_VARIATION if is_ui else PITCH_VARIATION
	for i in range(1, MAX_VARIANTS + 1):
		var path = "%s%s_%d.wav" % [SOUND_DIR, sound, i]
		if not ResourceLoader.exists(path):
			break
		randomizer.add_stream(-1, load(path))
	if randomizer.streams_count == 0:
		push_warning("Sfx: no files for %s" % sound)
		return null

	var player = AudioStreamPlayer.new()
	player.stream = randomizer
	player.bus = &"UI" if is_ui else &"SFX"
	player.max_polyphony = MAX_POLYPHONY
	add_child(player)
	return player

# regular enemies die silently, the hit sound covers it
func _on_enemy_killed(enemy: Entity, _info: DamageInfo) -> void:
	if enemy.is_boss:
		Play(&"boss/boss_death", -10)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(func(): Play(&"ui/click", -10))
		node.mouse_entered.connect(func(): if not node.disabled: Play(&"ui/hover", -16.0))
