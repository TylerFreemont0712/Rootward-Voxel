shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D control_map : filter_nearest, repeat_disable;
uniform sampler2DArray ground_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D warp_noise : filter_linear, repeat_enable;
uniform ivec2 control_size;
uniform int layer_of[64];
uniform vec4 tint_of[64];
uniform float tile_of[64];
uniform float height_strength : hint_range(0.0, 1.0) = 0.65;
uniform float warp_amplitude : hint_range(0.0, 2.0) = 1.25;
// Land levels, one texel per cell (level * 64). Terraces get a dark contour along every edge that drops away, so
// their far edges read from the fixed camera, and lower ground darkens softly at the foot of a cliff.
uniform sampler2D level_map : filter_nearest, repeat_disable;
uniform ivec2 level_size = ivec2(1);
uniform float contour_width = 0.07;
uniform float contour_shade : hint_range(0.0, 1.0) = 0.66;
uniform float foot_shade : hint_range(0.0, 1.0) = 0.8;
varying vec2 ground;

float level_of(ivec2 cell) {
    if (cell.x < 0 || cell.y < 0 || cell.x >= level_size.x || cell.y >= level_size.y) {
        return 0.0;
    }
    return floor(texelFetch(level_map, cell, 0).r * 255.0 / 64.0 + 0.5);
}

void vertex() {
    ground = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
    vec2 g = floor(ground * 32.0) / 32.0;
    vec2 warp = (texture(warp_noise, g * 0.21).rg - 0.5) * warp_amplitude;
    // Cell centres are whole numbers. Sub-tile centres sit at cell centre +/- 0.25.
    vec2 p = vec2(g.x, -g.y) * 2.0 + 0.5 + warp;
    ivec2 i = ivec2(floor(p));
    vec2 f = fract(p);
    float best = -2.0;
    vec3 colour = vec3(0.0);
    for (int k = 0; k < 4; k++) {
        ivec2 offset = ivec2(k & 1, k >> 1);
        ivec2 c = clamp(i + offset, ivec2(0), control_size - ivec2(1));
        float w = (offset.x == 1 ? f.x : 1.0 - f.x) * (offset.y == 1 ? f.y : 1.0 - f.y);
        int idx = int(texelFetch(control_map, c, 0).r * 255.0 + 0.5);
        vec4 s = texture(ground_albedo, vec3((g + 0.5 / 32.0) / tile_of[idx], float(layer_of[idx])));
        float score = w + (s.a - 0.5) * height_strength;
        if (score > best) {
            best = score;
            colour = s.rgb * tint_of[idx].rgb;
        }
    }
    // Snapped to the same art pixels as the pictures, so the contour is a crisp pixel line.
    vec2 logical = vec2(g.x, -g.y) + vec2(0.5 / 32.0, -0.5 / 32.0);
    ivec2 cell = ivec2(floor(logical + 0.5));
    vec2 inside = logical + 0.5 - vec2(cell);
    float here = level_of(cell);
    float shade = 1.0;
    ivec2 steps[4] = ivec2[](ivec2(-1, 0), ivec2(1, 0), ivec2(0, -1), ivec2(0, 1));
    float edges[4] = float[](inside.x, 1.0 - inside.x, inside.y, 1.0 - inside.y);
    for (int k = 0; k < 4; k++) {
        float there = level_of(cell + steps[k]);
        if (there < here) {
            shade *= mix(contour_shade, 1.0, step(contour_width, edges[k]));
        } else if (there > here) {
            shade *= mix(foot_shade, 1.0, smoothstep(0.0, 0.32, edges[k]));
        }
    }
    ALBEDO = colour * shade;
    ROUGHNESS = 0.94;
}
