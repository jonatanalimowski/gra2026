extends CharacterBody2D
class_name Entity

const DEFAULT_ELITE: EliteData = preload("res://Data/Elites/DefaultElite.tres")
const TELEGRAPH_MARK_MARGIN: float = 2.0
# Chill at max stacks freezes (bosses get Brittle instead), then Chill clears and Freeze can't come back for a while
const CHILL_STATUS: StatusEffect = preload("res://Data/Statuses/Chill.tres")
const FREEZE_STATUS: StatusEffect = preload("res://Data/Statuses/Freeze.tres")
const BRITTLE_STATUS: StatusEffect = preload("res://Data/Statuses/Brittle.tres")
const FREEZE_IMMUNITY: float = 3.0
const BURN_STATUS: StatusEffect = preload("res://Data/Statuses/Burn.tres")
const SHOCK_STATUS: StatusEffect = preload("res://Data/Statuses/Shock.tres")
# Kindling curse: Burning enemies move faster
const KINDLING_SPEED: float = 1.15
# Permafrost curse: elites chill the player when close
const CHILL_AURA_RADIUS: float = 70.0
const CHILL_AURA_INTERVAL: float = 0.5
const CHILL_AURA_MAX_STACKS: int = 2

signal died(entity: Entity)
# a brain spawned another enemy (SpawnMinion), the room counts it too
signal summoned(minion: Entity)
# a Jump() ended (Jumper elites fire a ring on landing)
signal landed

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
# elite version: rolled by EnemyRoom, set before add_child so _ready applies it. empty = DEFAULT_ELITE
@export var elite_data: EliteData


var is_elite: bool = false
# set by EnemyRoom before add_child, applied in _ready
var affixes: Array[Affix] = []
var ward_group: StringName = &"" # immune to statuses of this group (Warded affix, Kindled Halls omen)
var is_risen: bool = false # Restless Dead: already came back once
var time_since_damaged: float = 999.0
const REGEN_DELAY: float = 2.0
const REGEN_SHARE_PER_SECOND: float = 0.03
const VOLATILE_DAMAGE: float = 25.0
const VOLATILE_RADIUS: float = 44.0
const EXPLOSION_SCENE_PATH = "res://Scenes/Combat/Explosion.tscn" # load(), not preload: Explosion.gd refers to Entity (cycle)
const SWARMER_SCENE_PATH = "res://Scenes/Entities/FirstFloor/Swarmer.tscn"
const RISEN_HEALTH: float = 0.4
var spell_caster: SpellCaster
var stats: StatBlock
var health: Health
var status_holder: StatusEffectHolder
var is_boss = false
var is_dead: bool = false
var contact_damage_cooldown: float = 0.0
var move_velocity: Vector2 = Vector2.ZERO # what the brain wants
var knockback_velocity: Vector2 = Vector2.ZERO # what hits did to us
var hitstun_timer: float = 0.0
var hitstun_immunity_timer: float = 0.0
# own timers, not hitstun: hitstun is gated by knockback_resistance, so a dashing Charger could never freeze
var freeze_timer: float = 0.0
var freeze_immunity_timer: float = 0.0
var freeze_count: int = 0 # times frozen, Glacier's "first hit on a frozen enemy" checks it
var kindling_mod: StatModifier
var chill_aura_timer: float = 0.0
var spawn_shoot_timer: float = 0.0
var last_hit: DamageInfo
var telegraph_mark: TelegraphMark
var status_visuals: StatusVisuals
var status_icon_bar: StatusIconBar
# GetSpriteTop per frame texture, get_image() is too slow to call every frame
static var sprite_top_cache: Dictionary = {}

func _ready() -> void:
	stats = StatBlock.FromResource(base_stats)
	status_holder = StatusEffectHolder.new()
	add_child(status_holder)
	status_holder.status_added.connect(_on_status_changed)
	status_holder.status_changed.connect(_on_status_changed)
	status_holder.status_added.connect(_on_status_added_or_removed)
	status_holder.status_removed.connect(_on_status_added_or_removed)
	kindling_mod = StatModifier.new()
	kindling_mod.stat = &"movement_speed"
	kindling_mod.multiplier = KINDLING_SPEED
	if spell:
		spell_caster = SpellCaster.new(spell, [])
	if is_elite:
		ApplyElite()
	for affix in affixes:
		for modifier in affix.modifiers:
			AddEnemyModifier(modifier, affix)
	if ward_group == &"":
		ward_group = RunState.GetOmenWardGroup()
	# deeper floors = tougher enemies
	for modifier in RunState.floor_modifier.GetEnemyModifiers(RunState.floor_number):
		AddEnemyModifier(modifier, RunState)
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
	# outline + body effects and the icon bar above the head
	status_visuals = StatusVisuals.new()
	add_child(status_visuals)
	status_visuals.Setup(self)
	status_icon_bar = StatusIconBar.new()
	add_child(status_icon_bar)
	status_icon_bar.Setup(self)

func _physics_process(delta: float) -> void:
	hitstun_timer -= delta
	hitstun_immunity_timer -= delta
	freeze_timer -= delta
	freeze_immunity_timer -= delta
	time_since_damaged += delta
	if time_since_damaged > REGEN_DELAY and HasAffix(Affix.Kind.REGENERATING) and not is_dead:
		health.Heal(health.maximum * REGEN_SHARE_PER_SECOND * delta, false)
	spawn_shoot_timer -= delta
	if spell_caster:
		spell_caster.Tick(delta)
	# frozen = stands still even if a brain timer sets move_velocity, but can still be pushed
	velocity = (Vector2.ZERO if IsFrozen() else move_velocity) + knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	if not IsFrozen():
		HandleContactDamage(delta)
	if is_elite:
		HandleChillAura(delta)

func HandleChillAura(delta: float) -> void:
	chill_aura_timer -= delta
	if chill_aura_timer > 0 or not RunState.HasFlag(&"elite_chill_aura"):
		return
	chill_aura_timer = CHILL_AURA_INTERVAL
	var player = NodeReferences.player
	if player and global_position.distance_to(player.global_position) < CHILL_AURA_RADIUS * scale.x:
		if player.status_holder.GetStacks(CHILL_STATUS) < CHILL_AURA_MAX_STACKS:
			player.ApplyStatus(CHILL_STATUS, self)

# Kindling curse: speed bonus while Burning. the modifier itself is the source
func _on_status_added_or_removed(status: ActiveStatusEffect) -> void:
	if status.effect != BURN_STATUS:
		return
	stats.RemoveModifiersFrom(kindling_mod)
	if status_holder.Has(BURN_STATUS) and RunState.HasFlag(&"kindling"):
		stats.AddModifier(kindling_mod, kindling_mod)

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
	if not spell_caster or is_dead or spawn_shoot_timer > 0 or IsFrozen():
		return false
	var spawn_pos = $Muzzle.global_position if has_node("Muzzle") else global_position
	var cast = spell_caster.TryCast(self, direction, spawn_pos, effects)
	if cast:
		Sfx.Play(&"enemy/shoot", -20.0)
	return cast

func SpawnMinion(minion: Entity, pos: Vector2, summon_radius: float) -> void:
	var found_pos = FindSpawnPosition(minion, pos, summon_radius)
	if found_pos == Vector2.ZERO:
		return
	minion.global_position = found_pos
	get_parent().add_child(minion)
	summoned.emit(minion)

func FindSpawnPosition(minion: Entity, target: Vector2, summon_radius: float) -> Vector2:
	var shape_node: CollisionShape2D = minion.get_node_or_null("CollisionShape2D")
	if not shape_node or not shape_node.shape:
		return target
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape_node.shape
	query.collision_mask = BaseProjectile.LAYER_WORLD
	var offset = shape_node.position * minion.scale
	
	for i in range(8):
		var test_pos = target if i == 0 else global_position + Vector2.from_angle(randf() * TAU) * randf_range(0.2, 1.0) * summon_radius
		query.transform = Transform2D(0, minion.scale, 0, test_pos + offset)
		if get_world_2d().direct_space_state.intersect_shape(query).is_empty():
			return test_pos
			
	return Vector2.ZERO

func CanShoot() -> bool:
	return spell_caster != null and spell_caster.IsReady() and not is_dead and spawn_shoot_timer <= 0 and not IsFrozen()

func Move(direction: Vector2):
	move_velocity = direction * stats.GetStat(&"movement_speed")
	sprite.play("moving")

func Jump(direction: Vector2, duration: float, move_speed: float):
	move_velocity = direction * move_speed
	sprite.play("moving")

	var t = get_tree().create_timer(duration)
	t.timeout.connect(func():
		if not is_dead:
			Stop()
			landed.emit())

func Stop():
	move_velocity = Vector2.ZERO
	sprite.play("idle")

func TakeDamage(info: DamageInfo) -> void:
	if is_dead:
		return

	# Brittle etc. local copy, the same DamageInfo may be read again by on-hit effects
	var amount = info.amount * stats.GetStat(&"damage_taken")
	# a real hit on a Shocked enemy discharges it (ticks and arcs don't)
	var discharge = not info.is_periodic and not info.is_arc and status_holder.Has(SHOCK_STATUS)
	# before Damage, a lethal hit calls Die() from inside it
	last_hit = info
	var hp_before = health.current
	time_since_damaged = 0.0
	health.Damage(amount)
	Signals.enemy_damaged.emit(self, info, hp_before - health.current)
	if discharge:
		if not is_dead:
			status_holder.RemoveEffect(SHOCK_STATUS)
		ChainArc.Discharge(self, amount)

	# status ticks don't flinch, sprite.play would restart the animation on every tick
	if not is_dead and not info.is_periodic:
		GlobalMethods.FlashSprite(sprite)
		sprite.play("idle")
		ApplyKnockback(info.knockback)

	# ticks: small number in the status color instead of a flash, none under 1 so DoTs don't spam zeros
	if damage_number_scene and (not info.is_periodic or amount >= 1.0):
		var dmg_num = damage_number_scene.instantiate()
		get_tree().current_scene.add_child(dmg_num)
		var color = info.status.color if info.status else Color.WHITE
		dmg_num.display(amount, global_position, info.is_critical, color, info.is_periodic)

func ApplyStatus(effect: StatusEffect, source: Node2D, strength: float = 1.0, duration_multiplier: float = 1.0, stacks: int = 1) -> void:
	if not is_dead:
		status_holder.Apply(effect, source, strength, duration_multiplier, stacks)

# Chill reaching max stacks: freeze (or Brittle on bosses), clear Chill. while immune it just sits at max
func _on_status_changed(status: ActiveStatusEffect) -> void:
	if RunState.HasFlag(&"thermal_shock") and (status.effect == BURN_STATUS or status.effect == CHILL_STATUS):
		CheckThermalShock.call_deferred()
	if is_dead or status.effect != CHILL_STATUS or status.stacks < GetFreezeThreshold():
		return
	if freeze_immunity_timer > 0:
		return
	var source = status.GetSource()
	# deferred: we're inside StatusEffectHolder.Apply, removing statuses mid-call is asking for trouble
	call_deferred("Freeze", source)

func Freeze(source: Node2D = null) -> void:
	if is_dead or freeze_immunity_timer > 0:
		return
	status_holder.RemoveEffect(CHILL_STATUS)
	if is_boss:
		freeze_immunity_timer = BRITTLE_STATUS.duration
		ApplyStatus(BRITTLE_STATUS, source)
		return
	freeze_timer = FREEZE_STATUS.duration
	freeze_immunity_timer = FREEZE_STATUS.duration + FREEZE_IMMUNITY
	freeze_count += 1
	Stop()
	ApplyStatus(FREEZE_STATUS, source)
	Signals.enemy_frozen.emit(self)

# Thermal Shock duo: Burning + Chilled = a burst of 40 + 10 per stack of both, and both clear
const THERMAL_SHOCK_BASE: float = 40.0
const THERMAL_SHOCK_PER_STACK: float = 10.0
func CheckThermalShock() -> void:
	if is_dead or not status_holder.Has(BURN_STATUS) or not status_holder.Has(CHILL_STATUS):
		return
	var stacks = status_holder.GetStacks(BURN_STATUS) + status_holder.GetStacks(CHILL_STATUS)
	status_holder.RemoveEffect(BURN_STATUS)
	status_holder.RemoveEffect(CHILL_STATUS)
	var info = DamageInfo.new(THERMAL_SHOCK_BASE + THERMAL_SHOCK_PER_STACK * stacks, NodeReferences.player)
	info.element = &"thermal"
	info.is_critical = true # gold number, it's a payoff
	TakeDamage(info)
	var ring = NovaRing.new()
	ring.radius = 28.0
	ring.color = Color(1.0, 0.6, 0.9)
	ring.global_position = global_position
	get_tree().current_scene.add_child(ring)

# Chill stacks that freeze: max stacks, 1 less per Deep Cold glyph (never below 2)
func GetFreezeThreshold() -> int:
	return maxi(status_holder.GetMaxStacks(CHILL_STATUS) - RunState.CountFlag(&"deep_cold"), 2)

func IsFrozen() -> bool:
	return freeze_timer > 0

# resistance 1 or more = unstoppable (bosses, charger dash), no push and no hitstun
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
	return hitstun_timer > 0 or IsFrozen()

# "!" over the head for a brain's windup. a new one replaces the old one
func ShowTelegraphMark(duration: float) -> void:
	if is_instance_valid(telegraph_mark):
		telegraph_mark.queue_free()
	telegraph_mark = TelegraphMark.new()
	telegraph_mark.position = Vector2(0, GetSpriteTop() - TELEGRAPH_MARK_MARGIN)
	add_child(telegraph_mark)
	telegraph_mark.Show(duration)

# top of the visible pixels: frames differ in size per enemy and often have empty space above the art
func GetSpriteTop() -> float:
	var texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not texture:
		return sprite.position.y
	if not sprite_top_cache.has(texture):
		sprite_top_cache[texture] = texture.get_image().get_used_rect().position.y
	var frame_top = sprite.offset.y - (texture.get_height() / 2.0 if sprite.centered else 0.0)
	var top = frame_top + sprite_top_cache[texture]
	return sprite.position.y + top * sprite.scale.y

# a modifier goes to whichever block has its stat: max_health -> the enemy,
# projectile_speed -> its spell (so curses can buff enemy shots too)
func ApplyRunHalf(half: PactHalf) -> void:
	for modifier in half.enemy_modifiers:
		AddEnemyModifier(modifier, half)

# stats neither block has are skipped (spell damage on an enemy that doesn't shoot)
func AddEnemyModifier(modifier: StatModifier, source: Object) -> void:
	if spell_caster and spell_caster.stats.HasStat(modifier.stat):
		spell_caster.stats.AddModifier(modifier, source)
	elif stats.HasStat(modifier.stat):
		stats.AddModifier(modifier, source)

# tougher, faster, hits harder, bigger and tinted so it reads as a threat
func ApplyElite() -> void:
	var data := elite_data if elite_data else DEFAULT_ELITE
	for modifier in data.modifiers:
		AddEnemyModifier(modifier, data)
	scale *= data.scale
	sprite.self_modulate = data.color
	# elites feed the build: double mana (and they raise the room's glyph chance, see EnemyRoom)
	var mana_mod = StatModifier.new()
	mana_mod.stat = &"mana_drop"
	mana_mod.multiplier = 2.0
	stats.AddModifier(mana_mod, data)

func HasAffix(kind: Affix.Kind) -> bool:
	for affix in affixes:
		if affix.kind == kind:
			return true
	return false

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
	if HasAffix(Affix.Kind.VOLATILE):
		SpawnVolatileExplosion()
	# Restless Dead omen: rises once as a weak Swarmer. before died.emit, so the room counts it first
	if RunState.HasFlag(&"restless_dead") and not is_risen and not is_boss and scene_file_path != SWARMER_SCENE_PATH:
		RiseAgain()
	# set up before it's in the tree, then added deferred: Die() can run while the parent
	# is busy adding/removing children, and add_child would fail (corpse never ready)
	var corpse: EntityCorpse = corpse_scene.instantiate()
	var parent = get_parent()
	if is_instance_valid(parent) and is_instance_valid(corpse):
		corpse.SpawnCorpse(parent.to_local(global_position), sprite, death_offset if override_death_offset else sprite.offset, scale)
		parent.add_child.call_deferred(corpse)
		ManaOrb.SpawnBurst(get_tree().current_scene, global_position, stats.GetStat(&"mana_drop"))
	died.emit(self)
	Signals.enemy_killed.emit(self, last_hit, base_stats.experience_drop, is_elite)
	if is_boss:
		Signals.boss_defeated.emit()
	queue_free()

# Volatile affix: a telegraphed blast where it died, hurts only the player
func SpawnVolatileExplosion() -> void:
	var explosion = load(EXPLOSION_SCENE_PATH).instantiate()
	explosion.Setup(VOLATILE_DAMAGE * RunState.floor_modifier.GetDamageScale(RunState.floor_number), VOLATILE_RADIUS, null)
	explosion.hits_player = true
	explosion.hits_enemies = false
	explosion.global_position = global_position
	get_tree().current_scene.add_child.call_deferred(explosion)

func RiseAgain() -> void:
	var risen: Entity = load(SWARMER_SCENE_PATH).instantiate()
	risen.is_risen = true
	risen.get_node("Brain").can_summon = false
	risen.scale = Vector2.ONE * 0.8
	risen.modulate = Color(0.6, 0.7, 0.6)
	# counted by the room right now (before our died signal), added to the scene next frame:
	# a deferred call on us would be dropped, we're freed at the end of this frame
	risen.global_position = FindSpawnPosition(risen, global_position, 0)
	get_parent().add_child.call_deferred(risen)
	summoned.emit(risen)
	# hp after its _ready (Health keeps the ratio)
	risen.ready.connect(func():
		var mod = StatModifier.new()
		mod.stat = &"max_health"
		mod.multiplier = RISEN_HEALTH
		risen.stats.AddModifier(mod, risen))

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
