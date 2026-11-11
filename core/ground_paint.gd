class_name GroundPaint
extends RefCounted
## Pure appearance data. Sub-tile (0,0) is the southwest quarter of cell (0,0).
## Documents are north-up; control bytes are indexed south-up, sy * (2 * width) + sx.
## This schema palette is checked against the texture catalog; loaders may supply additional ground ids.

const DIGITS: String = "0123456789abcdefghijklmnopqrstuvwxyz"
const DEFAULT_PALETTE: Array[String] = ["grass", "grass_light", "grass_dark", "dirt", "dirt_light", "dirt_dark", "path", "path_light", "path_dark", "soil", "pebbles", "soil_light", "soil_dark", "rock_face"]
const NEIGHBORS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP]


static func is_ground(area: AreaDef, sub: Vector2i) -> bool:
	return sub.x >= 0 and sub.y >= 0 and sub.x < area.width * 2 and sub.y < area.height * 2 and area.terrain_at(Vector2i(sub.x / 2, sub.y / 2)) in [AreaDef.Terrain.GRASS, AreaDef.Terrain.PATH, AreaDef.Terrain.COBBLE]


static func terrain_family(terrain: int) -> String:
	match terrain:
		AreaDef.Terrain.GRASS: return "grass"
		AreaDef.Terrain.PATH: return "dirt"
		AreaDef.Terrain.COBBLE: return "path"
	return ""


static func family(material: String) -> String:
	return material.trim_suffix("_light").trim_suffix("_dark")


static func palette(area: AreaDef) -> Array[String]:
	var result: Array[String] = DEFAULT_PALETTE.duplicate()
	for id: String in area.paint.get("palette", []):
		if not result.has(id):
			result.append(id)
	return result


static func override_at(area: AreaDef, sub: Vector2i) -> String:
	if area.paint.is_empty() or not is_ground(area, sub):
		return ""
	var glyph: String = area.paint.rows[area.height * 2 - 1 - sub.y][sub.x]
	return "" if glyph == "." else str(area.paint.palette[DIGITS.find(glyph)])


static func material_at(area: AreaDef, sub: Vector2i) -> String:
	var authored: String = override_at(area, sub)
	return authored if authored != "" else derived(area, sub)


static func derived(area: AreaDef, sub: Vector2i, roughen: bool = true) -> String:
	if not is_ground(area, sub):
		return ""
	var source: Vector2i = sub
	var own: String = terrain_family(area.terrain_at(Vector2i(sub.x / 2, sub.y / 2)))
	if roughen:
		var candidates: Array[Vector2i] = []
		# Two neighbors are in this same logical cell and cannot have a different terrain family.
		for delta: Vector2i in [Vector2i(-1 if sub.x % 2 == 0 else 1, 0), Vector2i(0, -1 if sub.y % 2 == 0 else 1)]:
			var other: Vector2i = sub + delta
			if is_ground(area, other) and terrain_family(area.terrain_at(Vector2i(other.x / 2, other.y / 2))) != own:
				candidates.append(other)
		# Protect banks and outcrops, including diagonal corners. Out-of-map edges are protected too.
		var safe: bool = true
		if not candidates.is_empty():
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					if not is_ground(area, sub + Vector2i(dx, dy)):
						safe = false
		if safe and not candidates.is_empty():
			var best: int = 2147483647
			var strength: float = float(area.paint.get("roughen", 0.4))
			for other: Vector2i in candidates:
				var h: int = edge_hash(sub, other)
				if float(h % 65536) / 65536.0 < 0.5 * strength and h < best:
					source = other
					best = h
	var base: String = terrain_family(area.terrain_at(Vector2i(source.x / 2, source.y / 2)))
	return _tone(base, float(source.x) * 0.5 - 0.25, float(source.y) * 0.5 - 0.25)


static func _tone(base: String, x: float, y: float) -> String:
	var n: float
	if base == "path":
		n = noise(x / 5.0 + 11.0, y / 5.0) * 0.7 + noise(x / 1.7, y / 1.7 + 70.0) * 0.3
		return base + ("_dark" if n < 0.34 else ("_light" if n > 0.66 else ""))
	n = noise(x / 7.0, y / 7.0) * 0.65 + noise(x / 2.3 + 40.0, y / 2.3) * 0.35
	return base + ("_dark" if n < 0.36 else ("_light" if n > 0.64 else ""))


## One R8 texel per sub-tile. Multi-source BFS fills non-ground texels from nearest ground;
## deterministic traversal breaks equal-distance ties. It never invents water/rock palette entries.
static func control(area: AreaDef) -> PackedByteArray:
	var width: int = area.width * 2
	var height: int = area.height * 2
	var result := PackedByteArray()
	result.resize(width * height)
	result.fill(255)
	var ids: Array[String] = palette(area)
	var queue: Array[Vector2i] = []
	for y: int in range(height):
		for x: int in range(width):
			var at := Vector2i(x, y)
			if is_ground(area, at):
				result[y * width + x] = ids.find(material_at(area, at))
				queue.append(at)
	var cursor: int = 0
	while cursor < queue.size():
		var at: Vector2i = queue[cursor]
		cursor += 1
		for delta: Vector2i in NEIGHBORS:
			var next: Vector2i = at + delta
			if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height or result[next.y * width + next.x] != 255:
				continue
			result[next.y * width + next.x] = result[at.y * width + at.x]
			queue.append(next)
	if queue.is_empty():
		result.fill(0)
	return result


static func edge_hash(a: Vector2i, b: Vector2i) -> int:
	if a.x > b.x or (a.x == b.x and a.y > b.y):
		return edge_hash(b, a)
	return hash_xy(a.x * 193 + b.x, a.y * 193 + b.y) % 2147483647


static func hash_xy(x: int, y: int) -> int:
	return absi((x * 374761393 + y * 668265263 + 19) ^ ((x + y * 57) * 1274126177))


## The terrain builder's two-octave value-noise basis, now shared by the pure defaults.
static func noise(x: float, y: float) -> float:
	var ix: int = floori(x)
	var iy: int = floori(y)
	var fx: float = x - float(ix)
	var fy: float = y - float(iy)
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var v00: float = float(hash_xy(ix, iy) % 1024) / 1023.0
	var v10: float = float(hash_xy(ix + 1, iy) % 1024) / 1023.0
	var v01: float = float(hash_xy(ix, iy + 1) % 1024) / 1023.0
	var v11: float = float(hash_xy(ix + 1, iy + 1) % 1024) / 1023.0
	return lerpf(lerpf(v00, v10, fx), lerpf(v01, v11, fx), fy)
