shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;
void fragment() {
	float rim = pow(1.0-max(dot(NORMAL,VIEW),0.0),2.5);
	ALBEDO = mix(vec3(0.65,0.91,0.95),vec3(0.24,0.74,0.83),rim);
	METALLIC = 0.15;
	ROUGHNESS = 0.08;
	SPECULAR = 0.9;
	ALPHA = 0.08+rim*0.64;
}
