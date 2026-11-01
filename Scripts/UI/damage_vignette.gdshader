shader_type canvas_item;

// clear in the middle, the rect's color at the screen edges
uniform float inner_radius = 0.3;
uniform float outer_radius = 0.6;

void fragment() {
	COLOR.a *= smoothstep(inner_radius, outer_radius, distance(UV, vec2(0.5)));
}
