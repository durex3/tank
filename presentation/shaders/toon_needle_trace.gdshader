shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// Single short rounded ballistic streak, aligned to the committed projectile direction.
void fragment() {
	vec2 p=UV-0.5;
	float end=max(0.0,abs(p.y)-0.24)/0.25;
	float width=0.24*sqrt(max(0.0,1.0-end*end));
	float aa=max(fwidth(p.x),0.006);
	ALBEDO=abs(p.x)<width*0.45 ? vec3(1.0,0.93,0.64) : vec3(0.95,0.55,0.12);
	ALPHA=(1.0-smoothstep(width-aa,width+aa,abs(p.x)))*0.95;
}
