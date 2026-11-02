extends Room
class_name RestRoom

# Sanctuary: a quiet room at the end of a side branch (one every floor). stepping onto the shrine
# once gives +10 max HP for the rest of the run (SanctuaryBlessing, stacks) and heals 40%
const SANCTUARY_BLESSING = preload("res://Data/Blessings/SanctuaryBlessing.tres")
@export_range(0.0, 1.0) var heal_share: float = 0.4
@onready var shrine: Area2D = $Shrine
@onready var shrine_sprite: Sprite2D = %Heart
var is_used: bool = false
var bob_tween: Tween

func _ready() -> void:
	shrine.body_entered.connect(_on_shrine_body_entered)
	# slow bob so the heart reads as something to walk into
	bob_tween = create_tween().set_loops()
	bob_tween.tween_property(shrine_sprite, "position:y", -3.0, 0.6).set_trans(Tween.TRANS_SINE)
	bob_tween.tween_property(shrine_sprite, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)

func _on_shrine_body_entered(body: Node2D) -> void:
	if is_used or not body is Player:
		return

	var player = body as Player
	is_used = true
	# max HP first, so the heal counts the new maximum. works at full HP too, the max HP is the point
	RunState.AddHalf(SANCTUARY_BLESSING, true)
	# Cold Hearth curse
	var share = heal_share * (0.5 if RunState.HasFlag(&"sanctuary_heal_halved") else 1.0)
	player.health.Heal(player.health.maximum * share, false)
	Sfx.Play(&"world/heal", -10)
	GlobalMethods.FlashSprite(player.sprite, 0.4, Color.GREEN)

	bob_tween.kill()
	var fade = create_tween()
	fade.tween_property(shrine_sprite, "modulate:a", 0.0, 0.5)
