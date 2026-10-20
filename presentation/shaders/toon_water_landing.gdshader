shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// One expanding impact wave on XZ; coverage never exceeds the field radius.
uniform float life = 0.0;
void fragment() {
	vec2 p=UV-0.5;
	float angle=atan(p.y,p.x);
	float distance=length(p);
	float radius=mix(0.08,0.47,1.0-pow(1.0-life,2.0));
	float wobble=sin(angle*5.0)*0.008;
	float edge=abs(distance-radius-wobble);
	float aa=max(fwidth(distance),0.001);
	float wave=1.0-smoothstep(0.018-aa,0.026+aa,edge);
	float core=1.0-smoothstep(0.006,0.011,edge);
	ALBEDO=mix(vec3(0.04,0.52,0.66),vec3(0.85,1.0,0.96),core);
	ALPHA=wave*(1.0-smoothstep(0.65,1.0,life))*(1.0-step(0.49,distance));
}
