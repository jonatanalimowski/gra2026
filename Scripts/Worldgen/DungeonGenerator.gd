extends Node2D
class_name DungeonGenerator

# builds a floor in two steps:
# 1. layout - plain data (LayoutPiece rects + connectors). overlap checks are exact and instant,
#    so a bad layout is simply thrown away and retried
# 2. build - instantiates every piece and caps the connectors nothing was attached to
# shape of a floor: start -> main path of combat rooms -> boss room, plus short side branches
# with reward rooms at their ends, plus a loop here and there

const OPPOSITE: Dictionary[String, String] = {
	"UpConnector": "DownConnector",
	"DownConnector": "UpConnector",
	"LeftConnector": "RightConnector",
	"RightConnector": "LeftConnector"
}
const DIRECTION: Dictionary[String, Vector2] = {
	"UpConnector": Vector2.UP,
	"DownConnector": Vector2.DOWN,
	"LeftConnector": Vector2.LEFT,
	"RightConnector": Vector2.RIGHT
}
# which cap closes an unused connector
const CAP_FOR_CONNECTOR: Dictionary[String, String] = {
	"UpConnector": "CapUp",
	"DownConnector": "CapDown",
	"LeftConnector": "CapLeft",
	"RightConnector": "CapRight"
}
# atlas cells of the world tileset: plain floor gets swapped for a cracked variant now and then
const PLAIN_FLOOR: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)]
const FLOOR_VARIANTS: Array[Vector2i] = [
	Vector2i(2, 1), Vector2i(2, 2), Vector2i(14, 1), Vector2i(14, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(3, 2)
]

@export var rooms: Array[RoomData]
# straight and L-shaped, any scene with exactly two connectors
@export var corridors: Array[PackedScene]
@export var corridor_caps: Dictionary[String, PackedScene]
@export var starter_room: PackedScene
@export var boss_rooms: Array[PackedScene]

@export_group("Layout")
# rooms per floor, not counting start and boss. one more for every floor after the first
@export var min_rooms: int = 4
@export var max_rooms: int = 6
# share of those rooms on the main path, the rest go into side branches
@export_range(0.0, 1.0) var main_path_share: float = 0.6
@export var max_branch_length: int = 2
# chance to attach a room straight to the previous one, without a corridor
@export_range(0.0, 1.0) var direct_connection_chance: float = 0.1
@export var max_loops: int = 2
@export var max_attempts: int = 50
# non-zero = always generate this exact floor (for debugging a layout)
@export var debug_seed: int = 0
@export_range(0.0, 1.0) var floor_variant_chance: float = 0.15

var rng := RandomNumberGenerator.new()
var shapes: Dictionary[PackedScene, RoomShape] = {}
var layout: Array[LayoutPiece] = []
var placed_per_room: Dictionary[RoomData, int] = {}
var rooms_left_to_clear: int = 0

func _ready() -> void:
	rng.seed = debug_seed if debug_seed != 0 else RunState.GetFloorSeed()
	print("Floor seed: ", rng.seed)

	var success = false
	for attempt in max_attempts:
		if TryLayout():
			success = true
			break
	if not success:
		push_error("Dungeon layout failed %d times, building the last attempt" % max_attempts)

	Build()
	# deferred, so the HUD (ready after this node) is listening
	Signals.world_generated.emit.call_deferred(layout)

func _on_room_cleared(_room: EnemyRoom) -> void:
	rooms_left_to_clear -= 1
	print("Rooms left: " + str(rooms_left_to_clear))
	if rooms_left_to_clear == 0:
		Signals.all_rooms_cleared.emit()

#region layout

func TryLayout() -> bool:
	layout.clear()
	placed_per_room.clear()

	var target = rng.randi_range(min_rooms, max_rooms) + RunState.floor_number - 1
	var main_length = maxi(1, roundi(target * main_path_share))

	var start = AddPiece(LayoutPiece.Kind.START, GetShape(starter_room), null, Vector2.ZERO)

	# main path, every room needs a second connector to carry on
	var tip = start
	for i in main_length:
		tip = Extend(tip, PickRooms(tip.depth + 1, true, false))
		if tip == null:
			return false
		tip.on_main_path = true

	var boss_shapes: Array[RoomShape] = []
	for scene in boss_rooms:
		boss_shapes.append(GetShape(scene))
	var boss = Extend(tip, boss_shapes, LayoutPiece.Kind.BOSS)
	if boss == null:
		return false
	boss.on_main_path = true

	AddBranches(target - main_length)
	if not HasRequiredRooms():
		return false
	AddLoops()
	return true

func HasRequiredRooms() -> bool:
	for data in rooms:
		if placed_per_room.get(data, 0) < data.min_per_floor:
			return false
	return true

# grows side branches off the main path, one room at a time from a frontier of rooms with free connectors
func AddBranches(rooms_to_add: int) -> void:
	var frontier: Array[LayoutPiece] = []
	for piece in layout:
		if (piece.on_main_path and piece.kind != LayoutPiece.Kind.BOSS) or piece.kind == LayoutPiece.Kind.START:
			frontier.append(piece)

	while rooms_to_add > 0 and not frontier.is_empty():
		var root: LayoutPiece = frontier.pop_at(rng.randi() % frontier.size())
		var length = mini(rng.randi_range(1, max_branch_length), rooms_to_add)
		var tip = root
		for i in length:
			# the last room of a branch is where the rewards go
			var is_branch_end = i == length - 1
			var next = Extend(tip, PickRooms(tip.depth + 1, not is_branch_end, is_branch_end))
			if next == null:
				break
			rooms_to_add -= 1
			tip = next

		# a root that grew a branch can try another one later
		if tip != root and not root.open_connectors.is_empty():
			frontier.append(root)

# joins two free connectors that face each other, directly or with a straight corridor that fits the gap exactly
func AddLoops() -> void:
	var loops = 0
	for a in layout:
		if not CanLoop(a):
			continue
		for connector in a.open_connectors.duplicate():
			if loops >= max_loops:
				return
			var other_side = OPPOSITE[connector]
			var from_pos = a.GetConnectorPosition(connector)
			for b in layout:
				if b == a or not CanLoop(b) or b.index in a.neighbours or not b.open_connectors.has(other_side):
					continue

				var gap = b.GetConnectorPosition(other_side) - from_pos
				if gap == Vector2.ZERO:
					Link(a, connector, b, other_side)
					loops += 1
					break
				if not gap.normalized().is_equal_approx(DIRECTION[connector]):
					continue

				var corridor = FindStraightCorridor(connector, gap)
				if corridor:
					var corridor_pos = from_pos - corridor.connectors[other_side]
					if IsFree(corridor, corridor_pos):
						var piece = AddPiece(LayoutPiece.Kind.CORRIDOR, corridor, null, corridor_pos)
						Link(a, connector, piece, other_side)
						Link(piece, connector, b, other_side)
						loops += 1
						break

func CanLoop(piece: LayoutPiece) -> bool:
	# the boss room keeps a single entrance
	return piece.IsRoom() and piece.kind != LayoutPiece.Kind.BOSS

func FindStraightCorridor(connector: String, gap: Vector2) -> RoomShape:
	for scene in corridors:
		var corridor = GetShape(scene)
		if corridor.connectors.has(connector) and corridor.connectors.has(OPPOSITE[connector]):
			if corridor.connectors[connector] - corridor.connectors[OPPOSITE[connector]] == gap:
				return corridor
	return null

# attaches the first candidate that fits to a free connector of `from`, through a corridor or directly.
# returns the new room, or null when nothing fits anywhere
func Extend(from: LayoutPiece, candidates: Array[RoomShape], kind := LayoutPiece.Kind.ROOM) -> LayoutPiece:
	var exits = from.open_connectors.duplicate()
	Shuffle(exits)
	for exit in exits:
		var exit_pos = from.GetConnectorPosition(exit)
		for corridor in PickCorridors(exit):
			var corridor_pos: Vector2
			var corridor_exit = exit
			var door_pos = exit_pos
			if corridor:
				corridor_pos = exit_pos - corridor.connectors[OPPOSITE[exit]]
				if not IsFree(corridor, corridor_pos):
					continue
				corridor_exit = GetOtherConnector(corridor, OPPOSITE[exit])
				door_pos = corridor_pos + corridor.connectors[corridor_exit]

			var entry = OPPOSITE[corridor_exit]
			for shape in candidates:
				if not shape.connectors.has(entry):
					continue
				var room_pos = door_pos - shape.connectors[entry]
				if not IsFree(shape, room_pos):
					continue
				if corridor and Overlaps(shape, room_pos, corridor, corridor_pos):
					continue

				var room = AddPiece(kind, shape, DataForShape(shape), room_pos)
				room.depth = from.depth + 1
				if corridor:
					var piece = AddPiece(LayoutPiece.Kind.CORRIDOR, corridor, null, corridor_pos)
					piece.depth = from.depth
					Link(from, exit, piece, OPPOSITE[exit])
					Link(piece, corridor_exit, room, entry)
				else:
					Link(from, exit, room, entry)
				if room.data:
					placed_per_room[room.data] = placed_per_room.get(room.data, 0) + 1
				return room
	return null

# candidate rooms in weighted random order.
# main path / mid-branch rooms are combat rooms with a way on, branch ends prefer reward rooms
func PickRooms(depth: int, needs_exit: bool, is_branch_end: bool) -> Array[RoomShape]:
	var required: Array[RoomData] = []
	var rewards: Array[RoomData] = []
	var fights: Array[RoomData] = []
	var dead_ends: Array[RoomData] = []
	for data in rooms:
		if depth < data.min_depth:
			continue
		if data.max_per_floor > 0 and placed_per_room.get(data, 0) >= data.max_per_floor:
			continue
		var shape = GetShape(data.room_scene)
		if needs_exit and shape.connectors.size() < 2:
			continue
		if data.room_type != RoomData.RoomType.COMBAT:
			if is_branch_end:
				if placed_per_room.get(data, 0) < data.min_per_floor:
					required.append(data)
				else:
					rewards.append(data)
		elif is_branch_end and shape.connectors.size() == 1:
			dead_ends.append(data)
		else:
			fights.append(data)

	# branch ends: rooms the floor still needs, other rewards, then dead ends (they close a branch off cleanly), then the rest
	var ordered = WeightedShuffle(required)
	ordered.append_array(WeightedShuffle(rewards))
	ordered.append_array(WeightedShuffle(dead_ends))
	ordered.append_array(WeightedShuffle(fights))

	var result: Array[RoomShape] = []
	for data in ordered:
		result.append(GetShape(data.room_scene))
	return result

# corridors that can start at this exit, in random order. null = connect directly
func PickCorridors(exit: String) -> Array:
	var result: Array = []
	for scene in corridors:
		var corridor = GetShape(scene)
		if corridor.connectors.has(OPPOSITE[exit]):
			result.append(corridor)
	Shuffle(result)
	# a direct connection is mostly the fallback, now and then the first choice
	if rng.randf() < direct_connection_chance:
		result.push_front(null)
	else:
		result.push_back(null)
	return result

func AddPiece(kind: LayoutPiece.Kind, shape: RoomShape, data: RoomData, pos: Vector2) -> LayoutPiece:
	var piece = LayoutPiece.new(layout.size(), kind, shape, data, pos)
	layout.append(piece)
	return piece

func Link(a: LayoutPiece, a_connector: String, b: LayoutPiece, b_connector: String) -> void:
	a.open_connectors.erase(a_connector)
	b.open_connectors.erase(b_connector)
	a.neighbours.append(b.index)
	b.neighbours.append(a.index)

func IsFree(shape: RoomShape, pos: Vector2) -> bool:
	for piece in layout:
		for rect in piece.rects:
			for own in shape.rects:
				# shrunk a bit, pieces always touch at their connectors
				if Rect2(own.position + pos, own.size).grow(-1.0).intersects(rect):
					return false
	return true

func Overlaps(a: RoomShape, a_pos: Vector2, b: RoomShape, b_pos: Vector2) -> bool:
	for rect_a in a.rects:
		for rect_b in b.rects:
			if Rect2(rect_a.position + a_pos, rect_a.size).grow(-1.0).intersects(Rect2(rect_b.position + b_pos, rect_b.size)):
				return true
	return false

func GetOtherConnector(shape: RoomShape, connector: String) -> String:
	for other in shape.connectors:
		if other != connector:
			return other
	return connector

func GetShape(scene: PackedScene) -> RoomShape:
	if not shapes.has(scene):
		shapes[scene] = RoomShape.FromScene(scene)
	return shapes[scene]

func DataForShape(shape: RoomShape) -> RoomData:
	for data in rooms:
		if data.room_scene == shape.scene:
			return data
	return null

# seeded versions of shuffle/pick_random, so a seed always gives the same floor
func Shuffle(array: Array) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp

func WeightedShuffle(candidates: Array[RoomData]) -> Array[RoomData]:
	var pool = candidates.duplicate()
	var result: Array[RoomData] = []
	while not pool.is_empty():
		var total = 0.0
		for data in pool:
			total += data.weight
		var roll = rng.randf() * total
		var picked = pool.size() - 1
		for i in pool.size():
			roll -= pool[i].weight
			if roll <= 0.0:
				picked = i
				break
		result.append(pool.pop_at(picked))
	return result

#endregion

#region build

func Build() -> void:
	for piece in layout:
		var instance = piece.shape.scene.instantiate()
		instance.position = piece.position
		instance.z_index = -1
		add_child(instance)
		VaryFloor(instance, hash([rng.seed, piece.position]))

		if instance is EnemyRoom and not instance is BossRoom:
			instance.cleared.connect(_on_room_cleared)
			rooms_left_to_clear += 1

		for connector in piece.open_connectors:
			AddCap(piece, connector)

func AddCap(piece: LayoutPiece, connector: String) -> void:
	var cap_scene = corridor_caps[CAP_FOR_CONNECTOR[connector]]
	var cap = cap_scene.instantiate()
	cap.position = piece.GetConnectorPosition(connector) - GetShape(cap_scene).connectors[OPPOSITE[connector]]
	cap.z_index = 1
	add_child(cap)

# own rng per room so it never shifts the layout rng (same seed = same floor)
func VaryFloor(room: Node, room_seed: int) -> void:
	var floor_rng := RandomNumberGenerator.new()
	floor_rng.seed = room_seed
	for layer: TileMapLayer in room.find_children("*", "TileMapLayer", true, false):
		for cell in layer.get_used_cells():
			if layer.get_cell_atlas_coords(cell) in PLAIN_FLOOR and floor_rng.randf() < floor_variant_chance:
				var variant = FLOOR_VARIANTS[floor_rng.randi() % FLOOR_VARIANTS.size()]
				layer.set_cell(cell, layer.get_cell_source_id(cell), variant)

#endregion
