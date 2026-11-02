extends CanvasLayer
class_name CharacterOverlay

# character screen (C): player stats, the wand and taken pacts. hover the wand or a pact
# for its description. pauses the game while open. opened by RunScene
@onready var stat_list: VBoxContainer = %StatList
@onready var wand_row: HBoxContainer = %WandRow
@onready var wand_icon: TextureRect = %WandIcon
@onready var wand_name: Label = %WandName
@onready var pact_list: VBoxContainer = %PactList
@onready var no_pacts_label: Label = %NoPactsLabel
@onready var hover_panel: PanelContainer = %HoverPanel
@onready var hover_title: Label = %HoverTitle
@onready var hover_subtitle: Label = %HoverSubtitle
@onready var hover_text: RichTextLabel = %HoverText

const HOVER_OFFSET = Vector2(10, 10) # from the mouse
const PACT_NAME_COLOR = Color(1, 0.6, 0.9)

signal closed

var was_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hover_panel.visible = false
	var player = NodeReferences.player
	if player:
		BuildStats(player)
		BuildWand(player.wand)
	BuildPacts()
	was_paused = get_tree().paused
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("Character"):
		get_viewport().set_input_as_handled()
		Close()

func _process(_delta: float) -> void:
	if hover_panel.visible:
		MoveHoverPanel()

func Close() -> void:
	get_tree().paused = was_paused
	closed.emit()
	queue_free()

# hp + mana first, then every visible player stat
func BuildStats(player: Player) -> void:
	AddStatLabel("HP: %d/%d" % [player.health.current, player.health.maximum])
	AddStatLabel("MP: %d/%d" % [player.mana, player.stats.GetStat(&"max_mana")])
	var display = player.stats.GetDisplayStats()
	for stat_name in display:
		AddStatLabel(StatBlock.FormatStat(stat_name, display[stat_name]))

func AddStatLabel(text: String) -> void:
	var label = Label.new()
	label.text = text
	stat_list.add_child(label)

func BuildWand(wand: Wand) -> void:
	if wand == null:
		wand_row.visible = false
		return
	wand_icon.texture = wand.data.icon
	wand_name.text = wand.data.display_name
	# live stats from the casters, so runes, pacts and upgrades are included
	var sections: Array[String] = []
	if wand.data.description != "":
		sections.append(wand.data.GetRichDescription())
	if wand.primary:
		sections.append(CasterText("Primary", wand.primary))
	if wand.heavy:
		sections.append(CasterText("Heavy", wand.heavy))
	ConnectHover(wand_row, wand.data.display_name, "", Color.WHITE, "\n\n".join(sections))

func CasterText(slot: String, caster: SpellCaster) -> String:
	var stats = caster.stats.GetDisplayStats()
	if stats.get(&"mana_cost", 0.0) == 0.0:
		stats.erase(&"mana_cost")
	return StatsCard.BuildSectionText(slot, stats)

# one row per pact, stacked ones get "x2", "x3"
func BuildPacts() -> void:
	no_pacts_label.visible = RunState.pacts.is_empty()
	var shown: Array[AltarPact] = []
	for pact in RunState.pacts:
		if pact in shown:
			continue
		shown.append(pact)
		pact_list.add_child(MakePactRow(pact))

func MakePactRow(pact: AltarPact) -> HBoxContainer:
	var row = HBoxContainer.new()
	for icon in pact.GetTagIcons():
		var rect = TextureRect.new()
		rect.texture = icon
		rect.custom_minimum_size = Vector2(12, 12)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(rect)

	var broken = pact.curse != null and pact.curse in RunState.cleansed_curses
	var stacks = RunState.GetStackCount(pact)
	var label = Label.new()
	label.text = pact.display_name + (" x%d" % stacks if stacks > 1 else "")
	# a broken curse leaves just the blessing, shown in the buff color
	label.modulate = AltarPact.BUFF_COLOR if broken else PACT_NAME_COLOR
	row.add_child(label)

	var text = pact.GetRichDescription()
	if broken:
		text += "\n[color=#%s](curse broken)[/color]" % AltarPact.BUFF_COLOR.to_html(false)
	ConnectHover(row, label.text, pact.GetSubtitle(), pact.GetSubtitleColor(), text)
	return row

# the row catches the mouse, its children don't, so hovering anywhere on it works
func ConnectHover(row: Control, title: String, subtitle: String, subtitle_color: Color, text: String) -> void:
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	for child in row.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.mouse_entered.connect(ShowHover.bind(title, subtitle, subtitle_color, text))
	row.mouse_exited.connect(HideHover)

func ShowHover(title: String, subtitle: String, subtitle_color: Color, text: String) -> void:
	hover_title.text = title
	hover_subtitle.text = subtitle
	hover_subtitle.modulate = subtitle_color
	hover_subtitle.visible = subtitle != ""
	hover_text.text = text
	hover_panel.visible = true
	hover_panel.reset_size() # shrink back after a longer text
	MoveHoverPanel()

func HideHover() -> void:
	hover_panel.visible = false

# next to the mouse, flipped to the other side when it would leave the screen
func MoveHoverPanel() -> void:
	var mouse = hover_panel.get_viewport().get_mouse_position()
	var screen = hover_panel.get_viewport_rect().size
	var size = hover_panel.size
	var pos = mouse + HOVER_OFFSET
	if pos.x + size.x > screen.x:
		pos.x = mouse.x - HOVER_OFFSET.x - size.x
	if pos.y + size.y > screen.y:
		pos.y = mouse.y - HOVER_OFFSET.y - size.y
	hover_panel.position = pos.max(Vector2.ZERO)
