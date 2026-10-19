shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Tick phase, hard three-band intertwined strands. No halo or time-based motion.
uniform float life = 0.0;
uniform float phase = 0.0;
uniform vec4 dark_band : source_color = vec4(0.20,0.012,0.025,1.0);
uniform vec4 main_band : source_color = vec4(0.62,0.025,0.065,1.0);
uniform vec4 hot_band : source_color = vec4(0.82,0.09,0.12,1.0);
uniform float peak_fraction = 0.143;
void fragment() {
	float tail = clamp((life-peak_fraction)/(1.0-peak_fraction),0.0,1.0);
	float strength = pow(1.0-tail,1.5);
	float taper = 0.4+0.6*sin(UV.y*3.14159);
	float coverage = -1.0;
	for (int i=0; i<3; i++) {
		float k = float(i);
		float center = 0.5+sin(UV.y*(19.0+k*3.0)-phase+k*2.094)*0.15*taper;
		float width = (0.04+0.08*(0.5+0.5*sin(UV.y*39.0+k*5.0-phase)))*taper*max(0.05,strength);
		coverage = max(coverage,1.0-abs(UV.x-center)/width);
	}
	float band = coverage > 0.75 ? 1.0 : (coverage > 0.3 ? 0.7 : 0.3);
	ALBEDO = band > 0.9 ? hot_band.rgb : (band > 0.5 ? main_band.rgb : dark_band.rgb);
	float tear = 0.5+0.5*sin(UV.y*91.0+UV.x*31.0+phase);
	ALPHA = step(0.0,coverage)*step(tail*0.9,tear)*strength;
}
