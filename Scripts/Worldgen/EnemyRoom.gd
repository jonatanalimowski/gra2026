extends Room
class_name EnemyRoom

@onready var player_detection_area: Area2D = $PlayerDetectionArea
@onready var doors: TileMapLayer = $Doors
@onready var enemy_spawn_markers: Array = $SpawnMarkers.get_children()
@export var enemy_table: Array[PackedScene]
var is_room_cleared: bool = false
var is_room_active: bool = false
var enemies_left: int

#var temptimer: float = 0
#var tempcounter: int = 0

func _ready() -> void:
	DisableDoors()
	ConnectSignals()
	pass

func ConnectSignals() -> void:
	Signals.enemy_killed.connect(_on_enemy_killed)
	player_detection_area.body_entered.connect(_on_body_entered)

#func _process(delta: float) -> void:
	#print(temptimer)
	#temptimer += delta
	#if temptimer > 5.0:
		#tempcounter += 1
		#temptimer = 0
		#if tempcounter%2 == 0:
			#EnableDoors()
		#else:
			#DisableDoors()

func _on_enemy_killed() -> void:
	if is_room_active:
		enemies_left -= 1
		if enemies_left <= 0:
			_on_room_cleared()

func EnableDoors() -> void:
	doors.collision_enabled = true
	doors.visible = true

func DisableDoors() -> void:
	doors.collision_enabled = false
	doors.visible = false

func _on_body_entered(body: Node2D) -> void:
	if is_room_cleared == false and body.is_in_group("player") and is_room_active == false:
		is_room_active = true
		SpawnEnemies()
		EnableDoors()

func _on_room_cleared() -> void:
	is_room_cleared = true
	is_room_active = false
	DisableDoors()
	#SpawnLoot()?

func SpawnEnemies() -> void:
	for spawnpoint in enemy_spawn_markers:
		var enemy = enemy_table.pick_random().instantiate()
		enemy.global_position = spawnpoint.global_position
		get_parent().add_child(enemy)
		enemies_left += 1
