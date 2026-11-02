shader_type canvas_item;

// enemy status readability (BUILD_DESIGN.md §9), set up by StatusVisuals:
// a 1px outline in the color of the strongest status + a frozen look.
// works on top of modulate/self_modulate, so elite tints and hit flashes still show

uniform vec4 outline_color : source_color = vec4(0.0); // alpha 0 = no outline
// current frame's rect in the texture as uv (min.xy, max.xy). sprite frames are often atlas
// regions, without this the outline would pick up pixels of the neighbor frame
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
uniform float frozen : hint_range(0.0, 1.0) = 0.0;

// 1 inside the current frame, 0 outside
float in_region(vec2 uv) {
	return step(region.x, uv.x) * step(region.y, uv.y) * step(uv.x, region.z) * step(uv.y, region.w);
}

void fragment() {
	// COLOR already is texture * modulate here, multiplying by the texture again darkens everything
	vec4 tex = texture(TEXTURE, UV);
	vec4 col = COLOR;

	if (frozen > 0.0) {
		float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		vec3 ice = gray * vec3(0.7, 0.9, 1.1) + vec3(0.15, 0.25, 0.35);
		col.rgb = mix(col.rgb, ice, frozen);
	}

	if (tex.a < 0.1 && outline_color.a > 0.0) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		vec2 r = UV + vec2(px.x, 0.0);
		vec2 l = UV - vec2(px.x, 0.0);
		vec2 d = UV + vec2(0.0, px.y);
		vec2 u = UV - vec2(0.0, px.y);
		float near = max(
			max(texture(TEXTURE, r).a * in_region(r), texture(TEXTURE, l).a * in_region(l)),
			max(texture(TEXTURE, d).a * in_region(d), texture(TEXTURE, u).a * in_region(u)));
		if (near > 0.1) {
			// not COLOR.a: that's the texture alpha too, 0 on the transparent pixels the outline sits on
			col = outline_color;
		}
	}
	COLOR = col;
}
