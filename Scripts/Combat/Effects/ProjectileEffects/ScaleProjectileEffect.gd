extends Effect
class_name ScaleProjectileEffect

# bigger projectiles (sprite + hitbox): Hemoclast saws
@export var scale: float = 1.5

func OnProjectileSpawned(projectile: BaseProjectile) -> void:
	projectile.scale *= scale
