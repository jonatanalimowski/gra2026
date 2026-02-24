extends Resource
class_name WeaponPerk

# lesser perks - stat modifiers
# greater perks - logic changes
enum PerkType { LESSER, GREATER }
@export var type: PerkType = PerkType.LESSER

# LESSER PERK PARAMETERS
@export var stat_to_change: String = "damage"
@export var multiplier: float = 1.0
@export var flat_addition: float = 0.0

# ID list:
# "bounce_walls"
# "ricochet"
# "projectile+1"
# "pierce"

# GREATER PERK PARAMETERS
@export var effect_id: String = ""
@export var effect_count: int = 0
