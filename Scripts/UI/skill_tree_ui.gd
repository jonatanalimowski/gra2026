extends Control
class_name SkillTree

@onready var skill_node_container = %SkillNodeContainer
@onready var back_button: Button = %BackButton
@onready var level_label = %LevelLabel
@onready var experience_label = %ExperienceLabel
@onready var skill_points_label = %SkillPointsLabel
var skill_nodes: Array[Node]

func _ready() -> void:
	skill_nodes = skill_node_container.get_children()
	back_button.pressed.connect(_on_back_button_pressed)
	MetaProgress.player_leveled_up.connect(_on_player_leveled_up)
	_on_player_leveled_up()

func _on_back_button_pressed() -> void:
	GameFlow.GoToMainMenu()

func SetPlayerCardLabels(player_level: int, experience: int, skill_points: int) -> void:
	level_label.text = "Level: %d" % player_level
	experience_label.text = "Experience: %d" % experience
	skill_points_label.text = "Skill points: %d" % skill_points

func _on_player_leveled_up():
	SetPlayerCardLabels(MetaProgress.player_level, MetaProgress.experience, MetaProgress.skill_points)
