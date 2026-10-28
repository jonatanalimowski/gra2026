extends Resource
class_name EnemyPoolEntry

@export var scene: PackedScene
# relative chance vs other entries in the same pool
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
