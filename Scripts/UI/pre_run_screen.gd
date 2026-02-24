extends Control

@export var choice_card_scene: PackedScene
@export var primary_weapons: Array[PackedScene]
@export var secondary_weapons: Array[PackedScene]
@export var characters_weapons: Array[PackedScene]
@export var start_scene: PackedScene

@onready var choice_card_container: HBoxContainer = $UI/MarginContainer/HBoxContainer
var choices_amount: int = 2
var choices_made: int = 0

var character: PackedScene
var primary_weapon: PackedScene
var secondary_weapon: PackedScene

func _ready() -> void:
	GenerateNextChoices()

func GenerateNextChoices(chosen_thing = null):
	match choices_made:
		0:
			GenerateChoiceChards(primary_weapons)
		1:
			NodeReferences.chosen_primary = chosen_thing
			GenerateChoiceChards(secondary_weapons)
		choices_amount:
			NodeReferences.chosen_secondary = chosen_thing
			FinishChoices()
		_:
			print(choices_made)
			print("Something went wrong in the choice cards screen")
			FinishChoices()

func FinishChoices():
	get_tree().change_scene_to_packed(start_scene)

func GenerateChoiceChards(content_array: Array[PackedScene]):
	var pool = content_array.duplicate()
	pool.shuffle()
	var content_for_cards = pool.slice(0, 3)
	
	for child in choice_card_container.get_children():
		child.queue_free()
	
	for i in range(3):
		var new_choice_card: ChoiceCard = choice_card_scene.instantiate()
		new_choice_card.content_scene = content_for_cards[i]
		new_choice_card.content = content_for_cards[i].instantiate()
		new_choice_card.card_chosen.connect(_on_card_chosen)
		choice_card_container.add_child(new_choice_card)

func _on_card_chosen(content):
	choices_made += 1
	GenerateNextChoices(content)
