extends SkillReward
class_name KeystoneSlotReward

# more keystones per run (SkillManager.GetKeystoneSlotCount)
@export var extra_slots: int = 1

func GetDescription() -> String:
	return "+%d keystone slot%s" % [extra_slots, "" if extra_slots == 1 else "s"]
