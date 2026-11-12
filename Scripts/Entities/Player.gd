extends CharacterBody2D
class_name Player
@onready var sprite = $AnimatedSprite2D
@onready var muzzle = $Marker2D
@onready var in_game_health_bar = %HealthBar
@export var base_stats: PlayerStats
# used when Main.tscn is started straight from the editor, without picking a wand first
@export var fallback_wand: WandData
# seconds of immunity after taking a hit, so bullets landing together count once
@export var hit_iframes: float = 0.05

var stats: StatBlock
var health: Health
var status_holder: StatusEffectHolder
var mana: float = 100 # starts empty every floor, refilled by ManaOrbs
var wand: Wand
var mobility: MobilityAbility
# effects from equipment and blessings, added to every spell cast
var effects: Array[Effect] = []
# slot pacts: only added to the primary / heavy casts
var primary_effects: Array[Effect] = []
var heavy_effects: Array[Effect] = []
# Hoarfrost: each charge blocks one hit
var shield_charges: int = 0
const MAX_SHIELD_CHARGES: int = 1
# Slick Floor curse: barely any grip for a moment after a dash
const SLIDE_TIME: float = 0.45
const SLIDE_GRIP: float = 0.12
var slide_left: float = 0.0
# with Slick Floor the dash "ends" where the slide stops, so end-of-dash effects land under the player
var dash_end_pending: bool = false
var dash_area: Area2D
# Sanguine: overheal becomes a barrier that soaks damage before HP
var barrier: float = 0.0
const MAX_BARRIER: float = 20.0
# Cold Blood duo: once per floor (the player is rebuilt every floor)
var cold_blood_used: bool = false
# Overcharge curse: counts primary casts
var primary_cast_count: int = 0
const OVERCHARGE_EVERY: int = 10
const BLINK_DISTANCE: float = 60.0
const BLOOD_PRICE_SHARE: float = 0.15
var dashed_through: Array[Entity] = []

var can_dash: bool = true
var dash_velocity: Vector2 = Vector2.ZERO
var input: Vector2
enum player_state {MOVING, DASHING}
var current_state: player_state = player_state.MOVING
var is_invulnerable: bool = false # dash
var hit_iframes_left: float = 0.0
var is_dead: bool = false

func _ready() -> void:
	add_to_group("player")
	stats = StatBlock.FromResource(base_stats)
	status_holder = StatusEffectHolder.new()
	add_child(status_holder)
	ApplyLoadout(RunState.loadout)

	health = Health.new(stats.GetStat(&"max_health"))
	health.changed.connect(func(current, maximum): Signals.player_health_changed.emit(current, maximum))
	health.died.connect(Die)
	health.heal_multiplier = stats.GetStat(&"healing_received")
	health.overhealed.connect(_on_overhealed)
	stats.stat_changed.connect(_on_stat_changed)
	CreateDashArea()
	RunState.half_added.connect(ApplyHalf)
	RunState.half_removed.connect(RemoveHalf)
	Signals.player_health_changed.connect(_on_player_health_changed)
	Settings.player_additional_healthbar_visibility_changed.connect(ChangeAdditionalHealthbarVisiblility)
	in_game_health_bar.visible = Settings.show_health_above_player

	NodeReferences.player = self
	Signals.player_ready.emit(self)
	Signals.player_health_changed.emit(health.current, health.maximum)
	Signals.player_mana_changed.emit(mana, stats.GetStat(&"max_mana"))

func ApplyLoadout(loadout: Loadout) -> void:
	if loadout == null:
		loadout = Loadout.new()

	for item in loadout.GetEquipment():
		for modifier in item.player_modifiers:
			stats.AddModifier(modifier, item)
		effects.append_array(item.effects)

	if loadout.scroll and loadout.scroll.ability:
		mobility = loadout.scroll.ability
	else:
		mobility = DashAbility.new()

	wand = Wand.new()
	wand.name = "Wand"
	add_child(wand)
	wand.Setup(loadout.wand if loadout.wand else fallback_wand)
	# a heavy pact owns the heavy, set it before the halves add their spell modifiers
	wand.SetHeavy(GetHeavySpell())

	# run-wide blessings/curses (pacts, oaths). after the wand, halves can modify its spells
	for half in RunState.halves:
		ApplyHalf(half)
	DevTools.ApplyDamageCheat(self)
	DevTools.ApplyShotCheats(self)

# the half is the modifier source, so RemoveHalf takes back exactly what it gave
func ApplyHalf(half: PactHalf) -> void:
	for modifier in half.player_modifiers:
		stats.AddModifier(modifier, half)
	# a new heavy caster already gets every active half's modifiers, this one included
	var rebuilt_heavy = half.heavy_override != null and UpdateHeavy()
	for caster in wand.GetCasters():
		if rebuilt_heavy and caster == wand.heavy:
			continue
		for modifier in half.spell_modifiers:
			caster.stats.AddModifier(modifier, half)
	if wand.primary:
		for modifier in half.primary_modifiers:
			wand.primary.stats.AddModifier(modifier, half)
	effects.append_array(half.effects)
	primary_effects.append_array(half.primary_effects)
	heavy_effects.append_array(half.heavy_effects)
	for e in half.run_effects:
		e.OnAdded(self)

func RemoveHalf(half: PactHalf) -> void:
	stats.RemoveModifiersFrom(half)
	for caster in wand.GetCasters():
		caster.stats.RemoveModifiersFrom(half)
	for e in half.effects:
		effects.erase(e) # one copy, RunState emits half_removed once per stack
	for e in half.primary_effects:
		primary_effects.erase(e)
	for e in half.heavy_effects:
		heavy_effects.erase(e)
	if half.heavy_override:
		UpdateHeavy()
	for e in half.run_effects:
		e.OnRemoved(self)

# the last active half with a heavy_override wins, else the wand's own heavy
func GetHeavySpell() -> SpellData:
	for i in range(RunState.halves.size() - 1, -1, -1):
		if RunState.halves[i].heavy_override:
			return RunState.halves[i].heavy_override
	return wand.data.heavy_spell

# rebuilds the heavy caster if the spell changed. true = rebuilt (with every active half's modifiers)
func UpdateHeavy() -> bool:
	var spell = GetHeavySpell()
	if (wand.heavy.spell if wand.heavy else null) == spell:
		return false
	wand.SetHeavy(spell)
	if wand.heavy:
		for half in RunState.halves:
			for modifier in half.spell_modifiers:
				wand.heavy.stats.AddModifier(modifier, half)
	DevTools.ApplyDamageCheat(self)
	Signals.player_mana_changed.emit(mana, stats.GetStat(&"max_mana")) # HUD regrays the heavy slot
	return true

func _on_player_health_changed(new_curr, new_max) -> void:
	in_game_health_bar.value = new_curr
	in_game_health_bar.max_value = new_max

func _on_stat_changed(stat_name: StringName, value: float) -> void:
	if stat_name == &"max_health":
		health.SetMaximum(value)
	elif stat_name == &"max_mana":
		AddMana(0.0) # clamps to the new max + updates the bar
	elif stat_name == &"healing_received":
		health.heal_multiplier = value

func _on_overhealed(amount: float) -> void:
	if RunState.HasFlag(&"sanguine"):
		barrier = minf(barrier + amount, MAX_BARRIER)
		queue_redraw()

# negative = spend. extra mana over the max is lost
func AddMana(amount: float) -> void:
	var max_mana = stats.GetStat(&"max_mana")
	mana = clampf(mana + amount, 0.0, max_mana)
	Signals.player_mana_changed.emit(mana, max_mana)

func _exit_tree() -> void:
	NodeReferences.player = null

func TakeDamage(info: DamageInfo) -> void:
	if is_invulnerable or is_dead or DevTools.invincible:
		return
	# status ticks ignore hit i-frames and don't start them, poison shouldn't shield the player
	if not info.is_periodic:
		if hit_iframes_left > 0.0:
			return
		hit_iframes_left = hit_iframes
		# a shield eats the whole hit (still gives i-frames, so a volley only breaks one charge)
		if shield_charges > 0:
			AddShield(-1)
			GlobalMethods.FlashSprite(sprite, 0.3, Color(0.6, 0.9, 1.0))
			Signals.player_hit_blocked.emit(info)
			return

	var amount = info.amount
	# Hunted curse
	if RunState.HasFlag(&"hunted") and health.current < health.maximum * 0.5:
		amount *= 1.15
	if barrier > 0.0:
		var soaked = minf(barrier, amount)
		barrier -= soaked
		amount -= soaked
		queue_redraw()
	# Cold Blood duo: the first lethal hit of the floor freezes you instead
	if amount >= health.current and RunState.HasFlag(&"cold_blood") and not cold_blood_used:
		cold_blood_used = true
		amount = maxf(health.current - 1.0, 0.0)
		MakeInvulnerable(2.0)
		GlobalMethods.FlashSprite(sprite, 2.0, Color(0.6, 0.9, 1.0))
	health.Damage(amount)
	Signals.player_damaged.emit(info)
	if not is_dead and not info.is_periodic:
		GlobalMethods.FlashSprite(sprite)
	# the player has no damage numbers, a faint tint in the status color shows the tick
	elif not is_dead and info.status:
		GlobalMethods.FlashSprite(sprite, 0.2, info.status.color)

# dashing through a status area is a real dodge
func ApplyStatus(effect: StatusEffect, source: Node2D, strength: float = 1.0, duration_multiplier: float = 1.0, stacks: int = 1) -> void:
	if is_invulnerable or is_dead or DevTools.invincible:
		return
	status_holder.Apply(effect, source, strength, duration_multiplier, stacks)

func AddShield(amount: int) -> void:
	shield_charges = clampi(shield_charges + amount, 0, MAX_SHIELD_CHARGES)
	Signals.player_shield_changed.emit(shield_charges)
	queue_redraw()

# a light ring around the player while a shield charge is up
func _draw() -> void:
	if shield_charges > 0:
		draw_arc(Vector2(0, -6), 11.0, 0, TAU, 24, Color(0.6, 0.9, 1.0, 0.8), 1.0)
	# barrier: a red ring, fuller = more barrier
	if barrier > 0.0:
		draw_arc(Vector2(0, -6), 13.0, -PI / 2, -PI / 2 + TAU * barrier / MAX_BARRIER, 24, Color(0.9, 0.15, 0.25, 0.8), 1.0)

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
	hit_iframes_left -= delta
	if not is_dead:
		RunState.ProcessEffects(self, delta)
	match current_state:
		player_state.MOVING:
			HandleMoveState(delta)
			UpdateMovingAnimation()
		player_state.DASHING:
			HandleDashState()

func UseMobility() -> void:
	can_dash = false
	# Short Fuse curse
	var cooldown = mobility.cooldown * (1.0 + 0.3 * RunState.CountFlag(&"short_fuse"))
	get_tree().create_timer(cooldown).timeout.connect(func(): can_dash = true)
	FinishDashEnd() # still sliding from the last dash
	dashed_through.clear()
	var direction = GetMovementInput()
	Signals.player_dash_started.emit(global_position, direction)
	# Blink Step: an instant teleport (walls still stop it) instead of the dash
	if RunState.HasFlag(&"blink_dash"):
		if direction == Vector2.ZERO:
			direction = global_position.direction_to(get_global_mouse_position())
		move_and_collide(direction * BLINK_DISTANCE)
		MakeInvulnerable(0.15)
		Signals.player_dash_ended.emit(global_position)
	else:
		mobility.Activate(self, direction)
	Sfx.Play(&"player/dash", -16)
	GlobalMethods.FlashSprite(sprite, 0.3, Color(0.4, 0.4, 0.4, 0.3))

# moves the player with a fixed velocity for a while, ignoring input. used by DashAbility
func StartDash(velocity_during_dash: Vector2, duration: float) -> void:
	dash_velocity = velocity_during_dash
	current_state = player_state.DASHING
	dash_area.monitoring = true
	get_tree().create_timer(duration).timeout.connect(EndDash)

func HandleDashState() -> void:
	velocity = dash_velocity
	move_and_slide()

func EndDash() -> void:
	if current_state == player_state.DASHING:
		current_state = player_state.MOVING
		dash_area.set_deferred("monitoring", false)
		if RunState.HasFlag(&"slick_dash"):
			velocity = dash_velocity
			slide_left = SLIDE_TIME
			dash_end_pending = true
		else:
			Signals.player_dash_ended.emit(global_position)

func FinishDashEnd() -> void:
	if dash_end_pending:
		dash_end_pending = false
		Signals.player_dash_ended.emit(global_position)

# Dash slot: enemies the dash passes through (the player body doesn't collide with enemies)
func CreateDashArea() -> void:
	dash_area = Area2D.new()
	dash_area.collision_layer = 0
	dash_area.collision_mask = BaseProjectile.LAYER_ENEMY
	dash_area.monitorable = false
	dash_area.monitoring = false
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	shape.position = Vector2(0, -6)
	dash_area.add_child(shape)
	add_child(dash_area)
	dash_area.body_entered.connect(_on_dash_area_body_entered)

func ChangeAdditionalHealthbarVisiblility(is_on: bool):
	in_game_health_bar.visible = is_on

func _on_dash_area_body_entered(body: Node2D) -> void:
	if body is Entity and not body.is_dead and body not in dashed_through:
		dashed_through.append(body)
		Signals.player_dashed_through.emit(body)

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

	var spell_caster: SpellCaster = wand.primary if is_primary else wand.heavy
	if spell_caster == null:
		return
	var cost = spell_caster.stats.GetStat(&"mana_cost")
	# Blood Price: a heavy you can't afford costs HP instead
	var hp_cost = 0.0
	if mana < cost:
		if is_primary or not RunState.HasFlag(&"blood_price") or not spell_caster.IsReady():
			return
		hp_cost = health.current * BLOOD_PRICE_SHARE
		cost = 0.0
	# Overcharge curse: every 10th primary cast fizzles (cooldown still used)
	if is_primary and RunState.HasFlag(&"overcharge") and spell_caster.IsReady():
		primary_cast_count += 1
		if primary_cast_count % OVERCHARGE_EVERY == 0:
			spell_caster.cooldown_left = spell_caster.stats.GetStat(&"cooldown")
			GlobalMethods.FlashSprite(sprite, 0.2, Color(0.5, 0.5, 0.5))
			Sfx.Play(&"ui/denied", -14)
			return

	var cast_effects: Array[Effect] = []
	cast_effects.append_array(effects)
	cast_effects.append_array(primary_effects if is_primary else heavy_effects)
	var dir = (get_global_mouse_position() - global_position).normalized()
	if spell_caster.TryCast(self, dir, muzzle.global_position, cast_effects):
		AddMana(-cost)
		if hp_cost > 0.0:
			health.Damage(hp_cost) # self-inflicted: no hurt signal, doesn't break flawless
			GlobalMethods.FlashSprite(sprite, 0.2, Color(0.8, 0.1, 0.2))
		Sfx.Play(&"player/cast", -16.0)

func HandleMoveState(delta: float) -> void:
	var direction = GetMovementInput()
	slide_left -= delta
	if slide_left <= 0.0:
		FinishDashEnd()
	var grip = SLIDE_GRIP if slide_left > 0.0 else 1.0
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * stats.GetStat(&"movement_speed"), delta * stats.GetStat(&"acceleration") * grip)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, delta * stats.GetStat(&"friction") * grip)
	move_and_slide()

# projectiles pass through instead of hitting, see BaseProjectile.HandleCollision
func IsDodging() -> bool:
	return is_invulnerable or hit_iframes_left > 0.0

func MakeInvulnerable(seconds: float) -> void:
	is_invulnerable = true
	get_tree().create_timer(seconds).timeout.connect(func(): is_invulnerable = false)
