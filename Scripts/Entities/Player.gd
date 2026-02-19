extends CharacterBody2D
class_name Player
@onready var sprite = $AnimatedSprite2D
@onready var muzzle = $Marker2D
@onready var weapon_slot1 = $WeaponSlot1
@onready var weapon_slot2 = $WeaponSlot2
@export var stats: PlayerStats
@export var primary_weapon_scene: PackedScene
@export var secondary_weapon_scene: PackedScene

var current_weapon: Weapon
var slot1_weapon: Weapon
var slot2_weapon: Weapon
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO
var input: Vector2
enum player_state {MOVING, DASHING}
enum weapon_slots {PRIMARY, SECONDARY}
var current_state: player_state = player_state.MOVING
var is_invulnerable: bool = false

func SetWeaponInSlot(weapon_slot: weapon_slots, weapon: PackedScene):
	if weapon_slot == weapon_slots.PRIMARY:
		if slot1_weapon == null:
			slot1_weapon = weapon.instantiate() as Weapon
			weapon_slot1.add_child(slot1_weapon)
	else:
		if slot2_weapon == null:
			slot2_weapon = weapon.instantiate() as Weapon
			weapon_slot2.add_child(slot2_weapon)

func EquipWeapon(weapon_slot: weapon_slots):
	if weapon_slot == weapon_slots.PRIMARY:
		current_weapon = slot1_weapon
	else:
		current_weapon = slot2_weapon

#TEMP
func UnequipCurrentWeapon():
	if current_weapon:
		current_weapon = null

func UpdateDebugUI(key : String, text : String) -> void:
	var label: Label = Label.new()
	label.text = text
	Signals.debug_ui_updated.emit({key : label})

func _ready() -> void:
	stats.update_stat("current_health", stats.max_health)
	UpdateDebugUI("player_health", "HP " + str(stats.current_health))
	add_to_group("player")
	
	SetWeaponInSlot(weapon_slots.PRIMARY, primary_weapon_scene)
	SetWeaponInSlot(weapon_slots.SECONDARY, secondary_weapon_scene)
	EquipWeapon(weapon_slots.PRIMARY)
	
	NodeReferences.player = self
	Signals.player_ready.emit(self)
	Signals.player_health_changed.emit(stats.current_health, stats.max_health)
	

func _exit_tree() -> void:
	NodeReferences.player = null

func TakeDamage(amount: float) -> void:
	if is_invulnerable == false:
		if stats.current_health - amount <= 0:
			Die()
		else:
			GlobalMethods.FlashSprite(sprite)
			stats.update_stat("current_health", stats.current_health - amount)
			Signals.player_health_changed.emit(stats.current_health, stats.max_health)

func Die() -> void:
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Weapon1"):
		EquipWeapon(weapon_slots.PRIMARY)
	if event.is_action_pressed("Weapon2"):
		EquipWeapon(weapon_slots.SECONDARY)
	if event.is_action_pressed("Dash") and current_state == player_state.MOVING and can_dash:
		StartDash()
	if event.is_action_pressed("Restart"):
		Die()

func GetMovementInput():
	input.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	return input.normalized()

func _process(delta: float) -> void:
	if Input.is_action_pressed("LeftMouse"):
		HandleShooting()

func _physics_process(delta: float) -> void:
	match current_state:
		player_state.MOVING:
			HandleMoveState(delta)
			UpdateMovingAnimation()
		player_state.DASHING:
			HandleDashState()

func StartDash() -> void:
	var dash_duration = stats.dash_distance / stats.dash_speed
	can_dash = false
	dash_direction = GetMovementInput()
	
	get_tree().create_timer(dash_duration).timeout.connect(EndDash)
	get_tree().create_timer(stats.dash_cooldown).timeout.connect(func(): can_dash = true)
	MakeInvulnerable(dash_duration)
	current_state = player_state.DASHING

func HandleDashState() -> void:
	velocity = dash_direction * stats.dash_speed
	move_and_slide()

func EndDash() -> void:
	if current_state == player_state.DASHING:
		current_state = player_state.MOVING

func UpdateMovingAnimation():
	if velocity.length() > 0.01:
		if (abs(velocity.x) > abs(velocity.y)):
			if velocity.x > 0:
				sprite.play("walk_right")
			else:
				sprite.play("walk_left")
		else:
			if velocity.y > 0:
				sprite.play("walk_down")
			else:
				sprite.play("walk_up")
	else:
		sprite.stop()

func HandleShooting() -> void:
	if current_weapon:
		var dir = (get_global_mouse_position() - global_position).normalized()
		var pos = muzzle.global_position
		current_weapon.Shoot(dir, pos)

func HandleMoveState(delta: float) -> void:
	var direction = GetMovementInput()
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * stats.movement_speed, delta*stats.acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, delta*stats.friction)
	move_and_slide()

func MakeInvulnerable(seconds: float) -> void:
	is_invulnerable = true
	get_tree().create_timer(seconds).timeout.connect(func(): is_invulnerable = false)
