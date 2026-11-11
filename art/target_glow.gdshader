shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;
// A slow brass-and-teal pulse laid over a thing the traveller is heading for or standing at, so it reads as the
// destination. Added on top of the object's own surface through a material overlay; nothing else changes.

uniform vec4 glow : source_color = vec4(0.42, 0.92, 0.78, 1.0);

void fragment() {
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.0);
	float breathe = 0.65 + 0.35 * sin(TIME * 3.0);
	ALBEDO = glow.rgb * (0.17 + 0.6 * rim) * breathe;
}
