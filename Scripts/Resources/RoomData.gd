extends Resource
class_name RoomData

# a room the generator can place. connectors and footprint are read from the scene itself
enum RoomType { COMBAT, TREASURE, REST, SHRINE }

@export var room_scene: PackedScene
# combat rooms fill the main path, the other types are rewards at the end of side branches
@export var room_type: RoomType = RoomType.COMBAT
# relative chance to be picked among the rooms that fit
@export var weight: float = 1.0
# how many rooms away from the start it can first appear
@export var min_depth: int = 0
# 0 = no limit
@export var max_per_floor: int = 0
# layouts without at least this many get retried. needs a reward type (placed at branch ends)
@export var min_per_floor: int = 0
# first floor it can appear on
@export var min_floor: int = 1
# from this floor on, one more can appear (Sanctuary: a 2nd one from floor 3). 0 = never
@export var extra_from_floor: int = 0

func GetMaxPerFloor(floor_number: int) -> int:
	if max_per_floor > 0 and extra_from_floor > 0 and floor_number >= extra_from_floor:
		return max_per_floor + 1
	return max_per_floor
