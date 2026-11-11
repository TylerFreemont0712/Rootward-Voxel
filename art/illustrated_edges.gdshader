shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, fog_disabled;

uniform vec4 ink_color : source_color = vec4(0.20, 0.15, 0.12, 1.0);
// A fine line at the reference desktop height; scales with the actual viewport.
uniform float width_at_1080 = 0.85;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 normal_view = MODELVIEW_NORMAL_MATRIX * NORMAL;
	vec2 direction = (PROJECTION_MATRIX * vec4(normal_view, 0.0)).xy * VIEWPORT_SIZE;
	float length_squared = dot(direction, direction);
	if (length_squared > 0.00001) {
		direction *= inversesqrt(length_squared);
		float pixels = width_at_1080 * VIEWPORT_SIZE.y / 1080.0;
		clip.xy += direction * (2.0 * pixels / VIEWPORT_SIZE) * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = ink_color.rgb;
}
