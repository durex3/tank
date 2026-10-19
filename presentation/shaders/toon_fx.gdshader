shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// R = cel band, G = erosion key, A = coverage. life is injected from committed ticks only.

uniform sampler2D sheet : filter_linear, repeat_disable;
uniform sampler2D ramp : source_color, filter_nearest, repeat_disable;
uniform vec2 frames = vec2(2.0, 2.0);
uniform float cell = 0.0;
uniform bool use_instance_cell = false;
uniform float erode_start = 0.35;
uniform float erode_softness = 0.06;
uniform float ramp_shift = 0.12;
uniform float life = 0.0;
uniform float camera_pull = 0.0;
uniform float spin = 0.0;
uniform float lift = 0.0;
uniform float opacity = 1.0;
uniform bool billboard = true;

void vertex() {
	if (billboard) {
		float angle = spin;
		VERTEX.xy = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle))) * VERTEX.xy;
		VERTEX.y += lift;
		vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
		vec3 cam_z = normalize(INV_VIEW_MATRIX[2].xyz);
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			INV_VIEW_MATRIX[0] * scale.x,
			INV_VIEW_MATRIX[1] * scale.y,
			INV_VIEW_MATRIX[2] * scale.z,
			vec4(MODEL_MATRIX[3].xyz + cam_z * camera_pull, 1.0));
	}
	float index = use_instance_cell ? floor(clamp(INSTANCE_CUSTOM.z, 0.0, 0.999) * frames.x * frames.y) : cell;
	UV = (UV + vec2(mod(index, frames.x), floor(index / frames.x))) / frames;
}

void fragment() {
	vec4 texel = texture(sheet, UV);
	float value = clamp(texel.r - ramp_shift * life, 0.0, 1.0);
	vec3 colour = texture(ramp, vec2(value, 0.5)).rgb;
	float threshold = smoothstep(erode_start, 1.0, life);
	float keep = smoothstep(threshold, threshold + erode_softness, texel.g);
	ALBEDO = colour * COLOR.rgb;
	ALPHA = texel.a * keep * COLOR.a * opacity;
}
