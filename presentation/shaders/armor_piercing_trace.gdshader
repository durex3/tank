shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// A single ballistic discharge: two-tick bright streak, then rapidly thinning residue.
// Both inputs are committed-tick values; no ongoing jet or repeated strand motion.
uniform float life = 0.0;
uniform float phase = 0.0;
uniform vec4 dark_band : source_color = vec4(0.84,0.47,0.13,1.0);
uniform vec4 main_band : source_color = vec4(1.0,0.78,0.34,1.0);
uniform vec4 hot_band : source_color = vec4(1.0,0.97,0.84,1.0);
uniform float peak_fraction = 0.143;
void fragment() {
	float tail = clamp((life-peak_fraction)/(1.0-peak_fraction),0.0,1.0);
	float strength = pow(1.0-tail,2.5);
	float y = UV.y;
	float taper = (0.55+0.45*smoothstep(0.0,0.08,y))*(1.0-smoothstep(0.94,1.0,y));
	float chip = 0.94+0.06*sin(y*113.0);
	float width = 0.17*taper*chip*max(0.04,strength);
	float d = abs(UV.x-0.5)/max(0.001,width);
	float silhouette = 1.0-smoothstep(0.88,1.0,d);
	// Main mass stays whole at the peak; only the fading residue breaks into segments.
	float gaps = 1.0-step(0.62,tail)*step(0.78,fract(y*11.0));
	vec3 colour = mix(main_band.rgb,hot_band.rgb,1.0-step(0.56,d));
	colour = mix(colour,dark_band.rgb,step(0.86,d));
	ALBEDO = colour;
	ALPHA = silhouette*strength*gaps;
}
