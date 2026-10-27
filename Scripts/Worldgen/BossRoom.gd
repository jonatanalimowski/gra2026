extends EnemyRoom
class_name BossRoom

# sits at the end of the main path. walking in shuts the doors, the boss shows up a moment later
@onready var boss_spawn: Marker2D = $PlayerSpawn
@export var possible_bosses: Array[PackedScene]
@export var time_before_boss: float = 2.0

func SpawnEnemies() -> void:
	enemies_left = 1
	# a timer connection instead of await, so nothing runs if the room is freed before it fires
	get_tree().create_timer(time_before_boss).timeout.connect(SpawnBoss)

func SpawnBoss():
	var boss = possible_bosses.pick_random().instantiate() as Entity
	boss.died.connect(_on_enemy_died)
	get_parent().add_child(boss)
	boss.global_position = boss_spawn.global_position
	boss.is_boss = true
	Signals.boss_spawned.emit(boss.health.maximum)
