extends EnemyRoom
class_name BossRoom

@onready var player_spawn = $PlayerSpawn
@export var possible_bosses: Array[PackedScene]
var time_before_boss: float = 2.0

func _ready() -> void:
	SpawnBoss()

func SpawnBoss():
	await get_tree().create_timer(time_before_boss).timeout
	var boss = possible_bosses.pick_random().instantiate() as Entity
	add_child(boss)
	boss.global_position = player_spawn.global_position
	boss.is_boss = true
	Signals.boss_spawned.emit(boss.stats.max_health)
