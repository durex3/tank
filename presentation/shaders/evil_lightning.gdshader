shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float phase = 0.0;
uniform float opacity = 1.0;
float hash(float n) { return fract(sin(n)*43758.5453); }
float noise(float x) {
	float i=floor(x); float f=fract(x); f=f*f*(3.0-2.0*f);
	return mix(hash(i),hash(i+1.0),f);
}
void fragment() {
	float travel=UV.y;
	float jitter=(noise(travel*47.0+phase*13.0)-0.5)*0.24;
	float strand=abs(UV.x-0.5-jitter);
	float broken=noise(travel*97.0-phase*9.0);
	float core=exp(-strand*110.0);
	float body=exp(-strand*29.0);
	float fog=exp(-strand*7.0)*(0.35+0.65*noise(travel*24.0+UV.x*15.0+phase*3.0));
	float ends=smoothstep(0.0,0.015,travel)*(1.0-smoothstep(0.985,1.0,travel));
	vec3 dark=vec3(0.23,0.0,0.035);
	vec3 red=vec3(1.0,0.008,0.025);
	ALBEDO=mix(dark,red,body);
	ALBEDO=mix(ALBEDO,vec3(1.0,0.55,0.60),core);
	ALPHA=min(0.95,fog*0.50+body*0.8+core)*ends*opacity*(0.85+0.15*broken);
}
