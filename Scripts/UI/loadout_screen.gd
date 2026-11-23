extends Control

const STATS_OVERLAY = preload("res://Scenes/UI/StatsOverlay.tscn")

enum Category { WAND, KEYSTONE }
const CATEGORY_TITLES = { Category.WAND: "Wands", Category.KEYSTONE: "Keystones" }

@onready var wand_slot: ItemSlotButton = %WandSlot
@onready var keystone_slot: ItemSlotButton = %KeystoneSlot
@onready var picker: ItemPicker = %ItemPicker
@onready var details: ItemDetails = %LoadoutDetails
@onready var start_button: Button = %StartRunButton
@onready var back_button: Button = %BackButton

var loadout := Loadout.new()
var keystone: ItemData
var active_category: Category = Category.WAND
var slot_by_category: Dictionary = {} # Category -> ItemSlotButton
var shown_item: ItemData
var stats_button: Button

func _ready() -> void:
	slot_by_category = { Category.WAND: wand_slot, Category.KEYSTONE: keystone_slot }
	for category in slot_by_category:
		var slot: ItemSlotButton = slot_by_category[category]
		slot.item_pressed.connect(_on_slot_pressed.bind(category))
		slot.item_hovered.connect(_on_slot_hovered)
		slot.item_unhovered.connect(_on_item_unhovered)
	picker.item_picked.connect(_on_item_picked)
	picker.item_hovered.connect(ShowDetails)
	picker.item_unhovered.connect(_on_item_unhovered)
	back_button.pressed.connect(_on_back_button_pressed)
	start_button.pressed.connect(_on_start_pressed)
	AddDetailsActions()

	var wands := GetUnlocked(Category.WAND)
	if not wands.is_empty():
		loadout.wand = wands[0] # TODO: remember the last loadout from MetaProgress
	RefreshSlots()
	SelectCategory(Category.WAND)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()


func GetUnlocked(category: Category) -> Array:
	match category:
		Category.WAND:
			return InventoryManager.GetWands() # TODO: only owned wands once MetaProgress tracks them
		Category.KEYSTONE:
			return [] # TODO: Once keystones are made
	return []

func GetLocked(_category: Category) -> Array:
	return [] # TODO: the rest of the database minus GetUnlocked, drawn as silhouettes

func GetEquipped(category: Category) -> ItemData:
	match category:
		Category.WAND:
			return loadout.wand
		Category.KEYSTONE:
			return keystone
	return null

func Equip(category: Category, item: ItemData) -> void:
	match category:
		Category.WAND:
			loadout.wand = item as WandData
		Category.KEYSTONE:
			keystone = item

# --- flow ---

func SelectCategory(category: Category) -> void:
	active_category = category
	for c in slot_by_category:
		slot_by_category[c].SetSelected(c == category)
	picker.SetItems(CATEGORY_TITLES[category], GetUnlocked(category), GetLocked(category), GetEquipped(category))
	ShowEquipped()

func RefreshSlots() -> void:
	for category in slot_by_category:
		slot_by_category[category].SetItem(GetEquipped(category))
	start_button.disabled = loadout.wand == null # a run needs a wand

func ShowEquipped() -> void:
	ShowDetails(GetEquipped(active_category))

func ShowDetails(item: ItemData) -> void:
	shown_item = item
	if item:
		details.ShowItem(item)
	else:
		details.ShowText("Empty", "", Color.WHITE, "Pick one from the list below.")
	stats_button.visible = item != null and not item.GetDisplayStats().is_empty()

# buttons live in the details panel's Actions box, the logic stays here
func AddDetailsActions() -> void:
	stats_button = Button.new()
	stats_button.theme = preload("res://Data/UI/alt_button.tres")
	stats_button.text = "Stats"
	stats_button.pressed.connect(_on_stats_pressed)
	details.GetActions().add_child(stats_button)

# --- signal handlers ---

func _on_slot_pressed(_slot: ItemSlotButton, category: Category) -> void:
	SelectCategory(category)

func _on_slot_hovered(slot: ItemSlotButton) -> void:
	if slot.display_item_data:
		ShowDetails(slot.display_item_data)

# moving off anything falls back to the active slot's item, so the panel is never empty
func _on_item_unhovered(_item) -> void:
	ShowEquipped()

func _on_item_picked(item: ItemData) -> void:
	Equip(active_category, item)
	RefreshSlots()
	picker.SetEquipped(item)
	ShowDetails(item)

func _on_stats_pressed() -> void:
	if not shown_item:
		return
	var overlay: StatsOverlay = STATS_OVERLAY.instantiate()
	get_tree().root.add_child(overlay)
	overlay.Open(shown_item.display_name, [shown_item])

func _on_start_pressed() -> void:
	GameFlow.StartRun(loadout) # CollectRewards fills the skill part (mods, runes, schools)

func _on_back_button_pressed() -> void:
	GameFlow.GoToMainMenu()
