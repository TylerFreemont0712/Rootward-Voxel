shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
// A round ground marker with a solid outline: a dot for each step of a route, a pulsing ring where it ends.
// The shape is drawn from a distance field on a flat quad, so it stays crisp at every zoom.

uniform vec4 fill_color : source_color = vec4(0.99, 0.89, 0.62, 1.0);
uniform vec4 line_color : source_color = vec4(0.11, 0.29, 0.29, 1.0);
uniform float radius = 0.5;        // of the quad's half-size
uniform float ring_half = 0.0;     // 0 draws a dot; above 0 a ring of that half-width
uniform float line = 0.11;         // outline thickness, same units
uniform float pulse = 0.0;         // how far the shape breathes

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float r = radius * (1.0 + pulse * sin(TIME * 3.4));
	float sd = ring_half > 0.0 ? abs(d - r) - ring_half : d - r;
	float aa = max(fwidth(d) * 1.3, 0.004);
	float shape = 1.0 - smoothstep(-aa, aa, sd);
	float body = 1.0 - smoothstep(-aa, aa, sd + line);
	ALBEDO = mix(line_color.rgb, fill_color.rgb, body);
	ALPHA = shape;
}
