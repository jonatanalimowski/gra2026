extends Resource
class_name RunEffect

# Run-wide behaviour that reacts to game events instead of projectiles
# Lives in a PactHalf, called by RunState (_on_enemy_killed etc.) while that half is active.
# Shared resource: keep per-run state in RunState.run_effect_state[self], not in variables.

func OnAdded(_player: Player) -> void: pass           # picked up / player spawned on new floor
func OnRemoved(_player: Player) -> void: pass         # its half was removed (cleansed curse): undo OnAdded
func OnEnemyKilled(_enemy: Entity, _info: DamageInfo) -> void: pass
func OnPlayerDamaged(_player: Player, _info: DamageInfo) -> void: pass
func OnRoomEntered(_room: Room) -> void: pass
func OnRoomCleared() -> void: pass
func OnFloorStarted() -> void: pass
