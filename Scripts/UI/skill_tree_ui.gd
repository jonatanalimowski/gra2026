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

# lines match the SkillNode state colors: gold = owned link, flowing cyan = next unlock, dim = locked
@export_group("Lines")
@export var line_unlocked_color: Color = Color(1.0, 0.78, 0.32)
@export var line_available_color: Color = Color(0.4, 0.85, 1.0)
@export var line_locked_color: Color = Color(0.28, 0.27, 0.32)
@export var line_outline_color: Color = Color(0.0, 0.0, 0.0, 0.6)
@export var line_width: float = 6.0
@export var line_gap: float = 6.0 # space between a line's end and the node border
@export var dash_length: float = 14.0
@export var dash_speed: float = 40.0 # px/s the dashes flow from prerequisite to skill
@export_group("")

var skill_nodes: Array[SkillNode] = []
var node_by_skill: Dictionary = {} # SkillData -> SkillNode, lines are drawn from SkillData.prerequisites
var picked_skill_node: SkillNode
var dash_offset: float = 0.0

func _ready() -> void:
	for child in skill_node_container.find_children("*", "SkillNode", true, false):
		var node := child as SkillNode
		if node.skill_data:
			skill_nodes.append(node)
			node_by_skill[node.skill_data] = node
			node.node_picked.connect(_on_node_picked)
	back_button.pressed.connect(_on_back_button_pressed)
	skill_details_unlock_button.pressed.connect(_on_unlock_pressed)
	Signals.meta_progress_changed.connect(Refresh)
	details.visible = false
	Refresh()

func _on_back_button_pressed() -> void:
	GameFlow.GoToMainMenu()

func Refresh() -> void:
	SetPlayerCardLabels()
	for node in skill_nodes:
		node.Refresh()
	if picked_skill_node:
		ShowDetails(picked_skill_node)
	queue_redraw()

func _on_node_picked(node: SkillNode) -> void:
	if picked_skill_node:
		picked_skill_node.SetSelected(false)
	picked_skill_node = node
	node.SetSelected(true)
	ShowDetails(node)

func ShowDetails(node: SkillNode) -> void:
	var data = node.skill_data
	details.visible = true
	skill_details_icon.texture = data.icon
	skill_details_name.text = data.display_name
	skill_details_cost.text = "Cost: %d skill points" % data.cost
	skill_details_description.text = data.description
	SetUnlockButton(data)

func SetUnlockButton(skill: SkillData) -> void:
	skill_details_unlock_button.disabled = not SkillManager.CanUnlock(skill)
	if SkillManager.IsUnlocked(skill):
		skill_details_unlock_button.text = "Unlocked"
	elif not SkillManager.PrerequisitesMet(skill):
		skill_details_unlock_button.text = "Locked"
	elif MetaProgress.skill_points < skill.cost:
		skill_details_unlock_button.text = "Not enough points"
	else:
		skill_details_unlock_button.text = "Unlock"

func _on_unlock_pressed() -> void:
	if picked_skill_node:
		SkillManager.UnlockSkill(picked_skill_node.skill_data) # emits meta_progress_changed -> Refresh

func SetPlayerCardLabels() -> void:
	level_label.text = "Level: %d" % MetaProgress.player_level
	experience_label.text = "Experience: %d" % MetaProgress.experience
	skill_points_label.text = "Skill points: %d" % MetaProgress.skill_points

func _process(delta: float) -> void:
	# only the flowing dashes need redrawing every frame
	dash_offset = fmod(dash_offset + dash_speed * delta, dash_length * 2)
	queue_redraw()

func _draw() -> void:
	# _draw is in this control's local space, node positions are global
	var to_local := get_global_transform().affine_inverse()
	for node in skill_nodes:
		var skill = node.skill_data
		for prereq in skill.prerequisites:
			var other: SkillNode = node_by_skill.get(prereq)
			if other == null:
				continue
			# from prerequisite to skill, stopping at both borders
			var from: Vector2 = to_local * other.GetMiddle()
			var to: Vector2 = to_local * node.GetMiddle()
			var dir := from.direction_to(to)
			var scale_to_local := to_local.get_scale().x
			from += dir * (other.GetRadius() * scale_to_local + line_gap)
			to -= dir * (node.GetRadius() * scale_to_local + line_gap)
			if from.distance_to(to) <= 0.0 or dir.dot(from.direction_to(to)) < 0.0:
				continue # nodes overlap
			if SkillManager.IsUnlocked(skill):
				DrawSolidLine(from, to, line_unlocked_color, line_width, true)
			elif SkillManager.IsUnlocked(prereq):
				DrawSolidLine(from, to, Color(line_available_color, 0.25), line_width * 0.6, false)
				DrawFlowingDashes(from, to, line_available_color, line_width)
			else:
				DrawSolidLine(from, to, line_locked_color, line_width * 0.6, false)

func DrawSolidLine(from: Vector2, to: Vector2, color: Color, width: float, glow: bool) -> void:
	if glow:
		draw_line(from, to, Color(color, 0.25), width * 2.5, true)
	draw_line(from, to, line_outline_color, width + 4.0, true)
	draw_line(from, to, color, width, true)

func DrawFlowingDashes(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var length := from.distance_to(to)
	var dir := from.direction_to(to)
	# dash pattern scrolls by dash_offset, clipped to the line
	var t := dash_offset - dash_length * 2
	while t < length:
		var a := maxf(t, 0.0)
		var b := minf(t + dash_length, length)
		if b > a:
			draw_line(from + dir * a, from + dir * b, line_outline_color, width + 4.0, true)
			draw_line(from + dir * a, from + dir * b, color, width, true)
		t += dash_length * 2
