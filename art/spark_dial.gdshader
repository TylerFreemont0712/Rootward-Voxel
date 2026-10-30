shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// The mark on the floor where a job is done: a brass dial with a ring of ticks, and a warm glow inside it.

uniform vec4 brass : source_color = vec4(0.86, 0.66, 0.30, 1.0);
uniform vec4 ink : source_color = vec4(0.11, 0.29, 0.29, 1.0);
uniform vec4 spark : source_color = vec4(1.0, 0.82, 0.46, 1.0);
uniform int ticks = 16;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float aa = max(fwidth(d) * 1.3, 0.004);
	float ring_line = 1.0 - smoothstep(-aa, aa, abs(d - 0.7) - 0.1);
	float ring_fill = 1.0 - smoothstep(-aa, aa, abs(d - 0.7) - 0.06);
	float angle = atan(p.y, p.x) + TIME * 0.35;
	float step_size = 6.2831853 / float(ticks);
	float around = abs(mod(angle + step_size * 0.5, step_size) - step_size * 0.5);
	float tick_band = 1.0 - smoothstep(-aa, aa, abs(d - 0.92) - 0.08);
	float tick = tick_band * (1.0 - smoothstep(0.0, 0.01, around * d - 0.045));
	float glow = (1.0 - smoothstep(0.0, 0.62, d)) * (0.5 + 0.15 * sin(TIME * 2.4));
	vec3 colour = spark.rgb;
	colour = mix(colour, ink.rgb, max(ring_line, tick));
	colour = mix(colour, brass.rgb, ring_fill);
	ALBEDO = colour;
	ALPHA = clamp(max(ring_line, tick) + glow, 0.0, 1.0);
}
