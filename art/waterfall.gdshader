shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
// Falling water: the pools' own water picture, pixel-snapped the same way, pulled down the sheet in two layers at
// different speeds, with foam streaks, white water where it tips over the kerb (UV.y is the distance fallen) and
// where it lands (UV2.y is the distance still to fall). The picture and its set come from the texture catalog.

uniform sampler2D water_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D foam_texture : filter_nearest_mipmap, repeat_enable;

void fragment() {
    vec2 pixel = floor(vec2(UV.x, UV.y) * 32.0) / 32.0;
    vec3 fast = texture(water_texture, vec2(pixel.x * 0.9, pixel.y * 0.45 - TIME * 0.9)).rgb;
    vec3 slow = texture(water_texture, vec2(pixel.x * 0.7 + 0.37, pixel.y * 0.3 - TIME * 0.55)).rgb;
    vec3 water = mix(fast, slow, 0.45) * vec3(0.92, 1.08, 1.12);
    float streaks = texture(foam_texture, vec2(pixel.x * 1.6, pixel.y * 0.5 - TIME * 1.3)).r;
    float white = step(0.58, streaks) * 0.55;
    float lip = 1.0 - smoothstep(0.0, 0.16, UV.y);
    float landing = 1.0 - smoothstep(0.0, 0.22, UV2.y);
    white = max(white, max(lip * 0.7, landing * 0.85) * step(0.35, streaks + 0.25));
    ALBEDO = mix(water, vec3(0.88, 0.97, 0.96), clamp(white, 0.0, 0.85));
    // A faint glow keeps a waterfall bright on the shaded faces of cliffs.
    EMISSION = ALBEDO * 0.12;
    ROUGHNESS = 0.25;
    SPECULAR = 0.45;
}
