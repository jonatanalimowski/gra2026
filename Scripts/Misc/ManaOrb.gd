extends Node2D
class_name ManaOrb

# small blue orb dropped by dead enemies: pops out, then homes in on the player and gives mana
# path, not preload: the scene uses this script, preloading it here would be a cycle
const SCENE_PATH = "res://Scenes/Misc/ManaOrb.tscn"
const MANA_PER_ORB = 5.0

@export var radius: float = 2.5
@export var color: Color = Color(0.35, 0.6, 1.0)
@export var scatter_speed: float = 140.0
@export var scatter_time: float = 0.3 # before it starts flying to the player
@export var home_acceleration: float = 900.0
@export var max_speed: float = 600.0
@export var turn_rate: float = 10.0 # higher = tighter curve towards the player
@export var pickup_distance: float = 8.0

var amount: float = MANA_PER_ORB
var velocity: Vector2
var speed: float = 0.0
var age: float = 0.0

# splits the mana into orbs of ~MANA_PER_ORB each
static func SpawnBurst(parent: Node, pos: Vector2, total_mana: float) -> void:
	if total_mana <= 0:
		return
	var scene: PackedScene = load(SCENE_PATH)
	var count = ceili(total_mana / MANA_PER_ORB)
	for i in count:
		var orb: ManaOrb = scene.instantiate()
		orb.amount = total_mana / count
		orb.position = pos
		parent.add_child.call_deferred(orb)

func _ready() -> void:
	velocity = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.4, 1.0) * scatter_speed

func _physics_process(delta: float) -> void:
	age += delta
	var player = NodeReferences.player
	if age < scatter_time or player == null or player.is_dead:
		velocity = velocity.move_toward(Vector2.ZERO, scatter_speed * 3.0 * delta)
	else:
		var to_player = player.global_position - global_position
		speed = min(speed + home_acceleration * delta, max_speed)
		# within one step = caught, so fast orbs can't skip past the player
		if to_player.length() < max(pickup_distance, speed * delta):
			player.AddMana(amount)
			queue_free()
			return
		velocity = velocity.lerp(to_player.normalized() * speed, 1.0 - exp(-turn_rate * delta))
	global_position += velocity * delta

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius * 2.0, Color(color, 0.25)) # glow
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2(-0.5, -0.5), radius * 0.4, Color(0.85, 0.95, 1.0))
