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


const vec3 FLOOR_LO = vec3(0.074, 0.056, 0.040);
const vec3 FLOOR_HI = vec3(0.118, 0.092, 0.064);
const vec3 BRASS_LO = vec3(0.35, 0.26, 0.10);
const vec3 BRASS = vec3(0.84, 0.65, 0.29);
const vec3 BRASS_HI = vec3(0.96, 0.82, 0.53);
const vec3 TEAL = vec3(0.53, 0.84, 0.78);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// One spoked, toothed wheel. Returns (coverage, light) where light is 0..1 brass shading.
vec2 gear(vec2 p, vec2 centre, float teeth, float theta, float pitch, float spokes) {
	vec2 d = p - centre;
	float r = length(d);
	float a = atan(d.y, d.x) - theta;
	float tooth_h = 0.024;
	float root = pitch - tooth_h * 0.5;
	float aa = 0.0016;
	float f = abs(fract(a * teeth / TAU) - 0.5) * 2.0;
	float outer = root + tooth_h * smoothstep(0.20, 0.56, f);
	float body = 1.0 - smoothstep(outer - aa, outer + aa, r);
	// Between the hub and the rim the wheel is cut away, leaving straight spokes.
	float ang = (fract(a * spokes / TAU + 0.5) - 0.5) * TAU / spokes;
	float across = abs(sin(ang)) * r;
	float window = smoothstep(root * 0.34 - aa, root * 0.34 + aa, r) * (1.0 - smoothstep(root * 0.74 - aa, root * 0.74 + aa, r));
	float cut = window * smoothstep(0.0085 - aa, 0.0085 + aa, across);
	float bore = 1.0 - smoothstep(root * 0.11 - aa, root * 0.11 + aa, r);
	float cover = body * (1.0 - cut) * (1.0 - bore);
	// Light falls from the upper left; the rim catches it, the inside of each opening and the outline sit darker.
	float facing = 0.5 + 0.5 * dot(normalize(d + vec2(1e-5)), normalize(vec2(-0.55, -0.83)));
	float bevel = 1.0 - smoothstep(0.0, 0.010, outer - r);
	float hub = 1.0 - smoothstep(root * 0.34, root * 0.34 + 0.01, r);
	float groove = exp(-pow((r - root * 0.90) / 0.0022, 2.0));
	float bolts = 0.0;
	for (int i = 0; i < 4; i++) {
		float b = float(i) * 1.5707963 + theta;
		bolts = max(bolts, 1.0 - smoothstep(0.0042, 0.0062, length(d - vec2(cos(b), sin(b)) * root * 0.22)));
	}
	float light = 0.40 + 0.30 * facing + 0.26 * bevel * facing + 0.12 * hub - 0.16 * groove + 0.20 * bolts * facing;
	light *= 1.0 - 0.55 * smoothstep(outer - 0.0035, outer, r);
	return vec2(cover, clamp(light, 0.0, 1.0));
}

vec3 brass(float light) {
	return mix(mix(BRASS_LO, BRASS, smoothstep(0.1, 0.62, light)), BRASS_HI, smoothstep(0.66, 1.05, light)) * 0.93;
}

// Rotation of a wheel of `t2` teeth meshed with one of `t1` teeth turned to `theta1`, lying in direction `phi` from it.
float meshed(float theta1, float t1, float t2, float phi) {
	return phi * (t1 + t2) / t2 - theta1 * t1 / t2 + 3.14159265 - 3.14159265 / t2;
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

	// A dial ring of minute ticks around the main wheel.
	vec2 q = c;
	float qr = length(q);
	float qa = atan(q.y, q.x) - spin * 0.06;
	float tick60 = abs(fract(qa * 60.0 / TAU) - 0.5);
	float tick5 = abs(fract(qa * 12.0 / TAU) - 0.5);
	float ticks = (1.0 - smoothstep(0.012, 0.03, tick60)) * smoothstep(0.455, 0.457, qr) * (1.0 - smoothstep(0.468, 0.470, qr));
	ticks += (1.0 - smoothstep(0.018, 0.04, tick5)) * smoothstep(0.455, 0.457, qr) * (1.0 - smoothstep(0.482, 0.484, qr));
	float dial = exp(-pow((qr - 0.452) / 0.0016, 2.0)) * 0.9 + exp(-pow((qr - 0.49) / 0.0012, 2.0)) * 0.5;
	col = mix(col, BRASS_LO * 1.1, clamp(ticks * 0.8 + dial, 0.0, 1.0) * seen);

	// The train of wheels. Each meshes with the one before it, so the teeth really do lock.
	vec2 g0 = vec2(0.105, 0.06);
	float t0 = 14.0;
	float th0 = spin * 0.46;
	float t1 = 9.0;
	float phi1 = -0.5;
	vec2 g1 = g0 + vec2(cos(phi1), sin(phi1)) * (0.175 + 0.1125);
	float th1 = meshed(th0, t0, t1, phi1);
	float t2 = 7.0;
	float phi2 = -1.9;
	vec2 g2 = g1 + vec2(cos(phi2), sin(phi2)) * (0.1125 + 0.0875);
	float th2 = meshed(th1, t1, t2, phi2);
	float t3 = 11.0;
	float phi3 = 2.6;
	vec2 g3 = g0 + vec2(cos(phi3), sin(phi3)) * (0.175 + 0.1375);
	float th3 = meshed(th0, t0, t3, phi3);
	float t4 = 8.0;
	float phi4 = 3.6;
	vec2 g4 = g3 + vec2(cos(phi4), sin(phi4)) * (0.1375 + 0.10);
	float th4 = meshed(th3, t3, t4, phi4);

	vec2 shadow_shift = vec2(0.009, 0.013);
	float shade = 0.0;
	shade = max(shade, gear(c - shadow_shift, g0, t0, th0, 0.175, 5.0).x);
	shade = max(shade, gear(c - shadow_shift, g1, t1, th1, 0.1125, 4.0).x);
	shade = max(shade, gear(c - shadow_shift, g2, t2, th2, 0.0875, 4.0).x);
	shade = max(shade, gear(c - shadow_shift, g3, t3, th3, 0.1375, 5.0).x);
	shade = max(shade, gear(c - shadow_shift, g4, t4, th4, 0.10, 4.0).x);
	col *= 1.0 - 0.55 * shade * seen;

	vec2 w;
	w = gear(c, g3, t3, th3, 0.1375, 5.0);
	col = mix(col, brass(w.y) * 0.9, w.x * seen);
	w = gear(c, g4, t4, th4, 0.10, 4.0);
	col = mix(col, brass(w.y) * 0.85, w.x * seen);
	w = gear(c, g2, t2, th2, 0.0875, 4.0);
	col = mix(col, brass(w.y) * 0.95, w.x * seen);
	w = gear(c, g1, t1, th1, 0.1125, 4.0);
	col = mix(col, brass(w.y), w.x * seen);
	w = gear(c, g0, t0, th0, 0.175, 5.0);
	col = mix(col, brass(w.y) * 1.05, w.x * seen);

	// The edge: a warm brass lip with a cool line just outside it.
	col += BRASS_HI * rim * 0.42 + TEAL * exp(-pow((r - lip - 0.010) / 0.005, 2.0)) * 0.08 * rim;
	COLOR = vec4(col, max(veil, rim * 0.5));
}
