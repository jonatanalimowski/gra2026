extends Control
var player: Player
const GRAY: Color = Color(0.3, 0.3, 0.3, 1.0)
@onready var hp_bar: TextureProgressBar = $PlayerBars/VBoxContainer/Healthbar
@onready var hp_text: Label = $PlayerBars/VBoxContainer/Healthbar/Label
@onready var player_stats: VBoxContainer = $PlayerStatistics/VBoxContainer/Playerstats
@onready var primary_weapon_stats: VBoxContainer = $PlayerStatistics/VBoxContainer/PrimaryWpnStats
@onready var secondary_weapon_stats: VBoxContainer = $PlayerStatistics/VBoxContainer/SecondaryWpnStats
@onready var primary_weapon_slot: TextureRect = $WeaponSlots/HBoxContainer/PrimaryWeapon/WeaponTexture
@onready var secondary_weapon_slot: TextureRect = $WeaponSlots/HBoxContainer/SecondaryWeapon/WeaponTexture

var player_stats_dict: Dictionary[String, Label]
var primary_weapon_stats_dict: Dictionary[String, Label]
var secondary_weapon_stats_dict: Dictionary[String, Label]
var detailed_stats_dict: Dictionary[String, Label]

#ugly ass ui code
func _ready() -> void:
	ConnectSignals()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Tab"):
		ToggleDetailedStats()

func ToggleDetailedStats() -> void:
	for stat_name in detailed_stats_dict:
		detailed_stats_dict[stat_name].visible = !detailed_stats_dict[stat_name].visible

func ConnectSignals() -> void:
	Signals.player_ready.connect(_on_player_ready)
	Signals.player_health_changed.connect(UpdateHealth)
	Signals.player_stat_changed.connect(UpdatePlayerStatistics)
	Signals.player_weapon_changed.connect(_on_player_weapon_changed)
	Signals.weapon_stat_changed.connect(UpdateWeaponStatistics)

func _on_player_weapon_changed(weapon_slot: int):
	if weapon_slot == 1:
		# gray out currently unused slot
		secondary_weapon_stats.visible = false
		secondary_weapon_slot.modulate = GRAY
		for child in secondary_weapon_slot.get_children():
			child.modulate = GRAY
		
		# make normal current one
		primary_weapon_stats.visible = true
		primary_weapon_slot.modulate = Color.WHITE
		for child in primary_weapon_slot.get_children():
			child.modulate = Color.WHITE
		
	else:
		primary_weapon_stats.visible = false
		primary_weapon_slot.modulate = GRAY
		for child in primary_weapon_slot.get_children():
			child.modulate = GRAY
		
		secondary_weapon_stats.visible = true
		secondary_weapon_slot.modulate = Color.WHITE
		for child in secondary_weapon_slot.get_children():
			child.modulate = Color.WHITE

func _on_player_ready(player_node: CharacterBody2D):
	player = player_node
	InitialisePlayerStats()
	InitialisePrimaryWeaponStats()
	InitialiseSecondaryWeaponStats()
	ToggleDetailedStats()

func FixPlayerReference() -> void:
	if player == null:
		if NodeReferences.player != null:
			player = NodeReferences.player

func UpdateHealth(new_current: int, new_max: int):
	hp_bar.max_value = new_max
	hp_bar.value = new_current
	hp_text.text = str(new_current) + "/" + str(new_max)

func UpdatePlayerStatistics(stat_name: String, value: float):
	if stat_name in player_stats_dict:
		var label = player_stats_dict[stat_name]
		var display_name = stat_name.capitalize().replace("_", " ")
		label.text = "%s: %.1f" % [display_name, value]

func UpdateWeaponStatistics(stat_name: String, value: float, slot_number: int): #1 primary , 2 secondary
	var stats_dict
	if slot_number == 1:
		stats_dict = primary_weapon_stats_dict
	else:
		stats_dict = secondary_weapon_stats_dict
	
	if stat_name in stats_dict:
		var label = stats_dict[stat_name]
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
				AddStatLabel(prop.name, value, player_stats, player_stats_dict)
				if prop.name in player.stats.STAT_DETAILED:
					detailed_stats_dict[prop.name] = player_stats_dict[prop.name]
				

func InitialisePrimaryWeaponStats():
	primary_weapon_slot.texture = player.slot1_weapon.icon
	
	for child in primary_weapon_stats.get_children():
		child.queue_free()
	primary_weapon_stats_dict.clear()
	
	var stats = player.slot1_weapon.stats.get_property_list()
	for prop in stats:
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			if prop.name in player.slot1_weapon.stats.STAT_IGNORE_IN_DISPLAY:
				continue
			
			if prop.type in [TYPE_FLOAT, TYPE_INT]:
				var value = player.slot1_weapon.stats.get(prop.name) 
				var prop_name = "pw_" + prop.name
				AddStatLabel(prop_name, value, primary_weapon_stats, primary_weapon_stats_dict)
				if prop.name in player.slot1_weapon.stats.STAT_DETAILED:
					detailed_stats_dict[prop_name] = primary_weapon_stats_dict[prop_name]
					print("added stat for primary weapon to detailed dict stat name: " + prop_name)

func InitialiseSecondaryWeaponStats():
	secondary_weapon_slot.texture = player.slot2_weapon.icon
	
	for child in secondary_weapon_stats.get_children():
		child.queue_free()
	secondary_weapon_stats_dict.clear()
	
	var stats = player.slot2_weapon.stats.get_property_list()
	for prop in stats:
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			if prop.name in player.slot2_weapon.stats.STAT_IGNORE_IN_DISPLAY:
				continue
			
			if prop.type in [TYPE_FLOAT, TYPE_INT]:
				var value = player.slot2_weapon.stats.get(prop.name)
				var prop_name = "sw_" + prop.name
				AddStatLabel(prop_name, value, secondary_weapon_stats, secondary_weapon_stats_dict)
				if prop.name in player.slot2_weapon.stats.STAT_DETAILED:
					detailed_stats_dict[prop_name] = secondary_weapon_stats_dict[prop_name]

func AddStatLabel(stat_name: String, value: float, parent_node: Control, stat_dictionary: Dictionary):
	var label = Label.new()
	parent_node.add_child(label)
	
	stat_dictionary[stat_name] = label
	var display_name = stat_name.replace("pw_", "").replace("sw_", "").capitalize().replace("_", " ")
	label.text = "%s: %.1f" % [display_name, value]
