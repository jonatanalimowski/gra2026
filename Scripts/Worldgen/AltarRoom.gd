extends Room
class_name AltarRoom

# reward room at the end of a side branch. press Interact at the altar to see pacts
# (buff + curse), take one or leave. the altar stays active until something is taken
const CHOICE_OVERLAY = preload("res://Scenes/UI/ChoiceOverlay.tscn")
const BASE_OFFER_COUNT = 2

@export var pact_pool: Array[AltarPact] = []
@export var offer_count: int = BASE_OFFER_COUNT # before bonuses, see RunState.GetPactOfferCount
@onready var altar: Area2D = $Altar
@onready var altar_sprite: Sprite2D = %Sprite
@onready var prompt: Label = %Prompt
var offers: Array[AltarPact] = []
var offers_rolled: bool = false
var is_used: bool = false
var player_in_range: bool = false
var bob_tween: Tween

func _ready() -> void:
	altar.body_entered.connect(_on_altar_body_entered)
	altar.body_exited.connect(_on_altar_body_exited)
	prompt.visible = false
	bob_tween = create_tween().set_loops()
	bob_tween.tween_property(altar_sprite, "position:y", -3.0, 0.8).set_trans(Tween.TRANS_SINE)
	bob_tween.tween_property(altar_sprite, "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE)

# rolled on first approach instead of _ready, so bonuses picked up earlier on the floor count.
# seeded by position, so Ctrl+R shows the same offers, and only rolled once so reopening doesn't reroll
func GetOffers() -> Array[AltarPact]:
	if not offers_rolled:
		offers_rolled = true
		var rng = RandomNumberGenerator.new()
		rng.seed = hash([RunState.GetFloorSeed(), "altar", global_position])
		offers = RollOffers(pact_pool, RunState.GetPactOfferCount(offer_count), rng)
	return offers

# weighted pick without repeats, skipping pacts already taken or too early for this floor.
# static so DevTools can roll from the same pool rules
static func RollOffers(pool: Array[AltarPact], count: int, rng: RandomNumberGenerator = RandomNumberGenerator.new()) -> Array[AltarPact]:
	var valid: Array[AltarPact] = []
	for pact in pool:
		if pact and pact not in RunState.pacts and pact.min_floor <= RunState.floor_number:
			valid.append(pact)

	var result: Array[AltarPact] = []
	while result.size() < count and not valid.is_empty():
		var total = 0.0
		for pact in valid:
			total += pact.weight
		var roll = rng.randf() * total
		var picked = valid.size() - 1
		for i in valid.size():
			roll -= valid[i].weight
			if roll <= 0.0:
				picked = i
				break
		result.append(valid.pop_at(picked))
	return result

func _on_altar_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = true
		prompt.visible = not is_used and not GetOffers().is_empty()

func _on_altar_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
		prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and not is_used and not GetOffers().is_empty() and event.is_action_pressed("Interact"):
		get_viewport().set_input_as_handled()
		OpenOverlay()

func OpenOverlay() -> void:
	var overlay = CHOICE_OVERLAY.instantiate()
	add_child(overlay)
	overlay.chosen.connect(_on_overlay_chosen)
	overlay.Open("Altar of Pacts", offers, true)

func _on_overlay_chosen(pact: ItemData) -> void:
	if pact == null:
		return # walked away, altar stays usable

	is_used = true
	prompt.visible = false
	RunState.AddPact(pact)
	if NodeReferences.player:
		GlobalMethods.FlashSprite(NodeReferences.player.sprite, 0.4, Color(0.8, 0.2, 1.0))

	bob_tween.kill()
	var fade = create_tween()
	fade.tween_property(altar_sprite, "modulate", Color(0.3, 0.3, 0.3, 1.0), 0.5)
