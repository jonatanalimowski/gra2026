extends Room
class_name EnemyRoom

signal cleared(room: EnemyRoom)

@onready var player_detection_area: Area2D = $PlayerDetectionArea
@onready var doors: TileMapLayer = $Doors
@onready var enemy_spawn_markers: Array = $SpawnMarkers.get_children()
# the room rolls one of these when entered, then every spawn marker picks from it
@export var enemy_pools: Array[EnemyPool]
# chance per spawned enemy to be elite (see Entity.ApplyElite)
@export_range(0.0, 1.0) var elite_chance: float = 0.08
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
		Sfx.Play(&"world/doors_lock", -10)
		SpawnEnemies()

func _on_room_cleared() -> void:
	is_room_cleared = true
	is_room_active = false
	DisableDoors()
	cleared.emit(self)
	Signals.room_cleared.emit()
	#SpawnLoot()?

func SpawnEnemies() -> void:
	# seeded by position like altars, so Ctrl+R gives the same fights
	var rng = RandomNumberGenerator.new()
	rng.seed = hash([RunState.GetFloorSeed(), "enemies", global_position])
	var pool := PickPool(rng)

	for spawnpoint in enemy_spawn_markers:
		var scene := pool.PickEnemy(rng) if pool else null
		if scene == null:
			push_warning("%s: no enemy pool to spawn from" % name)
			break
		var enemy: Entity = scene.instantiate()
		enemy.global_position = spawnpoint.global_position
		# always roll, so the dev cheat doesn't shift the seeded picks after it
		enemy.is_elite = rng.randf() < elite_chance or DevTools.more_elites
		get_parent().add_child(enemy)
		RegisterEnemy(enemy)

	# a room without spawn markers would otherwise stay locked forever
	if enemies_left == 0:
		_on_room_cleared()

func PickPool(rng: RandomNumberGenerator) -> EnemyPool:
	var pools := enemy_pools.filter(func(p): return p != null)
	if pools.is_empty():
		return null
	return pools[rng.randi() % pools.size()]

# summoned enemies register too, so the doors stay shut until they're dead
func RegisterEnemy(enemy: Entity) -> void:
	enemy.died.connect(_on_enemy_died)
	enemy.summoned.connect(RegisterEnemy)
	enemies_left += 1
