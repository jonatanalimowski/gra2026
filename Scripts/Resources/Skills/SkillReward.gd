extends Resource
class_name SkillReward

# SkillManager.CollectRewards asks every unlocked skill to add its part to a fresh run loadout
func ApplyToLoadout(_loadout: Loadout) -> void:
	pass

# short text for the skill details panel. empty = use the skill's description only
func GetDescription() -> String:
	return ""
