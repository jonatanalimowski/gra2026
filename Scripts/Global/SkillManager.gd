extends Node

@warning_ignore("unused_signal")
signal skill_data_changed(skill_data)

func UnlockSkill(skill: SkillData):
	MetaProgress.UnlockSkill(skill)
	MetaProgress.skill_points -= skill.cost
	ApplySkillReward(skill)
	Signals.meta_progress_changed.emit()

func RefundSkill(skill: SkillData):
	skill.is_unlocked = false
	MetaProgress.RefundSkill(skill)
	MetaProgress.skill_points += skill.cost
	RollbackSkillReward(skill)
	Signals.meta_progress_changed.emit()

func ApplySkillReward(skill: SkillData):
	if skill.reward_type == SkillData.RewardType.RUNE:
		if skill.rune_reward != null:
			InventoryManager.ApplyRune("PurpleBolt", skill.rune_reward)
			
	if skill.reward_type == SkillData.RewardType.STAT_BOOST:
		if not skill.stat_rewards.is_empty():
			var eq = EquipmentData.new()
			eq.player_modifiers = skill.stat_rewards.duplicate()
			MetaProgress.skills_additional_equipment[skill.id] = eq

func RollbackSkillReward(skill: SkillData):
	if skill.reward_type == SkillData.RewardType.RUNE:
		if skill.rune_reward != null:
			InventoryManager.RemoveRune("PurpleBolt", skill.rune_reward)
			
	if skill.reward_type == SkillData.RewardType.STAT_BOOST:
		if not skill.stat_rewards.is_empty():
			if MetaProgress.skills_additional_equipment.has(skill.id):
				MetaProgress.skills_additional_equipment.erase(skill.id)
