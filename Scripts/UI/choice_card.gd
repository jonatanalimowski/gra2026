extends Control
class_name ChoiceCard

@onready var name_label: Label = %Name
@onready var description_label: RichTextLabel = %Description
@onready var element_icon: TextureRect = %ElementIcon
@onready var button: Button = %TakeButton
@onready var stats_button: Button = %ViewStatsButton

const STATS_OVERLAY = preload("res://Scenes/UI/StatsOverlay.tscn")

signal card_chosen(card)
var content: ItemData # a wand now, later blessings/runes/etc.

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	stats_button.pressed.connect(_on_stats_button_pressed)
	# nothing to show for items without stats (pacts: the card text is everything)
	stats_button.visible = content != null and not content.GetDisplayStats().is_empty()

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

# on the root, not the card: the card can be freed (ChoiceOverlay closing) while stats are open
func _on_stats_button_pressed():
	var overlay: StatsOverlay = STATS_OVERLAY.instantiate()
	get_tree().root.add_child(overlay)
	overlay.Open(content.display_name, [content])

func SetName(text: String) -> void:
	name_label.text = text

func SetDescription(text: String) -> void:
	description_label.text = text

func SetIcon(texture: Texture2D) -> void:
	element_icon.texture = texture
