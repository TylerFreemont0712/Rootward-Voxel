shader_type spatial;
render_mode cull_disabled;

void fragment() {
	// UV.x is surveyed distance along the conduit, including the stair risers.
	float pulse = pow(max(0.0, cos(UV.x * 0.65 - TIME * 1.25)), 8.0);
	float core = smoothstep(0.0, 0.18, UV.y) * smoothstep(0.0, 0.18, 1.0 - UV.y);
	ALBEDO = mix(vec3(0.21, 0.15, 0.07), vec3(0.62, 0.45, 0.21), core);
	METALLIC = 0.2;
	ROUGHNESS = 0.38;
	EMISSION = vec3(1.0, 0.63, 0.24) * core * (0.28 + pulse * 1.2);
}
