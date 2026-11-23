extends VBoxContainer
class_name ItemPicker

signal item_picked(item: ItemData)
signal item_hovered(item: ItemData)
signal item_unhovered(item: ItemData)

const SLOT_SCENE = preload("res://Scenes/UI/ItemSlotButton.tscn")

@export var cell_size: Vector2 = Vector2(32, 32)
@export var columns: int = 6
@export var empty_text: String = "Nothing unlocked yet"

@onready var title_label: Label = %PickerTitle
@onready var grid: GridContainer = %PickerGrid
@onready var empty_label: Label = %EmptyLabel

var slots: Array[ItemSlotButton] = []

func _ready() -> void:
	grid.columns = columns
	empty_label.text = empty_text

# equipped is an array so multi-pick categories (schools) work the same as single ones
func SetItems(title: String, unlocked: Array, locked: Array = [], equipped: Array = []) -> void:
	Clear()
	var total := unlocked.size() + locked.size()
	title_label.text = "%s (%d/%d)" % [title, unlocked.size(), total] if total > 0 else title
	for item in unlocked:
		AddSlot(item, false)
	for item in locked:
		AddSlot(item, true)
	empty_label.visible = slots.is_empty()
	SetEquipped(equipped)

# should be used before add_child()
func AddSlot(item: ItemData, locked: bool) -> void:
	var slot: ItemSlotButton = SLOT_SCENE.instantiate()
	slot.display_item_data = item
	slot.slot_size = cell_size
	grid.add_child(slot)
	slot.SetLocked(locked)
	slot.item_pressed.connect(_on_slot_pressed)
	slot.item_hovered.connect(_on_slot_hovered)
	slot.item_unhovered.connect(_on_slot_unhovered)
	slots.append(slot)

func Clear() -> void:
	for slot in slots:
		grid.remove_child(slot)
		slot.queue_free()
	slots.clear()

func SetEquipped(items: Array) -> void:
	for slot in slots:
		slot.SetEquipped(slot.display_item_data in items)

func _on_slot_pressed(slot: ItemSlotButton) -> void:
	item_picked.emit(slot.display_item_data)

func _on_slot_hovered(slot: ItemSlotButton) -> void:
	item_hovered.emit(slot.display_item_data)

func _on_slot_unhovered(slot: ItemSlotButton) -> void:
	item_unhovered.emit(slot.display_item_data)
