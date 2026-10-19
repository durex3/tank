shader_type spatial;
render_mode cull_back;
varying vec3 local_position;
void vertex() { local_position = VERTEX; }
void fragment() {
	if(local_position.y > 0.065) { discard; }
	ALBEDO = mix(vec3(0.025,0.37,0.46),vec3(0.10,0.70,0.76),smoothstep(-0.38,0.07,local_position.y));
	ROUGHNESS = 0.16;
	METALLIC = 0.25;
	SPECULAR = 0.85;
}
