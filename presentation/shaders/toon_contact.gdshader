shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// Original unequal lobes around a compact core; never a repeated radial star icon.
uniform sampler2D ramp : source_color, filter_nearest, repeat_disable;
uniform float life = 0.0;
uniform float spin = 0.0;
uniform float opacity = 1.0;
uniform int variant = 1; // 0 muzzle, 1 impact, 2 preparation glint
void vertex() {
	VERTEX.xy = mat2(vec2(cos(spin),-sin(spin)),vec2(sin(spin),cos(spin)))*VERTEX.xy;
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*scale.x,INV_VIEW_MATRIX[1]*scale.y,INV_VIEW_MATRIX[2]*scale.z,MODEL_MATRIX[3]);
}
float lobe(vec2 p,vec2 tip,float width) {
	float t=clamp(dot(p,tip)/dot(tip,tip),0.0,1.0);
	float radius=mix(width,0.008,t);
	return length(p-tip*t)/radius;
}
void fragment() {
	vec2 p=UV-0.5;
	if (variant==0) p=vec2(p.x*0.88,p.y*1.16);
	float core=length(p/vec2(0.14,0.12));
	float shape=min(core,lobe(p,vec2(0.35,0.08),0.095));
	shape=min(shape,lobe(p,vec2(-0.16,0.28),0.085));
	shape=min(shape,lobe(p,vec2(-0.30,-0.04),0.08));
	shape=min(shape,lobe(p,vec2(0.06,-0.23),0.065));
	if (variant==2) shape=length(p/vec2(0.23,0.12));
	float aa=max(fwidth(shape),0.008);
	float coverage=1.0-smoothstep(1.0-aa,1.0+aa,shape);
	float band=core<0.65 ? 1.0 : (core<1.25 ? 0.7 : 0.5);
	ALBEDO=texture(ramp,vec2(band,0.5)).rgb*COLOR.rgb;
	ALPHA=coverage*COLOR.a*opacity*(1.0-smoothstep(0.3,1.0,life));
}
