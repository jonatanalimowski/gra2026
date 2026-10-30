extends EnemyRoom
class_name BossRoom

# sits at the end of the main path. walking in shuts the doors, the boss shows up a moment later.
# killing it spawns the UpgradeShrine (stat upgrade -> next floor) in the middle of the room.
# no damage taken during the fight = flawless, the shrine gives flawless_picks upgrades instead of 1
@onready var boss_spawn: Marker2D = $PlayerSpawn
@export var possible_bosses: Array[PackedScene]
@export var time_before_boss: float = 1.0
@export var reward_scene: PackedScene = preload("res://Scenes/World/UpgradeShrine.tscn")
@export var time_before_reward: float = 1.0
@export var flawless_picks: int = 2
var took_damage: bool = false

func SpawnEnemies() -> void:
	enemies_left = 1
	Signals.player_damaged.connect(_on_player_damaged)
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

func _on_player_damaged(_info: DamageInfo) -> void:
	took_damage = true

func _on_boss_died(_boss: Entity) -> void:
	Signals.player_damaged.disconnect(_on_player_damaged)
	get_tree().create_timer(time_before_reward, false).timeout.connect(SpawnReward)

func SpawnReward() -> void:
	var reward = reward_scene.instantiate()
	if not took_damage:
		reward.picks = flawless_picks
	add_child(reward)
	reward.global_position = boss_spawn.global_position
