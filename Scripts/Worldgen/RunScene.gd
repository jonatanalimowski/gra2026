extends Node2D
class_name RunScene

# root of Main.tscn, decides when the run ends
# TODO: after the boss, generate the next floor instead of ending the run
@export var delay_after_boss: float = 3.0

func _ready() -> void:
	Signals.boss_defeated.connect(_on_boss_defeated)
	Signals.player_died.connect(_on_player_died)

func _on_boss_defeated() -> void:
	get_tree().create_timer(delay_after_boss).timeout.connect(_on_victory_delay_finished)

func _on_victory_delay_finished() -> void:
	if DevTools.infinite_floors:
		GameFlow.NextFloor()
	else:
		GameFlow.EndRun(true)

func _on_player_died() -> void:
	GameFlow.EndRun(false)
