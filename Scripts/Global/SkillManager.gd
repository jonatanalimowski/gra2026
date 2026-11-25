extends Node

# every skill tree rule lives here: the UI only asks CanUnlock / CanRefund / IsUnlocked
# and shows the answer. MetaProgress just stores the ids
const DATABASE_PATH = "res://Data/Skills/SkillDatabase.tres"
var DB: SkillDatabase
# schools every save has without a skill. the rest come from SchoolUnlockReward
const STARTING_SCHOOLS: Array[School.Kind] = []
# keystones per run without a KeystoneSlotReward
const BASE_KEYSTONE_SLOTS = 1

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

func GetUnlockedSchools() -> Array[School.Kind]:
	var schools: Array[School.Kind] = STARTING_SCHOOLS.duplicate()
	for skill in GetUnlockedSkills():
		for reward in skill.rewards:
			if reward is SchoolUnlockReward and reward.school not in schools:
				schools.append(reward.school)
	return schools

# every keystone some skill can unlock, in tree order (locked ones are drawn as silhouettes)
func GetAllKeystones() -> Array[KeystoneData]:
	return CollectKeystones(DB.skills)

func GetUnlockedKeystones() -> Array[KeystoneData]:
	return CollectKeystones(GetUnlockedSkills())

func CollectKeystones(skills: Array[SkillData]) -> Array[KeystoneData]:
	var keystones: Array[KeystoneData] = []
	for skill in skills:
		for reward in skill.rewards:
			if reward is KeystoneUnlockReward and reward.keystone and reward.keystone not in keystones:
				keystones.append(reward.keystone)
	return keystones

# keystones per run: the base slot + every unlocked KeystoneSlotReward
func GetKeystoneSlotCount() -> int:
	var count := BASE_KEYSTONE_SLOTS
	for skill in GetUnlockedSkills():
		for reward in skill.rewards:
			if reward is KeystoneSlotReward:
				count += reward.extra_slots
	return count

# fills the loadout's skill part from scratch, so calling it again (Ctrl+R restart) is safe
func CollectRewards(loadout: Loadout) -> void:
	loadout.skill_mods = EquipmentData.new()
	loadout.extra_runes.clear()
	loadout.altar_rerolls = 0
	var unlocked_schools := GetUnlockedSchools()
	loadout.schools.assign(loadout.schools.filter(func(s): return s in unlocked_schools))
	# refunded keystones (or lost slots) drop out of the pick
	var unlocked_keystones := GetUnlockedKeystones()
	loadout.keystones.assign(loadout.keystones.filter(func(k): return k in unlocked_keystones))
	loadout.keystones.resize(mini(loadout.keystones.size(), GetKeystoneSlotCount()))
	for skill in GetUnlockedSkills():
		for reward in skill.rewards:
			if reward:
				reward.ApplyToLoadout(loadout)
