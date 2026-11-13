extends Control

# TEMP loadout screen: pick 1 of 3 random wands and start the run.
# will become the grid-based Loadout screen once MetaProgress knows which items are unlocked
@export var choice_card_scene: PackedScene
var wands: Array[WandData]

@onready var choice_card_container: HBoxContainer = %CardRow
@onready var back_button: Button = %BackButton
var cards_amount: int = 3

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	wands = InventoryManager.GetWands()
	GenerateChoiceCards(wands)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

func GenerateChoiceCards(items: Array):
	var pool = items.duplicate()
	pool.shuffle()

	for child in choice_card_container.get_children():
		child.queue_free()

	for item in pool.slice(0, cards_amount):
		var new_choice_card: ChoiceCard = choice_card_scene.instantiate()
		new_choice_card.content = item
		new_choice_card.card_chosen.connect(_on_wand_chosen)
		choice_card_container.add_child(new_choice_card)

func _on_wand_chosen(wand: WandData):
	var loadout = Loadout.new()
	loadout.wand = wand
	GameFlow.StartRun(loadout)

func _on_back_button_pressed() -> void:
	GameFlow.GoToMainMenu()
