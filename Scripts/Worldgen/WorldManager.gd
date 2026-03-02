extends Node

var total_rooms: int = 0
var cleared_rooms: int = 0

func _ready() -> void:
	ConnectSignals()

func ConnectSignals() -> void:
	Signals.world_generated.connect(_on_world_generated)
	Signals.room_cleared.connect(_on_room_cleared)
	Signals.all_rooms_cleared.connect(_on_dungeon_cleared)

func _on_world_generated(room_amount) -> void:
	total_rooms = room_amount
	cleared_rooms = 0

func _on_room_cleared() -> void:
	cleared_rooms += 1
	print("Total rooms: " + str(total_rooms) + "\nLeft: " + str(total_rooms - cleared_rooms))

#TEMPORARY
func _on_dungeon_cleared() -> void:
	print("congratulations!")
