extends Node

signal debug_ui_updated(string_label: Dictionary[String, Label])
signal player_health_changed(new_current: int, new_max: int)
signal player_ready(player_node: CharacterBody2D)
signal enemy_killed()
signal player_stat_changed(stat_name: String, value: float, is_detailed: bool)
signal player_weapon_changed(slot_number: int)
signal weapon_stat_changed(stat_name: String, value: float, slot_number: int, is_detailed: bool)
signal room_cleared
signal world_generated(room_amount: int)
signal all_rooms_cleared
signal boss_spawned(hp_value: int)
signal boss_health_changed(new_current: int, new_max: int)
signal boss_defeated
