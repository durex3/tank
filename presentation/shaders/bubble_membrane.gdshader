shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.34,0.9,0.93,1.0);
void fragment() {
	float rim = pow(1.0-max(dot(NORMAL,VIEW),0.0),2.0);
	ALBEDO = mix(tint.rgb,vec3(0.88,0.97,1.0),0.4);
	ALPHA = 0.075+rim*0.14;
}
