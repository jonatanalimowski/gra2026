extends Node
class_name SlimeBossAI

# slime king: hops at the player, every few hops a telegraphed super jump straight at them,
# every so often stops to summon regular slimes. below enrage_threshold hp it rests less,
# jumps faster and super jumps more often. its slimes die with it
@onready var ParentEntity: Entity = get_parent()
@export_group("Jumping")
@export var jump_duration: float = 0.5
@export var rest_time: float = 0.5 # wait between actions
@export var movement_direction_offset: float = 30.0 # random spread on normal jumps
@export var jumps_between_super: int = 2
@export var super_jump_duration_multiplier: float = 1.5
@export var super_jump_speed_multiplier: float = 2.5
@export var super_telegraph_color: Color = Color(1, 0.65, 0)
@export var super_telegraph_duration: float = 0.75
@export_group("Enrage")
@export_range(0.0, 1.0) var enrage_threshold: float = 0.5 # fraction of max hp
@export var enraged_rest_multiplier: float = 0.4
@export var enraged_speed_multiplier: float = 1.3
@export var enraged_jumps_between_super: int = 1
@export var enraged_telegraph_multiplier: float = 0.7
@export var enrage_color: Color = Color(1, 0.3, 0.3)
@export_group("Summoning")
@export var minion_scene: PackedScene = preload("res://Scenes/BaseScenes/enemy_entity.tscn")
@export var summon_count: int = 2
@export var summon_cooldown: float = 6.0
@export var first_summon_delay: float = 3.0
@export var max_minions: int = 6 # alive at once
@export var summon_radius: float = 40.0
@export var summon_telegraph_color: Color = Color.LIME_GREEN
@export var summon_telegraph_duration: float = 0.6

enum State { REST, JUMP, SUPER_TELEGRAPH, SUMMON_TELEGRAPH }
var state: State = State.REST
var state_timer: float = 0.0
var summon_timer: float = 0.0
var jump_counter: int = 0
var is_enraged: bool = false
var minions: Array[Entity] = []

func _ready() -> void:
	# the entity's _ready runs after ours, health doesn't exist yet
	ParentEntity.ready.connect(_on_parent_ready)
	ParentEntity.died.connect(_on_boss_died)
	state_timer = rest_time
	summon_timer = first_summon_delay

func _on_parent_ready() -> void:
	ParentEntity.health.changed.connect(_on_health_changed)

func _process(delta: float) -> void:
	if not ParentEntity or ParentEntity.is_dead or ParentEntity.IsStunned(): return

	state_timer -= delta
	summon_timer -= delta
	if state_timer > 0:
		return

	match state:
		State.REST:
			ChooseAction()
		State.JUMP:
			StartRest()
		State.SUPER_TELEGRAPH:
			SuperJump()
		State.SUMMON_TELEGRAPH:
			Summon()
			StartRest()

func ChooseAction() -> void:
	if CanSummon():
		StartTelegraph(State.SUMMON_TELEGRAPH, summon_telegraph_duration, summon_telegraph_color)
		Sfx.Play(&"enemy/summon", -6.0)
	elif jump_counter >= GetJumpsBetweenSuper():
		StartTelegraph(State.SUPER_TELEGRAPH, super_telegraph_duration, super_telegraph_color)
	else:
		Jump()

func StartRest() -> void:
	state = State.REST
	state_timer = rest_time * (enraged_rest_multiplier if is_enraged else 1.0)
	ParentEntity.Stop()

func StartTelegraph(next_state: State, duration: float, color: Color) -> void:
	state = next_state
	state_timer = duration * (enraged_telegraph_multiplier if is_enraged else 1.0)
	ParentEntity.Stop()
	GlobalMethods.FlashSprite(ParentEntity.sprite, state_timer, color)

func Jump() -> void:
	var offset = deg_to_rad(randf_range(-movement_direction_offset, movement_direction_offset))
	ParentEntity.Jump(GetDirectionToPlayer().rotated(offset), jump_duration, GetJumpSpeed())
	Sfx.Play(&"enemy/slime_jump", -16.0)
	state = State.JUMP
	state_timer = jump_duration
	jump_counter += 1

func SuperJump() -> void:
	var duration = jump_duration * super_jump_duration_multiplier
	ParentEntity.Jump(GetDirectionToPlayer(), duration, GetJumpSpeed() * super_jump_speed_multiplier)
	Sfx.Play(&"enemy/slime_jump", -6.0)
	state = State.JUMP
	state_timer = duration
	jump_counter = 0

func GetJumpSpeed() -> float:
	return ParentEntity.stats.GetStat(&"movement_speed") * (enraged_speed_multiplier if is_enraged else 1.0)

func GetJumpsBetweenSuper() -> int:
	return enraged_jumps_between_super if is_enraged else jumps_between_super

func CanSummon() -> bool:
	return minion_scene != null and summon_timer <= 0 and minions.size() < max_minions

func Summon() -> void:
	summon_timer = summon_cooldown
	for i in summon_count:
		if minions.size() >= max_minions:
			break
		var minion: Entity = minion_scene.instantiate()
		var spawn_pos = ParentEntity.global_position + Vector2.from_angle(randf() * TAU) * summon_radius
		ParentEntity.SpawnMinion(minion, spawn_pos)
		minions.append(minion)
		minion.died.connect(_on_minion_died)

func _on_minion_died(minion: Entity) -> void:
	minions.erase(minion)

func _on_boss_died(_boss: Entity) -> void:
	# a copy, each Die() erases itself from minions
	for minion in minions.duplicate():
		if is_instance_valid(minion):
			minion.Die()

func _on_health_changed(current: float, maximum: float) -> void:
	if is_enraged or current <= 0 or current > maximum * enrage_threshold:
		return
	is_enraged = true
	GlobalMethods.FlashSprite(ParentEntity.sprite, 0.6, enrage_color)
	# keep it tinted so the player can tell the phase changed
	ParentEntity.sprite.self_modulate = enrage_color.lerp(Color.WHITE, 0.5)

func GetDirectionToPlayer() -> Vector2:
	if not NodeReferences.player:
		return Vector2.from_angle(randf() * TAU)
	return ParentEntity.global_position.direction_to(NodeReferences.player.global_position)
