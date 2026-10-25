class_name TerrainBuilder
extends RefCounted
## Turns an area document's terrain cells and segments into batched voxel blocks. It only describes
## geometry (through `block`); whether a cell is walkable stays in core/. Deterministic: no RNG, so a
## rebuilt area is identical.
##
## Land is terraced (AreaDef levels): a raised cell stands on a column of layered rock that reaches down to the
## valley floor, so wherever a neighbour is lower the column shows as a cliff, with a lip of turf along its top
## edge. Stairs are steps between stone cheeks. Water keeps its own level; where it runs on to lower water it falls
## (see `waterfalls`, drawn by WaterSurface).
##
## `block` is Callable(at: Vector3, size: Vector3, material_id: String, rotation: Vector3 = Vector3.ZERO).

const CELL_DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
## How tall one land level looks, in world units. The rules only know whole levels; this is how high they stand.
const LEVEL_RISE: float = 1.0
## A water surface lies this far below the land level it belongs to.
const WATER_DROP: float = 0.214
## Steps in one flight of stairs, which climbs one level across one cell.
const STAIR_STEPS: int = 4
## Where the dark foundation slab under the valley ends and cliff columns begin.
const FLOOR_TOP: float = -0.6


static func build(area: AreaDef, block: Callable, skin: bool = false, water_skin: bool = false) -> void:
	foundation(area, block)
	for y: int in range(area.height):
		for x: int in range(area.width):
			cell(area, Vector2i(x, y), block, skin, water_skin)
	segments(area, block)


## Water that the ground asset leaves to Godot: plain slabs in logical rectangles.
static func water_rects(rects: Array, block: Callable) -> void:
	for rect: Variant in rects:
		var r: Array = rect
		block.call(Vector3(float(r[0]) + float(r[2]) * 0.5, -0.255, -(float(r[1]) + float(r[3]) * 0.5)), Vector3(float(r[2]), 0.08, float(r[3])), "water")


## Every place where water steps down to lower water, as {from, to, drop}: the water cell above, its lower neighbour
## and how many levels it falls. In cell order, so the same land always gives the same list.
static func waterfalls(area: AreaDef) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	for y: int in range(area.height):
		for x: int in range(area.width):
			var from := Vector2i(x, y)
			if area.terrain_at(from) != AreaDef.Terrain.WATER:
				continue
			for direction: Vector2i in CELL_DIRECTIONS:
				var to: Vector2i = from + direction
				if area.terrain_at(to) == AreaDef.Terrain.WATER and area.level_at(to) < area.level_at(from):
					drops.append({"from": from, "to": to, "drop": area.level_at(from) - area.level_at(to)})
	return drops


## A dark underside makes the valley read as a lifted slab of earth, like the original diorama.
static func foundation(area: AreaDef, block: Callable) -> void:
	var center := Vector3(float(area.width - 1) * 0.5, -0.88, -float(area.height - 1) * 0.5)
	block.call(center, Vector3(float(area.width), 0.55, float(area.height)), "soil_dark")
	block.call(center + Vector3(0, -0.45, 0), Vector3(float(area.width) - 2.0, 0.45, float(area.height) - 2.0), "stone_dark")


## Walls and fences stand on the level of the ground under their middle.
static func segments(area: AreaDef, block: Callable) -> void:
	for segment: Dictionary in area.segments:
		var middle: Vector2 = ((segment.from as Vector2) + (segment.to as Vector2)) * 0.5
		var lift: float = float(area.level_at(Vector2i(floori(middle.x + 0.5), floori(middle.y + 0.5)))) * LEVEL_RISE
		if segment.kind == "wall":
			_wall(segment, block, lift)
		else:
			_fence(segment, block, lift)


## One cell's blocks: its cliff column when raised, then its ground, water, rock or stairs on top.
static func cell(area: AreaDef, at_cell: Vector2i, block: Callable, skin: bool = false, water_skin: bool = false) -> void:
	var terrain: int = area.terrain_at(at_cell)
	var level: int = area.level_at(at_cell)
	var at := Vector3(at_cell.x, float(level) * LEVEL_RISE, -at_cell.y)
	var noise: int = _hash(at_cell.x, at_cell.y)
	if level > 0:
		_cliff(area, at_cell, level, terrain == AreaDef.Terrain.WATER, noise, block)
	if terrain == AreaDef.Terrain.WATER:
		block.call(at + Vector3(0, -0.40, 0), Vector3(1, 0.12, 1), "stone_dark")
		if not water_skin:
			block.call(at + Vector3(0, -0.255, 0), Vector3(1, 0.08, 1), "water")
		_water_rims(area, at_cell, at, noise, block)
		return
	if terrain == AreaDef.Terrain.ROCK:
		_rock(area, at_cell, at, noise, block)
		return
	block.call(at + Vector3(0, -0.4, 0), Vector3(1, 0.4, 1), "soil")
	var flight: Dictionary = area.stair_at(at_cell)
	if not flight.is_empty():
		_stairs(flight, at, noise, block)
	elif not skin:
		match terrain:
			AreaDef.Terrain.GRASS:
				block.call(at + Vector3(0, -0.015, 0), Vector3(1, 0.06, 1), _grass_material(at_cell))
			AreaDef.Terrain.PATH:
				var dirt: String = ["dirt", "dirt", "dirt_light", "dirt_dark"][noise % 4]
				block.call(at + Vector3(0, -0.005, 0), Vector3(1, 0.05, 1), dirt)
			AreaDef.Terrain.COBBLE:
				_paving(at, at_cell, block)
	_banks(area, at_cell, at, noise, block)
	if flight.is_empty():
		_lips(area, at_cell, at, terrain, noise, block)


## The rock a raised cell stands on, from the valley floor up to just under its own ground: courses about half a
## level tall whose tones drift with place and height, with a few boulders bulging out of every face that shows.
static func _cliff(area: AreaDef, at_cell: Vector2i, level: int, water: bool, noise: int, block: Callable) -> void:
	var top: float = float(level) * LEVEL_RISE - (0.46 if water else 0.6)
	var courses: int = maxi(1, roundi((top - FLOOR_TOP) / (LEVEL_RISE * 0.5)))
	var course: float = (top - FLOOR_TOP) / float(courses)
	for index: int in range(courses):
		var tone: String = ["rock_face", "stone_dark", "rock_face", "stone"][(noise / 5 + index * 3 + level) % 4]
		block.call(Vector3(at_cell.x, FLOOR_TOP + course * (float(index) + 0.5), -at_cell.y), Vector3(1.0, course, 1.0), tone)
	for direction: Vector2i in CELL_DIRECTIONS:
		var below: int = area.level_at(at_cell + direction)
		var flight: Dictionary = area.stair_at(at_cell + direction)
		if below >= level or not flight.is_empty() and (flight.dir as Vector2i) == -direction:
			continue
		var low: float = float(below) * LEVEL_RISE - (WATER_DROP if area.terrain_at(at_cell + direction) == AreaDef.Terrain.WATER else 0.0)
		var outward := Vector3(float(direction.x), 0.0, -float(direction.y))
		var along_x: bool = direction.x == 0
		var shown: float = top - low
		for bump: int in range(1 + (noise / 3 + direction.x + direction.y + 2) % 2):
			var hash: int = _hash(at_cell.x * 3 + direction.x + bump * 17, at_cell.y * 3 + direction.y)
			var slide: float = float(hash % 7 - 3) * 0.12
			var height: float = low + shown * (0.25 + 0.5 * float((hash / 7) % 5) / 4.0)
			var size := Vector3(0.34 + float(hash % 3) * 0.06, 0.22 + float((hash / 3) % 3) * 0.07, 0.12)
			if not along_x:
				size = Vector3(size.z, size.y, size.x)
			var shift := Vector3(slide, 0, 0) if along_x else Vector3(0, 0, slide)
			block.call(Vector3(at_cell.x, height, -at_cell.y) + outward * 0.53 + shift, size, "stone" if hash % 3 else "stone_light")


## A lip of turf (or of path) along every edge where this cell stands above its neighbour, with a few tufts hanging
## over the cliff, so a terrace reads as ground with rock under it rather than as a box.
static func _lips(area: AreaDef, at_cell: Vector2i, at: Vector3, terrain: int, noise: int, block: Callable) -> void:
	var level: int = area.level_at(at_cell)
	if level == 0:
		return
	var material: String = {AreaDef.Terrain.PATH: "dirt_dark", AreaDef.Terrain.COBBLE: "path_dark"}.get(terrain, "grass_dark")
	for direction: Vector2i in CELL_DIRECTIONS:
		if area.level_at(at_cell + direction) >= level:
			continue
		# The top step of stairs climbing onto this cell meets it flush: no lip there.
		var flight: Dictionary = area.stair_at(at_cell + direction)
		if not flight.is_empty() and (flight.dir as Vector2i) == -direction:
			continue
		var outward := Vector3(float(direction.x), 0.0, -float(direction.y))
		var along_x: bool = direction.x == 0
		block.call(at + outward * 0.49 + Vector3(0, -0.035, 0), Vector3(1.02, 0.11, 0.12) if along_x else Vector3(0.12, 0.11, 1.02), material)
		if terrain != AreaDef.Terrain.GRASS:
			continue
		for tuft: int in range(2):
			var hash: int = _hash(at_cell.x * 5 + direction.x + tuft * 11, at_cell.y * 5 + direction.y + noise % 3)
			var slide: float = -0.32 + float(hash % 9) * 0.08
			var drop: float = 0.1 + float((hash / 9) % 3) * 0.05
			var shift := Vector3(slide, 0, 0) if along_x else Vector3(0, 0, slide)
			var size := Vector3(0.12, drop, 0.05) if along_x else Vector3(0.05, drop, 0.12)
			block.call(at + outward * 0.53 + shift + Vector3(0, -0.08 - drop * 0.5, 0), size, "leaf" if hash % 2 else "grass_dark")


## One flight of stairs on its own, standing at the origin and climbing toward `dir`: for a placement ghost.
static func flight(dir: Vector2i, block: Callable) -> void:
	_stairs({"dir": dir}, Vector3.ZERO, 0, block)


## A flight climbs from its own level at its foot edge to one level up at the top edge: STAIR_STEPS stone steps,
## each a block from the ground to its tread, between two stone cheeks that step up beside them.
static func _stairs(flight: Dictionary, at: Vector3, noise: int, block: Callable) -> void:
	var dir: Vector2i = flight.dir
	var forward := Vector3(float(dir.x), 0.0, -float(dir.y))
	var side := Vector3(-forward.z, 0.0, forward.x)
	var along_x: bool = dir.x != 0
	var depth: float = 1.0 / float(STAIR_STEPS)
	var bottom: float = -0.2
	for index: int in range(STAIR_STEPS):
		var reach: float = -0.5 + depth * (float(index) + 0.5)
		var tread: float = LEVEL_RISE * float(index + 1) / float(STAIR_STEPS)
		var middle: Vector3 = at + forward * reach + Vector3(0, (bottom + tread) * 0.5, 0)
		var tall: float = tread - bottom
		block.call(middle, Vector3(depth, tall, 0.8) if along_x else Vector3(0.8, tall, depth), "stone_light" if (index + noise) % 2 == 0 else "stone_warm")
		# A darker nosing on the front of each tread picks the steps out from the camera's height.
		block.call(at + forward * (reach - depth * 0.5 + 0.02) + Vector3(0, tread - 0.025, 0), Vector3(0.04, 0.05, 0.8) if along_x else Vector3(0.8, 0.05, 0.04), "stone_dark")
		for edge: float in [-1.0, 1.0]:
			var cheek: float = tread + 0.1 - bottom
			block.call(at + forward * reach + side * (0.45 * edge) + Vector3(0, bottom + cheek * 0.5, 0), Vector3(depth, cheek, 0.1) if along_x else Vector3(0.1, cheek, depth), "stone_dark")


## Water above lower ground is held by a stone kerb on each side that drops away. Where the drop is to more water
## the kerb sits under the surface, so the water spills over it as a waterfall.
static func _water_rims(area: AreaDef, at_cell: Vector2i, at: Vector3, noise: int, block: Callable) -> void:
	var level: int = area.level_at(at_cell)
	for direction: Vector2i in CELL_DIRECTIONS:
		var other: Vector2i = at_cell + direction
		if area.level_at(other) >= level:
			continue
		var falls: bool = area.terrain_at(other) == AreaDef.Terrain.WATER
		var top: float = -0.25 if falls else 0.02
		var outward := Vector3(float(direction.x), 0.0, -float(direction.y))
		var along_x: bool = direction.x == 0
		var tall: float = top + 0.46
		block.call(at + outward * 0.44 + Vector3(0, top - tall * 0.5, 0), Vector3(1.0, tall, 0.12) if along_x else Vector3(0.12, tall, 1.0), "stone" if (noise + direction.x + direction.y) % 2 else "stone_light")


## Stone paving: one slab per cell. The painted cobble texture draws the stones and mortar; the tone
## drifts in broad patches (never cell by cell, which reads as a checkerboard).
static func _paving(at: Vector3, at_cell: Vector2i, block: Callable) -> void:
	var n: float = _noise(float(at_cell.x) / 5.0 + 11.0, float(at_cell.y) / 5.0) * 0.7 + _noise(float(at_cell.x) / 1.7, float(at_cell.y) / 1.7 + 70.0) * 0.3
	var tone: String = "path_dark" if n < 0.34 else ("path_light" if n > 0.66 else "path")
	block.call(at + Vector3(0, 0.022, 0), Vector3(1.0, 0.06, 1.0), tone)


## Broad natural patches instead of a checkerboard: two octaves of value noise choose the grass tone.
static func _grass_material(at_cell: Vector2i) -> String:
	var n: float = _noise(float(at_cell.x) / 7.0, float(at_cell.y) / 7.0) * 0.65 + _noise(float(at_cell.x) / 2.3 + 40.0, float(at_cell.y) / 2.3) * 0.35
	if n < 0.36:
		return "grass_dark"
	if n > 0.64:
		return "grass_light"
	return "grass"


## Rock outcrops rise in irregular stacks. Taller toward the edge of the valley, so it reads as a rim.
static func _rock(area: AreaDef, at_cell: Vector2i, at: Vector3, noise: int, block: Callable) -> void:
	var edge: int = mini(mini(at_cell.x, at_cell.y), mini(area.width - 1 - at_cell.x, area.height - 1 - at_cell.y))
	var rise: float = 0.55 + float(noise % 5) * 0.12 + (0.5 if edge < 5 else 0.0) + 0.25 * _noise(float(at_cell.x) / 3.0, float(at_cell.y) / 3.0)
	block.call(at + Vector3(0, -0.2, 0), Vector3(1, 0.4, 1), "soil_dark")
	var main_material: String = ["stone", "stone_dark", "stone", "stone_light"][(noise / 7) % 4]
	block.call(at + Vector3(0, rise * 0.5 - 0.05, 0), Vector3(1.0, rise + 0.1, 1.0), main_material)
	var cap: float = 0.14 + float(noise % 3) * 0.05
	block.call(at + Vector3(float(noise % 3 - 1) * 0.06, rise + 0.02 + cap * 0.5, float((noise / 3) % 3 - 1) * 0.06),
		Vector3(0.82, cap, 0.82), "stone_light" if noise % 4 == 0 else "stone", Vector3(0, float(noise % 7 - 3) * 0.06, 0))


## Stone retaining edge wherever land meets water on its own level, with capstones in alternating tones.
static func _banks(area: AreaDef, at_cell: Vector2i, at: Vector3, noise: int, block: Callable) -> void:
	var level: int = area.level_at(at_cell)
	var wet := func(other: Vector2i) -> bool: return area.terrain_at(other) == AreaDef.Terrain.WATER and area.level_at(other) == level
	for direction: Vector2i in CELL_DIRECTIONS:
		if not wet.call(at_cell + direction):
			continue
		var along_x: bool = direction.x == 0
		var toward := Vector3(float(direction.x), 0.0, -float(direction.y)) * 0.41
		var span := Vector3(1.0, 0.36, 0.2) if along_x else Vector3(0.2, 0.36, 1.0)
		block.call(at + toward + Vector3(0, -0.15, 0), span, "stone_dark")
		for half: int in range(2):
			var slide: float = -0.25 + 0.5 * float(half)
			var shift := Vector3(slide, 0, 0) if along_x else Vector3(0, 0, slide)
			var stone: String = "stone_light" if (noise + half) % 3 else "stone"
			var cap_span := Vector3(0.48, 0.16, 0.27) if along_x else Vector3(0.27, 0.16, 0.48)
			block.call(at + toward * 0.88 + shift + Vector3(0, 0.0, 0), cap_span, stone)
	# Convex corners where only a diagonal neighbor is water get a post so the bank stays closed.
	for diagonal: Vector2i in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		if wet.call(at_cell + diagonal) and not wet.call(at_cell + Vector2i(diagonal.x, 0)) and not wet.call(at_cell + Vector2i(0, diagonal.y)):
			block.call(at + Vector3(float(diagonal.x), 0, -float(diagonal.y)) * 0.41 + Vector3(0, -0.12, 0), Vector3(0.2, 0.4, 0.2), "stone_dark")


static func _fence(segment: Dictionary, block: Callable, lift: float = 0.0) -> void:
	var a: Vector2 = segment.from
	var b: Vector2 = segment.to
	var along_x: bool = is_equal_approx(a.y, b.y)
	var length: float = (b - a).length()
	var count: int = maxi(1, roundi(length))
	var middle: Vector2 = (a + b) * 0.5
	var rail_size := Vector3(length, 0.075, 0.09) if along_x else Vector3(0.09, 0.075, length)
	for height: float in [0.22, 0.51]:
		block.call(Vector3(middle.x, lift + height, -middle.y), rail_size, "oak")
	for index: int in range(count + 1):
		var t: float = float(index) / float(count)
		var post: Vector2 = a.lerp(b, t)
		block.call(Vector3(post.x, lift + 0.32, -post.y), Vector3(0.13, 0.64, 0.15), "oak")
		block.call(Vector3(post.x, lift + 0.66, -post.y), Vector3(0.18, 0.09, 0.19), "wood_dark")


## A dry-stone wall: two staggered courses of block stone under a pale cap.
static func _wall(segment: Dictionary, block: Callable, lift: float = 0.0) -> void:
	var a: Vector2 = segment.from
	var b: Vector2 = segment.to
	var along_x: bool = is_equal_approx(a.y, b.y)
	var length: float = (b - a).length()
	var count: int = maxi(1, roundi(length / 0.78))
	var step: float = length / float(count)
	var direction: Vector2 = (b - a).normalized()
	for course: int in range(2):
		for index: int in range(count):
			var distance: float = (float(index) + 0.5 + (0.25 if course == 1 else 0.0)) * step
			if course == 1 and index == count - 1:
				distance = (float(index) + 0.5) * step - 0.25 * step
			var center: Vector2 = a + direction * distance
			var hash: int = _hash(roundi(center.x * 7.0), roundi(center.y * 7.0) + course)
			var stone: String = ["stone", "stone_light", "stone", "stone_dark"][hash % 4]
			var size := Vector3(step * 0.97, 0.46, 0.5) if along_x else Vector3(0.5, 0.46, step * 0.97)
			block.call(Vector3(center.x, lift + 0.23 + float(course) * 0.47, -center.y), size, stone)
	var cap_size := Vector3(length, 0.14, 0.62) if along_x else Vector3(0.62, 0.14, length)
	var middle: Vector2 = (a + b) * 0.5
	block.call(Vector3(middle.x, lift + 1.0, -middle.y), cap_size, "stone_light")


static func _hash(x: int, y: int) -> int:
	return absi((x * 374761393 + y * 668265263 + 19) ^ ((x + y * 57) * 1274126177))


## Smooth value noise in 0..1 from a hashed lattice.
static func _noise(x: float, y: float) -> float:
	var ix: int = floori(x)
	var iy: int = floori(y)
	var fx: float = x - float(ix)
	var fy: float = y - float(iy)
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var v00: float = float(_hash(ix, iy) % 1024) / 1023.0
	var v10: float = float(_hash(ix + 1, iy) % 1024) / 1023.0
	var v01: float = float(_hash(ix, iy + 1) % 1024) / 1023.0
	var v11: float = float(_hash(ix + 1, iy + 1) % 1024) / 1023.0
	return lerpf(lerpf(v00, v10, fx), lerpf(v01, v11, fx), fy)
