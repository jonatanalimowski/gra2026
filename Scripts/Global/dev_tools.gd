extends Node

# dev cheats, toggled from the DevUI panel (F6). lives in an autoload so the flags
# survive scene changes (new floors, restarts). only exists in debug builds
const DEV_UI_SCENE = preload("res://Scenes/UI/DevUI.tscn")
const CHOICE_OVERLAY = preload("res://Scenes/UI/ChoiceOverlay.tscn")
const PACTS_DIR = "res://Data/Altars/"

var invincible: bool = false
# killing the boss generates the next floor instead of ending the run
var infinite_floors: bool = true
# x10 damage on every player spell, as a modifier on the wand casters (source = DevTools)
var x10damage: bool = false:
	set(value):
		x10damage = value
		if is_instance_valid(NodeReferences.player):
			ApplyDamageCheat(NodeReferences.player)
var damage_cheat_mod: StatModifier = StatModifier.new()

var layer: CanvasLayer

func _init() -> void:
	damage_cheat_mod.stat = &"damage"
	damage_cheat_mod.multiplier = 10.0

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
	# altar anywhere: random pacts from Data/Altars, for testing without walking to one
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
	var offers = AltarRoom.RollOffers(pool, RunState.GetPactOfferCount(AltarRoom.BASE_OFFER_COUNT), rng)
	if offers.is_empty():
		return

	var overlay = CHOICE_OVERLAY.instantiate()
	get_tree().current_scene.add_child(overlay)
	overlay.chosen.connect(func(pact): if pact: RunState.AddPact(pact))
	overlay.Open("Altar of Pacts (dev)", offers, true)

# also called by Player.ApplyLoadout, the wand is rebuilt every floor/restart
func ApplyDamageCheat(player: Player) -> void:
	for caster in player.wand.GetCasters():
		caster.stats.RemoveModifiersFrom(self)
		if x10damage:
			caster.stats.AddModifier(damage_cheat_mod, self)
