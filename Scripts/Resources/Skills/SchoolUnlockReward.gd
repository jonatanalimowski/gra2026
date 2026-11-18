extends SkillReward
class_name SchoolUnlockReward

@export var school: School.Kind = School.Kind.NONE

func ApplyToLoadout(loadout: Loadout) -> void:
	if school not in loadout.schools:
		loadout.schools.append(school)

func GetDescription() -> String:
	return "Unlocks the %s school" % School.NAMES[school]
