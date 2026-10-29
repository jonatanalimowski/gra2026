extends EnemyRoom
class_name BossRoom

# sits at the end of the main path. walking in shuts the doors, the boss shows up a moment later.
# killing it spawns the UpgradeShrine (stat upgrade -> next floor) in the middle of the room
@onready var boss_spawn: Marker2D = $PlayerSpawn
@export var possible_bosses: Array[PackedScene]
@export var time_before_boss: float = 1.0
@export var reward_scene: PackedScene = preload("res://Scenes/World/UpgradeShrine.tscn")
@export var time_before_reward: float = 1.0

func SpawnEnemies() -> void:
	enemies_left = 1
	# a timer connection instead of await, so nothing runs if the room is freed before it fires
	get_tree().create_timer(time_before_boss).timeout.connect(SpawnBoss)

func SpawnBoss():
	var boss = possible_bosses.pick_random().instantiate() as Entity
	boss.died.connect(_on_enemy_died)
	boss.died.connect(_on_boss_died)
	get_parent().add_child(boss)
	boss.global_position = boss_spawn.global_position
	boss.is_boss = true
	Signals.boss_spawned.emit(boss.health.maximum)

func _on_boss_died(_boss: Entity) -> void:
	get_tree().create_timer(time_before_reward, false).timeout.connect(SpawnReward)

func SpawnReward() -> void:
	var reward = reward_scene.instantiate()
	add_child(reward)
	reward.global_position = boss_spawn.global_position
