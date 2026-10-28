extends Control
class_name ChoiceCard

@onready var name_label: Label = %Name
@onready var description_label: RichTextLabel = %Description
@onready var element_icon: TextureRect = %ElementIcon
@onready var button: Button = %TextureButton

signal card_chosen(card)

var content: ItemData # a wand now, later blessings/runes/etc.

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	
	if content:
		SetName(content.display_name)
		SetDescription(content.GetRichDescription())
		# pacts show their type icon, everything else its own icon
		var tag_icons = content.GetTagIcons()
		SetIcon(tag_icons[0] if not tag_icons.is_empty() else content.icon)
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
