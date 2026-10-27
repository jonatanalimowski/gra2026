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
