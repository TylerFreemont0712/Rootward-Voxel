shader_type canvas_item;
// The clockwork curtain between places. A toothed brass edge travels out of `origin` and, when `opening` is 0, leaves
// a dark workshop floor behind it with a train of meshed gears turning on it; when `opening` is 1 the same edge opens a
// hole in that floor instead. `front` runs 0..1 over either sweep, so the veil is opaque at the end of one sweep and at
// the start of the other and the scene can be swapped between them.

uniform float front : hint_range(0.0, 1.0) = 0.0;
uniform float opening : hint_range(0.0, 1.0) = 0.0;
uniform float spin = 0.0;
// Width over height of the area covered, so gears stay round in any window.
uniform float aspect = 1.77778;
uniform vec2 origin = vec2(0.5);


const vec3 FLOOR_LO = vec3(0.045, 0.074, 0.083);
const vec3 FLOOR_HI = vec3(0.105, 0.165, 0.172);
const vec3 BRASS_LO = vec3(0.35, 0.26, 0.10);
const vec3 BRASS = vec3(0.84, 0.65, 0.29);
const vec3 BRASS_HI = vec3(0.96, 0.82, 0.53);
const vec3 TEAL = vec3(0.53, 0.84, 0.78);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = (UV - origin) * vec2(aspect, 1.0);
	float r = length(p);
	float a = atan(p.y, p.x);
	float reach = length(max(origin, 1.0 - origin) * vec2(aspect, 1.0)) + 0.2;
	float radius = front * reach;
	// The advancing edge is itself a big gear wheel.
	float edge_teeth = 30.0;
	float profile = smoothstep(0.2, 0.55, abs(fract((a - spin * 0.22) * edge_teeth / TAU) - 0.5) * 2.0);
	float lip = radius + 0.030 * profile * smoothstep(0.0, 0.12, front);
	float inside = 1.0 - smoothstep(lip - 0.0022, lip + 0.0022, r);
	float veil = mix(inside, 1.0 - inside, opening);
	float rim = exp(-pow((r - lip) / 0.0065, 2.0)) * smoothstep(0.0, 0.05, front) * (1.0 - smoothstep(0.93, 1.0, front));
	float seen = mix(smoothstep(0.08, 0.50, front), 1.0 - smoothstep(0.30, 0.90, front), opening);

	// The workshop floor: dark, a little lighter in the middle, with a fine grain so the dark never bands.
	vec2 c = (UV - vec2(0.5)) * vec2(aspect, 1.0);
	float vignette = 1.0 - smoothstep(0.2, 1.1, length(c));
	vec3 col = mix(FLOOR_LO, FLOOR_HI, vignette * 0.8);
	col += (hash(floor(UV * vec2(aspect, 1.0) * 540.0)) - 0.5) * 0.012;

	// The edge: a warm brass lip with a cool line just outside it.
	col += BRASS_HI * rim * 0.42 + TEAL * exp(-pow((r - lip - 0.010) / 0.005, 2.0)) * 0.08 * rim;
	COLOR = vec4(col, max(veil, rim * 0.5));
}
