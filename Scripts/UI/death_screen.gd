extends Control

@onready var timer: Timer = %Timer
@onready var label: Label = %Label
@export var next_scene: PackedScene
@export  var is_start: bool = false

func _ready() -> void:
	timer.timeout.connect(func(): SceneTransition.transition_to(next_scene))
	if is_start:
		label.text = "Run #%d" % MetaProgress.runs_started
	timer.start()
