extends Resource
class_name EnemyPool

# a themed set of enemies a room can spawn from (Data/EnemyPools/*.tres)
@export var display_name: String
@export var entries: Array[EnemyPoolEntry]

func PickEnemy(rng: RandomNumberGenerator) -> PackedScene:
	var total := 0.0
	for entry in entries:
		if entry.scene:
			total += entry.weight
	if total <= 0.0:
		return null

	var roll := rng.randf() * total
	for entry in entries:
		if not entry.scene:
			continue
		roll -= entry.weight
		if roll <= 0.0:
			return entry.scene
	return entries.back().scene
