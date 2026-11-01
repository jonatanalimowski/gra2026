extends ColorRect

# red screen edges that flash and fade when the player takes damage. the shape is in the shader
@export_range(0.0, 1.0) var peak_alpha: float = 0.7
@export var fade_time: float = 0.4
var fade_tween: Tween

func _ready() -> void:
	modulate.a = 0.0
	Signals.player_damaged.connect(_on_player_damaged)

func _on_player_damaged(_info: DamageInfo) -> void:
	# a new hit restarts the fade instead of fighting the old one
	if fade_tween:
		fade_tween.kill()
	modulate.a = peak_alpha
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_time)
