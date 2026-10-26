extends Control
class_name ChoiceCard

@onready var name_label: Label = $TextureRect/VBoxContainer/NameDescription/Name
@onready var description_label: Label = $TextureRect/VBoxContainer/NameDescription/Description
@onready var element_icon: TextureRect = $TextureRect/TextureRect
@onready var button: TextureButton = $TextureRect/TextureButton

signal card_chosen(card)

var content: ItemData # a wand now, later blessings/runes/etc.

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	
	if content:
		SetName(content.display_name)
		SetDescription(content.description)
		SetIcon(content.icon)
	else:
		SetName("Missing Name")
		SetDescription("Missing description")
		SetIcon(PlaceholderTexture2D.new())

func _on_button_pressed():
	card_chosen.emit(content)

func SetName(text: String) -> void:
	name_label.text = text

func SetDescription(text: String) -> void:
	description_label.text = text

func SetIcon(texture: Texture2D) -> void:
	element_icon.texture = texture
