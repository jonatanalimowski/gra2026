extends ItemData
class_name RuneData

# attached to a wand, applies to all of the wand's spells
@export var spell_modifiers: Array[StatModifier] = [] # e.g. damage x1.2 (old "lesser perks")
@export var effects: Array[Effect] = [] # e.g. bounce, burn (old "greater perks")
