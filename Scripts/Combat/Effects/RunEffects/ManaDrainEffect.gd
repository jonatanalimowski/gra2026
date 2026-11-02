extends RunEffect
class_name ManaDrainEffect

# Leak curse: above `threshold` mana you lose `per_second`
@export var threshold: float = 50.0
@export var per_second: float = 2.0

func OnProcess(player: Player, delta: float) -> void:
	if player.mana > threshold:
		player.AddMana(-minf(per_second * delta, player.mana - threshold))
