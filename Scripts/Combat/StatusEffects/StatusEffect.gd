extends Resource
class_name StatusEffect

# definition of a timed buff/debuff, shared by everyone who gets it, never changed at runtime.
# the per-target part (time left, source...) is in ActiveStatusEffect
@export var duration: float = 3.0
@export var interval: float = 0.5 # seconds between ticks, 0 = never ticks (pure stat changes)
@export var damage: float = 0.0 # per tick, before the strength multiplier
@export var element: StringName = &"" # copied to the tick's DamageInfo
@export var modifiers: Array[StatModifier] = [] # held for as long as the status lasts
@export var name: String = "Status Effect"
@export var icon: Texture2D
@export var color: Color = Color.WHITE # tick flash + HUD text
@export var is_debuff: bool = true
