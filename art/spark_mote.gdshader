shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// One drifting spark: a small warm point with a soft edge, faded by `fade` as it rises.

uniform vec4 spark : source_color = vec4(1.0, 0.8, 0.42, 1.0);
uniform float fade = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float core = 1.0 - smoothstep(0.0, 0.35, d);
	float halo = (1.0 - smoothstep(0.0, 1.0, d)) * 0.35;
	ALBEDO = spark.rgb * (core + halo) * fade;
}
