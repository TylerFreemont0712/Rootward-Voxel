shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

uniform sampler2D painted_albedo : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 base_colour : source_color = vec4(1.0);
uniform vec4 glow_colour : source_color = vec4(0.0);
uniform float glow_strength = 1.0;
uniform float surface_roughness = 0.9;
uniform float surface_metallic = 0.0;
uniform mat4 mesh_to_tree;
uniform float fade_start = 8.0;
uniform float fade_end = 10.0;

varying float tree_height;

void vertex() {
	// Authored tree coordinates work at every placement, elevation and scale.
	tree_height = (mesh_to_tree * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	float coverage = 1.0 - smoothstep(fade_start, fade_end, tree_height);
	if (coverage <= 0.0) {
		discard;
	}
	ALBEDO = texture(painted_albedo, UV).rgb * base_colour.rgb;
	ROUGHNESS = surface_roughness;
	METALLIC = surface_metallic;
	EMISSION = glow_colour.rgb * glow_strength;
	ALPHA = coverage;
}
