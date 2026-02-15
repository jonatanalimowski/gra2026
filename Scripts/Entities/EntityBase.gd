extends CharacterBody2D
class_name Entity

@onready var hp_label: Label = $Control/HpLabel
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var brain = $Brain
@onready var melee_range = $Area2D
@export var stats: EntityStats

func _ready() -> void:
	stats.current_health = stats.max_health
	melee_range.body_entered.connect(_on_body_entered)
	sprite.play("idle")
	add_to_group("enemy")

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("TakeDamage"):
		body.TakeDamage(stats.attack_damage)

func _physics_process(delta: float) -> void:
	move_and_slide()

func _process(delta: float) -> void:
	if stats:
		hp_label.text = str(stats.current_health) + "/" + str(stats.max_health)

#func Shoot()

func Move(direction: Vector2):
	velocity = direction * stats.movement_speed
	sprite.play("moving")

func Jump(direction: Vector2, duration: float):
	get_tree().create_timer(duration).timeout.connect(Stop)
	velocity = direction * stats.movement_speed
	sprite.play("moving")

func Stop():
	velocity = Vector2.ZERO
	sprite.play("idle")

func TakeDamage(amount: float) -> void:
	if stats.current_health - amount <= 0:
		stats.current_health = 0
		Die()
	else:
		stats.current_health -= amount
		sprite.play("take_damage")
		await sprite.animation_finished
		sprite.play("idle")

func Die() -> void:
	#DisableCollisions()
	#sprite.play("die")
	
	queue_free()
	#sprite.play("die")
	#sprite.animation_finished.connect(queue_free)

func DisableCollisions() -> void:
	if $Area2D/CollisionShape2D:
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
	if $CollisionShape2D:
		$CollisionShape2D.set_deferred("disabled", true)
