extends Control
class_name SkillNode

@onready var icon: TextureRect = %Icon
@onready var name_label: Label = %NameLabel
@onready var button: Button = %Button
@onready var border: Panel = %Border

var description: String
@export var skill_data: SkillData 
@export var prerequisites: Array[SkillNode]
@export var unlocked_color: Color = Color(0.893, 0.698, 0.359, 1.0)
@export var unlockable_color: Color = Color(0.746, 0.746, 0.746, 1.0)
@export var locked_color: Color = Color(0.173, 0.173, 0.173, 1.0)
signal node_picked(skill_data: SkillData)


func _ready() -> void:
	if skill_data:
		name_label.text = skill_data.display_name
		icon.texture = skill_data.icon
		button.pressed.connect(_on_button_pressed)
		description = skill_data.description
		add_to_group("skill_node")
		
		SetBorder()

func SetBorder() -> void:
	var style_box = border.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if style_box:
		if skill_data.is_unlocked:
			style_box.bg_color = unlocked_color
		else:
			if CheckPrerequisites():
				style_box.bg_color = unlockable_color
			else:
				style_box.bg_color = locked_color
		border.add_theme_stylebox_override("panel", style_box)

func CheckPrerequisites() -> bool:
	if skill_data.prerequisites.is_empty():
		return true
	for data in skill_data.prerequisites:
		if not data.is_unlocked:
			return false
	return true

func _on_button_pressed() -> void:
	node_picked.emit(self)

func OnUnlock() -> void:
	if not CheckPrerequisites():
		return
	if skill_data.is_unlocked or MetaProgress.skill_points < skill_data.cost:
		return
	
	SkillManager.UnlockSkill(skill_data)
	Signals.skill_tree_changed.emit()

func GetMiddle() -> Vector2:
	return global_position + custom_minimum_size*scale/2

# returns a list of positions of related nodes
# the first index is the current node's position, the next ones are required nodes in order to unlock the current one
func GetLinePositions() -> Array[Vector2]:
	var points: Array[Vector2] = []
	points.append(self.GetMiddle())
	if prerequisites.is_empty():
		return points
	else:
		for node in prerequisites:
			points.append(node.GetMiddle())
		return points
