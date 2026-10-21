shader_type spatial;
render_mode ambient_light_disabled, cull_back;
// Original sample finish: broad lighting, warm paint, local vertex occlusion and restrained highlights.
uniform vec4 base_color : source_color = vec4(0.75,0.75,0.70,1.0);
uniform float roughness_value = 0.6;
uniform float ambient_strength = 0.30;
uniform float wrap_amount = 0.32;
uniform float occlusion_strength = 0.65;
uniform float top_bottom_strength = 0.12;
uniform float highlight_strength = 0.10;
uniform float key_strength = 0.80;
varying float local_occlusion;
varying float upward;
void vertex() {
	local_occlusion = mix(1.0,COLOR.r,occlusion_strength);
	upward = (MODEL_NORMAL_MATRIX*NORMAL).y;
}
void fragment() {
	ALBEDO=base_color.rgb*local_occlusion*(1.0-top_bottom_strength*(1.0-clamp(upward*0.5+0.5,0.0,1.0)));
	ROUGHNESS=roughness_value;
	METALLIC=0.0;
	EMISSION=ALBEDO*ambient_strength;
}
void light() {
	float diffuse=clamp((dot(NORMAL,LIGHT)+wrap_amount)/(1.0+wrap_amount),0.0,1.0);
	vec3 illumination=LIGHT_COLOR*ATTENUATION/3.141593;
	DIFFUSE_LIGHT+=illumination*diffuse*key_strength;
	vec3 half_vector=normalize(LIGHT+VIEW);
	float broad=pow(max(0.0,dot(NORMAL,half_vector)),mix(24.0,8.0,roughness_value));
	SPECULAR_LIGHT+=illumination*broad*highlight_strength;
}
