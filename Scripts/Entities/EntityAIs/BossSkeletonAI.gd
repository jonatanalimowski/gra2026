extends Node
class_name BossSkeletonAI

# skeleton mage boss: strafes around the player at a distance, then picks one of three attacks
# (never the same twice in a row), telegraphs it with a colored flash and fires it in steps:
# RING = bullet hell waves in every direction, SNIPE = fast aimed shots, BOMBS = explosions around the player.
# below enrage_threshold hp everything is faster (rests, telegraphs, steps) and attacks get extra steps
@onready var ParentEntity: Entity = get_parent()
@export_group("Movement")
@export var rest_time: float = 1.4 # repositioning between attacks
@export var preferred_distance: float = 130.0
@export var distance_tolerance: float = 25.0
@export var strafe_speed_multiplier: float = 0.7
@export var strafe_switch_chance: float = 0.4 # per second
@export_group("Ring")
@export var ring_spell: SpellData = preload("res://Data/Spells/BossSkeletonRingSpell.tres")
@export var ring_projectiles: int = 16 # per wave
@export var ring_waves: int = 3
@export var ring_wave_interval: float = 0.35
@export var ring_telegraph_color: Color = Color.MEDIUM_PURPLE
@export_group("Snipe")
@export var snipe_spell: SpellData = preload("res://Data/Spells/BossSkeletonSnipeSpell.tres")
@export var snipe_shots: int = 3
@export var snipe_interval: float = 0.3
@export var snipe_telegraph_color: Color = Color.ORANGE_RED
@export_group("Bombs")
@export var explosion_scene: PackedScene = preload("res://Scenes/Combat/Explosion.tscn")
@export var explosion_count: int = 5 # the first one lands right on the player
@export var explosion_interval: float = 0.15
@export var explosion_spread: float = 70.0 # max distance from the player
@export var explosion_damage: float = 20.0
@export var explosion_radius: float = 28.0
@export var explosion_telegraph_time: float = 0.8
@export var bombs_telegraph_color: Color = Color(1, 0.85, 0.2)
@export_group("Telegraph")
@export var telegraph_duration: float = 0.7
@export_group("Enrage")
@export_range(0.0, 1.0) var enrage_threshold: float = 0.5 # fraction of max hp
@export var enraged_speed_multiplier: float = 0.6 # on rest, telegraph and step intervals
@export var enraged_extra_steps: int = 1 # +1 ring wave / snipe shot / explosion... per attack
@export var enrage_color: Color = Color(1, 0.3, 0.3)

enum State { REPOSITION, TELEGRAPH, ATTACK }
enum Attack { RING, SNIPE, BOMBS }
var state: State = State.REPOSITION
var state_timer: float = 0.0
var attack: Attack
var last_attack: int = -1
var steps_left: int = 0
var step_index: int = 0
var strafe_direction: float = 1.0
var is_enraged: bool = false
var ring_caster: SpellCaster
var snipe_caster: SpellCaster

func _ready() -> void:
	# the entity's _ready runs after ours, health/stats don't exist yet
	ParentEntity.ready.connect(_on_parent_ready)
	strafe_direction = [-1.0, 1.0].pick_random()
	state_timer = rest_time

func _on_parent_ready() -> void:
	ParentEntity.health.changed.connect(_on_health_changed)
	ring_caster = SpellCaster.new(ring_spell, [])
	snipe_caster = SpellCaster.new(snipe_spell, [])
	# pact enemy modifiers (e.g. faster enemy shots) like Entity.ApplyRunHalf does for its own spell
	for half in RunState.halves:
		for modifier in half.enemy_modifiers:
			for caster in [ring_caster, snipe_caster]:
				if caster.stats.HasStat(modifier.stat):
					caster.stats.AddModifier(modifier, half)

func _process(delta: float) -> void:
	if not ParentEntity or ParentEntity.is_dead or ParentEntity.IsStunned(): return

	state_timer -= delta
	match state:
		State.REPOSITION:
			Reposition(delta)
			if state_timer <= 0 and NodeReferences.player:
				StartTelegraph()
		State.TELEGRAPH:
			if state_timer <= 0:
				StartAttack()
		State.ATTACK:
			if state_timer <= 0:
				AttackStep()

	UpdateFacing()

func Reposition(delta: float) -> void:
	var p = NodeReferences.player
	if not p:
		ParentEntity.Stop()
		return
	if randf() < strafe_switch_chance * delta:
		strafe_direction *= -1

	var distance = ParentEntity.global_position.distance_to(p.global_position)
	var to_player = ParentEntity.global_position.direction_to(p.global_position)
	var radial = 0.0
	if distance > preferred_distance + distance_tolerance:
		radial = 1.0
	elif distance < preferred_distance - distance_tolerance:
		radial = -1.0
	var tangent = to_player.orthogonal() * strafe_direction * strafe_speed_multiplier
	ParentEntity.Move((to_player * radial + tangent).limit_length(1.0))

func StartTelegraph() -> void:
	var options = Attack.values().filter(func(a): return a != last_attack)
	attack = options.pick_random()
	last_attack = attack
	state = State.TELEGRAPH
	state_timer = telegraph_duration * GetSpeedMultiplier()
	ParentEntity.Stop()
	var color = [ring_telegraph_color, snipe_telegraph_color, bombs_telegraph_color][attack]
	GlobalMethods.FlashSprite(ParentEntity.sprite, state_timer, color)
	Sfx.Play(&"enemy/charge_telegraph", -10.0)

func StartAttack() -> void:
	state = State.ATTACK
	state_timer = 0.0
	step_index = 0
	var extra = enraged_extra_steps if is_enraged else 0
	match attack:
		Attack.RING: steps_left = ring_waves + extra
		Attack.SNIPE: steps_left = snipe_shots + extra
		Attack.BOMBS: steps_left = explosion_count + extra * 2

func AttackStep() -> void:
	var p = NodeReferences.player
	if steps_left <= 0 or not p:
		StartReposition()
		return

	var interval: float
	match attack:
		Attack.RING:
			FireRing()
			interval = ring_wave_interval
		Attack.SNIPE:
			Fire(snipe_caster, ParentEntity.global_position.direction_to(p.global_position))
			Sfx.Play(&"enemy/shoot", -12.0)
			interval = snipe_interval
		Attack.BOMBS:
			SpawnExplosion()
			interval = explosion_interval
	steps_left -= 1
	step_index += 1
	state_timer = interval * GetSpeedMultiplier()

func StartReposition() -> void:
	state = State.REPOSITION
	state_timer = rest_time * GetSpeedMultiplier()

# every other wave is turned half a gap, so standing in a gap doesn't work twice
func FireRing() -> void:
	var step = TAU / ring_projectiles
	var start = step * 0.5 * (step_index % 2)
	for i in ring_projectiles:
		Fire(ring_caster, Vector2.from_angle(start + step * i))
	Sfx.Play(&"enemy/shoot", -14.0)

# the casters are only used for their stats and projectile setup, the AI does the timing
func Fire(caster: SpellCaster, direction: Vector2) -> void:
	var spawn_pos = ParentEntity.get_node("Muzzle").global_position if ParentEntity.has_node("Muzzle") else ParentEntity.global_position
	caster.cooldown_left = 0.0
	caster.TryCast(ParentEntity, direction, spawn_pos, ParentEntity.effects)

func SpawnExplosion() -> void:
	var pos = NodeReferences.player.global_position
	if step_index > 0:
		pos += Vector2.from_angle(randf() * TAU) * randf_range(explosion_radius, explosion_spread)
	var explosion: Explosion = explosion_scene.instantiate()
	explosion.Setup(explosion_damage, explosion_radius, ParentEntity)
	explosion.hits_enemies = false # would hurt the boss itself
	explosion.telegraph_time = explosion_telegraph_time
	explosion.global_position = pos
	ParentEntity.get_tree().current_scene.add_child(explosion)

func GetSpeedMultiplier() -> float:
	return enraged_speed_multiplier if is_enraged else 1.0

func _on_health_changed(current: float, maximum: float) -> void:
	if is_enraged or current <= 0 or current > maximum * enrage_threshold:
		return
	is_enraged = true
	GlobalMethods.FlashSprite(ParentEntity.sprite, 0.6, enrage_color)
	# keep it tinted so the player can tell the phase changed
	ParentEntity.sprite.self_modulate = enrage_color.lerp(Color.WHITE, 0.5)

func UpdateFacing() -> void:
	var p = NodeReferences.player
	if state != State.REPOSITION and p:
		ParentEntity.sprite.flip_h = p.global_position.x < ParentEntity.global_position.x
		return
	var vx = ParentEntity.move_velocity.x
	if vx < -0.01:
		ParentEntity.sprite.flip_h = true
	elif vx > 0.01:
		ParentEntity.sprite.flip_h = false
