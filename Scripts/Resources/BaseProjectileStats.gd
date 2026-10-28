extends Resource
class_name ProjectileStats

# team is not here: it's set per projectile by whoever fires it (see BaseProjectile.team)
@export var damage: float = 25.0
@export var speed: float = 1.0
@export var lifetime: float = 5.0
@export var knockback_force: float = 120.0
@export var motion: ProjectileMotion # empty = straight line

# damage is replaced by the spell's damage when a wand fires it
const STAT_IGNORE_IN_DISPLAY = ["damage"]
