extends Control
const GRAY: Color = Color(0.3, 0.3, 0.3, 1.0)
@onready var hp_bar: TextureProgressBar = %PlayerHealthbar
#@onready var hp_text: Label = %PlayerHealthbar/Label
@onready var player_stats: VBoxContainer = %Playerstats
@onready var primary_spell_stats: VBoxContainer = %PrimarySpellStats
@onready var heavy_spell_stats: VBoxContainer = %HeavySpellStats
@onready var primary_spell_slot: TextureRect = %PrimarySpellTexture
@onready var heavy_spell_slot: TextureRect = %HeavySpellTexture
@onready var boss_hp_bar: TextureProgressBar = %BossHpBar
@onready var boss_hp_text: Label = %BossHpLabel
@onready var boss_ui = %BossBar
@onready var stats_column: VBoxContainer = %StatsColumn
@onready var floor_label: Label = %FloorLabel
var pact_list: VBoxContainer
var tab_hint: Label
var hp_label: Label
var stats_visible: bool = false

func _ready() -> void:
	ConnectSignals()
	boss_ui.visible = false
	# the run scene reloads every floor, so setting it once is enough
	floor_label.text = "Floor %d" % RunState.floor_number
	# stats are hidden behind Tab, the hint takes their place while closed
	tab_hint = Label.new()
	tab_hint.text = "[Tab] Stats"
	stats_column.add_child(tab_hint)
	stats_column.move_child(tab_hint, 0)
	hp_label = Label.new()
	stats_column.add_child(hp_label)
	stats_column.move_child(hp_label, 2) # under the "Player Stats:" header
	pact_list = VBoxContainer.new()
	stats_column.add_child(pact_list)
	UpdatePacts()
	SetStatsVisible(false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Tab"):
		SetStatsVisible(!stats_visible)

# everything in the column but the hint
func SetStatsVisible(on: bool) -> void:
	stats_visible = on
	for child in stats_column.get_children():
		child.visible = on if child != tab_hint else not on

func ConnectSignals() -> void:
	Signals.player_ready.connect(_on_player_ready)
	Signals.player_health_changed.connect(UpdateHealth)
	Signals.boss_spawned.connect(_on_boss_spawned)
	Signals.boss_health_changed.connect(UpdateBossHP)
	Signals.boss_defeated.connect(_on_boss_deafeated)
	RunState.pact_added.connect(_on_pact_added)
	RunState.curse_cleansed.connect(func(_curse): UpdatePacts())

func _on_player_ready(player: Player):
	BuildStatList(player_stats, player.stats)

	var wand = player.wand
	primary_spell_slot.texture = wand.data.icon
	BuildStatList(primary_spell_stats, wand.primary.stats if wand.primary else null)

	# heavy slot shows the same wand icon, grayed out while the wand has no heavy spell
	heavy_spell_slot.texture = wand.data.icon
	heavy_spell_slot.modulate = Color.WHITE if wand.heavy else GRAY
	BuildStatList(heavy_spell_stats, wand.heavy.stats if wand.heavy else null)

# one label per stat, kept up to date through the StatBlock's stat_changed signal
func BuildStatList(container: VBoxContainer, stats: StatBlock) -> void:
	for child in container.get_children():
		child.queue_free()
	if stats == null:
		return

	var labels: Dictionary[StringName, Label] = {}
	for stat_name in stats.GetStatNames():
		if stat_name in stats.hidden_stats:
			continue

		var label = Label.new()
		container.add_child(label)
		SetStatLabel(label, stat_name, stats.GetStat(stat_name))
		labels[stat_name] = label

	stats.stat_changed.connect(func(stat_name, value):
		if labels.has(stat_name):
			SetStatLabel(labels[stat_name], stat_name, value)
	)

func SetStatLabel(label: Label, stat_name: String, value: float) -> void:
	label.text = StatBlock.FormatStat(stat_name, value)

func UpdateHealth(new_current: int, new_max: int):
	hp_bar.max_value = new_max
	hp_bar.value = new_current
	hp_label.text = "HP: %d/%d" % [new_current, new_max]

func UpdateBossHP(new_current, new_max):
	boss_hp_bar.max_value = new_max
	boss_hp_bar.value = new_current
	boss_hp_text.text = str(new_current) + "/" + str(new_max)

func _on_boss_spawned(hp_value):
	boss_ui.visible = true
	boss_hp_bar.max_value = hp_value
	boss_hp_bar.value = hp_value
	boss_hp_text.text = str(hp_value) + "/" + str(hp_value)

func _on_boss_deafeated():
	boss_ui.visible = false
	pact_list = VBoxContainer.new()
	pact_list.visible = stats_visible
	stats_column.add_child(pact_list)
	UpdatePacts()
	boss_hp_bar.visible = false
	boss_hp_text.visible = false

func _on_pact_added(_pact: AltarPact) -> void:
	UpdatePacts()

# taken altar pacts, hover a name for buff + curse text
func UpdatePacts() -> void:
	for child in pact_list.get_children():
		child.queue_free()
	if RunState.pacts.is_empty():
		return

	var header = Label.new()
	header.text = "Pacts:"
	pact_list.add_child(header)
	var shown: Array[AltarPact] = []
	for pact in RunState.pacts:
		if pact in shown:
			continue # stacked pacts get one row with a count
		shown.append(pact)
		var row = HBoxContainer.new()
		var broken = pact.curse and pact.curse in RunState.cleansed_curses
		row.tooltip_text = pact.GetDescription() + ("\n(curse broken)" if broken else "")
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		for icon in pact.GetTagIcons():
			var rect = TextureRect.new()
			rect.texture = icon
			rect.custom_minimum_size = Vector2(12, 12)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(rect)
		var label = Label.new()
		# a broken curse leaves just the blessing, shown in the buff color
		var stacks = RunState.GetStackCount(pact)
		label.text = pact.display_name + (" x%d" % stacks if stacks > 1 else "")
		label.modulate = AltarPact.BUFF_COLOR if broken else Color(1, 0.6, 0.9)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
		pact_list.add_child(row)
