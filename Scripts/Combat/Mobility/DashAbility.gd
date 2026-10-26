extends MobilityAbility
class_name DashAbility

# the classic dash, same values the player had before in PlayerStats
@export var distance: float = 25.0
@export var speed: float = 300.0

func Activate(player: Player, direction: Vector2) -> void:
	var duration = distance / speed
	player.StartDash(direction * speed, duration)
	player.MakeInvulnerable(duration)
