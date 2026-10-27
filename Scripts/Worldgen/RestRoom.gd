extends Room
class_name RestRoom

# a quiet room at the end of a side branch. stepping onto the shrine heals the player once
@export_range(0.0, 1.0) var heal_share: float = 0.5
@onready var shrine: Area2D = $Shrine
@onready var shrine_sprite: Sprite2D = $Shrine/Heart
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
	# at full health the shrine waits instead of being wasted
	if player.health.current >= player.health.maximum:
		return

	is_used = true
	player.health.Heal(player.health.maximum * heal_share)
	GlobalMethods.FlashSprite(player.sprite, 0.4, Color.GREEN)

	bob_tween.kill()
	var fade = create_tween()
	fade.tween_property(shrine_sprite, "modulate:a", 0.0, 0.5)
