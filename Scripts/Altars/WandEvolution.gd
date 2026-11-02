extends ItemData
class_name WandEvolution

# a wand's evolved form (BUILD_DESIGN.md §6): offered at the UpgradeShrine when you hold `wand` and
# have Tier I of `school`. its blessing only touches the primary (primary_modifiers / primary_effects),
# the heavy belongs to heavy pacts. kept as a run half, so it survives floors like any pact
@export var wand: WandData
@export var school: School.Kind = School.Kind.NONE
@export var blessing: Blessing

func IsEligible() -> bool:
	if RunState.evolution != null:
		return false
	var player = NodeReferences.player
	if player == null or player.wand == null or player.wand.data != wand:
		return false
	for attunement in RunState.active_attunements:
		if attunement.school == school and attunement.tier == 1:
			return true
	return false

func Claim() -> void:
	RunState.SetEvolution(self)

func GetSubtitle() -> String:
	return "Evolution - %s" % wand.display_name if wand else "Evolution"

func GetSubtitleColor() -> Color:
	return School.GetColor(school)

func GetTagIcons() -> Array[Texture2D]:
	var icons: Array[Texture2D] = []
	if wand and wand.icon:
		icons.append(wand.icon)
	return icons
