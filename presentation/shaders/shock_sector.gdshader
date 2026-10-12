shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;

uniform sampler2D dust : source_color, filter_linear_mipmap;
uniform float half_angle_cos = 0.819152;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 ground = (UV - vec2(0.5)) * 2.0;
	float radius = length(ground);
	float forward = -ground.y / max(radius, 0.001);
	float fan = smoothstep(half_angle_cos, half_angle_cos + 0.035, forward);
	float edge = 1.0 - smoothstep(0.97, 1.0, radius);
	// The source crescent faces right; rotate its UV so it faces local -Z.
	vec2 art_uv = vec2(-ground.y, ground.x) * 0.5 + vec2(0.5);
	vec4 art = texture(dust, art_uv);
	ALBEDO = art.rgb;
	ALPHA = art.a * fan * edge * opacity;
}
