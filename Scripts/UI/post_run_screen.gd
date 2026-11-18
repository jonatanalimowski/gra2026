extends Control

@onready var xp_label = %XpLabel
@onready var enemies_label = %EnemiesLabel
@onready var floor_label = %FloorLabel
@onready var ok_button = %OkButton
@onready var xp_bar = %XpBar
@onready var xp_bar_label = %XpBarLabel
@onready var level_label = %LevelLabel

@export var xp_transfer_interval: float = 0.05
@export var xp_transfer_amount: float = 20
var xp_transfer_timer: float = 0
var run_experience: int

var ui_experience: int
var ui_level_threshold: int
var ui_level: int
var bar_tween: Tween

func _ready() -> void:
	run_experience = RunState.collected_experience
	ui_experience = MetaProgress.experience
	ui_level_threshold = MetaProgress.GetLevelThreshold()
	ui_level = MetaProgress.player_level
	
	ok_button.pressed.connect(GoToMainMenu)
	xp_label.text = "Experience collected: %d" % run_experience
	enemies_label.text = "Enemies slain: %d" % RunState.enemies_killed
	floor_label.text = "Floor reached: %d" % RunState.floor_number
	level_label.text = "Level: %d" % ui_level
	xp_bar.max_value = ui_level_threshold
	xp_bar.value = 0
	
	MetaProgress.AddXP(RunState.collected_experience)

func UpdateXpBarLabel(current: int, maximum: int) -> void:
	xp_bar_label.text = "XP: %d/%d" % [current, maximum]

func TweenXpBar(from_val: float, to_val: float, maximum: float) -> void:
	if bar_tween and bar_tween.is_valid():
		bar_tween.kill()
	
	xp_bar.max_value = maximum
	xp_bar.value = from_val
	
	bar_tween = create_tween().set_parallel(true)
	bar_tween.tween_property(xp_bar, "value", to_val, xp_transfer_interval)
	
	UpdateXpBarLabel(int(to_val), int(maximum))

func _process(delta: float) -> void:
	xp_transfer_timer += delta
	if xp_transfer_timer > xp_transfer_interval: 
		xp_transfer_timer = 0
		
		var amount = int(min(run_experience, max(xp_transfer_amount, run_experience / 20.0)))
		run_experience -= amount
		
		var start_value = xp_bar.value
		var leveled_up = UIAddXP(amount)
		
		if leveled_up:
			TweenXpBar(0, ui_experience, ui_level_threshold)
		else:
			TweenXpBar(start_value, ui_experience, ui_level_threshold)

func UIAddXP(amount: int) -> bool:
	var leveled_up = false
	ui_experience += amount
	while ui_experience >= ui_level_threshold:
		leveled_up = true
		UILevelUp()
	return leveled_up

func UILevelUp() -> void:
	ui_experience = ui_experience - ui_level_threshold
	ui_level += 1
	ui_level_threshold = MetaProgress.GetThresholdForLevel(ui_level)
	level_label.text = "Level: %d" % ui_level

func _on_level_up() -> void:
	UpdateXpBarLabel(0, MetaProgress.GetLevelThreshold())

func GoToMainMenu() -> void:
	GameFlow.GoToMainMenu()
