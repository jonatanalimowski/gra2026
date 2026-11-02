extends RunEffect
class_name DashCostEffect

# Open Wounds curse: dashing costs HP (never the last one)
@export var hp_cost: float = 2.0

func OnDashStarted(player: Player, _position: Vector2, _direction: Vector2) -> void:
	if player and player.health.current > 1.0:
		player.health.Damage(minf(hp_cost, player.health.current - 1.0))
