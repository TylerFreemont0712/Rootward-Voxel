shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D control_map : filter_nearest, repeat_disable;
uniform sampler2DArray ground_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D warp_noise : filter_linear, repeat_enable;
uniform ivec2 control_size;
uniform bool authored_overlay = false;
uniform sampler2D paint_mask : filter_nearest, repeat_disable;
uniform int layer_of[64];
uniform vec4 tint_of[64];
uniform float tile_of[64];
// Town ground: 1 = laid paving with straight edges, 2 = lawn, bed or gravel that takes a limestone kerb where it
// meets paving (or the authored paving round a painted patch); 0 = natural ground with the warped edge.
uniform int edge_of[64];
uniform int kerb_layer = 0;
uniform float kerb_width = 0.11;
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
	if (authored_overlay) {
		ivec2 sub = ivec2(floor((vec2(ground.x, -ground.y) + 0.5) * 2.0));
		if (sub.x < 0 || sub.y < 0 || sub.x >= control_size.x || sub.y >= control_size.y || texelFetch(paint_mask, sub, 0).r < 0.5) discard;
	}
    vec2 g = floor(ground * 32.0) / 32.0;
    vec2 warp = (texture(warp_noise, g * 0.21).rg - 0.5) * warp_amplitude;
    // Cell centres are whole numbers. Sub-tile centres sit at cell centre +/- 0.25.
    vec2 p = vec2(g.x, -g.y) * 2.0 + 0.5 + warp;
    ivec2 i = ivec2(floor(p));
    vec2 f = fract(p);
    float best = -2.0;
    vec3 colour = vec3(0.0);
    // The sub-tile this art pixel really lies in (no warp). Town ground keeps to it, so paving is cut straight.
    // Sub-tile n spans logical x from n/2 - 0.5 to n/2 (as the paint mask's floor((x + 0.5) * 2) says).
    vec2 crisp_p = (vec2(g.x, -g.y) + vec2(0.5 / 32.0, -0.5 / 32.0)) * 2.0 + 1.0;
    ivec2 own = clamp(ivec2(floor(crisp_p)), ivec2(0), control_size - ivec2(1));
    int own_idx = int(texelFetch(control_map, own, 0).r * 255.0 + 0.5);
    if (edge_of[own_idx] != 0) {
        vec4 s = texture(ground_albedo, vec3((g + 0.5 / 32.0) / tile_of[own_idx], float(layer_of[own_idx])));
        colour = s.rgb * tint_of[own_idx].rgb;
    } else {
        for (int k = 0; k < 4; k++) {
            ivec2 offset = ivec2(k & 1, k >> 1);
            ivec2 c = clamp(i + offset, ivec2(0), control_size - ivec2(1));
            float w = (offset.x == 1 ? f.x : 1.0 - f.x) * (offset.y == 1 ? f.y : 1.0 - f.y);
            int idx = int(texelFetch(control_map, c, 0).r * 255.0 + 0.5);
            if (edge_of[idx] != 0) continue;  // town ground never bleeds into its neighbours
            vec4 s = texture(ground_albedo, vec3((g + 0.5 / 32.0) / tile_of[idx], float(layer_of[idx])));
            float score = w + (s.a - 0.5) * height_strength;
            if (score > best) {
                best = score;
                colour = s.rgb * tint_of[idx].rgb;
            }
        }
        if (best < -1.0) {
            vec4 s = texture(ground_albedo, vec3((g + 0.5 / 32.0) / tile_of[own_idx], float(layer_of[own_idx])));
            colour = s.rgb * tint_of[own_idx].rgb;
        }
    }
    // Kerbs: planted or loose town ground gets a limestone edging where a neighbouring sub-tile is paving (laid
    // town paving, or the authored surface left unpainted round a painted patch).
    if (edge_of[own_idx] == 2) {
        vec2 inside_sub = fract(crisp_p);
        ivec2 sides[4] = ivec2[](ivec2(-1, 0), ivec2(1, 0), ivec2(0, -1), ivec2(0, 1));
        float near[4] = float[](inside_sub.x, 1.0 - inside_sub.x, inside_sub.y, 1.0 - inside_sub.y);
        for (int k = 0; k < 4; k++) {
            ivec2 n = own + sides[k];
            if (n.x < 0 || n.y < 0 || n.x >= control_size.x || n.y >= control_size.y) continue;
            int n_idx = int(texelFetch(control_map, n, 0).r * 255.0 + 0.5);
            bool unpainted = authored_overlay && texelFetch(paint_mask, n, 0).r < 0.5;
            bool paved = unpainted || edge_of[n_idx] == 1;
            if (paved && near[k] * 0.5 < kerb_width) {
                vec3 stone = texture(ground_albedo, vec3((g + 0.5 / 32.0) / 1.5, float(kerb_layer))).rgb;
                float lip = step(kerb_width - 1.0 / 32.0, near[k] * 0.5);
                colour = mix(stone * 1.04, stone * 0.62, lip);
            }
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
