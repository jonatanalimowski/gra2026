extends Control
class_name SkillTree

@onready var skill_node_container = %SkillNodeContainer
@onready var back_button: Button = %BackButton
@onready var level_label = %LevelLabel
@onready var experience_label = %ExperienceLabel
@onready var skill_points_label = %SkillPointsLabel
@onready var details = %Details

@onready var skill_details_icon = %Icon
@onready var skill_details_name = %SkillName
@onready var skill_details_cost = %Cost
@onready var skill_details_description = %Description
@onready var skill_details_unlock_button = %UnlockSkillButton

var skill_nodes: Array[SkillNode]
var is_details_visible: bool = false
var picked_skill_node: SkillNode

func _ready() -> void:
	skill_nodes.assign(get_tree().get_nodes_in_group("skill_node"))
	back_button.pressed.connect(_on_back_button_pressed)
	MetaProgress.player_leveled_up.connect(_on_player_leveled_up)
	Signals.refresh_player_card.connect(SetPlayerCardLabels)
	Signals.meta_progress_changed.connect(SetPlayerCardLabels)
	skill_details_unlock_button.pressed.connect(UnlockNode)
	details.visible = false
	_on_player_leveled_up()
	queue_redraw()
	ConnectSignals()

func _on_back_button_pressed() -> void:
	GameFlow.GoToMainMenu()

func _on_skill_tree_changed() -> void:
	queue_redraw()
	
	if picked_skill_node:
		var data = picked_skill_node.skill_data
		details.visible = true
		skill_details_icon.texture = data.icon
		skill_details_name.text = data.display_name
		skill_details_cost.text = "Cost: %d skill points" % data.cost
		skill_details_description.text = data.description
		SetUnlockButton(picked_skill_node)
	
	for node in skill_nodes:
		node.SetBorder()

func ConnectSignals() -> void:
	for node in skill_nodes:
		node.node_picked.connect(_on_node_picked)
	Signals.skill_tree_changed.connect(_on_skill_tree_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("LeftMouse"):
		#details.visible = false
		pass

func _on_node_picked(node: SkillNode) -> void:
	var data = node.skill_data
	details.visible = true
	picked_skill_node = node
	skill_details_icon.texture = data.icon
	skill_details_name.text = data.display_name
	skill_details_cost.text = "Cost: %d skill points" % data.cost
	skill_details_description.text = data.description
	SetUnlockButton(node)

func SetUnlockButton(skill_node: SkillNode):
	if skill_node.skill_data.is_unlocked:
		skill_details_unlock_button.disabled = true
		skill_details_unlock_button.text = "Unlocked"
	else:
		if skill_node.CheckPrerequisites():
			skill_details_unlock_button.disabled = false
			skill_details_unlock_button.text = "Unlock"
		else:
			skill_details_unlock_button.disabled = true
			skill_details_unlock_button.text = "Locked"

func UnlockNode():
	if picked_skill_node:
		picked_skill_node.OnUnlock()
		SetUnlockButton(picked_skill_node)
		queue_redraw()

func SetPlayerCardLabels(player_level: int = MetaProgress.player_level, experience: int = MetaProgress.experience, skill_points: int = MetaProgress.skill_points) -> void:
	level_label.text = "Level: %d" % player_level
	experience_label.text = "Experience: %d" % experience
	skill_points_label.text = "Skill points: %d" % skill_points

func _on_player_leveled_up():
	SetPlayerCardLabels(MetaProgress.player_level, MetaProgress.experience, MetaProgress.skill_points)

func _draw() -> void:
	for node in skill_nodes:
		var lines: Array[Vector2] = node.GetLinePositions()
		if lines.size() == 1:
			continue

		var start_pos = lines[0]
		for i in range(1, lines.size()):
			var end_pos = lines[i]
			if node.skill_data.is_unlocked:
				draw_line(start_pos, end_pos, Color.WHITE, 10.0)
			else:
				draw_line(start_pos, end_pos, Color(0.352, 0.352, 0.352, 1.0), 10.0)
