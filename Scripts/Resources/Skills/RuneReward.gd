extends SkillReward
class_name RuneReward

# a rune the wand gets for free. empty wand_id = every wand
@export var rune: RuneData
@export var wand_id: StringName = &""

func ApplyToLoadout(loadout: Loadout) -> void:
	if rune == null or loadout.wand == null:
		return
	if wand_id == &"" or loadout.wand.id == wand_id:
		loadout.extra_runes.append(rune)
