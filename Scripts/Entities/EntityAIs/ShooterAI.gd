extends Node
class_name ShooterAI

# keeps its distance from the player, strafes around and shoots the entity's `spell` after a telegraph
# time between shots = the spell's cooldown, shot count / spread also come from the spell
# getting hit (hitstun) during the windup cancels the shot
@onready var ParentEntity: Entity = get_parent()
@export var preferred_distance: float = 140.0
@export var distance_tolerance: float = 25.0 # no moving closer/further inside this band, only strafing
@export var strafe_speed_multiplier: float = 0.5
@export var strafe_switch_chance: float = 0.3 # chance per second to change strafe direction
@export var attack_range: float = 200.0
@export var telegraph_color: Color = Color.ORANGE_RED
@export var telegraph_duration: float = 0.35
# if true the enemy wanders randomly and doesn't shoot when it can't see the player
@export var needs_line_of_sight: bool = true

enum State { REPOSITION, WINDUP }
var state: State = State.REPOSITION
var state_timer: float = 0.0
var strafe_direction: float = 1.0
var wander_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	strafe_direction = [-1.0, 1.0].pick_random()
	if not ParentEntity.spell:
		push_warning(ParentEntity.name + " has ShooterAI but no spell set, it will never shoot")

func _process(delta: float) -> void:
	if not ParentEntity or ParentEntity.is_dead: return
	if ParentEntity.IsStunned():
		state = State.REPOSITION
		return

	state_timer -= delta
	match state:
		State.REPOSITION:
			HandleReposition(delta)
		State.WINDUP:
			if state_timer <= 0:
				Fire()

	UpdateFacing()

func HandleReposition(delta: float) -> void:
	if not CanFindPlayer():
		Wander(delta)
		return

	var p = NodeReferences.player
	var distance = ParentEntity.global_position.distance_to(p.global_position)
	if distance <= attack_range and ParentEntity.CanShoot():
		StartWindup()
		return

	if randf() < strafe_switch_chance * delta:
		strafe_direction *= -1

	var to_player = ParentEntity.global_position.direction_to(p.global_position)
	var radial = 0.0
	if distance > preferred_distance + distance_tolerance:
		radial = 1.0
	elif distance < preferred_distance - distance_tolerance:
		radial = -1.0
	var tangent = to_player.orthogonal() * strafe_direction * strafe_speed_multiplier
	# not normalized, so pure strafing is slower than walking
	ParentEntity.Move((to_player * radial + tangent).limit_length(1.0))

func Wander(delta: float) -> void:
	if wander_direction == Vector2.ZERO or randf() < delta:
		wander_direction = Vector2.from_angle(randf() * TAU)
	ParentEntity.Move(wander_direction * 0.5)

func StartWindup() -> void:
	state = State.WINDUP
	state_timer = telegraph_duration
	ParentEntity.Stop()
	GlobalMethods.FlashSprite(ParentEntity.sprite, telegraph_duration, telegraph_color)

func Fire() -> void:
	state = State.REPOSITION
	var p = NodeReferences.player
	if not p:
		return
	# aim at where the player is now, not where they were at windup
	ParentEntity.Shoot(ParentEntity.global_position.direction_to(p.global_position))

func CanFindPlayer() -> bool:
	if not NodeReferences.player: return false
	return ParentEntity.CanSeePlayer() if needs_line_of_sight else true

func UpdateFacing() -> void:
	var p = NodeReferences.player
	if state == State.WINDUP and p:
		ParentEntity.sprite.flip_h = p.global_position.x < ParentEntity.global_position.x
		return
	var vx = ParentEntity.move_velocity.x
	if vx < -0.01:
		ParentEntity.sprite.flip_h = true
	elif vx > 0.01:
		ParentEntity.sprite.flip_h = false
