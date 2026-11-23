extends Node

const wands: Dictionary[String, WandData] = {
	"PurpleBolt": preload("res://Data/Wands/PurpleBoltWand.tres"),
	"Gamba": preload("res://Data/Wands/FlameShurikenWand.tres"),
	"Blue": preload("res://Data/Wands/BlueBlinkerWand.tres")
}

# every pickable school (Form isn't one: its pacts are always on offer)
const SCHOOL_PATHS = [
	"res://Data/Schools/EmberSchool.tres",
	"res://Data/Schools/FrostSchool.tres",
	"res://Data/Schools/StormSchool.tres",
	"res://Data/Schools/BloodSchool.tres",
]
var schools: Array[SchoolData] = []

# loaded here, not preloaded: a preload in an autoload loads the resource before its script
# is ready, so it comes in as a plain Resource (same as SkillManager.DB)
func _ready() -> void:
	for path in SCHOOL_PATHS:
		schools.append(load(path))

func GetWands() -> Array[WandData]:
	return wands.values()

func GetSchools() -> Array[SchoolData]:
	return schools

func GetSchoolData(kind: School.Kind) -> SchoolData:
	for school in schools:
		if school.kind == kind:
			return school
	return null
