extends Node
class_name SkeletonAI

# walks around the player, charges when behind player
# "behind" = on the opposite side of where the player is aiming (mouse)
@onready var ParentEntity: Entity = get_parent()
@export var orbit_radius: float = 70.0
@export var orbit_radius_correction: float = 0.6 # how hard it pulls back to the orbit radius
@export var orbit_switch_chance: float = 0.2 # chance per second to change circling direction
@export var behind_angle: float = 110.0 # min angle between player's aim and the skeleton to count as behind
@export var charge_range: float = 120.0
@export var charge_speed_multiplier: float = 3.0
@export var charge_duration: float = 0.5
@export var charge_cooldown: float = 1.5
@export var telegraph_color: Color = Color.AQUAMARINE
@export var telegraph_duration: float = 0.4
# if true the skeleton wanders randomly when it can't see the player
@export var needs_line_of_sight: bool = true

enum State { CIRCLE, WINDUP, CHARGE }
var state: State = State.CIRCLE
var state_timer: float = 0.0
var cooldown: float = 0.0
var orbit_direction: float = 1.0 # 1 = counter clockwise, -1 = clockwise
var wander_direction: Vector2 = Vector2.ZERO
var charge_direction: Vector2 = Vector2.ZERO
# added while charging so hits can't push or stun it
var unstoppable_mod: StatModifier

func _ready() -> void:
	orbit_direction = [-1.0, 1.0].pick_random()
	unstoppable_mod = StatModifier.new()
	unstoppable_mod.stat = &"knockback_resistance"
	unstoppable_mod.flat = 1.0

func _process(delta: float) -> void:
	if not ParentEntity or ParentEntity.is_dead: return
	if ParentEntity.IsStunned():
		UpdateFacing()
		return

	cooldown -= delta
	state_timer -= delta
	match state:
		State.CIRCLE:
			HandleCircle(delta)
		State.WINDUP:
			if state_timer <= 0:
				StartCharge()
		State.CHARGE:
			if state_timer <= 0:
				state = State.CIRCLE
				ParentEntity.stats.RemoveModifiersFrom(self)
				cooldown = charge_cooldown

	UpdateFacing()

func HandleCircle(delta: float) -> void:
	if not CanFindPlayer():
		Wander(delta)
		return

	if cooldown <= 0 and IsBehindPlayer():
		StartWindup()
		return

	if randf() < orbit_switch_chance * delta:
		orbit_direction *= -1

	# tangent keeps it circling, radial part keeps it near orbit_radius
	var to_player = ParentEntity.global_position.direction_to(NodeReferences.player.global_position)
	var distance = ParentEntity.global_position.distance_to(NodeReferences.player.global_position)
	var tangent = to_player.orthogonal() * orbit_direction
	var radial = to_player * clampf((distance - orbit_radius) / orbit_radius, -1.0, 1.0) * orbit_radius_correction
	ParentEntity.Move((tangent + radial).normalized())

func Wander(delta: float) -> void:
	if wander_direction == Vector2.ZERO or randf() < delta:
		wander_direction = Vector2.from_angle(randf() * TAU)
	ParentEntity.Move(wander_direction)

func StartWindup() -> void:
	state = State.WINDUP
	state_timer = telegraph_duration
	ParentEntity.Stop()
	GlobalMethods.FlashSprite(ParentEntity.sprite, telegraph_duration, telegraph_color)
	# face the player while winding up
	ParentEntity.sprite.flip_h = NodeReferences.player.global_position.x < ParentEntity.global_position.x

func StartCharge() -> void:
	state = State.CHARGE
	state_timer = charge_duration
	# aim at where the player is now, not where they were at windup
	if NodeReferences.player:
		charge_direction = ParentEntity.global_position.direction_to(NodeReferences.player.global_position)
	var move_speed = ParentEntity.stats.GetStat(&"movement_speed")
	ParentEntity.stats.AddModifier(unstoppable_mod, self)
	ParentEntity.Jump(charge_direction, charge_duration, move_speed * charge_speed_multiplier)

func IsBehindPlayer() -> bool:
	var p = NodeReferences.player
	var to_skeleton = p.global_position.direction_to(ParentEntity.global_position)
	var aim = p.global_position.direction_to(p.get_global_mouse_position())
	var in_range = p.global_position.distance_to(ParentEntity.global_position) <= charge_range
	return in_range and absf(rad_to_deg(aim.angle_to(to_skeleton))) > behind_angle

func CanFindPlayer() -> bool:
	if not NodeReferences.player: return false
	return ParentEntity.CanSeePlayer() if needs_line_of_sight else true

func UpdateFacing() -> void:
	var vx = ParentEntity.move_velocity.x
	if vx < -0.01:
		ParentEntity.sprite.flip_h = true
	elif vx > 0.01:
		ParentEntity.sprite.flip_h = false
