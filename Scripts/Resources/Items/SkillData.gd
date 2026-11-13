extends ItemData
class_name SkillData

@export var cost: int = 1
@export var prerequisites: Array[SkillData] = []

enum RewardType { RUNE, UNLOCK_WEAPON, STAT_BOOST, PASSIVE }
@export var reward_type: RewardType

@export_category("Reward Data")
@export var rune_reward: RuneData = null
