extends Resource
class_name PlayerStats

# base values only - at runtime the player uses a StatBlock built from this (see StatBlock.gd)
@export var max_health: float = 100.0
@export var max_mana: float = 100.0
@export var movement_speed: float = 1000.0
@export var acceleration: float = 1000.0
@export var friction: float = 1300
@export var mana_gain: float = 1.0 # multiplier on mana picked up from orbs
@export var orb_heal_chance: float = 0.0 # per mana orb, 0.2 = 20% of orbs also heal
@export var healing_received: float = 1.0 # multiplier on every heal (Thin Blood)

const STAT_IGNORE_IN_DISPLAY = ["friction", "acceleration", "max_health", "max_mana", "mana_gain", "orb_heal_chance", "healing_received"]
const STAT_DETAILED = []
