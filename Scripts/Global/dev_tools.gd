extends Node

# dev cheats, toggled from the DevUI panel (F6). lives in an autoload so the flags
# survive scene changes (new floors, restarts). only exists in debug builds
const DEV_UI_SCENE = preload("res://Scenes/UI/DevUI.tscn")
const CHOICE_OVERLAY = preload("res://Scenes/UI/ChoiceOverlay.tscn")
const PACTS_DIR = "res://Data/Altars/"

var invincible: bool = false
# x10 damage on every player spell, as a modifier on the wand casters (source = DevTools)
var x10damage: bool = false:
	set(value):
		x10damage = value
		if is_instance_valid(NodeReferences.player):
			ApplyDamageCheat(NodeReferences.player)
var damage_cheat_mod: StatModifier = StatModifier.new()

var more_elites: bool = false:
	set(value):
		more_elites = value

# every player hit applies 1 Burn / 1 Chill (ApplyStatusOnHitEffect on Player.effects), for testing statuses in real fights
const BURN_STATUS = preload("res://Data/Statuses/Burn.tres")
const CHILL_STATUS = preload("res://Data/Statuses/Chill.tres")
var burn_shots: bool = false:
	set(value):
		burn_shots = value
		if is_instance_valid(NodeReferences.player):
			ApplyShotCheats(NodeReferences.player)
var chill_shots: bool = false:
	set(value):
		chill_shots = value
		if is_instance_valid(NodeReferences.player):
			ApplyShotCheats(NodeReferences.player)
var burn_shot_effect: ApplyStatusOnHitEffect = ApplyStatusOnHitEffect.new()
var chill_shot_effect: ApplyStatusOnHitEffect = ApplyStatusOnHitEffect.new()

var layer: CanvasLayer

func _init() -> void:
	damage_cheat_mod.stat = &"damage"
	damage_cheat_mod.multiplier = 10.0
	burn_shot_effect.status = BURN_STATUS
	chill_shot_effect.status = CHILL_STATUS

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

# also called by Player.ApplyLoadout, effects are rebuilt every floor/restart
func ApplyShotCheats(player: Player) -> void:
	player.effects.erase(burn_shot_effect)
	player.effects.erase(chill_shot_effect)
	if burn_shots:
		player.effects.append(burn_shot_effect)
	if chill_shots:
		player.effects.append(chill_shot_effect)

# stacks of a status on every living enemy (dev panel)
func ApplyStatusToAllEnemies(effect: StatusEffect, stacks: int) -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Entity and not enemy.is_dead:
			enemy.ApplyStatus(effect, NodeReferences.player, 1.0, 1.0, stacks)
