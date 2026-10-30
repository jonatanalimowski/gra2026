extends Resource
class_name EliteData

# what being elite does to an enemy (Entity.ApplyElite). modifiers go to the enemy or its spell,
# whichever has the stat (max_health -> enemy, shot_count -> spell), like pact enemy_modifiers
@export var modifiers: Array[StatModifier] = []
@export var scale: float = 1.2
@export var color: Color = Color(1.0, 0.6, 0.25)
