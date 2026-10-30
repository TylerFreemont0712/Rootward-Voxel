class_name AreaDef
extends RefCounted
## A validated, versioned area document. The rules and the renderer both read this; neither
## hard-codes a map. Pure data: it never creates nodes or reads files (app/area_store.gd does).
##
## Logical `[x, y, height]` is the world's coordinate system. One cell is one unit and cell centers
## are integers. Terrain rows are written north-up (row 0 is the largest y) so a map reads like a map.

const SCHEMA: int = 1
## Facing is the side of a building that its door/front points toward, in logical directions.
## "S" is toward -y, "E" toward +x. The value is the Godot Y rotation in degrees.
const FACINGS: Dictionary = {"S": 0.0, "E": 90.0, "N": 180.0, "W": 270.0}
## What a quest can teach the player's code to do to the valley's houses, trees and doodads (see CodeBuild).
const CAPABILITIES: Array[String] = ["read", "turn"]
const FENCE_THICKNESS: float = 0.16
const WALL_THICKNESS: float = 0.5
const MAX_SIDE: int = 160
## The ground a prop without a catalog footprint covers (a small square), for clearance and picking. It never blocks.
const PROP_BODY: float = 0.4
## Land is terraced: every cell stands on level 0 (the valley floor), 1 or 2. Cliffs between levels block the way;
## stairs climb exactly one level. How tall a level looks is the renderer's business (TerrainBuilder.LEVEL_RISE).
const MAX_LEVEL: int = 2
## One cell's step toward each facing, in logical directions.
const STEPS: Dictionary = {"S": Vector2i(0, -1), "E": Vector2i(1, 0), "N": Vector2i(0, 1), "W": Vector2i(-1, 0)}

enum Terrain { GRASS, PATH, COBBLE, WATER, ROCK }
const GLYPHS: Dictionary = {".": Terrain.GRASS, ",": Terrain.PATH, "=": Terrain.COBBLE, "~": Terrain.WATER, "#": Terrain.ROCK}

var id: String = ""
var title: String = ""
var version: int = 0
var width: int = 0
var height: int = 0
var spawn: Vector2i = Vector2i.ZERO
## Cells, index = y * width + x. Values are Terrain.
var terrain: PackedByteArray = PackedByteArray()
## Land levels, indexed like `terrain`: 0 to MAX_LEVEL. All zero when the document has no `levels`.
var levels: PackedByteArray = PackedByteArray()
## Flights of stairs: {at: Vector2i, up: facing, dir: Vector2i, level}. Each climbs from `level` on its own cell to
## level + 1 on the cell at `at + dir`; the cell at `at - dir` is its foot.
var stairs: Array[Dictionary] = []
## {} for generated terrain, or {asset, water_rects} when a Blender-authored land model is selected.
var ground: Dictionary = {}
var paint: Dictionary = {}
var paint_materials: Array = GroundPaint.DEFAULT_PALETTE.duplicate()
var warnings: Array[String] = []
var buildings: Array[Dictionary] = []
var trees: Array[Dictionary] = []
## Loose decorations the player places: {id, asset, at, facing, scale, rect, solid}. `solid` is true when the
## catalog gives the asset a footprint, which then blocks movement; `rect` is the ground it covers either way.
var props: Array[Dictionary] = []
var segments: Array[Dictionary] = []
var lamps: Array[Dictionary] = []
var gates: Array[Dictionary] = []
var bridges: Array[Dictionary] = []
var wheels: Array[Dictionary] = []
var zones: Array[Dictionary] = []
## {id, title, object, zone, at}: reusable fixed terminals and their reachable approaches.
var terminals: Array[Dictionary] = []
## {id, item, object, title, at}: an authored thing the traveller can pick up, and where they stand to do it.
var pickups: Array[Dictionary] = []
var quests: Array[Dictionary] = []
## Presentation settings and logical furniture/inhabitant data for instanced rooms and the village edge.
var interior: Dictionary = {}
var boundary: Dictionary = {}
var villagers: Array[Dictionary] = []
var movement_lesson: bool = false
## The hello lesson (print speaks to Hotaru) without the movement-key lesson: the player walks normally.
var voice_lesson: bool = false
var _index: Dictionary = {}


## Returns {ok, area, errors}. `catalog` is pipeline/world-catalog.json's parsed `assets` block, used
## only to read building footprints. `quest_document` is optional.
static func parse(document: Variant, catalog: Dictionary, quest_document: Variant = {}, ground_materials: Array = GroundPaint.DEFAULT_PALETTE) -> Dictionary:
	var area := AreaDef.new()
	area.paint_materials = ground_materials.duplicate()
	var errors: Array[String] = []
	if not document is Dictionary:
		return {"ok": false, "area": null, "errors": ["The area document must be a JSON object."] as Array[String]}
	area._read(document, catalog, errors)
	if errors.is_empty() and quest_document is Dictionary and not (quest_document as Dictionary).is_empty():
		area._read_quests(quest_document, errors)
	if errors.is_empty():
		area._cross_check(errors)
	return {"ok": errors.is_empty(), "area": area if errors.is_empty() else null, "errors": errors, "warnings": area.warnings}


func terrain_at(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return -1
	return terrain[cell.y * width + cell.x]


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


## The land level of a cell, 0 to MAX_LEVEL. Outside the area the valley floor continues, so it is 0.
func level_at(cell: Vector2i) -> int:
	if not in_bounds(cell) or levels.is_empty():
		return 0
	return levels[cell.y * width + cell.x]


## The stairs standing on a cell, or {}.
func stair_at(cell: Vector2i) -> Dictionary:
	return _index.get("stairs:%d,%d" % [cell.x, cell.y], {})


## How high the walking surface is under a point, in levels: the cell's level, or on stairs a ramp from the stair's
## level at its foot edge to one more at its top edge. Presentation multiplies this by the height of a level.
func ground_level(point: Vector2) -> float:
	var cell := Vector2i(floori(point.x + 0.5), floori(point.y + 0.5))
	var flight: Dictionary = stair_at(cell)
	if flight.is_empty():
		return float(level_at(cell))
	var along: float = (point - Vector2(cell)).dot(Vector2(flight.dir))
	return float(flight.level) + clampf(along + 0.5, 0.0, 1.0)


## The one level shared by every cell a rect covers, or -1 if it straddles two levels or stands on stairs.
func level_under(rect: Rect2) -> int:
	var shared: int = -2
	for x: int in range(ceili(rect.position.x - 0.5), floori(rect.end.x + 0.5 - 0.000001) + 1):
		for y: int in range(ceili(rect.position.y - 0.5), floori(rect.end.y + 0.5 - 0.000001) + 1):
			var cell := Vector2i(x, y)
			if not stair_at(cell).is_empty():
				return -1
			if shared == -2:
				shared = level_at(cell)
			elif level_at(cell) != shared:
				return -1
	return maxi(shared, 0)


func lamp(lamp_id: String) -> Dictionary:
	return _index.get("lamp:" + lamp_id, {})


## The building with this id, or {} (a linear scan: an area has a handful of buildings).
func building(building_id: String) -> Dictionary:
	for entry: Dictionary in buildings:
		if entry.id == building_id:
			return entry
	return {}


## The prop with this id, or {} (a linear scan, like building()).
func prop(prop_id: String) -> Dictionary:
	for entry: Dictionary in props:
		if entry.id == prop_id:
			return entry
	return {}


func gate(gate_id: String) -> Dictionary:
	return _index.get("gate:" + gate_id, {})


func bridge(bridge_id: String) -> Dictionary:
	return _index.get("bridge:" + bridge_id, {})


func zone(zone_id: String) -> Dictionary:
	return _index.get("zone:" + zone_id, {})


func quest(quest_id: String) -> Dictionary:
	return _index.get("quest:" + quest_id, {})


## Which bridge owns a socket cell, and its position in the build order. {} if none.
func socket(cell: Vector2i) -> Dictionary:
	return _index.get("socket:%d,%d" % [cell.x, cell.y], {})


func zone_at(cell: Vector2i) -> String:
	for entry: Dictionary in zones:
		if (entry.rect as Rect2i).has_point(cell):
			return entry.id
	return ""


func lamp_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry: Dictionary in lamps:
		ids.append(entry.id)
	return ids


func lamps_in_zone(zone_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in lamps:
		if entry.zone == zone_id:
			result.append(entry)
	return result


func _read(document: Dictionary, catalog: Dictionary, errors: Array[String]) -> void:
	if int(document.get("schema", 0)) != SCHEMA:
		errors.append("Unsupported area schema %s (expected %d)." % [str(document.get("schema")), SCHEMA])
		return
	id = str(document.get("id", ""))
	title = str(document.get("title", ""))
	version = int(document.get("version", 0))
	if not document.get("movement_lesson", false) is bool:
		errors.append("movement_lesson must be true or false.")
		return
	movement_lesson = document.get("movement_lesson", false)
	if not document.get("voice_lesson", false) is bool:
		errors.append("voice_lesson must be true or false.")
		return
	voice_lesson = document.get("voice_lesson", false)
	if id == "" or not id.is_valid_filename() or title == "" or version < 1:
		errors.append("An area needs a file-safe id, a title and a version of at least 1.")
		return
	var size: Variant = document.get("size")
	if not size is Array or size.size() != 2 or not _whole(size[0]) or not _whole(size[1]):
		errors.append("size must be [width, height] in whole cells.")
		return
	width = int(size[0])
	height = int(size[1])
	if width < 4 or height < 4 or width > MAX_SIDE or height > MAX_SIDE:
		errors.append("Area size must be between 4 and %d cells per side." % MAX_SIDE)
		return
	_read_terrain(document.get("terrain"), errors)
	if not errors.is_empty():
		return
	_read_levels(document.get("levels"), errors)
	_read_stairs(document.get("stairs", []), errors)
	if not errors.is_empty():
		return
	_read_paint(document.get("paint"), errors)
	var spawn_value: Variant = document.get("spawn")
	if not _cell_value(spawn_value):
		errors.append("spawn must be [x, y].")
		return
	spawn = Vector2i(int(spawn_value[0]), int(spawn_value[1]))
	if not in_bounds(spawn):
		errors.append("spawn lies outside the area.")
	var ground_value: Variant = document.get("ground", {})
	if ground_value is Dictionary:
		ground = (ground_value as Dictionary).duplicate(true)
		if not ground.is_empty() and (not ground.get("asset") is String or not catalog.has(ground.asset)):
			errors.append("ground.asset must name a world-catalog asset.")
	else:
		errors.append("ground must be an object.")
	_read_zones(document.get("zones", []), errors)
	_read_buildings(document.get("buildings", []), catalog, errors)
	_read_props(document.get("props", []), catalog, errors)
	_read_trees(document.get("trees", []), catalog, errors)
	_read_segments(document.get("segments", []), errors)
	_read_lamps(document.get("lamps", []), errors)
	_read_gates(document.get("gates", []), errors)
	_read_bridges(document.get("bridges", []), errors)
	_read_wheels(document.get("wheels", []), errors)
	_read_places(document, errors)
	_read_terminals(document.get("terminals", []), catalog, errors)
	_read_pickups(document.get("pickups", []), errors)


func _read_terminals(value: Variant, catalog: Dictionary, errors: Array[String]) -> void:
	if not value is Array or value.size() > 24:
		errors.append("terminals must be a list of at most 24 zone connections.")
		return
	var ids: Array[String] = []
	var objects: Array[String] = []
	for raw: Variant in value:
		if not raw is Dictionary or not _id(raw.get("id")) or not _id(raw.get("object")) or not _id(raw.get("zone")) or not raw.get("title") is String or str(raw.title).is_empty() or str(raw.title).length() > 80 or not _cell_value(raw.get("at")):
			errors.append("A terminal needs an id, title, placed object, zone and approach cell.")
			return
		var at := Vector2i(int(raw.at[0]), int(raw.at[1]))
		if ids.has(str(raw.id)) or objects.has(str(raw.object)) or zone(str(raw.zone)).is_empty() or not in_bounds(at) or zone_at(at) != raw.zone or terrain_at(at) in [Terrain.WATER, Terrain.ROCK]:
			errors.append("Terminals need distinct ids and objects, and a safe approach in their named zone.")
			return
		if prop(str(raw.object)).is_empty() and not (interior.get("assets", []) as Array).any(func(item: Dictionary) -> bool: return item.id == raw.object):
			errors.append("A terminal must name a placed room asset or prop.")
			return
		var model: String = str(prop(str(raw.object)).get("asset", ""))
		var object_at: Vector2 = prop(str(raw.object)).get("at", Vector2.ZERO)
		for item: Dictionary in interior.get("assets", []):
			if item.id == raw.object:
				model = str(item.asset)
				object_at = Vector2(float(item.at[0]), float(item.at[1]))
		if object_at.distance_to(Vector2(at)) > 2.0:
			errors.append("A terminal approach must stand beside its placed computer.")
			return
		if not bool((catalog.get(model, {}) as Dictionary).get("zone_terminal", false)):
			errors.append("A zone connection must use a terminal model.")
			return
		if raw.has("requires") and (not raw.requires is String or not PlayerItems.KNOWN.has(raw.requires)):
			errors.append("A terminal can only require an item the game knows.")
			return
		for text: String in ["prompt", "idle", "locked"]:
			if raw.has(text) and (not raw[text] is String or str(raw[text]).is_empty() or str(raw[text]).length() > 160):
				errors.append("A terminal's prompt, idle words and locked text must be short text.")
				return
		ids.append(str(raw.id))
		objects.append(str(raw.object))
		terminals.append(raw.duplicate(true))


func _read_pickups(value: Variant, errors: Array[String]) -> void:
	if not value is Array or value.size() > 8:
		errors.append("pickups must be a list of at most 8 items.")
		return
	var ids: Array[String] = []
	var items: Array[String] = []
	for raw: Variant in value:
		if not raw is Dictionary or not _id(raw.get("id")) or not _id(raw.get("object")) or not raw.get("item") is String or not PlayerItems.KNOWN.has(raw.item) or not raw.get("title") is String or str(raw.title).is_empty() or str(raw.title).length() > 80 or not _cell_value(raw.get("at")):
			errors.append("A pickup needs an id, a known item, a placed object, a title and an approach cell.")
			return
		var at := Vector2i(int(raw.at[0]), int(raw.at[1]))
		if ids.has(str(raw.id)) or items.has(str(raw.item)) or not in_bounds(at) or terrain_at(at) in [Terrain.WATER, Terrain.ROCK]:
			errors.append("Pickups need distinct ids and items, and a safe approach inside the area.")
			return
		var object_at: Variant = null
		for item: Dictionary in interior.get("assets", []):
			if item.id == raw.object:
				object_at = Vector2(float(item.at[0]), float(item.at[1]))
		if object_at == null:
			errors.append("A pickup must name a placed room asset.")
			return
		if (object_at as Vector2).distance_to(Vector2(at)) > 2.5:
			errors.append("A pickup approach must stand beside the thing it lets you take.")
			return
		ids.append(str(raw.id))
		items.append(str(raw.item))
		pickups.append(raw.duplicate(true))


func _read_places(document: Dictionary, errors: Array[String]) -> void:
	var room: Variant = document.get("interior", {})
	if not room is Dictionary:
		errors.append("interior must be an object.")
		return
	if not room.is_empty():
		if not _cell_value(room.get("exit")) or not in_bounds(Vector2i(int(room.exit[0]), int(room.exit[1]))) or not room.get("furniture", []) is Array:
			errors.append("An interior needs an exit cell and a furniture list.")
			return
		interior = room.duplicate(true)
		var connection_error: String = _room_connection_error(room)
		if connection_error != "":
			errors.append(connection_error)
			return
		if room.has("stairwell"):
			var well: Variant = room.stairwell
			if not well is Dictionary or not well.get("rect") is Array or well.rect.size() != 4 or not well.rect.all(_number) or not STEPS.has(well.get("up", "")) or not well.get("treads") is Array or well.treads.is_empty() or well.treads.size() > 12 or not _number(well.get("floor")):
				errors.append("An interior stairwell needs rect [x,y,w,h], up, 1–12 tread heights and a floor height.")
				return
			var bounds := Rect2(float(well.rect[0]), float(well.rect[1]), float(well.rect[2]), float(well.rect[3]))
			if bounds.size.x <= 0 or bounds.size.y <= 0 or bounds.position.x < 0 or bounds.position.y < 0 or bounds.end.x > width or bounds.end.y > height or not bounds.has_point(Vector2(float(room.exit[0]), float(room.exit[1]))) or float(well.floor) < 0 or float(well.floor) > .2:
				errors.append("Keep the stairwell inside the room, containing its exit, with floor height 0–0.2.")
				return
			var previous: float = -2.0
			for tread: Variant in well.treads:
				if not _number(tread) or float(tread) < -1.5 or float(tread) <= previous or float(tread) >= float(well.floor):
					errors.append("Stairwell treads must rise in order from at least -1.5 to below the floor.")
					return
				previous = float(tread)
		for field: String in ["materials", "finishes"]:
			var finish_error: String = SurfaceFinishes.validate(room.get(field, {}), SurfaceFinishes.ROOM_SLOTS)
			if finish_error != "":
				errors.append("Interior %s: %s" % [field, finish_error])
				return
		var furniture: Array[Dictionary] = []
		for raw: Variant in room.get("furniture", []):
			if not raw is Dictionary or not raw.get("kind") in ["bed", "table", "chair", "shelf", "hearth", "bench", "rug", "counter"] or not _point_value(raw.get("at")) or not _point_value(raw.get("size")):
				errors.append("Furniture needs a known kind, at [x,y] and size [w,h].")
				return
			var at := Vector2(float(raw.at[0]), float(raw.at[1]))
			var size := Vector2(float(raw.size[0]), float(raw.size[1]))
			var rect := Rect2(at - size * 0.5, size)
			if size.x <= 0 or size.y <= 0 or rect.position.x < 0.0 or rect.position.y < 0.0 or rect.end.x > width or rect.end.y > height:
				errors.append("Keep furniture inside the room with a positive size.")
				return
			furniture.append({"kind": raw.kind, "at": at, "size": size, "rect": rect})
		interior.furniture = furniture
		if room.has("host"):
			var host: Variant = room.host
			if not host is Dictionary or not _cell_value(host.get("at")) or not host.get("route") is Array:
				errors.append("An interior host needs at [x,y] and a route list.")
				return
			var stops: Array = [host.at]
			stops.append_array(host.route)
			for stop: Variant in stops:
				if not _cell_value(stop) or not in_bounds(Vector2i(int(stop[0]), int(stop[1]))):
					errors.append("Keep the interior host's route inside the room.")
					return
	var edge: Variant = document.get("boundary", {})
	if not edge is Dictionary:
		errors.append("boundary must be an object.")
		return
	if not edge.is_empty():
		if not _number(edge.get("apron", 0)) or float(edge.apron) < 16.0 or float(edge.apron) > 64.0:
			errors.append("boundary.apron must be 16 to 64 world units.")
			return
		boundary = edge.duplicate(true)
	var residents: Variant = document.get("villagers", [])
	if not residents is Array:
		errors.append("villagers must be a list.")
		return
	var seen: Dictionary = {}
	for raw: Variant in residents:
		if not raw is Dictionary or not _id(raw.get("id")) or not _cell_value(raw.get("at")) or not raw.get("route", []) is Array or seen.has(raw.id):
			errors.append("Each villager needs a unique id, at [x,y] and a route list.")
			return
		var at := Vector2i(int(raw.at[0]), int(raw.at[1]))
		if not in_bounds(at) or terrain_at(at) in [Terrain.WATER, Terrain.ROCK]:
			errors.append("Villager '%s' needs ground inside the area." % raw.id)
			return
		var route: Array[Vector2i] = []
		for point: Variant in raw.get("route", []):
			if not _cell_value(point) or not in_bounds(Vector2i(int(point[0]), int(point[1]))):
				errors.append("Villager '%s' has an invalid route point." % raw.id)
				return
			route.append(Vector2i(int(point[0]), int(point[1])))
		seen[raw.id] = true
		villagers.append({"id": raw.id, "at": at, "route": route, "home": str(raw.get("home", ""))})


func _read_terrain(value: Variant, errors: Array[String]) -> void:
	if not value is Array or value.size() != height:
		errors.append("terrain must be a list of %d row strings." % height)
		return
	terrain.resize(width * height)
	for row: int in range(height):
		var line: Variant = value[row]
		if not line is String or (line as String).length() != width:
			errors.append("terrain row %d must be %d characters." % [row, width])
			return
		var y: int = height - 1 - row
		for x: int in range(width):
			var glyph: String = (line as String)[x]
			if not GLYPHS.has(glyph):
				errors.append("Unknown terrain glyph '%s' at row %d, column %d." % [glyph, row, x])
				return
			terrain[y * width + x] = GLYPHS[glyph]


## Optional `levels`: rows written north-up like terrain, one digit per cell from 0 to MAX_LEVEL.
func _read_levels(value: Variant, errors: Array[String]) -> void:
	levels.resize(width * height)
	levels.fill(0)
	if value == null:
		return
	if not value is Array or value.size() != height:
		errors.append("levels must be a list of %d row strings." % height)
		return
	for row: int in range(height):
		var line: Variant = value[row]
		if not line is String or (line as String).length() != width:
			errors.append("levels row %d must be %d characters." % [row, width])
			return
		for x: int in range(width):
			var glyph: String = (line as String)[x]
			if not glyph.is_valid_int() or glyph.to_int() > MAX_LEVEL:
				errors.append("Unknown land level '%s' at row %d, column %d: use 0 to %d." % [glyph, row, x, MAX_LEVEL])
				return
			levels[(height - 1 - row) * width + x] = glyph.to_int()


## Optional `stairs`: [{at: [x, y], up: facing}]. A flight stands on dry ground at the foot of a cliff exactly one
## level high, with dry ground of its own level behind it, and leads straight onto neither another flight nor water.
func _read_stairs(value: Variant, errors: Array[String]) -> void:
	if not value is Array:
		errors.append("stairs must be a list.")
		return
	for raw: Variant in value:
		if not raw is Dictionary or not _cell_value(raw.get("at")) or not STEPS.has(str(raw.get("up", ""))):
			errors.append("Each flight of stairs needs at [x, y] and up: N, E, S or W.")
			return
		var at := Vector2i(int(raw.at[0]), int(raw.at[1]))
		var dir: Vector2i = STEPS[str(raw.up)]
		if not stair_at(at).is_empty():
			errors.append("Two flights of stairs stand on [%d,%d]." % [at.x, at.y])
			return
		var level: int = level_at(at)
		for cell: Vector2i in [at, at - dir, at + dir]:
			if not in_bounds(cell) or terrain_at(cell) in [Terrain.WATER, Terrain.ROCK]:
				errors.append("The stairs at [%d,%d] need dry ground below, on and above them." % [at.x, at.y])
				return
		if level_at(at - dir) != level or level_at(at + dir) != level + 1:
			errors.append("The stairs at [%d,%d] must climb exactly one level, from their foot to the top." % [at.x, at.y])
			return
		var entry := {"at": at, "up": str(raw.up), "dir": dir, "level": level}
		_index["stairs:%d,%d" % [at.x, at.y]] = entry
		stairs.append(entry)
	for entry: Dictionary in stairs:
		for end: Vector2i in [entry.at - entry.dir, entry.at + entry.dir]:
			if not stair_at(end).is_empty():
				errors.append("The stairs at [%d,%d] lead straight onto more stairs." % [entry.at.x, entry.at.y])
				return


func _read_paint(value: Variant, errors: Array[String]) -> void:
	if value == null:
		return
	if not value is Dictionary or value.get("version") != 1:
		errors.append("paint must be an object with version 1.")
		return
	var ids: Variant = value.get("palette")
	if not ids is Array or ids.is_empty() or ids.size() > 36:
		errors.append("paint.palette needs 1 to 36 ground material ids.")
		return
	var seen: Dictionary = {}
	for material: Variant in ids:
		if not material is String or not paint_materials.has(material) or seen.has(material):
			errors.append("Unknown or duplicate ground material '%s' in paint.palette." % str(material))
			return
		seen[material] = true
	var roughen: Variant = value.get("roughen", 0.4)
	if not _number(roughen) or float(roughen) < 0.0 or float(roughen) > 1.0:
		errors.append("paint.roughen must be a number from 0 to 1.")
		return
	var rows: Variant = value.get("rows")
	if not rows is Array or rows.size() != height * 2:
		errors.append("paint.rows must contain %d north-up row strings." % (height * 2))
		return
	for row: int in range(height * 2):
		if not rows[row] is String or rows[row].length() != width * 2:
			errors.append("paint row %d must be %d characters." % [row, width * 2])
			return
		for sx: int in range(width * 2):
			var glyph: String = rows[row][sx]
			var index: int = GroundPaint.DIGITS.find(glyph)
			if glyph != "." and (index < 0 or index >= ids.size()):
				errors.append("Unknown paint digit '%s' at row %d, column %d." % [glyph, row, sx])
				return
			if glyph != "." and terrain_at(Vector2i(sx / 2, (height * 2 - 1 - row) / 2)) in [Terrain.WATER, Terrain.ROCK]:
				warnings.append("Paint at sub-tile [%d,%d] is ignored on water or rock." % [sx, height * 2 - 1 - row])
	paint = value.duplicate(true)
	paint["roughen"] = float(roughen)


func _read_zones(value: Variant, errors: Array[String]) -> void:
	if not value is Array:
		errors.append("zones must be a list.")
		return
	for raw: Variant in value:
		if not raw is Dictionary or not _id(raw.get("id")) or not raw.get("title") is String or not _rect_value(raw.get("rect")):
			errors.append("Each zone needs an id, title and rect [x, y, w, h].")
			return
		var r: Array = raw.rect
		var entry := {"id": raw.id, "title": raw.title, "rect": Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))}
		if not zone(raw.id).is_empty():
			errors.append("Duplicate zone id '%s'." % raw.id)
			return
		_index["zone:" + raw.id] = entry
		zones.append(entry)


func _read_buildings(value: Variant, catalog: Dictionary, errors: Array[String]) -> void:
	if not value is Array:
		errors.append("buildings must be a list.")
		return
	for raw: Variant in value:
		if not raw is Dictionary or not _id(raw.get("id")) or not raw.get("asset") is String or not _point_value(raw.get("at")):
			errors.append("Each building needs an id, an asset and at [x, y].")
			return
		var facing: String = str(raw.get("facing", "S"))
		var scale: float = float(raw.get("scale", 1.0))
		if not FACINGS.has(facing) or scale <= 0.0 or scale > 4.0 or not catalog.has(raw.asset):
			errors.append("Building '%s' has an unknown asset, facing or scale." % raw.id)
			return
		var footprint: Variant = (catalog[raw.asset] as Dictionary).get("logical_footprint")
		if not footprint is Array or footprint.size() != 4:
			errors.append("Asset '%s' has no logical_footprint in the catalog." % raw.asset)
			return
		var at := Vector2(float(raw.at[0]), float(raw.at[1]))
		# Catalog footprints are offsets from the ground pivot in the asset's own S-facing frame.
		var offset := Rect2(float(footprint[0]), float(footprint[1]), float(footprint[2]), float(footprint[3]))
		var quarter_turn: bool = facing == "E" or facing == "W"
		var half := Vector2(offset.size.y, offset.size.x) * 0.5 * scale if quarter_turn else offset.size * 0.5 * scale
		var rect := Rect2(at - half, half * 2.0)
		if rect.position.x < 0.0 or rect.position.y < 0.0 or rect.end.x > float(width) or rect.end.y > float(height):
			errors.append("Building '%s' lies outside the area." % raw.id)
			return
		if level_under(rect) < 0:
			errors.append("Building '%s' must stand on level ground, off any stairs." % raw.id)
			return
		var finish_error: String = SurfaceFinishes.validate(raw.get("finishes", {}), SurfaceFinishes.asset_slots(catalog[raw.asset]))
		if finish_error != "":
			errors.append("Building '%s': %s" % [raw.id, finish_error])
			return
		var solids: Array[Rect2]=[]
		var shapes: Variant=catalog[raw.asset].get("collision_rects",[])
		if not shapes is Array or shapes.size()>16:
			errors.append("Asset '%s' needs a bounded collision rectangle list." % raw.asset)
			return
		for shape: Variant in shapes:
			if not shape is Array or shape.size()!=4 or not shape.all(_number) or float(shape[2])<=0 or float(shape[3])<=0:
				errors.append("Asset '%s' has an invalid collision rectangle." % raw.asset)
				return
			var local:=Rect2(float(shape[0]),float(shape[1]),float(shape[2]),float(shape[3]))
			var angle: float=deg_to_rad(float(FACINGS[facing]))
			var solid:=Rect2(at+local.position.rotated(angle)*scale,Vector2.ZERO)
			for corner: Vector2 in [local.position,local.end,Vector2(local.end.x,local.position.y),Vector2(local.position.x,local.end.y)]:solid=solid.expand(at+corner.rotated(angle)*scale)
			solids.append(solid)
		var door_offset: int=0
		var entrance: Variant=catalog[raw.asset].get("entrance",{})
		if not entrance is Dictionary:
			errors.append("Asset '%s' needs a plain entrance definition." % raw.asset)
			return
		if not entrance.is_empty():
			if not _number(entrance.get("plane")) or not _number(entrance.get("width")) or float(entrance.width)<=0 or not _number(entrance.get("center_x",0)):
				errors.append("Asset '%s' needs a door plane, width and numeric center_x." % raw.asset)
				return
			var extra: Variant=entrance.get("approach_cells",0)
			if not _whole(extra) or int(extra)<0 or int(extra)>1:
				errors.append("Asset '%s' approach_cells must be 0 or 1." % raw.asset)
				return
			door_offset=AreaBuild.door_offset(rect,at,facing,scale,entrance)
			if solids.is_empty():solids.append(rect)
			# Exterior doors remain solid: travel crosses to a separate room. The
			# former threshold is reserved too, so no side-step can reach the leaf.
			if door_offset>0:
				var threshold:=Vector2(AreaBuild.threshold_cell(rect,at,facing))
				solids.append(Rect2(threshold-Vector2.ONE*.25,Vector2.ONE*.5))
			solids.append(AreaBuild.entrance_rect(at,facing,scale,entrance))
		buildings.append({"id": raw.id, "asset": raw.asset, "at": at, "facing": facing, "scale": scale, "rect": rect, "collision_rects":solids,"door_offset":door_offset,"locked": raw.get("locked", false) == true, "finishes": raw.get("finishes", {}).duplicate(true)})


## Props have no door, and their catalog footprint is optional: one with a footprint blocks movement (`solid`), one
## without is a small thing to walk past. `rect` is centred on `at`, as a building's is, and turns with `facing`.
func _read_props(value: Variant, catalog: Dictionary, errors: Array[String]) -> void:
	if not value is Array:
		errors.append("props must be a list.")
		return
	for raw: Variant in value:
		if not raw is Dictionary or not _id(raw.get("id")) or not raw.get("asset") is String or not _point_value(raw.get("at")):
			errors.append("Each prop needs an id, an asset and at [x, y].")
			return
		var facing: String = str(raw.get("facing", "S"))
		var scale: float = float(raw.get("scale", 1.0))
		if not FACINGS.has(facing) or scale <= 0.0 or scale > 4.0 or not catalog.has(raw.asset):
			errors.append("Prop '%s' has an unknown asset, facing or scale." % raw.id)
			return
		if not prop(str(raw.id)).is_empty():
			errors.append("Prop id '%s' is used twice." % raw.id)
			return
		var footprint: Variant = (catalog[raw.asset] as Dictionary).get("logical_footprint")
		var solid: bool = footprint is Array and footprint.size() == 4
		var size := Vector2(float(footprint[2]), float(footprint[3])) if solid else Vector2(PROP_BODY, PROP_BODY)
		if facing == "E" or facing == "W":
			size = Vector2(size.y, size.x)
		size *= scale
		var at := Vector2(float(raw.at[0]), float(raw.at[1]))
		var rect := Rect2(at - size * 0.5, size)
		if rect.position.x < 0.0 or rect.position.y < 0.0 or rect.end.x > float(width) or rect.end.y > float(height):
			errors.append("Prop '%s' lies outside the area." % raw.id)
			return
		if level_under(rect) < 0:
			errors.append("Prop '%s' must stand on level ground, off any stairs." % raw.id)
			return
		var interaction: Variant = (catalog[raw.asset] as Dictionary).get("interaction", {})
		if not interaction is Dictionary or (not interaction.is_empty() and (not interaction.get("kind") in PropInteractions.KINDS or not interaction.get("on") is String or not interaction.get("off") is String)):
			errors.append("Prop '%s' has an invalid interaction capability in the asset catalog." % raw.id)
			return
		var finish_error: String = SurfaceFinishes.validate(raw.get("finishes", {}), SurfaceFinishes.asset_slots(catalog[raw.asset]))
		if finish_error != "":
			errors.append("Prop '%s': %s" % [raw.id, finish_error])
			return
		props.append({"id": raw.id, "asset": raw.asset, "at": at, "facing": facing, "scale": scale, "rect": rect, "solid": solid, "finishes": raw.get("finishes", {}).duplicate(true),
			"interaction": interaction.duplicate(true), "title": str((catalog[raw.asset] as Dictionary).get("label", raw.asset)), "zone": zone_at(Vector2i(roundi(at.x), roundi(at.y)))})


func _read_trees(value: Variant, catalog: Dictionary, errors: Array[String]) -> void:
	if not value is Array:
		errors.append("trees must be a list of [x, y] or [x, y, size].")
		return
	for raw: Variant in value:
		if raw is Dictionary:
			var asset: String = str(raw.get("asset", ""))
			var footprint: Variant = (catalog.get(asset, {}) as Dictionary).get("logical_footprint")
			if not _point_value(raw.get("at")) or not footprint is Dictionary or not _number(footprint.get("trunk_radius")) or not _number(raw.get("size", 1.0)):
				errors.append("A model tree needs at [x,y], size and an asset with a trunk_radius footprint.")
				return
			var at := Vector2(float(raw.at[0]), float(raw.at[1]))
			var scale: float = float(raw.get("size", 1.0))
			if scale < 0.5 or scale > 2.0 or at.x < -1.0 or at.y < -1.0 or at.x > float(width) or at.y > float(height):
				errors.append("Model tree position or size is outside the area's limits.")
				return
			trees.append({"at": at, "size": scale, "asset": asset, "trunk_radius": float(footprint.trunk_radius) * scale})
			continue
		if not raw is Array or raw.size() < 2 or raw.size() > 3 or not _number(raw[0]) or not _number(raw[1]):
			errors.append("Each tree is [x, y] or [x, y, size].")
			return
		var at := Vector2(float(raw[0]), float(raw[1]))
		# Trunks may stand just past the edge: the map edge is a tree line, not a wall.
		if at.x < -1.0 or at.y < -1.0 or at.x > float(width) or at.y > float(height):
			errors.append("Tree [%s, %s] lies outside the area." % [str(raw[0]), str(raw[1])])
			return
		trees.append({"at": at, "size": float(raw[2]) if raw.size() == 3 else 1.0})


func _read_segments(value: Variant, errors: Array[String]) -> void:
	if not value is Array:
		errors.append("segments must be a list.")
		return
	for raw: Variant in value:
		if not raw is Dictionary or not raw.get("kind") in ["fence", "wall"] or not _point_value(raw.get("from")) or not _point_value(raw.get("to")):
			errors.append("Each segment needs kind fence|wall, from [x, y] and to [x, y].")
			return
		var a := Vector2(float(raw["from"][0]), float(raw["from"][1]))
		var b := Vector2(float(raw["to"][0]), float(raw["to"][1]))
		if not is_equal_approx(a.x, b.x) and not is_equal_approx(a.y, b.y):
			errors.append("Segments run along the x or y axis only.")
			return
		var thickness: float = FENCE_THICKNESS if raw.kind == "fence" else WALL_THICKNESS
		var low := Vector2(minf(a.x, b.x), minf(a.y, b.y))
		var high := Vector2(maxf(a.x, b.x), maxf(a.y, b.y))
		# Segments run to the exact ends given, so a wall can stop flush against a gate cell.
		var rect: Rect2
		if is_equal_approx(a.y, b.y):
			rect = Rect2(Vector2(low.x, low.y - thickness * 0.5), Vector2(high.x - low.x, thickness))
		else:
			rect = Rect2(Vector2(low.x - thickness * 0.5, low.y), Vector2(thickness, high.y - low.y))
		segments.append({"kind": raw.kind, "from": a, "to": b, "rect": rect, "thickness": thickness})


func _read_lamps(value: Variant, errors: Array[String]) -> void:
	if not value is Array:
		errors.append("lamps must be a list.")
		return
	for raw: Variant in value:
		if not raw is Dictionary or not _id(raw.get("id")) or not _point_value(raw.get("at")) or not raw.get("zone") is String:
			errors.append("Each lamp needs an id, a zone and at [x, y].")
			return
		var at := Vector2(float(raw["at"][0]), float(raw["at"][1]))
		var style: String = str(raw.get("style", "post"))
		if not style in ["post", "beacon", "sconce", "fixture"] or not lamp(raw.id).is_empty():
			errors.append("Lamp '%s' is duplicated or has an unknown style." % raw.id)
			return
		var entry := {"id": raw.id, "zone": raw.zone, "at": at, "cell": Vector2i(roundi(at.x), roundi(at.y)), "style": style}
		# Optional: where the traveller stands to work on this one lamp, what that needs, and what to call it.
		if raw.has("stand"):
			if not _cell_value(raw.stand) or not in_bounds(Vector2i(int(raw.stand[0]), int(raw.stand[1]))):
				errors.append("Lamp '%s' needs a stand cell inside the area." % raw.id)
				return
			entry["stand"] = [int(raw.stand[0]), int(raw.stand[1])]
		if raw.has("requires"):
			if not raw.requires is String or not PlayerItems.KNOWN.has(raw.requires):
				errors.append("Lamp '%s' can only require an item the game knows." % raw.id)
				return
			entry["requires"] = raw.requires
		if raw.has("title"):
			if not raw.title is String or str(raw.title).is_empty() or str(raw.title).length() > 60:
				errors.append("Lamp '%s' needs a short title." % raw.id)
				return
			entry["title"] = raw.title
		_index["lamp:" + raw.id] = entry
		lamps.append(entry)


func _read_gates(value: Variant, errors: Array[String]) -> void:
	if not value is Array:
		errors.append("gates must be a list.")
		return
	for raw: Variant in value:
		if not raw is Dictionary or not _id(raw.get("id")) or not _cell_value(raw.get("cell")) or not raw.get("zone") is String:
			errors.append("Each gate needs an id, a zone and a cell [x, y].")
			return
		var axis: String = str(raw.get("axis", "y"))
		if not axis in ["x", "y"] or not gate(raw.id).is_empty():
			errors.append("Gate '%s' is duplicated or has an axis other than x or y." % raw.id)
			return
		var entry := {"id": raw.id, "zone": raw.zone, "cell": Vector2i(int(raw.cell[0]), int(raw.cell[1])), "axis": axis}
		_index["gate:" + raw.id] = entry
		gates.append(entry)


func _read_bridges(value: Variant, errors: Array[String]) -> void:
	if not value is Array:
		errors.append("bridges must be a list.")
		return
	for raw: Variant in value:
		if not raw is Dictionary or not _id(raw.get("id")) or not raw.get("zone") is String or not raw.get("sockets") is Array or raw.sockets.is_empty():
			errors.append("Each bridge needs an id, a zone and an ordered list of socket cells.")
			return
		var sockets: Array[Vector2i] = []
		for cell: Variant in raw.sockets:
			if not _cell_value(cell):
				errors.append("Bridge '%s' has an invalid socket." % raw.id)
				return
			var at := Vector2i(int(cell[0]), int(cell[1]))
			if terrain_at(at) != Terrain.WATER or not socket(at).is_empty():
				errors.append("Bridge '%s' socket [%d,%d] must be an unclaimed water cell." % [raw.id, at.x, at.y])
				return
			if not sockets.is_empty() and (absi(at.x - sockets[-1].x) + absi(at.y - sockets[-1].y)) != 1:
				errors.append("Bridge '%s' sockets must be neighboring cells in build order." % raw.id)
				return
			_index["socket:%d,%d" % [at.x, at.y]] = {"bridge": raw.id, "order": sockets.size()}
			sockets.append(at)
		if not bridge(raw.id).is_empty():
			errors.append("Duplicate bridge id '%s'." % raw.id)
			return
		var entry := {"id": raw.id, "zone": raw.zone, "sockets": sockets}
		_index["bridge:" + raw.id] = entry
		bridges.append(entry)


func _read_wheels(value: Variant, errors: Array[String]) -> void:
	if not value is Array:
		errors.append("wheels must be a list.")
		return
	for raw: Variant in value:
		if not raw is Dictionary or not _id(raw.get("id")) or not _point_value(raw.get("at")) or not _point_value(raw.get("size")):
			errors.append("Each wheel needs an id, at [x, y] and a footprint size [w, h].")
			return
		var at := Vector2(float(raw["at"][0]), float(raw["at"][1]))
		var size := Vector2(float(raw["size"][0]), float(raw["size"][1]))
		if size.x <= 0.0 or size.y <= 0.0 or size.x > 3.0 or size.y > 4.0:
			errors.append("A wheel needs a positive footprint no larger than 3 by 4 cells.")
			return
		var axle := at
		if raw.has("axle_to"):
			if not _point_value(raw.axle_to):
				errors.append("A wheel's axle_to must be a finite [x, y] point.")
				return
			axle = Vector2(float(raw.axle_to[0]),float(raw.axle_to[1]))
			if not is_equal_approx(axle.y,at.y) or axle.x < at.x or axle.x-at.x > 4.0:
				errors.append("A mill axle must run east from its wheel, at most four cells.")
				return
		var rect := Rect2(at - size * 0.5, size)
		if axle != at:
			rect = rect.merge(Rect2(Vector2(at.x,at.y-.24),Vector2(axle.x-at.x+.2,.48)))
		wheels.append({"id": raw.id, "at": at, "size":size, "axle_to":axle, "rect":rect})


func _read_quests(document: Dictionary, errors: Array[String]) -> void:
	var list: Variant = document.get("quests")
	if int(document.get("schema", 0)) != SCHEMA or document.get("area") != id or not list is Array:
		errors.append("The quest document must match schema %d and area '%s'." % [SCHEMA, id])
		return
	for raw: Variant in list:
		if not raw is Dictionary or not _id(raw.get("id")) or not raw.get("title") is String or not raw.get("goal") is Dictionary:
			errors.append("Each quest needs an id, a title and a goal.")
			return
		if not quest(raw.id).is_empty():
			errors.append("Duplicate quest id '%s'." % raw.id)
			return
		var entry: Dictionary = (raw as Dictionary).duplicate(true)
		entry["requires"] = raw.get("requires", [])
		entry["hints"] = raw.get("hints", [])
		entry["lesson"] = _joined(raw.get("lesson", ""))
		entry["starter"] = _joined(raw.get("starter", ""))
		entry["done"] = _joined(raw.get("done", ""))
		entry["summary"] = _joined(raw.get("summary", ""))
		entry["concept"] = str(raw.get("concept", ""))
		entry["optional"] = bool(raw.get("optional", false))
		entry["chapter"] = str(raw.get("chapter", ""))
		var unlocks: Array[String] = []
		for capability: Variant in raw.get("unlocks", []):
			if not capability is String or not CAPABILITIES.has(capability):
				errors.append("Quest '%s' unlocks an unknown ability '%s'. Known: %s." % [raw.id, str(capability), ", ".join(PackedStringArray(CAPABILITIES))])
				return
			unlocks.append(capability)
		entry["unlocks"] = unlocks
		entry["focus"] = raw.get("focus", {})
		_index["quest:" + raw.id] = entry
		quests.append(entry)


func _cross_check(errors: Array[String]) -> void:
	for entry: Dictionary in lamps:
		if zone(entry.zone).is_empty():
			errors.append("Lamp '%s' names an unknown zone '%s'." % [entry.id, entry.zone])
	for entry: Dictionary in gates:
		if zone(entry.zone).is_empty():
			errors.append("Gate '%s' names an unknown zone '%s'." % [entry.id, entry.zone])
		elif not in_bounds(entry.cell) or terrain_at(entry.cell) == Terrain.WATER or terrain_at(entry.cell) == Terrain.ROCK:
			errors.append("Gate '%s' needs a walkable cell inside the area." % entry.id)
	for entry: Dictionary in bridges:
		if zone(entry.zone).is_empty():
			errors.append("Bridge '%s' names an unknown zone '%s'." % [entry.id, entry.zone])
	if terrain_at(spawn) == Terrain.WATER or terrain_at(spawn) == Terrain.ROCK:
		errors.append("The spawn cell must be walkable terrain.")
	for entry: Dictionary in quests:
		for required: Variant in entry.requires:
			if quest(str(required)).is_empty():
				errors.append("Quest '%s' requires unknown quest '%s'." % [entry.id, str(required)])
			elif not bool(entry.optional) and bool(quest(str(required)).optional):
				errors.append("Quest '%s' is part of the main arc but requires the optional quest '%s'." % [entry.id, str(required)])
		_check_goal(entry.goal, entry.id, errors)
		var focus: Dictionary = entry.focus
		if not focus.is_empty() and not _point_value(focus.get("at")):
			errors.append("Quest '%s' focus needs at [x, y]." % entry.id)
		var access: Variant = entry.get("access")
		if access != null:
			var valid: bool = access is Dictionary and access.get("kind") in ["device", "zone"] and _id(access.get("id"))
			if valid and access.kind == "device": valid = not lamp(str(access.id)).is_empty()
			if valid and access.kind == "zone": valid = not zone(str(access.id)).is_empty()
			if not valid: errors.append("Quest '%s' access must name a known lamp (device) or zone." % entry.id)


func _check_goal(goal: Dictionary, quest_id: String, errors: Array[String]) -> void:
	match str(goal.get("type", "")):
		"movement_ready":
			if not movement_lesson:
				errors.append("A movement quest needs movement_lesson enabled in its area.")
		"hotaru_greeted":
			if not movement_lesson and not voice_lesson:
				errors.append("A movement quest needs movement_lesson enabled in its area.")
		"inspection_read":
			if not _id(goal.get("id")) or not (interior.get("inspections", []) as Array).any(func(item: Dictionary) -> bool: return item.id == goal.id):
				errors.append("Quest '%s' needs a known room inspection." % quest_id)
		"lamps_lit":
			if goal.has("zone") and zone(str(goal.zone)).is_empty():
				errors.append("Quest '%s' goal names unknown zone '%s'." % [quest_id, str(goal.zone)])
			for lamp_id: Variant in goal.get("ids", []):
				if lamp(str(lamp_id)).is_empty():
					errors.append("Quest '%s' goal names unknown lamp '%s'." % [quest_id, str(lamp_id)])
			if not goal.has("zone") and not goal.has("ids") and not goal.get("all", false):
				errors.append("Quest '%s' lamps_lit goal needs zone, ids or all." % quest_id)
		"bridge_built":
			if bridge(str(goal.get("bridge", ""))).is_empty():
				errors.append("Quest '%s' goal names unknown bridge." % quest_id)
		"gate_open":
			if gate(str(goal.get("gate", ""))).is_empty():
				errors.append("Quest '%s' goal names unknown gate." % quest_id)
		"reach_zone":
			if zone(str(goal.get("zone", ""))).is_empty():
				errors.append("Quest '%s' goal names unknown zone." % quest_id)
		"houses_facing":
			# The houses are not looked up here: the player may take one away in build mode, and the document must
			# still load (the quest then counts only the houses that remain). The shipped ids are checked by tests.
			if not goal.get("ids") is Array or (goal.ids as Array).is_empty() or not (goal.ids as Array).all(func(house_id: Variant) -> bool: return house_id is String):
				errors.append("Quest '%s' houses_facing goal needs a list of house ids." % quest_id)
			if not FACINGS.has(str(goal.get("facing", ""))):
				errors.append("Quest '%s' houses_facing goal needs a facing of N, E, S or W." % quest_id)
		"all":
			if not goal.get("goals") is Array or (goal.goals as Array).is_empty():
				errors.append("Quest '%s' composite goal needs goals." % quest_id)
				return
			for child: Variant in goal.goals:
				if child is Dictionary:
					_check_goal(child, quest_id, errors)
				else:
					errors.append("Quest '%s' composite goal contains a non-object." % quest_id)
		_:
			errors.append("Quest '%s' has an unknown goal type." % quest_id)


static func _joined(value: Variant) -> String:
	if value is Array:
		var lines: PackedStringArray = []
		for line: Variant in value:
			lines.append(str(line))
		return "\n".join(lines)
	return str(value)


func _room_connection_error(room: Dictionary) -> String:
	if not STEPS.has(room.get("exit_direction", "S")): return "A room exit needs a cardinal direction."
	if room.has("walk_front") and (not _number(room.walk_front) or float(room.walk_front) < 0 or float(room.walk_front) >= height): return "Keep the room's walking front inside its height."
	for field: String in ["links", "inspections", "stair_flights", "exit_posts", "lamp_fixtures"]:
		# A hub such as the town square has many more things to look at than a room.
		var bound: int = 64 if field == "inspections" else 24
		if not room.get(field, []) is Array or room.get(field, []).size() > bound: return "Room %s must be a bounded list." % field
	var ids: Array[String] = []
	for link: Variant in room.get("links", []):
		if not link is Dictionary or not _id(link.get("id")) or ids.has(str(link.get("id"))) or not _cell_value(link.get("at")) or not _cell_value(link.get("arrival")) or not _id(link.get("to")) or link.get("to") == id or not STEPS.has(link.get("direction", "")):
			return "A room link needs a unique id, at, arrival, another area id and a direction."
		ids.append(str(link.id))
		if not in_bounds(Vector2i(int(link.at[0]), int(link.at[1]))) or not _cell_value(link.get("approach", link.at)): return "Keep room links and their approaches inside the area."
		var wide: Variant = link.get("cells", [link.at])
		if not wide is Array or wide.is_empty() or wide.size() > 8 or not wide.all(_cell_value) or not wide.any(func(cell: Variant) -> bool: return int(cell[0]) == int(link.at[0]) and int(cell[1]) == int(link.at[1])): return "A wide room link lists 1 to 8 cells, including its own at."
		if not wide.all(func(cell: Variant) -> bool: return in_bounds(Vector2i(int(cell[0]), int(cell[1])))): return "Keep every cell of a room link inside the area."
		if link.has("arrivals") and (not link.arrivals is Array or link.arrivals.size() != wide.size() or not link.arrivals.all(_cell_value)): return "A wide room link's arrivals match its cells one for one."
		if link.has("walk_through") and not link.walk_through is bool: return "A room link's walk_through is true or false."
		if link.has("enter") and (not _whole(link.enter) or int(link.enter) < 0 or int(link.enter) > 4): return "A room link enters 0 to 4 cells past its arrival."
		if link.has("doors") and (not link.doors is String or link.doors != "shell" and not (room.get("assets", []) as Array).any(func(item: Variant) -> bool: return item is Dictionary and item.get("id") == link.doors)): return "A room link's doors must name a placed room asset, or the room's shell."
		var approach: Array = link.get("approach", link.at)
		if not in_bounds(Vector2i(int(approach[0]), int(approach[1]))): return "Keep room link approaches inside the area."
	ids.clear()
	for item: Variant in room.get("inspections", []):
		if not item is Dictionary or not _id(item.get("id")) or not _point_value(item.get("at")) or not item.get("title") is String or not item.get("text") is String or str(item.title).length() > 80 or str(item.text).length() > 1200: return "Room inspections need an id, at, title and bounded text."
		if ids.has(str(item.id)) or float(item.at[0]) < 0 or float(item.at[1]) < 0 or float(item.at[0]) >= width or float(item.at[1]) >= height: return "Room inspections need distinct ids and positions inside the area."
		ids.append(str(item.id))
	ids.clear()
	for fixture: Variant in room.get("lamp_fixtures", []):
		if not fixture is Dictionary or not _id(fixture.get("id")) or ids.has(str(fixture.id)) or not _id(fixture.get("asset")) or not _number(fixture.get("range")) or float(fixture.range) <= 0 or float(fixture.range) > 12 or not _number(fixture.get("energy")) or float(fixture.energy) <= 0 or float(fixture.energy) > 3: return "A lamp fixture needs a unique lamp id, room asset, range and energy."
		if not room.get("assets", []) is Array or not (room.get("assets", []) as Array).any(func(item: Variant) -> bool: return item is Dictionary and item.get("id") == fixture.asset): return "A lamp fixture must use an authored room asset."
		ids.append(str(fixture.id))
	for lamp: Dictionary in lamps:
		if lamp.style == "fixture" and not ids.has(str(lamp.id)): return "Every fixture lamp needs an authored room asset mapping."
	for fixture_id: String in ids:
		if lamp(fixture_id).get("style") != "fixture": return "A room fixture must name a fixture lamp."
	for raw: Variant in room.get("exit_posts", []):
		if not raw is Array or raw.size() != 4 or not raw.all(_number) or float(raw[2]) <= 0 or float(raw[3]) <= 0: return "Exit posts need positive rectangles [x,y,w,h]."
	for flight: Variant in room.get("stair_flights", []):
		if not flight is Dictionary or not flight.get("rect") is Array or flight.rect.size() != 4 or not flight.rect.all(_number) or not STEPS.has(flight.get("up", "")) or not flight.get("treads") is Array or flight.treads.is_empty() or flight.treads.size() > 24: return "A stair flight needs a rectangle, up direction and bounded tread list."
		var raw: Array = flight.rect
		if float(raw[0]) < 0 or float(raw[1]) < 0 or float(raw[2]) <= 0 or float(raw[3]) <= 0 or float(raw[0])+float(raw[2]) > width or float(raw[1])+float(raw[3]) > height: return "Keep stair flights inside the room."
		var previous: float = 0.0
		for tread: Variant in flight.treads:
			if not _number(tread) or float(tread) <= previous or float(tread) > 3.5: return "Stair flight treads must rise from the floor to at most 3.5."
			previous = float(tread)
	for item: Variant in room.get("assets", []):
		if item is Dictionary and item.has("look") and not _look(item.look): return "Room asset %s has a look that is not a seed, a palette name or {seed, palette, plain}." % str(item.get("id", ""))
	var outdoor_error: String = _outdoor_error(room.get("outdoor", {}))
	return outdoor_error if outdoor_error != "" else _life_error(room)


## The street's small motions: chimney smoke, cloth that sways, a tram's round trip, gulls. Positions are map data,
## so they live in the document; nothing here decides where anyone may stand.
static func _life_error(room: Dictionary) -> String:
	var life: Variant = room.get("life", {})
	if not life is Dictionary: return "A room's life block must be an object."
	if life.is_empty(): return ""
	var placed: Array = (room.get("assets", []) as Array).map(func(item: Variant) -> String: return str(item.get("id", "")) if item is Dictionary else "")
	var smoke: Variant = life.get("smoke", [])
	if not smoke is Array or smoke.size() > 8: return "Room smoke must be a list of at most eight chimneys."
	for puff: Variant in smoke:
		if not puff is Dictionary or not _point_value(puff.get("at")) or not _number(puff.get("height")) or float(puff.height) < 0 or float(puff.height) > 16: return "Each chimney needs at [x,y] and a height from 0 to 16."
	var sway: Variant = life.get("sway", [])
	if not sway is Array or not sway.all(func(id: Variant) -> bool: return id is String and placed.has(id)): return "Swaying cloth must name placed room assets."
	var tram: Variant = life.get("tram", {})
	if not tram is Dictionary: return "A room tram must be an object."
	if not tram.is_empty():
		if not placed.has(str(tram.get("asset", ""))): return "A room tram must name a placed room asset."
		for field: String in ["out", "stop", "edge", "fade", "period"]:
			if not _number(tram.get(field)): return "A room tram needs out, stop, edge, fade and period numbers."
		if float(tram.fade) <= 0 or float(tram.period) < 30: return "A room tram needs a positive fade and a period of at least 30 seconds."
		if tram.has("travel") and (not _number(tram.travel) or float(tram.travel) < 3 or float(tram.travel) * 2 + 15 > float(tram.period)): return "A room tram's travel must be at least 3 seconds and leave its round trip inside the period."
	var gulls: Variant = life.get("gulls", {})
	if not gulls is Dictionary: return "Room gulls must be an object."
	if not gulls.is_empty() and (not _point_value(gulls.get("at")) or not _number(gulls.get("height")) or not _whole(gulls.get("count")) or int(gulls.count) < 1 or int(gulls.count) > 6): return "Room gulls need at [x,y], a height and a count from 1 to 6."
	var robots: Variant = life.get("robots", [])
	if not robots is Array or robots.size() > 8: return "Room robots must be a list of at most eight."
	for robot: Variant in robots:
		if not robot is Dictionary or not placed.has(str(robot.get("asset", ""))): return "A robot on its rounds must name a placed room asset."
		var path: Variant = robot.get("path")
		if not path is Array or path.size() < 2 or path.size() > 16 or not path.all(_point_value): return "A robot's round needs a path of 2 to 16 points [x,y]."
		if not _number(robot.get("speed")) or float(robot.speed) <= 0 or float(robot.speed) > 3: return "A robot's round needs a speed above 0 and at most 3."
		if not _number(robot.get("pause", 0)) or float(robot.get("pause", 0)) < 0 or float(robot.get("pause", 0)) > 30: return "A robot's pause must be from 0 to 30 seconds."
	return ""


## An outdoor room's sunlight, sky and painted distance. They are presentation, but a malformed block is refused at
## load so a broken document fails with a sentence instead of drawing a black sky.
static func _outdoor_error(outdoor: Variant) -> String:
	if not outdoor is Dictionary: return "A room's outdoor block must be an object."
	if outdoor.is_empty(): return ""
	var sun: Variant = outdoor.get("sun", {})
	var ambient: Variant = outdoor.get("ambient", {})
	if not sun is Dictionary or not ambient is Dictionary: return "Outdoor sun and ambient must be objects."
	if not sun.get("rotation") is Array or sun.rotation.size() != 3 or not sun.rotation.all(_number): return "The outdoor sun needs a rotation [x, y, z] in degrees."
	for light: Dictionary in [sun, ambient]:
		if not _colour(light.get("color")) or not _number(light.get("energy")) or float(light.energy) < 0 or float(light.energy) > 3: return "Outdoor light needs a hex colour and an energy from 0 to 3."
	if not _colour(outdoor.get("haze")): return "An outdoor room needs a haze colour behind its painted distance."
	if outdoor.has("backdrop") and (not outdoor.backdrop is String or not str(outdoor.backdrop).begins_with("res://assets/") or not str(outdoor.backdrop).ends_with(".png")): return "An outdoor backdrop must be a PNG under res://assets/."
	if outdoor.has("parallax") and (not _number(outdoor.parallax) or float(outdoor.parallax) < 0 or float(outdoor.parallax) > 0.6): return "Outdoor parallax must be from 0 to 0.6."
	return ""


## A placed house's look, checked for shape only: a whole seed, a palette name, or {seed, palette, plain}. Which
## palettes exist is the renderer's business (HouseVariants); an unknown one shows the authored look.
static func _look(value: Variant) -> bool:
	if value is Dictionary:
		var keys: Array = (value as Dictionary).keys()
		return not keys.is_empty() and keys.all(func(key: Variant) -> bool: return key in ["seed", "palette", "plain"]) \
			and (not value.has("seed") or _whole(value.seed) and float(value.seed) >= 0) and (not value.has("palette") or _id(value.palette)) \
			and (not value.has("plain") or value.plain is bool)
	return _whole(value) and float(value) >= 0 or _id(value)


static func _colour(value: Variant) -> bool:
	return value is String and (value as String).length() == 6 and (value as String).is_valid_hex_number()


static func _id(value: Variant) -> bool:
	return value is String and (value as String) != "" and (value as String).length() <= 48 and (value as String).is_valid_filename()


static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and absf(float(value)) < 100000.0


static func _whole(value: Variant) -> bool:
	return _number(value) and float(value) == floorf(float(value))


static func _point_value(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _number(value[0]) and _number(value[1])


static func _cell_value(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _whole(value[0]) and _whole(value[1])


static func _rect_value(value: Variant) -> bool:
	return value is Array and value.size() == 4 and _whole(value[0]) and _whole(value[1]) and _whole(value[2]) and _whole(value[3]) and int(value[2]) > 0 and int(value[3]) > 0
