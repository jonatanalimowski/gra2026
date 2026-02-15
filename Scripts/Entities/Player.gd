extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var muzzle = $Marker2D
@export var stats: PlayerStats
@export var weapon_scene: PackedScene

var current_weapon: Weapon
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO
var input: Vector2
enum player_state {MOVING, DASHING}
var current_state: player_state = player_state.MOVING

func EquipWeapon():
	current_weapon = weapon_scene.instantiate() as Weapon
	add_child(current_weapon)

func UpdateDebugUI(key : String, text : String) -> void:
	var label: Label = Label.new()
	label.text = text
	Signals.debug_ui_updated.emit({key : label})

func _ready() -> void:
	stats.current_health = stats.max_health
	UpdateDebugUI("player_health", "HP " + str(stats.current_health))
	add_to_group("player")
	NodeReferences.player = self
	EquipWeapon()

func _exit_tree() -> void:
	NodeReferences.player = null

func TakeDamage(amount: float) -> void:
	if stats.current_health - amount <= 0:
		Die()
	else:
		GlobalMethods.FlashSprite(sprite)
		stats.current_health -= amount
	UpdateDebugUI("player_health", "HP " + str(stats.current_health))

func Die() -> void:
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
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
	can_dash = false
	dash_direction = GetMovementInput()
	get_tree().create_timer(stats.dash_duration).timeout.connect(EndDash)
	get_tree().create_timer(stats.dash_cooldown).timeout.connect(func(): can_dash = true)
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
