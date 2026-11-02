extends RunEffect
class_name ExplodeOnKillEffect

@export_range(0.0, 1.0) var chance: float = 0.25
@export var damage: float = 15.0
@export var radius: float = 48.0
@export var explosion_scene: PackedScene
# enemies with this status always explode (chance above = everyone else). empty = chance for all
@export var required_status: StatusEffect
@export var explosion_status: StatusEffect # applied by the explosion (Inferno later)
@export var explosion_status_stacks: int = 1

func OnEnemyKilled(enemy: Entity, info: DamageInfo) -> void:
	# an explosion kill can't explode again
	if not info: # and info.element == &"explosion":
		return
	# Volatile Dead + Pyromancer both active: one corpse, one explosion
	if enemy.has_meta(&"exploded_on_death"):
		return
	var has_status = required_status != null and StatusEffectHolder.TargetHas(enemy, required_status)
	if not has_status and randf() > chance:
		return
	enemy.set_meta(&"exploded_on_death", true)
	var explosion = explosion_scene.instantiate()
	explosion.Setup(damage, radius, enemy)
	explosion.status = explosion_status
	explosion.status_stacks = explosion_status_stacks
	# Inferno (Ember Tier II): the player's explosions burn, so burning packs chain
	if not explosion_status and RunState.HasFlag(&"inferno"):
		explosion.status = ExplodingEffect.INFERNO_STATUS
		explosion.status_stacks = ExplodingEffect.INFERNO_STACKS
	# harmless to the player unless a curse says otherwise (Reckless Blast)
	explosion.hits_player = RunState.HasFlag(&"explosions_hit_player")
	explosion.global_position = enemy.global_position
	# Die() runs inside a physics callback, adding areas there is not allowed
	enemy.get_tree().current_scene.add_child.call_deferred(explosion)
