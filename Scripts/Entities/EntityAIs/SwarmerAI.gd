extends Node
class_name SwarmerAI

# walks at the player in bursts with breaks, sticking together with other swarmers
# the original (can_summon) stops every so often to summon copies of its own scene, copies can't summon
@onready var ParentEntity: Entity = get_parent()
@export_group("Movement")
@export var walk_time: float = 1.2
@export var rest_time: float = 0.6
@export var time_variation: float = 0.4 # random +- on walk/rest, so a swarm doesn't pulse in sync
@export var neighbor_radius: float = 80.0 # swarmers closer than this count as the group
@export var separation_radius: float = 18.0 # pushed apart when closer than this, so they don't stack
@export var chase_weight: float = 1.0
@export var cohesion_weight: float = 0.6
@export var separation_weight: float = 1.2
# if true it wanders (still grouping up) when it can't see the player
@export var needs_line_of_sight: bool = true
@export_group("Summoning")
@export var can_summon: bool = true
@export var summon_count: int = 2
@export var summon_cooldown: float = 4.0
@export var first_summon_delay: float = 1.5
@export var max_minions: int = 6 # alive at once, per summoner
@export var summon_radius: float = 20.0
@export var minion_scale: float = 0.75
@export var minion_health_multiplier: float = 0.5
@export var telegraph_color: Color = Color.AQUAMARINE
@export var telegraph_duration: float = 0.5

enum State { WALK, REST, SUMMON }
var state: State = State.REST
var state_timer: float = 0.0
var summon_timer: float = 0.0
var summon_scene: PackedScene
var minions: Array[Entity] = []
var wander_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	ParentEntity.add_to_group("swarmer")
	state_timer = Vary(rest_time)
	summon_timer = first_summon_delay
	# copies come from the entity's own scene (can't be an export, a scene can't contain itself)
	if can_summon and ParentEntity.scene_file_path != "":
		summon_scene = load(ParentEntity.scene_file_path)

func _process(delta: float) -> void:
	if not ParentEntity or ParentEntity.is_dead: return
	if ParentEntity.IsStunned():
		UpdateFacing()
		return

	state_timer -= delta
	summon_timer -= delta
	match state:
		State.WALK:
			if CanSummon():
				StartSummon()
			elif state_timer <= 0:
				StartRest()
			else:
				ParentEntity.Move(GetSwarmDirection(delta))
		State.REST:
			if CanSummon():
				StartSummon()
			elif state_timer <= 0:
				StartWalk()
		State.SUMMON:
			if state_timer <= 0:
				Summon()
				StartRest()

	UpdateFacing()

func StartWalk() -> void:
	state = State.WALK
	state_timer = Vary(walk_time)

func StartRest() -> void:
	state = State.REST
	state_timer = Vary(rest_time)
	ParentEntity.Stop()

func StartSummon() -> void:
	state = State.SUMMON
	state_timer = telegraph_duration
	ParentEntity.Stop()
	GlobalMethods.FlashSprite(ParentEntity.sprite, telegraph_duration, telegraph_color)

func CanSummon() -> bool:
	return can_summon and summon_scene != null and summon_timer <= 0 \
		and minions.size() < max_minions and CanFindPlayer()

func Summon() -> void:
	summon_timer = summon_cooldown
	for i in summon_count:
		if minions.size() >= max_minions:
			break
		var minion: Entity = summon_scene.instantiate()
		var minion_brain: SwarmerAI = minion.get_node("Brain")
		minion_brain.can_summon = false
		minion.scale = Vector2.ONE * minion_scale
		var spawn_pos = ParentEntity.global_position + Vector2.from_angle(randf() * TAU) * summon_radius
		ParentEntity.SpawnMinion(minion, spawn_pos)

		# stats exist only after the minion's _ready, Health keeps the ratio so it spawns at full hp
		var hp_mod = StatModifier.new()
		hp_mod.stat = &"max_health"
		hp_mod.multiplier = minion_health_multiplier
		minion.stats.AddModifier(hp_mod, minion_brain)

		minions.append(minion)
		minion.died.connect(_on_minion_died)

func _on_minion_died(minion: Entity) -> void:
	minions.erase(minion)

# chase the player + pull towards nearby swarmers + push away from ones too close
func GetSwarmDirection(delta: float) -> Vector2:
	var pos = ParentEntity.global_position
	var chase: Vector2
	if CanFindPlayer():
		chase = pos.direction_to(NodeReferences.player.global_position)
	else:
		if wander_direction == Vector2.ZERO or randf() < delta:
			wander_direction = Vector2.from_angle(randf() * TAU)
		chase = wander_direction

	var center = Vector2.ZERO
	var count = 0
	var separation = Vector2.ZERO
	for other in get_tree().get_nodes_in_group("swarmer"):
		if other == ParentEntity or other.is_dead:
			continue
		var dist = pos.distance_to(other.global_position)
		if dist > neighbor_radius:
			continue
		center += other.global_position
		count += 1
		if dist < separation_radius and dist > 0.01:
			separation += other.global_position.direction_to(pos) * (1.0 - dist / separation_radius)

	# weaker pull the closer it already is to the group's center
	var cohesion = Vector2.ZERO
	if count > 0:
		cohesion = ((center / count - pos) / neighbor_radius).limit_length(1.0)

	return (chase * chase_weight + cohesion * cohesion_weight + separation * separation_weight).normalized()

func CanFindPlayer() -> bool:
	if not NodeReferences.player: return false
	return ParentEntity.CanSeePlayer() if needs_line_of_sight else true

func Vary(value: float) -> float:
	return maxf(0.05, value + randf_range(-time_variation, time_variation))

func UpdateFacing() -> void:
	var vx = ParentEntity.move_velocity.x
	if vx < -0.01:
		ParentEntity.sprite.flip_h = true
	elif vx > 0.01:
		ParentEntity.sprite.flip_h = false
