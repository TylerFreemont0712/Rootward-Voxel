shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

varying vec4 light_colour;

void vertex() {
	light_colour = COLOR;
	// Preserve the per-instance size while facing the orthographic camera.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz),
		INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz),
		INV_VIEW_MATRIX[2] * length(MODEL_MATRIX[2].xyz), MODEL_MATRIX[3]);
}

void fragment() {
	float radius = length(UV - vec2(0.5)) * 2.0;
	float halo = pow(max(0.0, 1.0 - radius), 3.0);
	ALBEDO = light_colour.rgb;
	ALPHA = halo * light_colour.a;
}
