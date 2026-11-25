extends ItemData
class_name KeystoneData

# build-defining pick in the loadout, unlocked by a KeystoneUnlockReward in the skill tree.
# its effect is a run half with no curse (the downside is part of the blessing): RunState.Begin adds it
@export var blessing: PactHalf

func GetSubtitle() -> String:
	return "Keystone"

func GetSubtitleColor() -> Color:
	return Color(1.0, 0.8, 0.35)
