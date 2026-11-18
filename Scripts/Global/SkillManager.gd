extends Node

# every skill tree rule lives here: the UI only asks CanUnlock / CanRefund / IsUnlocked
# and shows the answer. MetaProgress just stores the ids
const DATABASE_PATH = "res://Data/Skills/SkillDatabase.tres"
var DB: SkillDatabase
# schools every save has without a skill. the rest come from SchoolUnlockReward
const STARTING_SCHOOLS: Array[School.Kind] = []

# loaded here, not preloaded as a const: a preload makes this autoload depend on SkillData at parse time
func _ready() -> void:
	DB = load(DATABASE_PATH)

func IsUnlocked(skill: SkillData) -> bool:
	return skill != null and MetaProgress.unlocked_ids.has(skill.id)

func PrerequisitesMet(skill: SkillData) -> bool:
	return skill.prerequisites.all(IsUnlocked)

func CanUnlock(skill: SkillData) -> bool:
	if skill == null or IsUnlocked(skill):
		return false
	return PrerequisitesMet(skill) and MetaProgress.skill_points >= skill.cost

# a skill can't be refunded while an unlocked skill depends on it
func CanRefund(skill: SkillData) -> bool:
	if not IsUnlocked(skill):
		return false
	for other in DB.skills:
		if IsUnlocked(other) and other.prerequisites.has(skill):
			return false
	return true

func UnlockSkill(skill: SkillData) -> bool:
	if not CanUnlock(skill):
		return false
	MetaProgress.unlocked_ids[skill.id] = true
	MetaProgress.skill_points -= skill.cost
	MetaProgress.Save()
	Signals.meta_progress_changed.emit()
	return true

func RefundSkill(skill: SkillData) -> bool:
	if not CanRefund(skill):
		return false
	MetaProgress.unlocked_ids.erase(skill.id)
	MetaProgress.skill_points += skill.cost
	MetaProgress.Save()
	Signals.meta_progress_changed.emit()
	return true

func GetUnlockedSkills() -> Array[SkillData]:
	var unlocked: Array[SkillData] = []
	for skill in DB.skills:
		if IsUnlocked(skill):
			unlocked.append(skill)
	return unlocked

# fills the loadout's skill part from scratch, so calling it again (Ctrl+R restart) is safe
func CollectRewards(loadout: Loadout) -> void:
	loadout.skill_mods = EquipmentData.new()
	loadout.extra_runes.clear()
	loadout.schools.assign(STARTING_SCHOOLS)
	for skill in GetUnlockedSkills():
		for reward in skill.rewards:
			if reward:
				reward.ApplyToLoadout(loadout)
