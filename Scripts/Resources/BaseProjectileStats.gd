extends Resource
class_name ProjectileStats

enum team {PLAYER, ENEMY}
@export var damage: float = 25.0
@export var speed: float = 1.0
@export var lifetime: float = 5.0
@export var current_team: team = team.ENEMY
