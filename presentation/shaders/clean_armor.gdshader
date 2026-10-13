shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D orm_map : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool has_orm_map = true;
uniform bool has_normal_map = true;
uniform float cleanup_strength : hint_range(0.0, 1.0) = 0.45;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.45;
uniform vec4 armor_color : source_color = vec4(0.92, 0.91, 0.85, 1.0);

void fragment() {
    vec3 source = texture(albedo_map, UV).rgb;
    vec3 orm = has_orm_map ? texture(orm_map, UV).rgb : vec3(1.0, 0.68, 0.18);
    float high = max(source.r, max(source.g, source.b));
    float low = min(source.r, min(source.g, source.b));
    float saturation = (high - low) / max(high, 0.001);
    // Clean only bright neutral paint; keep dark seams, gold and optical details.
    float paint = smoothstep(0.28, 0.62, low) * (1.0 - smoothstep(0.22, 0.42, saturation));
    ALBEDO = mix(source, armor_color.rgb, paint * cleanup_strength);
    float brass = smoothstep(0.30, 0.55, saturation) * smoothstep(0.04, 0.18, source.r - source.b)
        * (1.0 - smoothstep(0.05, 0.20, source.b - source.g));
    float metallic = has_orm_map ? orm.b : mix(0.12, 0.75, brass);
    float roughness = has_orm_map ? clamp(orm.g, 0.35, 0.95) : mix(0.68, 0.38, brass);
    METALLIC = mix(metallic, 0.12, paint);
    ROUGHNESS = mix(roughness, 0.68, paint);
    if (has_normal_map) {
        NORMAL_MAP = texture(normal_map, UV).rgb;
        NORMAL_MAP_DEPTH = normal_strength;
    }
}
