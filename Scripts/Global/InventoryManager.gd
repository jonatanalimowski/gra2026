extends Node

const wands: Dictionary[String, WandData] = {
	"PurpleBolt": preload("res://Data/Wands/PurpleBoltWand.tres"),
	"Gamba": preload("res://Data/Wands/FlameShurikenWand.tres"),
	"Blue": preload("res://Data/Wands/BlueBlinkerWand.tres")
}

func _ready() -> void:
	SkillManager.skill_unlocked.connect(_on_skill_unlocked)

func GetWands() -> Array[WandData]:
	return wands.values()

func ApplyRune(wand_name: String, rune: RuneData) -> void:
	var wand: WandData = wands.get(wand_name, null)
	if wand == null:
		return
	
	wand.runes.append(rune)
	return

func _on_skill_unlocked(skill: SkillData):
	if skill.reward_type == SkillData.RewardType.RUNE:
		if skill.rune_reward != null:
			ApplyRune("PurpleBolt", skill.rune_reward)
