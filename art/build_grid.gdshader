shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
// Build mode's ground grid: thin brass lines along every cell edge that glow near the cursor and fade away
// from it, so the whole valley never turns into graph paper. Cell centres are whole numbers, so edges sit at k + 0.5.

uniform vec2 cursor = vec2(0.0);
uniform float radius = 9.0;
uniform float base_alpha = 0.07;
uniform float cell_scale = 1.0;
uniform vec3 line_color : source_color = vec3(0.96, 0.8, 0.45);

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 f = fract((world_position.xz + 0.5) * cell_scale);
    vec2 edge = min(f, 1.0 - f);
    float line = 1.0 - smoothstep(0.0, 0.034 * cell_scale, min(edge.x, edge.y));
    float near = 1.0 - smoothstep(radius * 0.3, radius, length(world_position.xz - cursor));
    ALBEDO = line_color;
    ALPHA = line * (base_alpha + 0.55 * near);
}
