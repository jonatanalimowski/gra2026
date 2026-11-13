extends Node

signal skill_unlocked(skill: SkillData)

func UnlockSkill(skill: SkillData):
	skill.is_unlocked = true
	skill_unlocked.emit(skill)
