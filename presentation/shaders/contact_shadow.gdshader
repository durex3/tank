shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float opacity : hint_range(0.0, 1.0) = 0.30;
void fragment() {
    float distance = length((UV - vec2(0.5)) * 2.0);
    ALBEDO = vec3(0.045, 0.055, 0.065);
    ALPHA = (1.0 - smoothstep(0.25, 1.0, distance)) * opacity;
}
