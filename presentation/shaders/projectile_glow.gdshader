shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(1.0,0.5,0.1,1.0);
void fragment() {
	float taper = mix(0.08,0.8,UV.y);
	float cross_section = max(0.0,1.0-abs(UV.x-0.5)*2.0/taper);
	float ends = smoothstep(0.0,0.16,UV.y)*(1.0-smoothstep(0.82,1.0,UV.y));
	ALBEDO = mix(tint.rgb,vec3(0.48,0.16,0.025),pow(cross_section,5.0));
	ALPHA = pow(cross_section,1.8)*ends*0.5;
}
