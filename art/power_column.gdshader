shader_type spatial;
render_mode cull_disabled;

// The amber glass shaft of a town power pillar: the whole column glows. UV.y is height in metres (top near 0, lower
// down negative), so pulses of light climb every pillar at the same pace toward the square, and UV.x runs across
// each face; the faces darken a little toward their brass-railed edges.

void fragment() {
	float across = smoothstep(0.0, 0.1, UV.x) * smoothstep(0.0, 0.1, 1.0 - UV.x);
	float rise = pow(max(0.0, cos(UV.y * 0.9 - TIME * 1.6)), 8.0);
	float shimmer = 0.5 + 0.5 * sin(UV.y * 5.0 + UV.x * 2.0 + TIME * 0.7);
	ALBEDO = vec3(0.46, 0.24, 0.07);
	ROUGHNESS = 0.3;
	EMISSION = vec3(1.0, 0.56, 0.18) * (0.95 + 0.2 * shimmer + 1.1 * rise) * mix(0.72, 1.0, across);
}
