extends Resource
class_name RunEffect

# Run-wide behaviour that reacts to game events instead of projectiles
# Lives in a PactHalf, called by RunState (_on_enemy_killed etc.) while that half is active.
# Shared resource: keep per-run state in RunState.run_effect_state[self], not in variables.

func OnAdded(_player: Player) -> void: pass           # picked up / player spawned on new floor
func OnRemoved(_player: Player) -> void: pass         # its half was removed (cleansed curse): undo OnAdded
func OnEnemyKilled(_enemy: Entity, _info: DamageInfo, _xp_drop: int, _is_elite: bool) -> void: pass
func OnEnemyFrozen(_enemy: Entity) -> void: pass # Chill reached max stacks (not bosses: they get Brittle)
func OnEnemyDamaged(_enemy: Entity, _info: DamageInfo, _amount: float) -> void: pass # amount = what it really lost
func OnProcess(_player: Player, _delta: float) -> void: pass # every physics frame while the player lives
func OnPlayerDamaged(_player: Player, _info: DamageInfo) -> void: pass
func OnRoomEntered(_room: Room) -> void: pass
func OnRoomCleared() -> void: pass
func OnFloorStarted() -> void: pass
# Dash slot
func OnDashStarted(_player: Player, _position: Vector2, _direction: Vector2) -> void: pass
func OnDashedThrough(_player: Player, _enemy: Entity) -> void: pass # once per enemy per dash
func OnDashEnded(_player: Player, _position: Vector2) -> void: pass
# Orb slot. mana = what the player actually got (after mana_gain)
func OnOrbCollected(_player: Player, _orb: ManaOrb, _mana: float) -> void: pass
func OnOrbProcess(_orb: ManaOrb, _delta: float) -> void: pass # every physics frame while it flies to the player
# a shield (Hoarfrost) ate a hit instead of the player
func OnHitBlocked(_player: Player, _info: DamageInfo) -> void: pass
