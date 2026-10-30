shader_type spatial;

uniform sampler2D stone_texture : source_color, filter_linear_mipmap, repeat_enable;

void fragment() {
	vec3 stone = texture(stone_texture, UV * vec2(0.4, 3.0)).rgb;
	float border = smoothstep(0.12, 0.23, UV.x) * smoothstep(0.12, 0.23, 1.0 - UV.x);
	float flutes = pow(max(0.0, cos((UV.x - 0.5) * 54.0)), 16.0);
	float ends = smoothstep(0.0, 0.07, UV.y) * smoothstep(0.0, 0.07, 1.0 - UV.y);
	float carved = border * flutes * ends;
	float pulse = pow(max(0.0, cos(UV.y * 12.0 - TIME * 1.25)), 6.0);
	ALBEDO = mix(stone, vec3(0.50, 0.34, 0.12), carved * 0.55);
	ROUGHNESS = 0.8;
	EMISSION = vec3(1.0, 0.65, 0.27) * carved * (0.8 + 2.0 * pulse);
}
