extends Control

const STATS_OVERLAY = preload("res://Scenes/UI/StatsOverlay.tscn")
const SLOT_SCENE = preload("res://Scenes/UI/ItemSlotButton.tscn")

enum Category { WAND, KEYSTONE, SCHOOL }
const CATEGORY_TITLES = { Category.WAND: "Wands", Category.KEYSTONE: "Keystones", Category.SCHOOL: "Schools" }
const EMPTY_HINTS = {
	Category.WAND: "Pick one from the list below.",
	Category.KEYSTONE: "Pick one from the list below.",
	Category.SCHOOL: "Pick the schools whose pacts can show up this run. Form pacts always can.",
}

# schools per run: only these (+ Form) get offered at altars. the minimum keeps offers from running dry
const MIN_SCHOOLS = 2
const MAX_SCHOOLS = 3
const SCHOOL_SLOT_SIZE = Vector2(36, 36)

@onready var wand_slot: ItemSlotButton = %WandSlot
@onready var keystone_slot: ItemSlotButton = %KeystoneSlot
@onready var school_slots_box: HBoxContainer = %SchoolSlots
@onready var schools_hint: Label = %SchoolsHint
@onready var picker: ItemPicker = %ItemPicker
@onready var details: ItemDetails = %LoadoutDetails
@onready var start_button: Button = %StartRunButton
@onready var back_button: Button = %BackButton

var loadout := Loadout.new()
var keystone: ItemData
var active_category: Category = Category.WAND
var slots_by_category: Dictionary = {} # Category -> Array of ItemSlotButton
var unlocked_schools: Array[School.Kind] = []
var shown_item: ItemData
var stats_button: Button

func _ready() -> void:
	unlocked_schools = SkillManager.GetUnlockedSchools()
	slots_by_category = {
		Category.WAND: [wand_slot],
		Category.KEYSTONE: [keystone_slot],
		Category.SCHOOL: BuildSchoolSlots(),
	}
	for category in slots_by_category:
		for slot: ItemSlotButton in slots_by_category[category]:
			slot.item_pressed.connect(_on_slot_pressed.bind(category))
			slot.item_hovered.connect(_on_slot_hovered)
			slot.item_unhovered.connect(_on_item_unhovered)
	picker.item_picked.connect(_on_item_picked)
	picker.item_hovered.connect(ShowDetails)
	picker.item_unhovered.connect(_on_item_unhovered)
	back_button.pressed.connect(_on_back_button_pressed)
	start_button.pressed.connect(_on_start_pressed)
	AddDetailsActions()

	loadout.wand = GetStartingWand()
	loadout.schools.assign(GetStartingSchools())
	RefreshSlots()
	SelectCategory(Category.WAND)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

# one slot per school you can take, so a save with 1 school unlocked shows 1 slot
func BuildSchoolSlots() -> Array:
	var slots := []
	var count := mini(MAX_SCHOOLS, unlocked_schools.size())
	for i in count:
		var slot: ItemSlotButton = SLOT_SCENE.instantiate()
		slot.slot_size = SCHOOL_SLOT_SIZE
		school_slots_box.add_child(slot)
		slots.append(slot)
	schools_hint.visible = count == 0
	return slots

# last picked wand if it's still unlocked, else the first one
func GetStartingWand() -> WandData:
	var wands := GetUnlocked(Category.WAND)
	for wand: WandData in wands:
		if String(wand.id) == MetaProgress.last_wand:
			return wand
	return wands[0] if not wands.is_empty() else null

# last picked schools if they're still unlocked, topped up from the unlocked ones
func GetStartingSchools() -> Array[School.Kind]:
	var schools: Array[School.Kind] = []
	for id in MetaProgress.last_schools:
		var kind := School.FromId(id)
		if kind in unlocked_schools and kind not in schools and schools.size() < MAX_SCHOOLS:
			schools.append(kind)
	if schools.size() < GetMinSchools() or MetaProgress.last_schools.is_empty():
		for kind in unlocked_schools:
			if schools.size() >= MAX_SCHOOLS:
				break
			if kind not in schools:
				schools.append(kind)
	return schools

# a save with fewer schools unlocked than the minimum can still start (Form pacts fill in)
func GetMinSchools() -> int:
	return mini(MIN_SCHOOLS, unlocked_schools.size())

func CanStart() -> bool:
	return loadout.wand != null and loadout.schools.size() >= GetMinSchools()


func GetUnlocked(category: Category) -> Array:
	match category:
		Category.WAND:
			return InventoryManager.GetWands() # TODO: only owned wands once MetaProgress tracks them
		Category.KEYSTONE:
			return [] # TODO: Once keystones are made
		Category.SCHOOL:
			return InventoryManager.GetSchools().filter(func(s): return s.kind in unlocked_schools)
	return []

func GetLocked(category: Category) -> Array:
	match category:
		Category.SCHOOL:
			return InventoryManager.GetSchools().filter(func(s): return s.kind not in unlocked_schools)
	return [] # TODO: the rest of the database minus GetUnlocked, drawn as silhouettes

# an array for every category, so single slots and multi-pick schools share the same code
func GetEquipped(category: Category) -> Array:
	match category:
		Category.WAND:
			return [loadout.wand] if loadout.wand else []
		Category.KEYSTONE:
			return [keystone] if keystone else []
		Category.SCHOOL:
			return loadout.schools.map(InventoryManager.GetSchoolData).filter(func(s): return s != null)
	return []

func Equip(category: Category, item: ItemData) -> void:
	match category:
		Category.WAND:
			loadout.wand = item as WandData
		Category.KEYSTONE:
			keystone = item
		Category.SCHOOL:
			ToggleSchool((item as SchoolData).kind)

# picking a taken school drops it. picking a new one while full drops the oldest pick
func ToggleSchool(kind: School.Kind) -> void:
	if kind in loadout.schools:
		loadout.schools.erase(kind)
		return
	if loadout.schools.size() >= MAX_SCHOOLS:
		loadout.schools.remove_at(0)
	loadout.schools.append(kind)

# --- flow ---

func SelectCategory(category: Category) -> void:
	active_category = category
	for c in slots_by_category:
		for slot: ItemSlotButton in slots_by_category[c]:
			slot.SetSelected(c == category)
	picker.SetItems(CATEGORY_TITLES[category], GetUnlocked(category), GetLocked(category), GetEquipped(category))
	ShowEquipped()

func RefreshSlots() -> void:
	for category in slots_by_category:
		var equipped := GetEquipped(category)
		var slots: Array = slots_by_category[category]
		for i in slots.size():
			slots[i].SetItem(equipped[i] if i < equipped.size() else null)
	start_button.disabled = not CanStart()

func ShowEquipped() -> void:
	var equipped := GetEquipped(active_category)
	ShowDetails(equipped[0] if not equipped.is_empty() else null)

func ShowDetails(item: ItemData) -> void:
	shown_item = item
	if item:
		details.ShowItem(item)
	else:
		details.ShowText("Empty", "", Color.WHITE, EMPTY_HINTS[active_category])
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
	picker.SetEquipped(GetEquipped(active_category))
	ShowDetails(item)
	SaveLoadout()

# TODO: keystone too, once they exist
func SaveLoadout() -> void:
	var wand_id := String(loadout.wand.id) if loadout.wand else ""
	MetaProgress.SetLastLoadout(wand_id, loadout.schools.map(School.GetId))

func _on_stats_pressed() -> void:
	if not shown_item:
		return
	var overlay: StatsOverlay = STATS_OVERLAY.instantiate()
	get_tree().root.add_child(overlay)
	overlay.Open(shown_item.display_name, [shown_item])

func _on_start_pressed() -> void:
	SaveLoadout() # also covers a loadout started without any picks
	GameFlow.StartRun(loadout) # CollectRewards fills the skill part (mods, runes) and drops refunded schools

func _on_back_button_pressed() -> void:
	GameFlow.GoToMainMenu()
