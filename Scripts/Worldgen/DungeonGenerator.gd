extends Node2D

var opposite_connector: Dictionary = {
	"UpConnector": "DownConnector",
	"LeftConnector": "RightConnector",
	"RightConnector": "LeftConnector",
	"DownConnector": "UpConnector"
}

var fitting_rooms_for_connector: Dictionary
var rooms_with_up_connectors: Array[PackedScene]
var rooms_with_down_connectors: Array[PackedScene]
var rooms_with_left_connectors: Array[PackedScene]
var rooms_with_right_connectors: Array[PackedScene]

@export var rooms: Array[RoomData]

@export var left_right_corridors: Array[PackedScene]
@export var up_down_corridors: Array[PackedScene]
@export var corridor_caps: Dictionary[String, PackedScene]
@export var starter_room: PackedScene

var generation_iterations: int = 3
var rooms_to_cleanup: Array
var unhandled_rooms: Array
var unhandled_corridors: Array

func _ready() -> void:
	SortRooms()
	GenerateDungeon()
	CleanupDungeon()

func InitialiseDict():
	fitting_rooms_for_connector = {
		"UpConnector": rooms_with_up_connectors,
		"LeftConnector": rooms_with_left_connectors,
		"RightConnector": rooms_with_right_connectors,
		"DownConnector": rooms_with_down_connectors
	}

func SortRooms():
	for room in rooms:
		if room.has_up_connector:
			rooms_with_up_connectors.append(room.room_scene)
		if room.has_down_connector:
			rooms_with_down_connectors.append(room.room_scene)
		if room.has_left_connector:
			rooms_with_left_connectors.append(room.room_scene)
		if room.has_right_connector:
			rooms_with_right_connectors.append(room.room_scene)
	InitialiseDict()


func GenerateDungeon():
	var starter_room_instance = starter_room.instantiate()
	starter_room_instance.global_position = Vector2.ZERO
	add_child(starter_room_instance)
	unhandled_rooms.append(starter_room_instance)
	for i in range(generation_iterations):
		var rooms_to_process = unhandled_rooms.duplicate()
		for room in rooms_to_process:
			#print("ITERACJA NR " + str(i) + " " + str(room))
			GenerateConnectingCorridors(room)
		var corridors_to_process = unhandled_corridors.duplicate()
		for corridor in corridors_to_process:
			#print("ITERACJA NR " + str(i) + " " + str(corridor))
			GenerateConnectingRooms(corridor)

func CleanupDungeon() -> void:
	for corridor_instance: Room in unhandled_corridors.duplicate():
		unhandled_corridors.erase(corridor_instance)
		
		corridor_instance.LocateConnectors()
		var connector = corridor_instance.GetFirstOccupiedConnector()
		ReplaceConnectorWithWall(corridor_instance, connector, true)
		corridor_instance.queue_free()
		
	for room_instance: Room in unhandled_rooms.duplicate():
		unhandled_rooms.erase(room_instance)
		
		room_instance.LocateConnectors()
		for connector in room_instance.GetAllUnoccupiedConnectors():
			ReplaceConnectorWithWall(room_instance, opposite_connector[connector], false)
	
	for room_instance: Room in rooms_to_cleanup.duplicate():
		if room_instance != null:
			rooms_to_cleanup.erase(room_instance)
			
			room_instance.LocateConnectors()
			for connector in room_instance.GetAllUnoccupiedConnectors():
				ReplaceConnectorWithWall(room_instance, opposite_connector[connector], false)

func GenerateConnectingCorridors(room_instance: Room):
	if room_instance in unhandled_rooms:
		unhandled_rooms.erase(room_instance)
	
	room_instance.LocateConnectors()
	for connector in room_instance.connectors:
		if room_instance.connectors[connector] and room_instance.occupied_connectors[connector] == false:
			var fitting_corridor_instance: Room
			if connector == "LeftConnector" or connector == "RightConnector":
				fitting_corridor_instance = left_right_corridors.pick_random().instantiate()
			else:
				fitting_corridor_instance = up_down_corridors.pick_random().instantiate()
			
			fitting_corridor_instance.LocateConnectors()
			var difference_vector = room_instance.connectors[connector].global_position - fitting_corridor_instance.connectors[opposite_connector[connector]].global_position
			var corridor_pos = fitting_corridor_instance.global_position + difference_vector
			fitting_corridor_instance.global_position = corridor_pos
			if IsRoomFree(fitting_corridor_instance, corridor_pos):
				add_child(fitting_corridor_instance)
				
				room_instance.occupied_connectors[connector] = true
				fitting_corridor_instance.occupied_connectors[opposite_connector[connector]] = true
				unhandled_corridors.append(fitting_corridor_instance)
			else:
				rooms_to_cleanup.append(room_instance)
				fitting_corridor_instance.queue_free()

func GenerateConnectingRooms(corridor_instance: Room):
	#A corridor can only have 2 exits - left/right or up/down, otherwise might break.
	if corridor_instance in unhandled_corridors:
		unhandled_corridors.erase(corridor_instance)
	
	corridor_instance.LocateConnectors()
	for connector in corridor_instance.connectors:
		if corridor_instance.connectors[connector] and corridor_instance.occupied_connectors[connector] == false:
			var fitting_room_instance: Room
			fitting_room_instance = GetFittingRoom(connector).instantiate()
			fitting_room_instance.LocateConnectors()
			
			var difference_vector = corridor_instance.connectors[connector].global_position - fitting_room_instance.connectors[opposite_connector[connector]].global_position
			var room_pos = fitting_room_instance.global_position + difference_vector
			fitting_room_instance.global_position = room_pos
			if IsRoomFree(fitting_room_instance, room_pos):
				add_child(fitting_room_instance)
				
				corridor_instance.occupied_connectors[connector] = true
				fitting_room_instance.occupied_connectors[opposite_connector[connector]] = true
				unhandled_rooms.append(fitting_room_instance)
			else:
				# if there is no space for a room, remove corridor and place a wall on the room exit.
				ReplaceConnectorWithWall(corridor_instance, opposite_connector[connector], true)
				corridor_instance.queue_free()
				fitting_room_instance.queue_free()

func IsRoomFree(room_instance: Node2D, target_pos: Vector2) -> bool:
	var area = room_instance.get_node("Area2D")
	var collision_shape = area.get_node("CollisionShape2D")
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = Transform2D(0, target_pos + collision_shape.position)
	query.collision_mask = 128
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var space_state = get_world_2d().direct_space_state
	var results = space_state.intersect_shape(query)
	
	return results.size() == 0

func GetFittingRoom(connector: String):
	var fitting_rooms_list = fitting_rooms_for_connector[opposite_connector[connector]]
	var fitting_room = fitting_rooms_list.pick_random()
	return fitting_room

func ReplaceConnectorWithWall(room_instance: Node2D, connector: String, is_corridor: bool) -> void:
	var fitting_cap: Room
	match connector:
		"UpConnector":
			fitting_cap = corridor_caps["CapDown"].instantiate()
		"DownConnector":
			fitting_cap = corridor_caps["CapUp"].instantiate()
		"LeftConnector":
			fitting_cap = corridor_caps["CapRight"].instantiate()
		"RightConnector":
			fitting_cap = corridor_caps["CapLeft"].instantiate()
		_:
			print("Something went wrong in connector-wall replacement")
			return
	fitting_cap.LocateConnectors()
	var cap_connector = fitting_cap.GetFirstConnector()
	var cap_pos
	if cap_connector != null:
		if is_corridor:
			var difference_vector = room_instance.connectors[connector].global_position - fitting_cap.connectors[connector].global_position
			cap_pos = fitting_cap.global_position + difference_vector
		else:
			var difference_vector = room_instance.connectors[opposite_connector[connector]].global_position - fitting_cap.connectors[connector].global_position
			cap_pos = fitting_cap.global_position + difference_vector
		fitting_cap.global_position = cap_pos
		add_child(fitting_cap)
	else:
		return
