extends Control

# TEMP loadout screen: pick 1 of 3 random wands and start the run.
# will become the grid-based Loadout screen once MetaProgress knows which items are unlocked
@export var choice_card_scene: PackedScene
@export var wands: Array[WandData]

@onready var choice_card_container: HBoxContainer = %CardRow
var cards_amount: int = 3

func _ready() -> void:
	GenerateChoiceCards(wands)

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
