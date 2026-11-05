extends Control

@onready var timer: Timer = %Timer

func _ready() -> void:
	timer.timeout.connect(func(): SceneTransition.transition_to(GameFlow.POST_RUN_SCENE))
	timer.start()
