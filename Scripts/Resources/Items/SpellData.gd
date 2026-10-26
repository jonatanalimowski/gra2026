extends Resource
class_name SpellData

# what a wand shoots on one mouse button
# numeric exports become stats (see StatBlock), so runes/blessings can modify them
@export var projectile_scene: PackedScene
@export var damage: float = 25.0
@export var cooldown: float = 0.5 # seconds between casts (was fire_rate)
@export var shot_count: int = 1
@export var spread: float = 10.0 # random angle in degrees (was firing_inaccuracy)
# effects every projectile of this spell has by default
@export var effects: Array[Effect] = []

const STAT_IGNORE_IN_DISPLAY = []
const STAT_DETAILED = ["spread"]
