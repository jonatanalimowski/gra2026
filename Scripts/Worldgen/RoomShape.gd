extends RefCounted
class_name RoomShape

# the geometry of a room/corridor scene, read once so the generator can lay out a whole floor
# without instantiating anything. all positions are local to the scene's origin
const CONNECTOR_NAMES: Array[String] = ["UpConnector", "DownConnector", "LeftConnector", "RightConnector"]

var scene: PackedScene
# footprint, from every RectangleShape2D under the scene's "Area2D" (L-shaped corridors have two)
var rects: Array[Rect2] = []
var connectors: Dictionary[String, Vector2] = {}

static func FromScene(packed: PackedScene) -> RoomShape:
	var shape = RoomShape.new()
	shape.scene = packed

	var instance = packed.instantiate()
	for child in instance.get_children():
		if String(child.name) in CONNECTOR_NAMES:
			shape.connectors[String(child.name)] = child.position

	var area = instance.get_node_or_null("Area2D")
	if area:
		for collision in area.get_children():
			if collision is CollisionShape2D and collision.shape is RectangleShape2D:
				var size: Vector2 = collision.shape.size
				shape.rects.append(Rect2(area.position + collision.position - size / 2.0, size))

	instance.free()
	return shape
