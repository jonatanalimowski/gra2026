extends Node

# dev cheats, toggled from the DevUI panel (F6). lives in an autoload so the flags
# survive scene changes (new floors, restarts). only exists in debug builds
const DEV_UI_SCENE = preload("res://Scenes/UI/DevUI.tscn")
const CHOICE_OVERLAY = preload("res://Scenes/UI/ChoiceOverlay.tscn")
const PACTS_DIR = "res://Data/Altars/"

var invincible: bool = false
# killing the boss generates the next floor instead of ending the run
var infinite_floors: bool = false

var layer: CanvasLayer

func _ready() -> void:
	if not OS.is_debug_build():
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = CanvasLayer.new()
	layer.layer = 100
	layer.visible = false
	layer.add_child(DEV_UI_SCENE.instantiate())
	add_child(layer)

func _unhandled_input(event: InputEvent) -> void:
	if layer and event.is_action_pressed("DevMenu"):
		layer.visible = not layer.visible
		get_viewport().set_input_as_handled()
	# altar anywhere: 3 random pacts from Data/Altars, for testing without walking to one
	if layer and event.is_action_pressed("DevPacts") and NodeReferences.player and not get_tree().paused:
		get_viewport().set_input_as_handled()
		OpenPactChoice()

func OpenPactChoice() -> void:
	var pool: Array[AltarPact] = []
	for file in ResourceLoader.list_directory(PACTS_DIR):
		var pact = load(PACTS_DIR + file)
		if pact is AltarPact:
			pool.append(pact)
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var offers = AltarRoom.RollOffers(pool, 3, rng)
	if offers.is_empty():
		return

	var overlay = CHOICE_OVERLAY.instantiate()
	get_tree().current_scene.add_child(overlay)
	overlay.chosen.connect(func(pact): if pact: RunState.AddPact(pact))
	overlay.Open("Altar of Pacts (dev)", offers, true)
