shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Painted water: two layers of the water picture drift against each other, so the ripples move without
// the pixel shapes ever blurring. The picture and its set come from the texture catalog.

uniform sampler2D water_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform float tile_size = 1.0;
uniform sampler2D foam_texture : filter_nearest_mipmap, repeat_enable;
uniform sampler2D detail_noise : filter_linear, repeat_enable;
uniform sampler2D depth_map : filter_linear, repeat_disable;
uniform vec2 map_size = vec2(1.0);
uniform vec4 ripples[4];

varying vec3 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float a = world_position.x * 2.7 + world_position.z * 1.9 + TIME * 1.25;
    float b = world_position.z * 5.1 - world_position.x * 1.3 - TIME * 1.8;
    VERTEX.y += sin(a) * 0.018 + sin(b) * 0.008;
    NORMAL = normalize(vec3(-cos(a) * 0.0486 + cos(b) * 0.0104, 1.0, -cos(a) * 0.0342 - cos(b) * 0.0408));
}

void fragment() {
    vec2 ground = floor(world_position.xz * 32.0) / (32.0 * tile_size);
    vec3 near_layer = texture(water_texture, ground + vec2(TIME * 0.025, TIME * 0.012)).rgb;
    vec3 far_layer = texture(water_texture, ground * 0.77 + vec2(3.1, 1.7) - vec2(TIME * 0.018, TIME * 0.02)).rgb;
    float depth = texture(depth_map, (vec2(world_position.x, -world_position.z) + 0.5) / map_size).r;
    vec3 paint = mix(near_layer, far_layer, 0.5) * mix(vec3(1.09, 1.1, 0.97), vec3(0.48, 0.79, 0.91), depth);
    float foam_pattern = texture(foam_texture, ground * 0.83 - vec2(0.013, TIME * 0.09)).r;
    float shore = 1.0 - smoothstep(0.27, 0.49, depth);
    float foam = step(0.56 + sin(TIME * 0.9 + world_position.z * 1.7) * 0.06, foam_pattern) * shore * 0.65;
    float noise = texture(detail_noise, ground * 0.33 + vec2(TIME * 0.015, -TIME * 0.025)).r;
    float caustic = pow(max(0.0, sin(ground.x * 7.0 + noise * 5.0 + TIME * 0.65) * sin(ground.y * 8.2 - noise * 4.0 - TIME * 0.4)), 6.0);
    paint += vec3(0.1, 0.25, 0.22) * caustic * (1.0 - depth) * 0.45;
    for (int k = 0; k < 4; k++) {
        float radius = ripples[k].z * 1.5;
        float ring = 1.0 - smoothstep(0.018, 0.055, abs(length(world_position.xz - ripples[k].xy) - radius));
        foam += ring * (1.0 - ripples[k].z) * 0.3;
    }
    float glint = smoothstep(0.1, 0.9, sin(world_position.x * 9.0 + world_position.z));
    ALBEDO = mix(paint, vec3(0.7, 0.9, 0.85), clamp(foam, 0.0, 0.8)) + vec3(0.1, 0.14, 0.12) * glint * smoothstep(0.7, 1.0, sin(world_position.z * 12.0 + world_position.x * 3.0 + TIME * 0.8)) * 0.4;
    ROUGHNESS = 0.28;
    SPECULAR = 0.42;
}
