extends SkillReward
class_name AltarRerollReward

# altar rerolls for the whole run, shared between every altar (RunState.altar_rerolls_left)
@export var rerolls: int = 1

func ApplyToLoadout(loadout: Loadout) -> void:
	loadout.altar_rerolls += rerolls

func GetDescription() -> String:
	return "+%d altar reroll%s per run" % [rerolls, "" if rerolls == 1 else "s"]
