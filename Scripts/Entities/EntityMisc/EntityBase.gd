extends CharacterBody2D
class_name Entity

signal died(entity: Entity)

@onready var hp_label: Label = $Control/HpLabel
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var brain = $Brain
@onready var melee_range: Area2D = $Area2D
@export var base_stats: EntityStats
@export var corpse_scene: PackedScene
@export var damage_number_scene: PackedScene
# how often touching the player deals damage
@export var contact_damage_interval: float = 1.0
var stats: StatBlock
var health: Health
var is_boss = false
var is_dead: bool = false
var contact_damage_cooldown: float = 0.0

func _ready() -> void:
	stats = StatBlock.FromResource(base_stats)
	health = Health.new(stats.GetStat(&"max_health"))
	health.changed.connect(_on_health_changed)
	health.died.connect(Die)
	sprite.play("idle")
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	move_and_slide()
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

#func Shoot()

func Move(direction: Vector2):
	velocity = direction * stats.GetStat(&"movement_speed")
	sprite.play("moving")

func Jump(direction: Vector2, duration: float, move_speed: float):
	velocity = direction * move_speed
	sprite.play("moving")

	var t = get_tree().create_timer(duration)
	t.timeout.connect(func(): if not is_dead: Stop())

func Stop():
	velocity = Vector2.ZERO
	sprite.play("idle")

func TakeDamage(info: DamageInfo) -> void:
	if is_dead:
		return

	health.Damage(info.amount)
	if not is_dead:
		GlobalMethods.FlashSprite(sprite)
		sprite.play("idle")

	#spawning damage number
	if damage_number_scene:
		var dmg_num = damage_number_scene.instantiate()
		get_tree().current_scene.add_child(dmg_num)
		dmg_num.display(info.amount, global_position, info.is_critical)

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
	corpse.SpawnCorpse(self.global_position, sprite.sprite_frames)
	died.emit(self)
	Signals.enemy_killed.emit(self)
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
