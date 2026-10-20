shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// Original compact contact glyph. Palette bands stay solid; only coverage edges anti-alias.
uniform sampler2D ramp : source_color, filter_nearest, repeat_disable;
uniform float life = 0.0;
uniform float spin = 0.0;
uniform float opacity = 1.0;
void vertex() {
	VERTEX.xy = mat2(vec2(cos(spin),-sin(spin)),vec2(sin(spin),cos(spin)))*VERTEX.xy;
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*scale.x,INV_VIEW_MATRIX[1]*scale.y,INV_VIEW_MATRIX[2]*scale.z,MODEL_MATRIX[3]);
}
void fragment() {
	vec2 p = UV-0.5;
	float angle = atan(p.y,p.x);
	float ray = pow(max(0.0,cos(angle*5.0+0.35)),5.0);
	float radius = 0.17+0.24*ray;
	float d = length(p)/radius;
	float aa = max(fwidth(d),0.008);
	float shape = 1.0-smoothstep(1.0-aa,1.0+aa,d);
	float band = length(p)<0.115 ? 1.0 : (d<0.65 ? 0.7 : 0.5);
	ALBEDO = texture(ramp,vec2(band,0.5)).rgb*COLOR.rgb;
	ALPHA = shape*COLOR.a*opacity*(1.0-smoothstep(0.45,1.0,life));
}
