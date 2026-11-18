extends SkillReward
class_name StatReward

# permanent player stat modifiers, e.g. +50 max_health
@export var modifiers: Array[StatModifier] = []
@export var effects: Array[Effect] = [] # added to every spell the player casts

func ApplyToLoadout(loadout: Loadout) -> void:
	loadout.skill_mods.player_modifiers.append_array(modifiers)
	loadout.skill_mods.effects.append_array(effects)
