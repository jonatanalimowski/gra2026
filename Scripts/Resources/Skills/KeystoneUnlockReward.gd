extends SkillReward
class_name KeystoneUnlockReward

# no loadout effect: the keystone becomes pickable on the loadout screen (SkillManager.GetUnlockedKeystones)
@export var keystone: KeystoneData

func GetDescription() -> String:
	return "Unlocks the %s keystone" % keystone.display_name if keystone else ""
