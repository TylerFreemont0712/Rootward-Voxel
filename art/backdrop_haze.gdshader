shader_type spatial;
// The painted distance behind an outdoor room. It is a little hazed everywhere, so it sits behind the room's own
// colours, and fades fully into the haze toward its foot, where the room's terraces float over the drop.
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D painting : source_color, filter_linear_mipmap;
uniform vec4 haze : source_color = vec4(0.73, 0.81, 0.84, 1.0);
uniform float distance_haze = 0.12;
uniform float foot_from = 0.3;
uniform float foot_to = 0.82;
uniform float foot_haze = 1.0;

void fragment() {
	vec3 colour = texture(painting, UV).rgb;
	float foot = smoothstep(foot_from, foot_to, UV.y) * foot_haze;
	ALBEDO = mix(colour, haze.rgb, clamp(distance_haze + foot, 0.0, 1.0));
}
