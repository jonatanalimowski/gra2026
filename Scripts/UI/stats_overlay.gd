extends CanvasLayer
class_name StatsOverlay

# read-only "look at these items" screen (wand stats now, inventory/forge later).
# pauses the game while open. usage:
#   var overlay = STATS_OVERLAY.instantiate()
#   add_child(overlay)
#   overlay.closed.connect(_on_closed) # optional
#   overlay.Open("Your Wand", [wand_data])
@export var stats_card_scene: PackedScene
@onready var title_label: Label = %Title
@onready var card_container: HBoxContainer = %Stats
@onready var leave_button: Button = %LeaveButton

signal closed

var was_paused: bool = false # opened over another paused screen (ChoiceOverlay) -> keep it paused

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	leave_button.pressed.connect(Close)

func Open(title: String, items: Array) -> void:
	title_label.text = title
	# drop editor placeholders
	for child in card_container.get_children():
		child.queue_free()
	for item in items:
		var card: StatsCard = stats_card_scene.instantiate()
		card.content = item
		card_container.add_child(card)
	was_paused = get_tree().paused
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Close()

func Close() -> void:
	get_tree().paused = was_paused
	closed.emit()
	queue_free()
