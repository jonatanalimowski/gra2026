extends Control
const SETTINGS_OVERLAY = preload("res://Scenes/UI/SettingsOverlay.tscn")
@onready var start_button = %Start
@onready var skill_tree_button = %SkillTreeButton
@onready var quit_button = %Quit
@onready var settings_button = %SettingsButton
@onready var level_label = %LevelLabel
@onready var skill_points_label = %SkillPointsLabel
@onready var experience_label = %ExperienceLabel

func _ready() -> void:
	_on_player_leveled_up()
	ConnectSignals()

func ConnectSignals():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	skill_tree_button.pressed.connect(_on_skill_tree_button_pressed)
	MetaProgress.player_leveled_up.connect(_on_player_leveled_up)
	Signals.meta_progress_changed.connect(_on_player_leveled_up)

func SetPlayerCardLabels(player_level: int = MetaProgress.player_level, experience: int = MetaProgress.experience, skill_points: int = MetaProgress.skill_points) -> void:
	level_label.text = "Level: %d" % player_level
	experience_label.text = "Experience: %d" % experience
	skill_points_label.text = "Skill points: %d" % skill_points

func _on_player_leveled_up():
	SetPlayerCardLabels(MetaProgress.player_level, MetaProgress.experience, MetaProgress.skill_points)

func _on_skill_tree_button_pressed():
	GameFlow.GoToSkillTree()

func _on_start_pressed():
	GameFlow.GoToLoadout()

func _on_settings_pressed():
	add_child(SETTINGS_OVERLAY.instantiate())

func _on_quit_pressed():
	get_tree().quit()
