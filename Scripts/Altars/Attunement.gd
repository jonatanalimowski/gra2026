extends Resource
class_name Attunement

# a school tier (BUILD_DESIGN.md §6): reached at `threshold` school points (slot pact 2, glyph 1),
# then RunState adds `blessing` like any other half. lost again if the points drop (slot replaced).
# listed in RunState.ATTUNEMENTS
@export var school: School.Kind = School.Kind.NONE
@export var threshold: int = 4
@export var tier: int = 1
@export var display_name: String = ""
@export var blessing: Blessing
