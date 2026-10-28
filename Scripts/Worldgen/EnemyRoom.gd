extends Room
class_name EnemyRoom

signal cleared(room: EnemyRoom)

@onready var player_detection_area: Area2D = $PlayerDetectionArea
@onready var doors: TileMapLayer = $Doors
@onready var enemy_spawn_markers: Array = $SpawnMarkers.get_children()
@export var enemy_table: Array[PackedScene]
var is_room_cleared: bool = false
var is_room_active: bool = false
var enemies_left: int = 0

func _ready() -> void:
	DisableDoors()
	ConnectSignals()

func ConnectSignals() -> void:
	player_detection_area.body_entered.connect(_on_body_entered)

func _on_enemy_died(_enemy: Entity) -> void:
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
	# on first player detection
	if is_room_cleared == false and body.is_in_group("player") and is_room_active == false:
		is_room_active = true
		EnableDoors()
		SpawnEnemies()

func _on_room_cleared() -> void:
	is_room_cleared = true
	is_room_active = false
	DisableDoors()
	cleared.emit(self)
	Signals.room_cleared.emit()
	#SpawnLoot()?

func SpawnEnemies() -> void:
	for spawnpoint in enemy_spawn_markers:
		var enemy: Entity = enemy_table.pick_random().instantiate()
		enemy.global_position = spawnpoint.global_position
		get_parent().add_child(enemy)
		RegisterEnemy(enemy)

	# a room without spawn markers would otherwise stay locked forever
	if enemies_left == 0:
		_on_room_cleared()

# summoned enemies register too, so the doors stay shut until they're dead
func RegisterEnemy(enemy: Entity) -> void:
	enemy.died.connect(_on_enemy_died)
	enemy.summoned.connect(RegisterEnemy)
	enemies_left += 1
