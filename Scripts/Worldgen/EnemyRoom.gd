extends Room
class_name EnemyRoom

signal cleared(room: EnemyRoom)

@onready var player_detection_area: Area2D = $PlayerDetectionArea
@onready var doors: TileMapLayer = $Doors
@onready var enemy_spawn_markers: Array = $SpawnMarkers.get_children()
# the room rolls one of these when entered, then every spawn marker picks from it
@export var enemy_pools: Array[EnemyPool]
# chance per spawned enemy to be elite (see Entity.ApplyElite), before the floor's FloorModifier
@export_range(0.0, 1.0) var elite_chance: float = 0.08
# how long the spawn markers show before the enemies appear
@export var spawn_telegraph_time: float = 0.8
# glyph drop on clear: base + per elite killed (capped), + RunState.glyph_pity per dry room before it
const GLYPH_SHRINE_SCENE = preload("res://Scenes/World/GlyphShrine.tscn")
@export var glyph_chance: float = 0.3
@export var glyph_chance_per_elite: float = 0.15
@export var glyph_chance_cap: float = 0.75
@export var glyph_pity_per_room: float = 0.1
var is_room_cleared: bool = false
var is_room_active: bool = false
var enemies_left: int = 0
var elites_spawned: int = 0
var last_death_position: Vector2
var had_kill: bool = false # empty rooms (no spawn markers) don't drop glyphs
# phase F: threats unlocked by floor (BUILD_DESIGN.md §8.2)
@export var affix_floor: int = 3 # elites get 1 affix from here
@export var second_affix_floor: int = 6 # and 2 from here
@export var second_wave_floor: int = 3
@export var second_wave_chance: float = 0.4
@export var champion_floor: int = 5
@export var champion_chance: float = 0.25
@export var champion_minions: int = 3
var wave: int = 0
var has_second_wave: bool = false
var pool: EnemyPool

func _ready() -> void:
	DisableDoors()
	ConnectSignals()

func ConnectSignals() -> void:
	player_detection_area.body_entered.connect(_on_body_entered)

func _on_enemy_died(enemy: Entity) -> void:
	last_death_position = enemy.global_position
	had_kill = true
	enemies_left -= 1
	if enemies_left <= 0:
		# second wave: the doors stay shut, more come from the same markers
		if has_second_wave and wave == 0:
			wave = 1
			SpawnEnemies()
			return
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
	RollGlyph()

# seeded by floor + room position like the enemies, so Ctrl+R drops the same glyphs.
# the boss room has its own reward (UpgradeShrine)
func RollGlyph() -> void:
	if self is BossRoom or not had_kill:
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = hash([RunState.GetFloorSeed(), "glyph_drop", global_position])
	var per_elite = glyph_chance_per_elite + RunState.GetEliteGlyphBonus() # Champions omen
	var chance = minf(glyph_chance + per_elite * elites_spawned, glyph_chance_cap) + RunState.glyph_pity
	if rng.randf() >= chance:
		RunState.glyph_pity += glyph_pity_per_room
		return
	RunState.glyph_pity = 0.0
	var shrine = GLYPH_SHRINE_SCENE.instantiate()
	var parent = get_parent()
	shrine.position = parent.to_local(last_death_position)
	# the last death runs inside a physics callback, no new Area2D there
	parent.add_child.call_deferred(shrine)
	#SpawnLoot()?

func SpawnEnemies() -> void:
	# seeded by position like altars, so Ctrl+R gives the same fights
	var rng = RandomNumberGenerator.new()
	rng.seed = hash([RunState.GetFloorSeed(), "enemies", global_position, wave])
	if wave == 0:
		pool = PickPool(rng)
		has_second_wave = RunState.floor_number >= second_wave_floor and rng.randf() < second_wave_chance
	var spawns: Array[Dictionary] = []
	var floor_elite_chance := RunState.floor_modifier.GetEliteChance(RunState.floor_number, elite_chance)
	floor_elite_chance = minf(floor_elite_chance * RunState.GetEliteChanceMultiplier(), 1.0) # pacts, omens
	var count_multiplier = RunState.GetEnemyCountMultiplier() # Swarm omen
	var room_has_ward := false

	for spawnpoint in enemy_spawn_markers:
		# Swarm: a 1.5 multiplier = a 50% chance of a 2nd enemy at each marker
		var count = 1 + (1 if rng.randf() < count_multiplier - 1.0 else 0)
		for i in count:
			var scene := pool.PickEnemy(rng) if pool else null
			if scene == null:
				push_warning("%s: no enemy pool to spawn from" % name)
				break
			var spawn_pos = spawnpoint.global_position + (Vector2.from_angle(rng.randf() * TAU) * 14.0 if i > 0 else Vector2.ZERO)
			# always roll, so the dev cheat doesn't shift the seeded picks after it
			var is_elite = rng.randf() < floor_elite_chance or DevTools.more_elites
			var affixes: Array[Affix] = []
			if is_elite:
				affixes = RollAffixes(rng, not room_has_ward)
				room_has_ward = room_has_ward or affixes.any(func(a): return a.kind == Affix.Kind.WARDED)
			spawns.append(MakeSpawn(scene, spawn_pos, is_elite, affixes))

	# champion pack: one elite + minions of the same kind sharing its affix
	if RunState.floor_number >= champion_floor and wave == 0 and not spawns.is_empty() and rng.randf() < champion_chance:
		var leader = spawns[0]
		leader.is_elite = true
		if leader.affixes.is_empty():
			leader.affixes = RollAffixes(rng, false, 1)
		for i in champion_minions:
			var offset = Vector2.from_angle(TAU * i / champion_minions) * 20.0
			spawns.append(MakeSpawn(leader.scene, leader.position + offset, false, leader.affixes.duplicate()))

	# a room without spawn markers would otherwise stay locked forever
	if spawns.is_empty():
		_on_room_cleared()
		return

	# a timer connection instead of await, so nothing runs if the room is freed before it fires
	get_tree().create_timer(spawn_telegraph_time, false).timeout.connect(FinishSpawning.bind(spawns))

func FinishSpawning(spawns: Array[Dictionary]) -> void:
	for spawn in spawns:
		spawn.telegraph.queue_free()
		var enemy: Entity = spawn.scene.instantiate()
		enemy.global_position = spawn.position
		enemy.is_elite = spawn.is_elite
		enemy.affixes.assign(spawn.affixes)
		for affix in spawn.affixes:
			if affix.kind == Affix.Kind.WARDED:
				enemy.ward_group = RunState.GetTopSchoolWardGroup()
		get_parent().add_child(enemy)
		RegisterEnemy(enemy)

func MakeSpawn(scene: PackedScene, spawn_pos: Vector2, is_elite: bool, affixes: Array[Affix]) -> Dictionary:
	var telegraph = SpawnTelegraph.new()
	add_child(telegraph)
	telegraph.global_position = spawn_pos
	return { "scene": scene, "position": spawn_pos, "is_elite": is_elite, "affixes": affixes, "telegraph": telegraph }

# 1 affix from affix_floor, 2 from second_affix_floor (or `count`). Warded only if the room has none yet
# and the player owns a school to ward against
func RollAffixes(rng: RandomNumberGenerator, allow_ward: bool, count: int = -1) -> Array[Affix]:
	if count < 0:
		count = 2 if RunState.floor_number >= second_affix_floor else (1 if RunState.floor_number >= affix_floor else 0)
	var options = RunState.AFFIXES.filter(func(a):
		return a.kind != Affix.Kind.WARDED or (allow_ward and RunState.GetTopSchoolWardGroup() != &""))
	var result: Array[Affix] = []
	for i in mini(count, options.size()):
		var affix = options[rng.randi() % options.size()]
		options.erase(affix)
		result.append(affix)
	return result

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
	if enemy.is_elite:
		elites_spawned += 1
