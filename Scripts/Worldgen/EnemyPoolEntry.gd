extends Resource
class_name EnemyPoolEntry

@export var scene: PackedScene
# relative chance vs other entries in the same pool
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
# deeper enemies: not picked before this floor
@export var min_floor: int = 1

func IsAvailable() -> bool:
	return scene != null and RunState.floor_number >= min_floor
