extends Resource
class_name MobilityAbility

# what happens when the player presses Dash. subclasses: DashAbility (later Blink, Decoy...)
# the player only provides building blocks (StartDash, MakeInvulnerable, global_position)
@export var cooldown: float = 1.0

func Activate(_player: Player, _direction: Vector2) -> void:
	pass
