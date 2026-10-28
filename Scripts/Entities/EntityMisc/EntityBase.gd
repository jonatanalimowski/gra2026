extends CharacterBody2D
class_name Entity

signal died(entity: Entity)
# a brain spawned another enemy (SpawnMinion), the room counts it too
signal summoned(minion: Entity)

@onready var hp_label: Label = $Control/HpLabel
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var brain = $Brain
@onready var melee_range: Area2D = $Area2D
@export var base_stats: EntityStats
@export var corpse_scene: PackedScene
@export var damage_number_scene: PackedScene
# how often touching the player deals damage
@export var contact_damage_interval: float = 1.0
# death anim frames can be a different size than idle/moving, override the sprite offset to realign them
@export var override_death_offset: bool = false
@export var death_offset: Vector2 = Vector2.ZERO
# knockback: how fast a push dies out and the fastest it can stack up to
@export var knockback_friction: float = 900.0
@export var max_knockback_speed: float = 300.0
# hitstun: brain is paused this long after a push, then can't be stunned again for hitstun_cooldown
@export var hitstun_duration: float = 0.15
@export var hitstun_cooldown: float = 0.6
# optional ranged attack, the brain decides when to call Shoot(). fired from a "Muzzle" Marker2D if there is one
@export var spell: SpellData
# extra projectile effects added to every shot (elites, curses)
@export var effects: Array[Effect] = []
# can't shoot this long after spawning, so a room doesn't open with a volley
@export var spawn_shoot_delay: float = 1.0
var spell_caster: SpellCaster
var stats: StatBlock
var health: Health
var is_boss = false
var is_dead: bool = false
var contact_damage_cooldown: float = 0.0
var move_velocity: Vector2 = Vector2.ZERO # what the brain wants
var knockback_velocity: Vector2 = Vector2.ZERO # what hits did to us
var hitstun_timer: float = 0.0
var hitstun_immunity_timer: float = 0.0
var spawn_shoot_timer: float = 0.0
var last_hit: DamageInfo

func _ready() -> void:
	stats = StatBlock.FromResource(base_stats)
	if spell:
		spell_caster = SpellCaster.new(spell, [])
	# pact/oath enemy modifiers (enemies +hp etc.), before Health so max_health includes them
	for half in RunState.halves:
		ApplyRunHalf(half)
	health = Health.new(stats.GetStat(&"max_health"))
	health.changed.connect(_on_health_changed)
	health.died.connect(Die)
	stats.stat_changed.connect(_on_stat_changed)
	# live enemies follow pacts taken / curses cleansed mid-room
	RunState.half_added.connect(ApplyRunHalf)
	RunState.half_removed.connect(_on_run_half_removed)
	spawn_shoot_timer = spawn_shoot_delay
	sprite.play("idle")
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	hitstun_timer -= delta
	hitstun_immunity_timer -= delta
	spawn_shoot_timer -= delta
	if spell_caster:
		spell_caster.Tick(delta)
	velocity = move_velocity + knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	HandleContactDamage(delta)

func HandleContactDamage(delta: float) -> void:
	contact_damage_cooldown -= delta
	if contact_damage_cooldown > 0:
		return

	for body in melee_range.get_overlapping_bodies():
		if body.has_method("TakeDamage") and body.is_in_group("player"):
			body.TakeDamage(DamageInfo.new(stats.GetStat(&"attack_damage"), self))
			contact_damage_cooldown = contact_damage_interval
			return

#func _process(delta: float) -> void:
	#if stats:
		#hp_label.text = str(health.current) + "/" + str(health.maximum)

# casts `spell` towards direction. false = no spell, on cooldown or dead
func Shoot(direction: Vector2) -> bool:
	if not spell_caster or is_dead or spawn_shoot_timer > 0:
		return false
	var spawn_pos = $Muzzle.global_position if has_node("Muzzle") else global_position
	return spell_caster.TryCast(self, direction, spawn_pos, effects)

# adds an enemy next to this one (same parent as the room's enemies)
func SpawnMinion(minion: Entity, pos: Vector2) -> void:
	minion.global_position = pos
	get_parent().add_child(minion)
	summoned.emit(minion)

func CanShoot() -> bool:
	return spell_caster != null and spell_caster.IsReady() and not is_dead and spawn_shoot_timer <= 0

func Move(direction: Vector2):
	move_velocity = direction * stats.GetStat(&"movement_speed")
	sprite.play("moving")

func Jump(direction: Vector2, duration: float, move_speed: float):
	move_velocity = direction * move_speed
	sprite.play("moving")

	var t = get_tree().create_timer(duration)
	t.timeout.connect(func(): if not is_dead: Stop())

func Stop():
	move_velocity = Vector2.ZERO
	sprite.play("idle")

func TakeDamage(info: DamageInfo) -> void:
	if is_dead:
		return

	# before Damage, a lethal hit calls Die() from inside it
	last_hit = info
	health.Damage(info.amount)

	if not is_dead:
		GlobalMethods.FlashSprite(sprite)
		sprite.play("idle")
		ApplyKnockback(info.knockback)

	#spawning damage number
	if damage_number_scene:
		var dmg_num = damage_number_scene.instantiate()
		get_tree().current_scene.add_child(dmg_num)
		dmg_num.display(info.amount, global_position, info.is_critical)

# resistance 1 or more = unstoppable (bosses, skeleton charge), no push and no hitstun
func ApplyKnockback(knockback: Vector2) -> void:
	var resist = clampf(stats.GetStat(&"knockback_resistance"), 0.0, 1.0)
	if knockback == Vector2.ZERO or resist >= 1.0:
		return

	knockback_velocity = (knockback_velocity + knockback * (1.0 - resist)).limit_length(max_knockback_speed)

	# one stun per window, so a fast fire rate can't keep the enemy frozen
	if hitstun_immunity_timer <= 0:
		hitstun_timer = hitstun_duration
		hitstun_immunity_timer = hitstun_duration + hitstun_cooldown
		Stop()

func IsStunned() -> bool:
	return hitstun_timer > 0

# a modifier goes to whichever block has its stat: max_health -> the enemy,
# projectile_speed -> its spell (so curses can buff enemy shots too)
func ApplyRunHalf(half: PactHalf) -> void:
	for modifier in half.enemy_modifiers:
		if spell_caster and spell_caster.stats.HasStat(modifier.stat):
			spell_caster.stats.AddModifier(modifier, half)
		else:
			stats.AddModifier(modifier, half)

func _on_run_half_removed(half: PactHalf) -> void:
	stats.RemoveModifiersFrom(half)
	if spell_caster:
		spell_caster.stats.RemoveModifiersFrom(half)

func _on_stat_changed(stat_name: StringName, value: float) -> void:
	if stat_name == &"max_health":
		health.SetMaximum(value)

func _on_health_changed(current: float, maximum: float) -> void:
	if is_boss:
		Signals.boss_health_changed.emit(current, maximum)

func Die() -> void:
	if is_dead:
		return

	is_dead = true
	DisableCollisions()
	var corpse: EntityCorpse = corpse_scene.instantiate()
	get_parent().add_child(corpse)
	corpse.SpawnCorpse(self.global_position, sprite, death_offset if override_death_offset else sprite.offset, scale)
	died.emit(self)
	Signals.enemy_killed.emit(self, last_hit)
	if is_boss:
		Signals.boss_defeated.emit()
	queue_free()

func DisableCollisions() -> void:
	if $Area2D/CollisionShape2D:
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
	if $CollisionShape2D:
		$CollisionShape2D.set_deferred("disabled", true)

func CanSeePlayer() -> bool:
	var p = NodeReferences.player
	if p:
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, p.global_position)
		query.exclude = [get_rid()]
		query.collision_mask = 3

		var result = space_state.intersect_ray(query)
		if result:
			return result.collider.is_in_group("player")
	return false
