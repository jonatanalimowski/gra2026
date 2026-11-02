extends Resource
class_name PactHalf

# one side of a pact (Blessing or Curse). each half is its own .tres so it can be removed
# alone (cleansed curse) or used without a pact (oaths = curses with no blessing).
# the half itself is the source of its modifiers, so removing it removes exactly what it added
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var player_modifiers: Array[StatModifier] = []
@export var spell_modifiers: Array[StatModifier] = [] #damage, cooldown... of every wand spell
@export var effects: Array[Effect] = [] #projectile hooks, on every spell
# Primary slot pacts: only the primary (LMB) spell gets these
@export var primary_effects: Array[Effect] = []
@export var primary_modifiers: Array[StatModifier] = []
# Heavy slot pacts own the heavy: replaces the wand's heavy spell while active (the last one taken wins)
@export var heavy_override: SpellData
@export var heavy_effects: Array[Effect] = []
# changes to statuses the player applies (max stacks, duration), see StatusTweak
@export var status_tweaks: Array[StatusTweak] = []
# which school this half counts toward (blessings), NONE for curses
@export var school: School.Kind = School.Kind.NONE
@export var run_effects: Array[RunEffect] = [] #event hooks (on kill etc.)
@export var enemy_modifiers: Array[StatModifier] = []
# simple rules other scripts check with RunState.HasFlag (e.g. &"explosions_hit_player")
@export var flags: Array[StringName] = []
# multiplies every room's elite chance (1.3 = 30% more likely). counts once per half, stacks don't add up
@export var elite_chance_multiplier: float = 1.0
