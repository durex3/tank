shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D orm_map : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool has_orm_map = true;
uniform bool has_normal_map = true;
uniform float cleanup_strength : hint_range(0.0, 1.0) = 0.45;
uniform float speckle_cleanup : hint_range(0.0, 1.0) = 0.75;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.45;
uniform vec4 armor_color : source_color = vec4(0.92, 0.91, 0.85, 1.0);
uniform bool rolling_track = false;
uniform float track_travel = 0.0;
varying vec3 source_position;

void vertex() {
    source_position = VERTEX;
}

void fragment() {
    vec3 source = texture(albedo_map, UV).rgb;
    vec3 orm = has_orm_map ? texture(orm_map, UV).rgb : vec3(1.0, 0.68, 0.18);
    float high = max(source.r, max(source.g, source.b));
    float low = min(source.r, min(source.g, source.b));
    float saturation = (high - low) / max(high, 0.001);
    // Clean only bright neutral paint; keep dark seams, gold and optical details.
    float paint = smoothstep(0.28, 0.62, low) * (1.0 - smoothstep(0.22, 0.42, saturation));
    // A coarse neighbourhood distinguishes isolated neutral grime from broad dark hardware.
    vec3 neighbourhood = textureLod(albedo_map, UV, 3.0).rgb;
    float nearby_paint = smoothstep(0.32, 0.60, min(neighbourhood.r, min(neighbourhood.g, neighbourhood.b)));
    float isolated = nearby_paint * (1.0 - smoothstep(0.16, 0.34, saturation));
    paint = max(paint, isolated * speckle_cleanup);
    ALBEDO = mix(source, armor_color.rgb, paint * cleanup_strength);
    if (rolling_track) {
        float z = source_position.z;
        float y = source_position.y + 0.257;
        float path;
        if (z > 0.106) {
            path = 0.811 + 0.266 * (1.570796 - atan(y, z - 0.106));
        } else if (z < -0.705) {
            path = 2.0 * 0.811 + 0.266 * 3.141593 + 0.266 * (atan(y, -z - 0.705) + 1.570796);
        } else {
            path = y >= 0.0 ? z + 0.705 : 0.811 + 0.266 * 3.141593 + 0.106 - z;
        }
        float rubber = 1.0 - smoothstep(0.12, 0.25, high);
        float tread = smoothstep(0.25, 0.65, sin((path - track_travel) * 90.0));
        ALBEDO = mix(ALBEDO, ALBEDO * (0.60 + tread * 0.65), rubber);
    }
    float brass = smoothstep(0.30, 0.55, saturation) * smoothstep(0.04, 0.18, source.r - source.b)
        * (1.0 - smoothstep(0.05, 0.20, source.b - source.g));
    float metallic = has_orm_map ? orm.b : mix(0.12, 0.75, brass);
    float roughness = has_orm_map ? clamp(orm.g, 0.35, 0.95) : mix(0.68, 0.38, brass);
    METALLIC = mix(metallic, 0.12, paint);
    ROUGHNESS = mix(roughness, 0.78, paint);
    AO = mix(1.0, clamp(orm.r, 0.65, 1.0), 0.35);
    if (has_normal_map) {
        NORMAL_MAP = texture(normal_map, UV).rgb;
        NORMAL_MAP_DEPTH = normal_strength;
    }
}
