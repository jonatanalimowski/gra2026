extends Resource
class_name Affix

# an elite modifier (BUILD_DESIGN.md §8.3): rolled by EnemyRoom for elites from floor 3 (2 from floor 6).
# shown gold-framed on the left of the StatusIconBar. listed in RunState.AFFIXES
enum Kind { PLAIN, VOLATILE, WARDED, REGENERATING }
@export var display_name: String = ""
@export var icon: Texture2D
@export var kind: Kind = Kind.PLAIN
# routed like elite modifiers: to the enemy or its spell, whichever has the stat (Hasted: +40% speed)
@export var modifiers: Array[StatModifier] = []
