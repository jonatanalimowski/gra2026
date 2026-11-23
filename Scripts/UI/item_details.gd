extends PanelContainer
class_name ItemDetails

# generic "show an item" panel: icon, name, subtitle, rich description + an %Actions slot
# for buttons the owning screen adds (unlock, buy, equip). it only displays, never decides:
# item-specific text goes through ItemData hooks (GetSubtitle, GetRichDescription, GetTagIcons)

const MOUSE_OFFSET := Vector2(16, 16)

@export var follow_mouse: bool = false # tooltip mode: sticks next to the mouse, flips at screen edges
@export var hide_on_start: bool = true
@export var prefer_tag_icon: bool = false # use the first GetTagIcons() icon instead of `icon` (like ChoiceCard)
# true = the panel keeps the size its parent gives it (e.g. inside an HBox), a long description scrolls.
# false = the panel shrinks/grows to fit its text (tooltips)
@export var fixed_size: bool = false

@onready var icon_rect: TextureRect = %Icon
@onready var name_label: Label = %Name
@onready var subtitle_label: Label = %Subtitle
@onready var description_label: RichTextLabel = %Description
@onready var actions: Container = %Actions

var item: ItemData

func _ready() -> void:
	if follow_mouse:
		# a tooltip must never eat the hover/clicks of what's under it
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child in find_children("*", "Control", true, false):
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if fixed_size:
		# the description takes the leftover height instead of sizing the panel to its text
		description_label.fit_content = false
		description_label.scroll_active = true
		description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if hide_on_start:
		visible = false

func _process(_delta: float) -> void:
	if follow_mouse and visible:
		MoveToMouse()

func ShowItem(new_item: ItemData) -> void:
	item = new_item
	if item == null:
		Clear()
		return
	ShowText(item.display_name, item.GetSubtitle(), item.GetSubtitleColor(), item.GetRichDescription(), GetItemIcon(item))

# for text that isn't exactly an item's (e.g. a pact row with "(curse broken)" appended)
func ShowText(title: String, subtitle: String, subtitle_color: Color, text: String, texture: Texture2D = null) -> void:
	name_label.text = title
	subtitle_label.text = subtitle
	subtitle_label.modulate = subtitle_color
	subtitle_label.visible = subtitle != ""
	description_label.text = text
	description_label.visible = text != ""
	icon_rect.texture = texture
	icon_rect.visible = texture != null
	actions.visible = actions.get_child_count() > 0
	visible = true
	if not fixed_size:
		reset_size() # shrink back after a longer text
	if follow_mouse:
		MoveToMouse()

func Clear() -> void:
	item = null
	visible = false

func GetActions() -> Container:
	return actions

func GetItemIcon(for_item: ItemData) -> Texture2D:
	if prefer_tag_icon:
		var tags := for_item.GetTagIcons()
		if not tags.is_empty():
			return tags[0]
	return for_item.icon

# next to the mouse, flipped to the other side when it would leave the screen
func MoveToMouse() -> void:
	var mouse := get_viewport().get_mouse_position()
	var screen := get_viewport_rect().size
	var panel_size := size * scale
	var pos := mouse + MOUSE_OFFSET
	if pos.x + panel_size.x > screen.x:
		pos.x = mouse.x - MOUSE_OFFSET.x - panel_size.x
	if pos.y + panel_size.y > screen.y:
		pos.y = mouse.y - MOUSE_OFFSET.y - panel_size.y
	global_position = pos.max(Vector2.ZERO)
