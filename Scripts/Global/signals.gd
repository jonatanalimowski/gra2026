extends Node

signal debug_ui_updated(string_label: Dictionary[String, Label])
signal player_health_changed(new_current: int, new_max: int)
signal player_ready(player_node: Player)
signal player_died
signal enemy_killed(enemy: Entity)
signal room_cleared
signal world_generated(layout: Array) # Array[LayoutPiece]
signal all_rooms_cleared
signal boss_spawned(hp_value: int)
signal boss_health_changed(new_current: int, new_max: int)
signal boss_defeated
