extends Resource
class_name FloorModifier

# what changes from floor to floor. every rule is a function of f, the floor number (first floor = 1).
# shared resource, read only: tune it in Data/Floors/, or override a function in a subclass for another curve
@export_group("Enemy scaling")
# linear past the first floor: floor 3 = +40% hp, +20% damage
@export var health_per_floor: float = 0.2
@export var damage_per_floor: float = 0.1
@export_group("Elites")
# added to the room's elite_chance per floor past the first
@export var elite_chance_per_floor: float = 0.0
@export_group("Look")
# floors cycle through these, two colors = every other floor. multiplied onto the tiles, so keep them close to white
@export var tints: Array[Color] = [Color.WHITE]

func GetHealthScale(f: int) -> float:
	return 1.0 + health_per_floor * (f - 1)

func GetDamageScale(f: int) -> float:
	return 1.0 + damage_per_floor * (f - 1)

func GetEliteChance(f: int, base_chance: float) -> float:
	return clampf(base_chance + elite_chance_per_floor * (f - 1), 0.0, 1.0)

func GetTint(f: int) -> Color:
	if tints.is_empty():
		return Color.WHITE
	return tints[(f - 1) % tints.size()]

# max_health, contact damage and spell damage. new each call, modifiers aren't shared between floors
func GetEnemyModifiers(f: int) -> Array[StatModifier]:
	var result: Array[StatModifier] = []
	for entry in [[&"max_health", GetHealthScale(f)], [&"attack_damage", GetDamageScale(f)], [&"damage", GetDamageScale(f)]]:
		var modifier := StatModifier.new()
		modifier.stat = entry[0]
		modifier.multiplier = entry[1]
		result.append(modifier)
	return result
