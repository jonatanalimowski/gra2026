extends CharacterBody2D
class_name Entity

@onready var hp_label: Label = $Control/HpLabel
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var brain = $Brain
@onready var melee_range = $Area2D
@export var stats: EntityStats
@export var corpse_scene: PackedScene
@export var damage_number_scene: PackedScene

var is_dead: bool = false

func _ready() -> void:
	stats = stats.duplicate()
	stats.current_health = stats.max_health
	melee_range.body_entered.connect(_on_body_entered)
	sprite.play("idle")
	add_to_group("enemy")

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("TakeDamage") and body.is_in_group("player"):
		body.TakeDamage(stats.attack_damage)

func _physics_process(delta: float) -> void:
	move_and_slide()

#func _process(delta: float) -> void:
	#if stats:
		#hp_label.text = str(stats.current_health) + "/" + str(stats.max_health)

#func Shoot()

func Move(direction: Vector2):
	velocity = direction * stats.movement_speed
	sprite.play("moving")

func Jump(direction: Vector2, duration: float, move_speed = stats.movement_speed):
	velocity = direction * move_speed
	sprite.play("moving")
	
	var t = get_tree().create_timer(duration)
	t.timeout.connect(func(): if not is_dead: Stop())

func Stop():
	velocity = Vector2.ZERO
	sprite.play("idle")

func TakeDamage(amount: float) -> void:
	if is_dead:
		return
	
	if stats.current_health - amount <= 0:
		stats.current_health = 0
		Die()
	else:
		stats.current_health -= amount
		GlobalMethods.FlashSprite(sprite)
		sprite.play("idle")
	
	#spawning damage number
	if damage_number_scene:
		var dmg_num = damage_number_scene.instantiate()
		get_tree().current_scene.add_child(dmg_num)
		dmg_num.display(amount, global_position)

func Die() -> void:
	if is_dead == false:
		is_dead = true
		DisableCollisions()
		var corpse: EntityCorpse = corpse_scene.instantiate()
		get_parent().add_child(corpse)
		corpse.SpawnCorpse(self.global_position, sprite.sprite_frames) 
		Signals.enemy_killed.emit()
		queue_free()

func DisableCollisions() -> void:
	if $Area2D/CollisionShape2D:
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
	if $CollisionShape2D:
		$CollisionShape2D.set_deferred("disabled", true)
