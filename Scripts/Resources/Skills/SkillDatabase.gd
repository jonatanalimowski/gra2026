extends Resource
class_name SkillDatabase

# every skill in the game. the save file stores ids, this turns them back into SkillData
@export var skills: Array[SkillData] = []

func Get(id: StringName) -> SkillData:
	for skill in skills:
		if skill and skill.id == id:
			return skill
	return null
