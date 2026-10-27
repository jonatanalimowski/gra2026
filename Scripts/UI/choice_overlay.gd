extends CanvasLayer
class_name ChoiceOverlay

# generic "pick 1 of N" screen over the game (altars now, post-room blessings later).
# pauses the game while open. usage:
#   var overlay = CHOICE_OVERLAY.instantiate()
#   add_child(overlay)
#   overlay.chosen.connect(_on_chosen)
#   overlay.Open("Altar of Pacts", offers, true)
@export var choice_card_scene: PackedScene
@onready var title_label: Label = $Root/VBoxContainer/Title
@onready var card_container: HBoxContainer = $Root/VBoxContainer/Cards
@onready var leave_button: Button = $Root/VBoxContainer/LeaveButton

signal chosen(item: ItemData) # null = left without choosing

var can_skip: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	leave_button.pressed.connect(func(): Close(null))

func Open(title: String, options: Array, skippable: bool = true) -> void:
	title_label.text = title
	can_skip = skippable
	leave_button.visible = skippable
	for item in options:
		var card: ChoiceCard = choice_card_scene.instantiate()
		card.content = item
		card.card_chosen.connect(Close)
		card_container.add_child(card)
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if can_skip and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Close(null)

func Close(result: ItemData) -> void:
	get_tree().paused = false
	chosen.emit(result)
	queue_free()
