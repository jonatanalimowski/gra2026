extends Control
class_name SkillTree

@onready var skill_node_container = %SkillNodeContainer
@onready var back_button: Button = %BackButton
var skill_nodes: Array[Node]

func _ready() -> void:
	skill_nodes = skill_node_container.get_children()
	back_button.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed() -> void:
	GameFlow.GoToMainMenu()
