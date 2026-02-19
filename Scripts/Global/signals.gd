extends Node

signal debug_ui_updated(string_label: Dictionary[String, Label])
signal player_health_changed(new_current: int, new_max: int)
signal player_ready(player_node: CharacterBody2D)
signal enemy_killed()
signal player_stat_changed(stat_name: String, value: float)
