extends Effect
class_name ExplodingEffect

# some projectiles are explosive: they blow up where they hit an enemy or a wall
@export_range(0.0, 1.0) var chance: float = 0.15
@export var explosion_damage: float = 5
@export var override_explosion_damage_with_projectile_damage: bool = true
# explosion damage = projectile damage * this (when overriding)
@export var damage_modifier: float = 2
@export var radius: float = 32.0
@export var hits_player: bool = true
@export var tint: Color = Color(0.75, 0.5, 0.2, 1.0)
@export var explosion_scene: PackedScene

func OnProjectileSpawned(projectile: BaseProjectile) -> void:
	var is_explosive = randf() < chance
	projectile.effect_state[self] = is_explosive
	if is_explosive:
		projectile.sprite.modulate = tint

func OnHitTarget(projectile: BaseProjectile, _target: Node2D, _info: DamageInfo) -> bool:
	SpawnExplosion(projectile)
	return false

func OnHitWall(projectile: BaseProjectile, _collision: KinematicCollision2D) -> bool:
	SpawnExplosion(projectile)
	return false

func SpawnExplosion(projectile: BaseProjectile) -> void:
	if not projectile.effect_state.get(self, false):
		return
	# only once, even if the projectile survives the hit (pierce)
	projectile.effect_state[self] = false

	var dmg = explosion_damage
	if override_explosion_damage_with_projectile_damage:
		# projectile.damage already includes spell modifiers (e.g. the -50% curse)
		dmg = projectile.damage * damage_modifier
	var source = projectile.caster if is_instance_valid(projectile.caster) else null

	var explosion = explosion_scene.instantiate()
	explosion.Setup(dmg, radius, source)
	explosion.hits_player = hits_player
	explosion.global_position = projectile.global_position
	# we're inside the projectile's physics step, add it after
	projectile.get_tree().current_scene.add_child.call_deferred(explosion)
