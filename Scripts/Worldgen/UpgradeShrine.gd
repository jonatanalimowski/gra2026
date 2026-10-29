extends Area2D
class_name UpgradeShrine

# spawned by BossRoom when the boss dies. Interact = pick 1 stat upgrade, then the next floor
# starts after a short delay. walking away keeps it usable, the only way forward is to take one
const CHOICE_OVERLAY = preload("res://Scenes/UI/ChoiceOverlay.tscn")

@export var upgrades: Array[StatUpgrade] = []
@export var next_floor_delay: float = 1.5
@onready var sprite: Sprite2D = %Sprite
@onready var prompt: Label = %Prompt
var is_used: bool = false
var player_in_range: bool = false
var bob_tween: Tween

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.visible = false
	bob_tween = create_tween().set_loops()
	bob_tween.tween_property(sprite, "position:y", -3.0, 0.8).set_trans(Tween.TRANS_SINE)
	bob_tween.tween_property(sprite, "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE)

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
		var overlay = CHOICE_OVERLAY.instantiate()
		add_child(overlay)
		overlay.chosen.connect(_on_overlay_chosen)
		overlay.Open("Boss Reward", upgrades, true)

func _on_overlay_chosen(upgrade: ItemData) -> void:
	if upgrade == null:
		return

	is_used = true
	prompt.visible = false
	RunState.AddHalf((upgrade as StatUpgrade).blessing, true)
	Sfx.Play(&"altar/pact_take", -6)
	if NodeReferences.player:
		GlobalMethods.FlashSprite(NodeReferences.player.sprite, 0.4, Color(1.0, 0.85, 0.3))

	bob_tween.kill()
	create_tween().tween_property(sprite, "modulate", Color(0.3, 0.3, 0.3, 1.0), 0.5)
	get_tree().create_timer(next_floor_delay, false).timeout.connect(GameFlow.NextFloor)
