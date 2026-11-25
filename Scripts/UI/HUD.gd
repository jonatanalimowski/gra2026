extends Control
const GRAY: Color = Color(0.3, 0.3, 0.3, 1.0)
@onready var hp_bar: catch_up_progress_bar = %PlayerHealthbar
@onready var mana_bar: catch_up_progress_bar = %ManaBar
#@onready var hp_text: Label = %PlayerHealthbar/Label
@onready var primary_spell_slot: TextureRect = %PrimarySpellTexture
@onready var heavy_spell_slot: TextureRect = %HeavySpellTexture
@onready var boss_hp_bar: TextureProgressBar = %BossHpBar
@onready var boss_hp_text: Label = %BossHpLabel
@onready var boss_ui = %BossBar
@onready var floor_label: Label = %FloorLabel
@onready var experience_label: Label = %ExperienceLabel
# above the hp/mana panel, bottom-anchored so it grows upwards as statuses come in
@onready var status_list: VBoxContainer = %PlayerStatusList

var pact_list: VBoxContainer
var status_rows: Dictionary = {} # ActiveStatusEffect -> its time label
var tab_hint: Label
var hp_label: Label
var mana_label: Label
var player: Player
var stats_visible: bool = false
# boss bar phases (BossBrain): phase 1 shows the hp above the threshold, phase 2 the rest, refilled
var boss_phase: int = 1
var boss_threshold: float = 0.0 # 0 = no phases, plain bar
var boss_hp: float = 0.0
var boss_max_hp: float = 0.0
var boss_refill_tween: Tween

func _ready() -> void:
	ConnectSignals()
	boss_ui.visible = false
	# the run scene reloads every floor, so setting it once is enough
	floor_label.text = "Floor %d" % RunState.floor_number
	for omen in RunState.omens:
		floor_label.text += "\nOmen: %s" % omen.display_name
	if not RunState.omens.is_empty():
		floor_label.tooltip_text = "\n".join(RunState.omens.map(func(o): return "%s: %s" % [o.display_name, o.description]))
		floor_label.mouse_filter = Control.MOUSE_FILTER_STOP
	# stats are hidden behind Tab, the hint takes their place while closed
	tab_hint = Label.new()
	tab_hint.text = "[C] Stats"
	hp_label = Label.new()
	mana_label = Label.new()
	pact_list = VBoxContainer.new()
	UpdatePacts()
	_on_experience_changed(RunState.collected_experience)
	# the player sits before the UI in Main.tscn, so its player_ready fired before we connected
	if is_instance_valid(NodeReferences.player) and NodeReferences.player.is_inside_tree():
		_on_player_ready(NodeReferences.player)

func ConnectSignals() -> void:
	Signals.player_ready.connect(_on_player_ready)
	Signals.player_health_changed.connect(UpdateHealth)
	Signals.player_mana_changed.connect(UpdateMana)
	Signals.boss_spawned.connect(_on_boss_spawned)
	Signals.boss_health_changed.connect(UpdateBossHP)
	Signals.boss_defeated.connect(_on_boss_deafeated)
	Signals.boss_phase_changed.connect(_on_boss_phase_changed)
	RunState.pact_added.connect(_on_pact_added)
	RunState.curse_cleansed.connect(func(_curse): UpdatePacts())
	RunState.attunement_reached.connect(_on_attunement_reached)
	RunState.on_experience_changed.connect(_on_experience_changed)

func _on_experience_changed(new_xp: int):
	experience_label.text = "Experience: %d" % [new_xp]

# big named popup in the middle of the screen when a school tier is reached
func _on_attunement_reached(attunement: Attunement) -> void:
	var label = Label.new()
	label.text = "%s Attunement: %s" % [School.GetName(attunement.school), attunement.display_name]
	if attunement.blessing:
		label.text += "\n" + attunement.blessing.description
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = School.GetColor(attunement.school)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.position.y = 60
	label.scale = Vector2(1.5, 1.5)
	add_child(label)
	label.pivot_offset = label.size / 2.0
	Sfx.Play(&"altar/cleanse", -4)
	var tween = label.create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func _on_player_ready(new_player: Player):
	if player == new_player:
		return
	player = new_player
	player.status_holder.status_added.connect(_on_status_added)
	player.status_holder.status_removed.connect(_on_status_removed)
	# same story for the first bar values, they were emitted before we listened
	UpdateHealth(player.health.current, player.health.maximum)
	UpdateMana(player.mana, player.stats.GetStat(&"max_mana"))

	var wand = player.wand
	primary_spell_slot.texture = wand.data.icon

	# heavy slot shows the same wand icon
	heavy_spell_slot.texture = wand.data.icon
	UpdateHeavySlot()

# one row per status above the bars: icon (if it has one) + name + stacks + time left
func _on_status_added(status: ActiveStatusEffect) -> void:
	var row = HBoxContainer.new()
	if status.effect.icon:
		var icon = TextureRect.new()
		icon.texture = status.effect.icon
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		row.add_child(icon)
	var label = Label.new()
	label.modulate = status.effect.color
	row.add_child(label)
	status_list.add_child(row)
	status_rows[status] = label

func _on_status_removed(status: ActiveStatusEffect) -> void:
	status_rows[status].get_parent().queue_free()
	status_rows.erase(status)

func _process(_delta: float) -> void:
	for status in status_rows:
		var stacks = " x%d" % status.stacks if status.stacks > 1 else ""
		status_rows[status].text = "%s%s %.1fs" % [status.effect.name, stacks, maxf(status.time_left, 0.0)]

# grayed out while the wand has no heavy spell or the player can't pay for it
func UpdateHeavySlot() -> void:
	if player == null:
		return
	var heavy = player.wand.heavy
	var can_cast = heavy != null and (player.mana >= heavy.stats.GetStat(&"mana_cost") or RunState.HasFlag(&"blood_price"))
	heavy_spell_slot.modulate = Color.WHITE if can_cast else GRAY

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
	hp_bar.UpdateValue(new_current, new_max)

func UpdateMana(new_current: float, new_max: float) -> void:
	mana_bar.UpdateValue(new_current, new_max)
	UpdateHeavySlot()

func UpdateBossHP(new_current, new_max):
	boss_hp = new_current
	boss_max_hp = new_max
	RefreshBossBar()

func _on_boss_spawned(hp_value):
	boss_ui.visible = true
	UpdateBossHP(hp_value, hp_value)

# the bar only shows the current phase's slice of the hp
func RefreshBossBar() -> void:
	var split = boss_max_hp * boss_threshold
	var bar_max = boss_max_hp
	var bar_value = boss_hp
	if boss_threshold > 0:
		bar_max = boss_max_hp - split if boss_phase == 1 else split
		bar_value = boss_hp - split if boss_phase == 1 else boss_hp
	boss_hp_bar.max_value = max(bar_max, 1.0)
	# the refill animation sets the value itself and syncs at the end
	if not (boss_refill_tween and boss_refill_tween.is_running()):
		boss_hp_bar.value = bar_value
	boss_hp_text.text = "%d/%d" % [boss_hp, boss_max_hp]

func _on_boss_phase_changed(phase: int, threshold: float) -> void:
	boss_phase = phase
	boss_threshold = threshold
	if phase == 1:
		boss_hp_bar.tint_progress = Color.WHITE
		RefreshBossBar()
		return
	# phase 2: the bar sits empty for a beat, then refills in the enraged color
	boss_hp_bar.value = 0
	if boss_refill_tween:
		boss_refill_tween.kill()
	boss_refill_tween = create_tween()
	boss_refill_tween.tween_interval(0.25)
	boss_refill_tween.tween_property(boss_hp_bar, "value", boss_max_hp * threshold, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	boss_refill_tween.finished.connect(RefreshBossBar)
	RefreshBossBar()

func _on_boss_deafeated():
	boss_ui.visible = false
	pact_list = VBoxContainer.new()
	pact_list.visible = stats_visible
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
		if pact.slot != AltarPact.Slot.NONE:
			label.text = "[%s] %s" % [AltarPact.GetSlotName(pact.slot), label.text]
		label.modulate = AltarPact.BUFF_COLOR if broken else Color(1, 0.6, 0.9)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
		pact_list.add_child(row)
