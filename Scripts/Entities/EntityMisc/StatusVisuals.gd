extends Node2D
class_name StatusVisuals

# layers 2 + 3 of status readability (BUILD_DESIGN.md §9), created by Entity._ready:
# - outline in the color of the highest-priority status (status_outline.gdshader on the sprite)
# - body effects: Freeze = ice look + stopped animation, Chill = slower animation, Burn = embers.
# never touches modulate/self_modulate, those belong to hit flashes and elite tints
const OUTLINE_SHADER = preload("res://Shaders/status_outline.gdshader")
const FREEZE_STATUS = preload("res://Data/Statuses/Freeze.tres")
const CHILL_STATUS = preload("res://Data/Statuses/Chill.tres")
const BURN_STATUS = preload("res://Data/Statuses/Burn.tres")
const SHOCK_STATUS = preload("res://Data/Statuses/Shock.tres")
const BLEED_STATUS = preload("res://Data/Statuses/Bleed.tres")
const CRACKLE_INTERVAL: float = 0.3
var crackle_timer: float = 0.0
var crackle_points: PackedVector2Array = []
var drips: CPUParticles2D
const CHILL_ANIM_SLOW_PER_STACK: float = 0.1
const EMBERS_PER_STACK: int = 3

var entity: Entity
var sprite: AnimatedSprite2D
var holder: StatusEffectHolder
var outline_material: ShaderMaterial
# one emitter per Burn stack, turned on/off: changing amount would restart the particles
var embers: Array[CPUParticles2D] = []

func Setup(owner_entity: Entity) -> void:
	entity = owner_entity
	sprite = entity.sprite
	holder = entity.status_holder

	outline_material = ShaderMaterial.new()
	outline_material.shader = OUTLINE_SHADER
	sprite.material = outline_material
	sprite.frame_changed.connect(UpdateRegion)
	sprite.animation_changed.connect(UpdateRegion)
	UpdateRegion()

	for i in BURN_STATUS.max_stacks:
		var emitter := CreateEmbers()
		embers.append(emitter)
		add_child(emitter)

	drips = CreateDrips()
	add_child(drips)
	holder.status_added.connect(_on_status_event)
	holder.status_changed.connect(_on_status_event)
	holder.status_removed.connect(_on_status_event)
	Refresh()

func _on_status_event(_status: ActiveStatusEffect) -> void:
	Refresh()

func Refresh() -> void:
	if not is_instance_valid(sprite):
		return
	# outline: strongest status that has one
	var best: StatusEffect = null
	for status in holder.active:
		var effect := status.effect
		if effect.outline_color.a > 0.0 and (best == null or effect.priority > best.priority):
			best = effect
	outline_material.set_shader_parameter("outline_color", best.outline_color if best else Color(0, 0, 0, 0))

	var frozen := holder.Has(FREEZE_STATUS)
	outline_material.set_shader_parameter("frozen", 1.0 if frozen else 0.0)
	var chill_stacks := holder.GetStacks(CHILL_STATUS)
	sprite.speed_scale = 0.0 if frozen else maxf(1.0 - CHILL_ANIM_SLOW_PER_STACK * chill_stacks, 0.2)

	drips.emitting = holder.Has(BLEED_STATUS)
	if not holder.Has(SHOCK_STATUS):
		crackle_points.clear()
		queue_redraw()
	var burn_stacks := holder.GetStacks(BURN_STATUS)
	for i in embers.size():
		embers[i].emitting = i < burn_stacks

# Shock: a jagged yellow line flickers over the body every CRACKLE_INTERVAL
func _process(delta: float) -> void:
	if holder == null or not holder.Has(SHOCK_STATUS):
		return
	crackle_timer -= delta
	if crackle_timer <= 0.0:
		crackle_timer = CRACKLE_INTERVAL
		var top = entity.GetSpriteTop()
		crackle_points = PackedVector2Array()
		var x = randf_range(-6, 6)
		for i in 5:
			crackle_points.append(Vector2(x + randf_range(-4, 4), lerpf(top, 0, i / 4.0)))
		queue_redraw()
	elif crackle_timer < CRACKLE_INTERVAL * 0.5 and not crackle_points.is_empty():
		crackle_points.clear() # 2-frame flicker: on half the interval, off the other half
		queue_redraw()

func _draw() -> void:
	if crackle_points.size() > 1:
		draw_polyline(crackle_points, Color(1.0, 0.95, 0.4), 1.0)

func CreateDrips() -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.emitting = false
	particles.amount = 3
	particles.lifetime = 0.6
	particles.local_coords = false
	particles.position = Vector2(0, entity.GetSpriteTop() / 2.0)
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(5, 3)
	particles.direction = Vector2.DOWN
	particles.gravity = Vector2(0, 120)
	particles.initial_velocity_min = 5.0
	particles.initial_velocity_max = 15.0
	particles.color = Color(0.7, 0.05, 0.1)
	particles.z_index = 5
	return particles

# the shader needs the current frame's rect, atlas frames would bleed in from their neighbors otherwise
func UpdateRegion() -> void:
	if not sprite.sprite_frames or not sprite.sprite_frames.has_animation(sprite.animation):
		return
	var texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var region := Vector4(0, 0, 1, 1)
	if texture is AtlasTexture and texture.atlas:
		var size = Vector2(texture.atlas.get_size())
		var rect: Rect2 = texture.region
		region = Vector4(rect.position.x / size.x, rect.position.y / size.y, rect.end.x / size.x, rect.end.y / size.y)
	outline_material.set_shader_parameter("region", region)

# small orange squares rising from the body
func CreateEmbers() -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.emitting = false
	particles.amount = EMBERS_PER_STACK
	particles.lifetime = 0.7
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	var top = entity.GetSpriteTop()
	particles.position = Vector2(0, top / 2.0)
	particles.emission_rect_extents = Vector2(6, maxf(absf(top) / 2.0, 4.0))
	particles.direction = Vector2.UP
	particles.spread = 25.0
	particles.gravity = Vector2(0, -40)
	particles.initial_velocity_min = 10.0
	particles.initial_velocity_max = 25.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.85, 0.3))
	ramp.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
	particles.color_ramp = ramp
	particles.z_index = 5
	return particles
