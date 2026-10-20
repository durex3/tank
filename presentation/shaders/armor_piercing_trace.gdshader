shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Original ballistic profile: a fast head, tapered wake and thin brief residue.
uniform float life = 0.0;
uniform float phase = 0.0;
uniform vec4 dark_band : source_color = vec4(0.84,0.47,0.13,1.0);
uniform vec4 main_band : source_color = vec4(1.0,0.78,0.34,1.0);
uniform vec4 hot_band : source_color = vec4(1.0,0.97,0.84,1.0);
uniform float peak_fraction = 0.143;
void fragment() {
	float along = 1.0-UV.y;
	float front = min(1.2,0.18+phase*1.6);
	float behind = front-along;
	float packet = step(0.0,behind)*(1.0-smoothstep(0.0,0.28,behind));
	float residue = step(along,min(front,1.0))*pow(max(0.0,1.0-life),3.0);
	float width = 0.12*packet+0.025*residue;
	float d = abs(UV.x-0.5)/max(0.001,width);
	float shape = 1.0-smoothstep(0.92,1.0,d);
	float head_tip = step(behind,0.025)*packet;
	vec3 colour = mix(main_band.rgb,hot_band.rgb,step(d,0.48));
	colour = mix(colour,hot_band.rgb,head_tip);
	float strength = max(packet,residue*0.42);
	ALBEDO = colour;
	ALPHA = shape*strength*(1.0-smoothstep(0.55,1.0,life));
}
