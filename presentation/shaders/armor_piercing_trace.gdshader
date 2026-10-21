shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// A rounded projectile smear and a readable fading wake, scaled in metres.
uniform float life = 0.0;
uniform float phase = 0.0;
uniform float length_m = 16.0;
uniform vec4 dark_band : source_color = vec4(0.84,0.47,0.13,1.0);
uniform vec4 main_band : source_color = vec4(1.0,0.78,0.34,1.0);
uniform vec4 hot_band : source_color = vec4(1.0,0.97,0.84,1.0);
uniform float wake_half_width = 0.106;
uniform float wake_strength = 0.92;
void fragment() {
	float along=1.0-UV.y;
	float front=0.18+phase*1.6;
	float distance=(front-along)*length_m;
	float cap=sqrt(max(0.0,1.0-pow((distance-0.28)/0.42,2.0)));
	float tail=step(0.45,distance)*max(0.0,1.0-(distance-0.45)/1.45);
	float residue=step(along,min(front,1.0))*pow(max(0.0,1.0-smoothstep(0.25,1.0,life)),0.65);
	float width=max(cap*0.19,tail*0.08)+residue*wake_half_width;
	float d=abs(UV.x-0.5)/max(0.001,width);
	float coverage=1.0-smoothstep(0.90,1.0,d);
	float packet=max(cap,tail*0.65);
	float strength=max(packet,residue*wake_strength);
	ALBEDO=mix(dark_band.rgb,mix(main_band.rgb,hot_band.rgb,step(d,0.45)),step(d,0.82));
	ALPHA=coverage*strength*(1.0-smoothstep(0.65,1.0,life));
}
