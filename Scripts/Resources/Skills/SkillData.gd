extends ItemData
class_name SkillData

# skill tree node definition. read-only at runtime: whether it's unlocked lives in MetaProgress
# (ask SkillManager.IsUnlocked). id must be unique and never change - saves store it
@export var cost: int = 1
@export var prerequisites: Array[SkillData] = []
@export var rewards: Array[SkillReward] = []
