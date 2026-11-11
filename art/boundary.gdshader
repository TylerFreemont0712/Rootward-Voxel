shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 mist_color : source_color = vec4(0.47, 0.67, 0.63, 1.0);
uniform vec2 extent;
varying vec3 world;
varying float height;

void vertex() {
    world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    height = UV.y;
}

void fragment() {
    float drift = sin(world.x * 0.64 + world.z * 0.47 + TIME * 0.17) * 0.5 + 0.5;
    float veil = (0.025 + 0.045 * drift) * pow(1.0 - height, 1.6);
    float threads = pow(max(0.0, sin(world.x * 1.9 - world.z * 1.1 + TIME * 0.22)), 16.0);
    ALBEDO = mist_color.rgb;
    ALPHA = veil + threads * 0.045 * (1.0 - height);
}
