extends RunEffect
class_name MoteOnKillEffect

# Bloodthirst: enemies that die with the status drop a blood mote (heal-only orb)
@export var status: StatusEffect
@export var heal: float = 3.0

func OnEnemyKilled(enemy: Entity, _info: DamageInfo, _xp: int, _is_elite: bool) -> void:
	if status == null or StatusEffectHolder.TargetHas(enemy, status):
		ManaOrb.SpawnMote(enemy.get_tree().current_scene, enemy.global_position, heal)
