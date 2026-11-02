extends ItemData
class_name DuoData

# a two-school payoff (BUILD_DESIGN.md §6), offered at the boss UpgradeShrine once you have a slot pact
# of both schools. taken once, no curse
@export var school_a: School.Kind = School.Kind.EMBER
@export var school_b: School.Kind = School.Kind.FROST
@export var blessing: Blessing

func IsEligible() -> bool:
	return self not in RunState.duos and RunState.GetPactSchoolPoints(school_a) > 0 \
		and RunState.GetPactSchoolPoints(school_b) > 0

func Claim() -> void:
	RunState.AddDuo(self)

func GetSubtitle() -> String:
	return "Duo - %s + %s" % [School.GetName(school_a), School.GetName(school_b)]

func GetSubtitleColor() -> Color:
	return Color(1.0, 0.8, 0.3)

func GetTagIcons() -> Array[Texture2D]:
	var icons: Array[Texture2D] = []
	icons.append(School.GetIcon(school_a))
	return icons
