extends RefCounted
class_name LayoutPiece

# one room or corridor in a floor layout. plain data: the generator instantiates it at the end,
# the minimap draws it
enum Kind { START, ROOM, CORRIDOR, BOSS }

var index: int
var kind: Kind
var shape: RoomShape
var data: RoomData # only set for Kind.ROOM
var position: Vector2
var rects: Array[Rect2] = [] # footprint in world space
var depth: int = 0 # rooms between this one and the start
var on_main_path: bool = false
var open_connectors: Array[String] = []
# indexes into the layout instead of references, so pieces don't keep each other alive
var neighbours: Array[int] = []

func _init(new_index: int, new_kind: Kind, new_shape: RoomShape, new_data: RoomData, new_position: Vector2) -> void:
	index = new_index
	kind = new_kind
	shape = new_shape
	data = new_data
	position = new_position
	open_connectors.assign(shape.connectors.keys())
	for rect in shape.rects:
		rects.append(Rect2(rect.position + position, rect.size))

func GetConnectorPosition(connector: String) -> Vector2:
	return position + shape.connectors[connector]

func IsRoom() -> bool:
	return kind != Kind.CORRIDOR

func GetRoomType() -> RoomData.RoomType:
	return data.room_type if data else RoomData.RoomType.COMBAT

func HasPoint(point: Vector2) -> bool:
	for rect in rects:
		if rect.has_point(point):
			return true
	return false
