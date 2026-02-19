extends Control
var player: Player
@onready var hp_bar: TextureProgressBar = $PlayerBars/VBoxContainer/Healthbar
@onready var hp_text: Label = $PlayerBars/VBoxContainer/Healthbar/Label
@onready var player_stats: VBoxContainer = $PlayerStatistics/VBoxContainer/Playerstats
var player_stats_dict: Dictionary[String, Label]

func _ready() -> void:
	ConnectSignals()

func ConnectSignals() -> void:
	Signals.player_ready.connect(_on_player_ready)
	Signals.player_health_changed.connect(UpdateHealth)
	Signals.player_stat_changed.connect(UpdateStatistics)

func _on_player_ready(player_node: CharacterBody2D):
	player = player_node
	InitialisePlayerStats()

func FixPlayerReference() -> void:
	if player == null:
		if NodeReferences.player != null:
			player = NodeReferences.player

func UpdateHealth(new_current: int, new_max: int):
	hp_bar.max_value = new_max
	hp_bar.value = new_current
	hp_text.text = str(new_current) + "/" + str(new_max)

func UpdateStatistics(stat_name: String, value: float):
	if stat_name in player_stats_dict:
		var label = player_stats_dict[stat_name]
		var display_name = stat_name.capitalize().replace("_", " ")
		label.text = "%s: %.1f" % [display_name, value]

func InitialisePlayerStats():
	for child in player_stats.get_children():
		child.queue_free()
	player_stats_dict.clear()
	
	var stats = player.stats.get_property_list()
	for prop in stats:
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			if prop.name in player.stats.STAT_IGNORE_IN_DISPLAY:
				continue
			
			if prop.type in [TYPE_FLOAT, TYPE_INT]:
				var value = player.stats.get(prop.name) 
				AddStatLabel(prop.name, value)

func AddStatLabel(stat_name: String, value: float):
	var label = Label.new()
	player_stats.add_child(label)
	
	player_stats_dict[stat_name] = label
	var display_name = stat_name.capitalize().replace("_", " ")
	label.text = "%s: %.1f" % [display_name, value]
