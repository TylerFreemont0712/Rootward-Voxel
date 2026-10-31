shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
// What a Test proposes in the world: a pulsing blue ghost. Faces are a faint fill that brightens at grazing angles
// (so a model keeps its silhouette); `edges` draws a box's outline lines solid. A fact is warm, a proposal is blue.

uniform vec4 tint : source_color = vec4(0.29, 0.66, 1.0, 1.0);
uniform float fill = 0.16;
uniform float rim = 0.8;
uniform bool edges = false;

void fragment() {
	float pulse = 0.8 + 0.2 * sin(TIME * 2.6);
	ALBEDO = tint.rgb;
	if (edges) {
		ALPHA = 0.95 * pulse;
	} else {
		float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.0);
		ALPHA = clamp(fill + fresnel * rim, 0.0, 0.9) * pulse;
	}
}
