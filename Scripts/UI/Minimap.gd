extends Control
class_name Minimap

# map of the floor, centred on the player. fog of war: a room shows up as an outline once you've been
# in a neighbouring room or corridor, and gets filled in once you've been inside it
const BACKGROUND = Color(0.05, 0.05, 0.1, 0.6)
const FRAME = Color(0.55, 0.6, 0.75, 0.9)
const SEEN = Color(0.45, 0.5, 0.65, 0.9)
const VISITED = Color(0.35, 0.4, 0.55, 0.9)
const CURRENT = Color(0.6, 0.66, 0.8, 1.0)
const BOSS = Color(0.75, 0.2, 0.25, 1.0)
const PLAYER = Color(1.0, 1.0, 1.0, 1.0)
const ROOM_TYPE_COLORS: Dictionary[RoomData.RoomType, Color] = {
	RoomData.RoomType.TREASURE: Color(0.95, 0.75, 0.2),
	RoomData.RoomType.REST: Color(0.9, 0.3, 0.35),
	RoomData.RoomType.SHRINE: Color(0.5, 0.75, 1.0),
}

@export var world_scale: float = 1.0 / 14.0

var layout: Array = []
var seen: Dictionary[int, bool] = {}
var visited: Dictionary[int, bool] = {}
var current: LayoutPiece

func _ready() -> void:
	clip_contents = true
	Signals.world_generated.connect(_on_world_generated)

func _on_world_generated(new_layout: Array) -> void:
	layout = new_layout
	seen.clear()
	visited.clear()
	current = null

func _process(_delta: float) -> void:
	var player = NodeReferences.player
	if player == null or layout.is_empty():
		return

	if current == null or not current.HasPoint(player.global_position):
		for piece: LayoutPiece in layout:
			if piece.HasPoint(player.global_position):
				current = piece
				Visit(piece)
				break
	queue_redraw()

func Visit(piece: LayoutPiece) -> void:
	visited[piece.index] = true
	seen[piece.index] = true
	for neighbour_index in piece.neighbours:
		seen[neighbour_index] = true
		# looking down a corridor shows the room at its other end
		var neighbour: LayoutPiece = layout[neighbour_index]
		if not neighbour.IsRoom():
			for far_index in neighbour.neighbours:
				seen[far_index] = true

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	var player = NodeReferences.player
	if player == null:
		return

	var origin = player.global_position
	var centre = size / 2.0
	for piece: LayoutPiece in layout:
		if not seen.has(piece.index):
			continue
		for rect in piece.rects:
			var map_rect = Rect2((rect.position - origin) * world_scale + centre, rect.size * world_scale)
			var color = SEEN
			if piece.kind == LayoutPiece.Kind.BOSS:
				color = BOSS
			elif piece == current:
				color = CURRENT
			elif visited.has(piece.index):
				color = VISITED
			draw_rect(map_rect, color, visited.has(piece.index) or piece.kind == LayoutPiece.Kind.BOSS)

		# reward rooms get a marker so side branches are worth a detour
		var type = piece.GetRoomType()
		if ROOM_TYPE_COLORS.has(type) and not piece.rects.is_empty():
			var marker = (piece.rects[0].get_center() - origin) * world_scale + centre
			draw_circle(marker, 2.0, ROOM_TYPE_COLORS[type])

	draw_circle(centre, 1.5, PLAYER)
	draw_rect(Rect2(Vector2.ZERO, size), FRAME, false, 1.0)
