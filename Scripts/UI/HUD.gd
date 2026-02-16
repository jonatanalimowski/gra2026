extends Control
var player: CharacterBody2D
@onready var hp_bar: TextureProgressBar = $PlayerBars/VBoxContainer/Healthbar
@onready var hp_text: Label = $PlayerBars/VBoxContainer/Healthbar/Label

func _ready() -> void:
	ConnectSignals()

func ConnectSignals() -> void:
	Signals.player_ready.connect(func(player_node: CharacterBody2D): player = player_node)
	Signals.player_health_changed.connect(UpdateHealth)

func FixPlayerReference() -> void:
	if player == null:
		if NodeReferences.player != null:
			player = NodeReferences.player

func UpdateHealth(new_current: int, new_max: int):
	hp_bar.max_value = new_max
	hp_bar.value = new_current
	hp_text.text = str(new_current) + "/" + str(new_max)
