shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// One water body with three cel regions. No repeated droplets in the projectile silhouette.
uniform sampler2D ramp : source_color, filter_nearest, repeat_disable;
uniform float life = 0.0;
void vertex() {
	vec3 scale=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*scale.x,INV_VIEW_MATRIX[1]*scale.y,INV_VIEW_MATRIX[2]*scale.z,MODEL_MATRIX[3]);
}
void fragment() {
	vec2 p=UV-0.5;
	float d=length(p/vec2(0.39,0.42));
	float aa=max(fwidth(d),0.006);
	float band=p.y>0.15 ? 0.42 : 0.72;
	if (length((p-vec2(-0.10,-0.13))/vec2(0.16,0.09))<1.0) band=1.0;
	ALBEDO=texture(ramp,vec2(band,0.5)).rgb*COLOR.rgb;
	ALPHA=(1.0-smoothstep(1.0-aa,1.0+aa,d))*COLOR.a*(1.0-smoothstep(0.9,1.0,life));
}
