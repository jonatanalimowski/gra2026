extends Resource
class_name StatusEffect

# definition of a timed buff/debuff, shared by everyone who gets it, never changed at runtime.
# the per-target part (time left, stacks, source...) is in ActiveStatusEffect
@export var duration: float = 3.0
@export var interval: float = 0.5 # seconds between ticks, 0 = never ticks (pure stat changes)
@export var damage: float = 0.0 # per tick and per stack, before the strength multiplier
@export var element: StringName = &"" # copied to the tick's DamageInfo
# held for as long as the status lasts, scaled by stacks (flat x stacks, multiplier 1 + (m - 1) x stacks)
@export var modifiers: Array[StatModifier] = []
@export var name: String = "Status Effect"
@export var icon: Texture2D # 7x7, shown in the enemy StatusIconBar and the HUD
@export var color: Color = Color.WHITE # tick damage numbers + HUD text
@export var is_debuff: bool = true
# 1 = getting it again only refreshes it. more = every application adds stacks (up to this)
@export var max_stacks: int = 1
# enemy outline: the active status with the highest priority picks the color. alpha 0 = no outline
@export var priority: int = 0
@export var outline_color: Color = Color(0, 0, 0, 0)
# Warded affix (phase F): an enemy warded against this group refuses every status in it
@export var ward_group: StringName = &""
# Bleed: tick damage +1% per 1% of the player's missing HP
@export var scales_with_missing_hp: bool = false
