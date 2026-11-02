extends Area2D
class_name GlyphShrine

# glyph pickup, dropped by EnemyRoom on some room clears (where the last enemy died).
# Interact = pick 1 of 3 glyphs. walking away keeps it, it only goes once something is taken
const CHOICE_OVERLAY = preload("res://Scenes/UI/ChoiceOverlay.tscn")
const OFFER_COUNT = 3
const TOP_SCHOOL_WEIGHT = 2.0

@export var glyph_pool: Array[GlyphData] = []
@onready var sprite: Sprite2D = %Sprite
@onready var prompt: Label = %Prompt
var offers: Array[GlyphData] = []
var offers_rolled: bool = false
var is_used: bool = false
var player_in_range: bool = false
var bob_tween: Tween

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.visible = false
	bob_tween = create_tween().set_loops()
	bob_tween.tween_property(sprite, "position:y", -3.0, 0.7).set_trans(Tween.TRANS_SINE)
	bob_tween.tween_property(sprite, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
	Sfx.Play(&"world/pickup", -8)

# rolled on first use (pacts taken since the drop count), seeded so Ctrl+R repeats it
func GetOffers() -> Array[GlyphData]:
	if not offers_rolled:
		offers_rolled = true
		var rng = RandomNumberGenerator.new()
		rng.seed = hash([RunState.GetFloorSeed(), "glyph", global_position])
		offers = RollOffers(glyph_pool, OFFER_COUNT, rng)
	return offers

# only FORM glyphs and schools you own a pact of (pacts open doors, glyphs walk through them).
# at least one FORM card, schools with the most points weigh x2
static func RollOffers(pool: Array[GlyphData], count: int, rng: RandomNumberGenerator) -> Array[GlyphData]:
	var valid: Array[GlyphData] = []
	var top_points := 0
	for glyph in pool:
		if glyph == null or not RunState.CanTakeGlyph(glyph):
			continue
		if glyph.school != School.Kind.FORM and RunState.GetPactSchoolPoints(glyph.school) <= 0:
			continue
		valid.append(glyph)
		if glyph.school != School.Kind.FORM:
			top_points = maxi(top_points, RunState.GetSchoolPoints(glyph.school))

	var result: Array[GlyphData] = []
	var forms = valid.filter(func(g): return g.school == School.Kind.FORM)
	if not forms.is_empty():
		var first = _PickWeighted(forms, rng, top_points)
		result.append(first)
		valid.erase(first)
	while result.size() < count and not valid.is_empty():
		var glyph = _PickWeighted(valid, rng, top_points)
		valid.erase(glyph)
		result.append(glyph)
	return result

static func _PickWeighted(candidates: Array, rng: RandomNumberGenerator, top_points: int) -> GlyphData:
	var weights: Array[float] = []
	var total := 0.0
	for glyph in candidates:
		var weight: float = glyph.weight
		if glyph.school != School.Kind.FORM and top_points > 0 and RunState.GetSchoolPoints(glyph.school) == top_points:
			weight *= TOP_SCHOOL_WEIGHT
		weights.append(weight)
		total += weight
	var roll = rng.randf() * total
	for i in candidates.size():
		roll -= weights[i]
		if roll <= 0.0:
			return candidates[i]
	return candidates.back()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = true
		prompt.visible = not is_used

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
		prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and not is_used and event.is_action_pressed("Interact"):
		get_viewport().set_input_as_handled()
		if GetOffers().is_empty():
			return
		var overlay = CHOICE_OVERLAY.instantiate()
		add_child(overlay)
		overlay.chosen.connect(_on_overlay_chosen)
		overlay.Open("Glyph", GetOffers(), true)

func _on_overlay_chosen(glyph: ItemData) -> void:
	if glyph == null:
		return
	is_used = true
	RunState.AddGlyph(glyph)
	Sfx.Play(&"altar/pact_take", -8)
	if NodeReferences.player:
		GlobalMethods.FlashSprite(NodeReferences.player.sprite, 0.4, School.GetColor(glyph.school))
	bob_tween.kill()
	var fade = create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.4)
	fade.tween_callback(queue_free)
