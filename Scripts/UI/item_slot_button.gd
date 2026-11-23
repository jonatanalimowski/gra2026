extends Button
class_name ItemSlotButton

# one square showing an ItemData: loadout slots and ItemPicker grid cells.
# display only: the owning screen decides what's locked / selected / equipped and calls the setters
# locked, selected and equipped are separate flags since they combine (an equipped item can be selected)

signal item_pressed(slot: ItemSlotButton)
signal item_hovered(slot: ItemSlotButton)
signal item_unhovered(slot: ItemSlotButton)

@export var display_item_data: ItemData
@export var lock_icon: Texture2D # optional
@export var slot_size: Vector2 = Vector2(32, 32)

@export_group("Colors")
@export var normal_border: Color = Color(0.28, 0.27, 0.32)
@export var normal_bg: Color = Color(0.07, 0.07, 0.09)
@export var selected_border: Color = Color.WHITE
@export var equipped_border: Color = Color(1.0, 0.78, 0.32) # same gold as unlocked skill nodes
@export var equipped_bg: Color = Color(0.32, 0.22, 0.08)
@export var locked_icon_tint: Color = Color(0.05, 0.05, 0.07) # dark silhouette
@export_group("")
@export var corner_radius: int = 4
@export var border_width: int = 2

@onready var icon_rect: TextureRect = %IconRect
@onready var panel: Panel = %Panel
@onready var lock_rect: TextureRect = %LockRect

var is_locked: bool = false
var is_selected: bool = false
var is_equipped: bool = false
@warning_ignore("shadowed_variable_base_class")
var is_hovered: bool = false
var border_style: StyleBoxFlat

func _ready() -> void:
	border_style = StyleBoxFlat.new()
	border_style.set_border_width_all(border_width)
	border_style.set_corner_radius_all(corner_radius)
	panel.add_theme_stylebox_override("panel", border_style)
	SetupButtonStyles()
	lock_rect.texture = lock_icon
	SetSize(slot_size)
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_hover_changed.bind(true))
	mouse_exited.connect(_on_hover_changed.bind(false))
	SetItem(display_item_data)

func SetItem(item: ItemData) -> void:
	display_item_data = item
	icon_rect.texture = item.icon if item else null
	tooltip_text = ""
	ApplyLook()

func SetLocked(value: bool) -> void:
	is_locked = value
	ApplyLook()

func SetSelected(value: bool) -> void:
	is_selected = value
	ApplyLook()

func SetEquipped(value: bool) -> void:
	is_equipped = value
	ApplyLook()

# containers size children by custom_minimum_size, so that's what actually sticks
func SetSize(new_size: Vector2 = slot_size, new_scale: Vector2 = Vector2.ONE) -> void:
	slot_size = new_size
	custom_minimum_size = new_size
	size = new_size
	scale = new_scale

func ApplyLook() -> void:
	if not border_style:
		return # called before _ready
	var border_color := normal_border
	border_style.bg_color = normal_bg
	if is_equipped:
		border_color = equipped_border
		border_style.bg_color = equipped_bg
	if is_selected:
		border_color = selected_border
	elif is_hovered and not is_locked:
		border_color = border_color.lightened(0.3)
	border_style.border_color = border_color
	icon_rect.modulate = locked_icon_tint if is_locked else Color.WHITE
	lock_rect.visible = is_locked and lock_icon != null


func MakeRoundedBox(color: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	return box

# the Panel is the look, the button itself only adds a light overlay on hover/press
func SetupButtonStyles() -> void:
	var empty := StyleBoxEmpty.new()
	var radius := maxi(corner_radius - border_width, 0)
	add_theme_stylebox_override("normal", empty)
	add_theme_stylebox_override("disabled", empty)
	add_theme_stylebox_override("focus", empty)
	add_theme_stylebox_override("hover", MakeRoundedBox(Color(1, 1, 1, 0.08), radius))
	add_theme_stylebox_override("pressed", MakeRoundedBox(Color(1, 1, 1, 0.2), radius))
	add_theme_stylebox_override("hover_pressed", MakeRoundedBox(Color(1, 1, 1, 0.2), radius))

func _on_pressed() -> void:
	if not is_locked: # locked items still hover (to show details), just can't be picked
		item_pressed.emit(self)

func _on_hover_changed(hovered: bool) -> void:
	is_hovered = hovered
	ApplyLook()
	if hovered:
		item_hovered.emit(self)
	else:
		item_unhovered.emit(self)
