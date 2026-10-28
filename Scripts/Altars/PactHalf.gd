extends Resource
class_name PactHalf

# one side of a pact (Blessing or Curse). each half is its own .tres so it can be removed
# alone (cleansed curse) or used without a pact (oaths = curses with no blessing).
# the half itself is the source of its modifiers, so removing it removes exactly what it added
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var player_modifiers: Array[StatModifier] = []
@export var spell_modifiers: Array[StatModifier] = [] #damage, cooldown... of every wand spell
@export var effects: Array[Effect] = [] #projectile hooks
@export var run_effects: Array[RunEffect] = [] #event hooks (on kill etc.)
@export var enemy_modifiers: Array[StatModifier] = []
# simple rules other scripts check with RunState.HasFlag (e.g. &"kill_explosions_hit_player")
@export var flags: Array[StringName] = []
