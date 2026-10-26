extends EnemyRoom
class_name BossRoom

@onready var player_spawn = $PlayerSpawn
@export var possible_bosses: Array[PackedScene]
var time_before_boss: float = 2.0

func _ready() -> void:
	# a timer connection instead of await, so nothing runs if the room is freed before it fires
	get_tree().create_timer(time_before_boss).timeout.connect(SpawnBoss)

func SpawnBoss():
	var boss = possible_bosses.pick_random().instantiate() as Entity
	add_child(boss)
	boss.global_position = player_spawn.global_position
	boss.is_boss = true
	Signals.boss_spawned.emit(boss.health.maximum)
