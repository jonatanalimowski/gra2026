extends CharacterBody2D
class_name Player
@onready var sprite = $AnimatedSprite2D
@onready var muzzle = $Marker2D
@export var base_stats: PlayerStats
# used when Main.tscn is started straight from the editor, without picking a wand first
@export var fallback_wand: WandData

var stats: StatBlock
var health: Health
var wand: Wand
var mobility: MobilityAbility
# effects from equipment and blessings, added to every spell cast
var effects: Array[Effect] = []

var can_dash: bool = true
var dash_velocity: Vector2 = Vector2.ZERO
var input: Vector2
enum player_state {MOVING, DASHING}
var current_state: player_state = player_state.MOVING
var is_invulnerable: bool = false
var is_dead: bool = false

func _ready() -> void:
	add_to_group("player")
	stats = StatBlock.FromResource(base_stats)
	ApplyLoadout(RunState.loadout)

	health = Health.new(stats.GetStat(&"max_health"))
	health.changed.connect(func(current, maximum): Signals.player_health_changed.emit(current, maximum))
	health.died.connect(Die)
	stats.stat_changed.connect(_on_stat_changed)

	NodeReferences.player = self
	Signals.player_ready.emit(self)
	Signals.player_health_changed.emit(health.current, health.maximum)

func ApplyLoadout(loadout: Loadout) -> void:
	if loadout == null:
		loadout = Loadout.new()

	for item in loadout.GetEquipment():
		for modifier in item.player_modifiers:
			stats.AddModifier(modifier, item)
		effects.append_array(item.effects)

	# run-wide buffs (blessings, altars)
	for modifier in RunState.player_modifiers:
		stats.AddModifier(modifier, RunState)
	effects.append_array(RunState.effects)

	if loadout.scroll and loadout.scroll.ability:
		mobility = loadout.scroll.ability
	else:
		mobility = DashAbility.new()

	wand = Wand.new()
	wand.name = "Wand"
	add_child(wand)
	wand.Setup(loadout.wand if loadout.wand else fallback_wand)

func _on_stat_changed(stat_name: StringName, value: float) -> void:
	if stat_name == &"max_health":
		health.SetMaximum(value)

func _exit_tree() -> void:
	NodeReferences.player = null

func TakeDamage(info: DamageInfo) -> void:
	if is_invulnerable or is_dead:
		return

	health.Damage(info.amount)
	if not is_dead:
		GlobalMethods.FlashSprite(sprite)

func Die() -> void:
	if is_dead:
		return
	is_dead = true
	Signals.player_died.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("RightMouse"):
		CastSpell(false)
	if event.is_action_pressed("Dash") and current_state == player_state.MOVING and can_dash:
		UseMobility()
	if event.is_action_pressed("Restart"):
		GameFlow.RestartRun()

func GetMovementInput():
	input.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	return input.normalized()

func _process(delta: float) -> void:
	if Input.is_action_pressed("LeftMouse"):
		CastSpell(true)

func _physics_process(delta: float) -> void:
	match current_state:
		player_state.MOVING:
			HandleMoveState(delta)
			UpdateMovingAnimation()
		player_state.DASHING:
			HandleDashState()

func UseMobility() -> void:
	can_dash = false
	get_tree().create_timer(mobility.cooldown).timeout.connect(func(): can_dash = true)
	mobility.Activate(self, GetMovementInput())

# moves the player with a fixed velocity for a while, ignoring input. used by DashAbility
func StartDash(velocity_during_dash: Vector2, duration: float) -> void:
	dash_velocity = velocity_during_dash
	current_state = player_state.DASHING
	get_tree().create_timer(duration).timeout.connect(EndDash)

func HandleDashState() -> void:
	velocity = dash_velocity
	move_and_slide()

func EndDash() -> void:
	if current_state == player_state.DASHING:
		current_state = player_state.MOVING

func UpdateMovingAnimation():
	if velocity.length() > 0.01:
		if (abs(velocity.x) > abs(velocity.y)):
			if velocity.x > 0:
				sprite.flip_h = true
				sprite.play("walk_right")
			else:
				sprite.flip_h = false
				sprite.play("walk_left")
		else:
			if velocity.y > 0:
				sprite.play("walk_down")
			else:
				sprite.play("walk_up")
	else:
		sprite.stop()

func CastSpell(is_primary: bool) -> void:
	if is_dead:
		return

	var dir = (get_global_mouse_position() - global_position).normalized()
	var pos = muzzle.global_position
	if is_primary:
		wand.CastPrimary(self, dir, pos, effects)
	else:
		wand.CastHeavy(self, dir, pos, effects)

func HandleMoveState(delta: float) -> void:
	var direction = GetMovementInput()
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * stats.GetStat(&"movement_speed"), delta * stats.GetStat(&"acceleration"))
	else:
		velocity = velocity.move_toward(Vector2.ZERO, delta * stats.GetStat(&"friction"))
	move_and_slide()

func MakeInvulnerable(seconds: float) -> void:
	is_invulnerable = true
	get_tree().create_timer(seconds).timeout.connect(func(): is_invulnerable = false)
