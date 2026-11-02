extends RunEffect
class_name DashEffect

# Dash slot pacts. any mix of:
# - trail: StatusAreas along the dash path (Trail of Cinders)
# - end area: one StatusArea where the dash ends (Cold Snap)
# - through status: enemies dashed through get a status (Cold Snap)
@export var trail_area_scene: PackedScene
@export var trail_spacing: float = 14.0
@export var end_area_scene: PackedScene
@export var area_radius: float = 16.0
@export var through_status: StatusEffect
@export var through_stacks: int = 1
@export var heal_per_enemy: float = 0.0 # Crimson Step
# a pulse where the dash starts (Blink Step: Shock)
@export var start_status: StatusEffect
@export var start_radius: float = 50.0
@export var start_color: Color = Color(1.0, 0.9, 0.3)

func OnDashStarted(player: Player, position: Vector2, _direction: Vector2) -> void:
	RunState.run_effect_state[self] = position
	if start_status and player:
		for enemy in player.get_tree().get_nodes_in_group("enemy"):
			if not enemy.is_dead and enemy.global_position.distance_to(position) < start_radius:
				enemy.ApplyStatus(start_status, player)
		var ring = NovaRing.new()
		ring.radius = start_radius
		ring.color = start_color
		ring.global_position = position
		player.get_tree().current_scene.add_child(ring)

func OnDashedThrough(player: Player, enemy: Entity) -> void:
	if through_status and is_instance_valid(enemy):
		enemy.ApplyStatus(through_status, player, 1.0, 1.0, through_stacks)
	if heal_per_enemy > 0.0 and player:
		player.health.Heal(heal_per_enemy, false)

func OnDashEnded(player: Player, position: Vector2) -> void:
	var start: Vector2 = RunState.run_effect_state.get(self, position)
	if trail_area_scene:
		var length = start.distance_to(position)
		var count = maxi(int(length / trail_spacing), 1)
		for i in count + 1:
			SpawnArea(player, trail_area_scene, start.lerp(position, float(i) / count))
	if end_area_scene:
		SpawnArea(player, end_area_scene, position)

func SpawnArea(player: Player, scene: PackedScene, position: Vector2) -> void:
	var area = scene.instantiate() as StatusArea
	area.Setup(area_radius, player)
	area.global_position = position
	player.get_tree().current_scene.add_child.call_deferred(area)
