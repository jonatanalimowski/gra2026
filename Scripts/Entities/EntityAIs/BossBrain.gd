extends Node
class_name BossBrain

# shared by boss AIs: two health phases split at enrage_threshold.
# the hit that reaches the threshold can't go past it (phase 2 always starts full),
# then the boss breaks: invulnerable and paused for enrage_transition_time, flash, shake, roar,
# and OnEnraged() lets the AI drop whatever attack it was doing. the HUD splits the boss bar
# at the threshold via Signals.boss_phase_changed
@onready var ParentEntity: Entity = get_parent()
@export_group("Enrage")
@export_range(0.0, 1.0) var enrage_threshold: float = 0.5 # fraction of max hp
@export var enrage_color: Color = Color(1, 0.3, 0.3)
@export var enrage_transition_time: float = 1.2 # invulnerable + paused
@export var enrage_shake: float = 0.6 # screen_shake trauma
@export var carry_over_damage: bool = false # true = the breaking hit's leftover damage goes into phase 2

var is_enraged: bool = false
var transition_timer: float = 0.0

# subclasses with their own _ready must call super()
func _ready() -> void:
	# the entity's _ready runs after ours, health doesn't exist yet
	ParentEntity.ready.connect(_on_boss_parent_ready)

func _on_boss_parent_ready() -> void:
	ParentEntity.health.changed.connect(_on_boss_health_changed)
	if not carry_over_damage:
		ParentEntity.health_floor_ratio = enrage_threshold
	Signals.boss_phase_changed.emit(1, enrage_threshold)
	OnBossReady()

func _physics_process(delta: float) -> void:
	transition_timer -= delta

# true while the AI shouldn't do anything this frame
func IsBusy() -> bool:
	return not ParentEntity or ParentEntity.is_dead or ParentEntity.IsStunned() or transition_timer > 0

func _on_boss_health_changed(current: float, maximum: float) -> void:
	# small margin: the clamped hit lands on the threshold, float rounding mustn't leave it just above
	if is_enraged or current <= 0 or current > maximum * enrage_threshold + 0.01:
		return
	Enrage()

func Enrage() -> void:
	is_enraged = true
	transition_timer = enrage_transition_time
	ParentEntity.health_floor_ratio = 0.0
	ParentEntity.invulnerable_timer = enrage_transition_time
	ParentEntity.Stop()
	ParentEntity.ClearTelegraphMark()
	OnEnraged()
	# self_modulate, so it doesn't fight the telegraph/hit flashes on modulate.
	# bright pulse, then stays tinted so the player can tell the phase changed
	var sprite = ParentEntity.sprite
	var tinted = enrage_color.lerp(Color.WHITE, 0.5)
	var tween = create_tween()
	tween.tween_property(sprite, "self_modulate", enrage_color * 1.6, enrage_transition_time * 0.3)
	tween.tween_property(sprite, "self_modulate", tinted, enrage_transition_time * 0.7)
	Signals.screen_shake.emit(enrage_shake)
	Sfx.Play(&"enemy/summon", -2.0)
	Signals.boss_phase_changed.emit(2, enrage_threshold)

# override: set up casters etc. once the entity's health/stats exist
func OnBossReady() -> void:
	pass

# override: drop the current attack, apply enraged values
func OnEnraged() -> void:
	pass
