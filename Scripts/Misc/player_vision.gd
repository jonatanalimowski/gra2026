extends Node2D
class_name PlayerVision

# fog of war look (experimental): the world is darkened by a CanvasModulate and the player carries
# a shadow-casting light, so whatever walls hide stays dim. occluders live in TileMap.tres (occlusion layer 0)
# off when Entity.fog_of_war is off. enemies hiding is separate (Entity.UpdateVisibility)

# how dark unseen areas get
@export var ambient_color: Color = Color(0.567, 0.568, 0.691, 1.0)
# radius of the lit circle in world pixels, fades out over the last edge_softness share
@export var radius: float = 220.0
@export var edge_softness: float = 0.3
@export var light_color: Color = Color(1.0, 0.971, 0.914, 1.0)
# blurs the shadow edges a bit, higher = softer
@export var shadow_smooth: float = 1.25

const TEXTURE_SIZE: int = 256

var light: PointLight2D
var darkness: CanvasModulate

func _ready() -> void:
	if not Entity.fog_of_war:
		return
	darkness = CanvasModulate.new()
	darkness.color = ambient_color
	add_child(darkness)
	light = PointLight2D.new()
	light.texture = BuildLightTexture()
	light.texture_scale = radius * 2.0 / TEXTURE_SIZE
	light.color = light_color
	# lit = ambient + light, so this brings lit areas back to roughly full color
	light.energy = 1.0 - ambient_color.v
	light.shadow_enabled = true
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.shadow_filter_smooth = shadow_smooth
	add_child(light)

# radial white -> black, flat in the middle so the room around you is evenly lit
func BuildLightTexture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color.BLACK)
	gradient.add_point(1.0 - edge_softness, Color.WHITE)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = TEXTURE_SIZE
	texture.height = TEXTURE_SIZE
	return texture
