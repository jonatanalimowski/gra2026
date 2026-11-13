extends Control
class_name SkillNode

@onready var icon: TextureRect = %Icon
@onready var name_label: Label = %NameLabel
@onready var button: Button = %Button

var description: String
@export var skill_data: SkillData 

func _ready() -> void:
	if skill_data:
		#TEMP!
		skill_data.is_unlocked = false
		name_label.text = skill_data.display_name
		icon.texture = skill_data.icon
		button.pressed.connect(_on_button_pressed)
		description = skill_data.description

func _on_button_pressed() -> void:
	if skill_data.is_unlocked:
		return
	SkillManager.UnlockSkill(skill_data)
