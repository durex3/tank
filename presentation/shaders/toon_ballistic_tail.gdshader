shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// Solid open-ended wake behind the bullet, narrowing and fading toward its tail.
void fragment() {
	float along=clamp(UV.y,0.0,1.0);
	float width=mix(0.42,0.015,along);
	float d=abs(UV.x-0.5);
	float aa=max(fwidth(d),0.004);
	ALBEDO=along<0.35 ? vec3(1.0,0.80,0.32) : vec3(0.88,0.42,0.08);
	ALPHA=(1.0-smoothstep(width-aa,width+aa,d))*(1.0-smoothstep(0.15,1.0,along))*0.85;
}
