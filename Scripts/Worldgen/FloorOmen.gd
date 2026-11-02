extends PactHalf
class_name FloorOmen

# one rule for a whole floor (BUILD_DESIGN.md §8.4), from floor 2. a PactHalf, so its enemy_modifiers,
# run_effects, flags and elite_chance_multiplier work like any curse. RunState.RollOmens adds it as a half
# for one floor (GameFlow.NextFloor), shown under the HUD floor label
@export var icon: Texture2D
@export var min_floor: int = 2
@export var enemy_count_multiplier: float = 1.0 # Swarm: 1.5 = every spawn marker has a 50% chance of a 2nd enemy
@export var elite_glyph_bonus: float = 0.0 # Champions: extra glyph chance per elite killed
@export var enemy_ward_group: StringName = &"" # Kindled Halls: every enemy is Warded against this
