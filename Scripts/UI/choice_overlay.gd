extends CanvasLayer
class_name ChoiceOverlay

# generic "pick 1 of N" screen over the game (altars now, post-room blessings later).
# pauses the game while open. usage:
#   var overlay = CHOICE_OVERLAY.instantiate()
#   add_child(overlay)
#   overlay.chosen.connect(_on_chosen)
#   overlay.Open("Altar of Pacts", offers, true)
# optional reroll: overlay.SetRerolls(count) shows the button, rerolled fires on press,
# the caller rolls new options and passes them to SetOptions
@export var choice_card_scene: PackedScene
@onready var title_label: Label = %Title
@onready var card_container: HBoxContainer = %Cards
@onready var leave_button: Button = %LeaveButton
@onready var reroll_button: Button = %RerollButton

signal chosen(item: ItemData) # null = left without choosing
signal rerolled

var can_skip: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	leave_button.pressed.connect(func(): Close(null))
	reroll_button.pressed.connect(func(): rerolled.emit())

func Open(title: String, options: Array, skippable: bool = true) -> void:
	title_label.text = title
	can_skip = skippable
	leave_button.visible = skippable
	SetOptions(options)
	get_tree().paused = true

# replaces the cards, used by Open and after a reroll
func SetOptions(options: Array) -> void:
	for child in card_container.get_children():
		card_container.remove_child(child)
		child.queue_free()
	for item in options:
		var card: ChoiceCard = choice_card_scene.instantiate()
		card.content = item
		card.card_chosen.connect(Close)
		card_container.add_child(card)

# 0 = no reroll button
func SetRerolls(count: int) -> void:
	reroll_button.visible = count > 0
	reroll_button.text = "Reroll (%d)" % count

func _unhandled_input(event: InputEvent) -> void:
	if can_skip and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Close(null)

func Close(result: ItemData) -> void:
	get_tree().paused = false
	chosen.emit(result)
	queue_free()
