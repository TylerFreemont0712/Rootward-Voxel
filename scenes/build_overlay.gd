class_name BuildOverlay
extends Node3D
## Everything build mode draws over the valley: the ground grid, the placement ghost with its footprint tiles
## and door arrow, and the highlight on whatever the pointer is over. Presentation only: whether a spot is
## allowed is decided by BuildLedger and shown here as green or red. It also answers "what is under the pointer?"
## by casting the camera's ray at the buildings and trees.

const WorldAssets := preload("res://art/world_assets.gd")
const GRID_SHADER: Shader = preload("res://art/build_grid.gdshader")
const OK: Color = Color(0.45, 0.93, 0.52)
const BAD: Color = Color(0.96, 0.4, 0.34)
const MOVE: Color = Color(0.98, 0.78, 0.36)
const LOCKED: Color = Color(0.62, 0.66, 0.72)

var view: ClearingView
var _grid: MeshInstance3D
var _grid_material: ShaderMaterial
var _tiles: Node3D
var _tile_pool: Array[MeshInstance3D] = []
var _tile_material: StandardMaterial3D
var _bad_material: StandardMaterial3D
var _arrow: MeshInstance3D
var _arrow_material: StandardMaterial3D
var _ghost_root: Node3D
var _ghost_models: Dictionary = {}
var _ghost_key: String = ""
var _ghost_tint: StandardMaterial3D
var _ring: MeshInstance3D
var _ring_material: StandardMaterial3D
var _highlight_tint: StandardMaterial3D
var _highlighted: Node3D
var _selection: Node3D
var _selection_material: StandardMaterial3D
var _selection_bars: Array[MeshInstance3D] = []
var _selection_ring: MeshInstance3D
var _highlight_color: Color = MOVE
var _elapsed: float = 0.0
var _shape_root: Node3D
var _shape_pool: Array[MeshInstance3D] = []
var _shape_materials: Dictionary = {}


func setup(clearing_view: ClearingView) -> void:
	view = clearing_view
	name = "BuildOverlay"
	visible = false
	_grid_material = ShaderMaterial.new()
	_grid_material.shader = GRID_SHADER
	_grid = MeshInstance3D.new()
	_grid.name = "Grid"
	_grid.material_override = _grid_material
	_grid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_grid)
	_tile_material = _flat_material(OK, 0.34)
	_bad_material = _flat_material(BAD, 0.42)
	_tiles = Node3D.new()
	_tiles.name = "FootprintTiles"
	add_child(_tiles)
	_arrow_material = _flat_material(Color(1.0, 0.86, 0.5), 0.9)
	_arrow = MeshInstance3D.new()
	_arrow.name = "DoorArrow"
	_arrow.mesh = _arrow_mesh()
	_arrow.material_override = _arrow_material
	_arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arrow.visible = false
	add_child(_arrow)
	_ghost_root = Node3D.new()
	_ghost_root.name = "Ghost"
	_ghost_root.visible = false
	add_child(_ghost_root)
	_ghost_tint = _overlay_material(OK, 0.4)
	_highlight_tint = _overlay_material(MOVE, 0.4)
	_ring_material = _flat_material(MOVE, 0.85)
	_ring = MeshInstance3D.new()
	_ring.name = "TreeRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.78
	torus.outer_radius = 0.92
	torus.rings = 40
	torus.ring_segments = 6
	_ring.mesh = torus
	_ring.material_override = _ring_material
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = false
	add_child(_ring)
	_make_selection()


## Shows or hides the overlay. The grid is sized to the area each time, in case an edit changed nothing but the area did.
func set_active(active: bool) -> void:
	visible = active
	if not active:
		hide_ghost()
		clear_highlight()
		clear_selection()
		clear_shape()
		return
	refresh_grid()


## The grid is one square per cell at that cell's own height, so it lies on the terraces and the valley floor alike.
## Called again whenever the land is shaped.
func refresh_grid() -> void:
	var vertices := PackedVector3Array()
	for y: int in range(view.area.height):
		for x: int in range(view.area.width):
			var a := Vector3(x - 0.5, view.ground_y(Vector2(x, y)) + 0.045, -y + 0.5)
			vertices.append_array(PackedVector3Array([a, a + Vector3(1, 0, -1), a + Vector3(1, 0, 0), a, a + Vector3(0, 0, -1), a + Vector3(1, 0, -1)]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_grid.mesh = mesh
	_grid.position = Vector3.ZERO


## Where the pointer is on the ground (a logical point), so the grid lights up around it.
func set_cursor(point: Vector2) -> void:
	_grid_material.set_shader_parameter("cursor", Vector2(point.x, -point.y))


func set_paint_grid(painting: bool) -> void:
	_grid_material.set_shader_parameter("cell_scale", 2.0 if painting else 1.0)


func show_brush(cells: Array[Vector2i], color: Color) -> void:
	_show_tiles(cells, color)
	for index: int in range(cells.size()):
		var sub: Vector2i = cells[index]
		var tile: MeshInstance3D = _tile_pool[index]
		tile.position = Vector3(float(sub.x) * 0.5 - 0.25, view.ground_y(Vector2(float(sub.x) * 0.5 - 0.25, float(sub.y) * 0.5 - 0.25)) + 0.065, -float(sub.y) * 0.5 + 0.25)
		tile.scale = Vector3(0.5, 1, 0.5)
		tile.material_override = _tile_material if GroundPaint.is_ground(view.area, sub) else _bad_material


# ------------------------------------------------------------------ the ghost
## Draws what is about to be placed. `spec`: {kind: "building"|"prop"|"tree", asset, size, at: Vector2, facing,
## valid, cells: Array[Vector2i], door: Vector2i}. Buildings show their footprint tiles and a door arrow; props
## show their footprint tiles only.
func show_ghost(spec: Dictionary) -> void:
	var valid: bool = bool(spec.get("valid", false))
	var color: Color = OK if valid else BAD
	var at: Vector2 = spec.at
	var key: String = "%s|%s" % [spec.kind, str(spec.get("asset", spec.get("size", 1.0)))]
	if key != _ghost_key:
		for child: Node in _ghost_root.get_children():
			_ghost_root.remove_child(child)
		var model: Node3D = _ghost_model(spec, key)
		if model != null:
			_ghost_root.add_child(model)
		_ghost_key = key
	_ghost_root.visible = _ghost_root.get_child_count() > 0
	_ghost_root.position = Vector3(at.x, view.ground_y(at), -at.y)
	_ghost_root.rotation_degrees.y = float(AreaDef.FACINGS[spec.get("facing", "S")]) if spec.kind in ["building", "prop", "stairs"] else 0.0
	_ghost_tint.albedo_color = Color(color, 0.4)
	if spec.kind == "building":
		_show_tiles(spec.get("cells", []), color)
		_show_arrow(spec.get("door", Vector2i(-1, -1)), str(spec.get("facing", "S")), valid)
	elif spec.kind == "prop":
		_show_tiles(spec.get("cells", []), color)
		_arrow.visible = false
	elif spec.kind == "stairs":
		_show_tiles([], color)
		var top: Vector2i = Vector2i(at.round()) + (AreaDef.STEPS[spec.facing] as Vector2i)
		_show_arrow(top if view.area.in_bounds(top) else Vector2i(-1, -1), str(spec.facing), valid)
	else:
		_show_tiles([], color)
		_arrow.visible = false
		_show_ring(at, color, 0.85 * float(spec.get("size", 1.0)))


func hide_ghost() -> void:
	_ghost_root.visible = false
	_arrow.visible = false
	_show_tiles([], OK)
	if _highlighted == null:
		_ring.visible = false


func _ghost_model(spec: Dictionary, key: String) -> Node3D:
	if _ghost_models.has(key):
		return _ghost_models[key]
	var model: Node3D
	if spec.kind == "stairs":
		var flight := MeshInstance3D.new()
		flight.mesh = _stairs_mesh()
		flight.material_override = _ghost_tint
		flight.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		model = flight
	elif spec.get("asset", "") != "":
		model = WorldAssets.instantiate(str(spec.asset))
		if model != null:
			if spec.kind == "tree":
				model.scale = Vector3.ONE * float(spec.get("size", 1.0))
			_mark(model, _ghost_tint)
	else:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = view.build_tree_mesh(float(spec.get("size", 1.0)), 7)
		mesh_instance.material_overlay = _ghost_tint
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		model = mesh_instance
	_ghost_models[key] = model
	return model


## A flight of stairs climbing toward local +z (the way a south-facing thing faces), as one mesh for the ghost.
func _stairs_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE
	TerrainBuilder.flight(Vector2i(0, -1), func(at: Vector3, size: Vector3, _material: String, _rotation: Vector3 = Vector3.ZERO) -> void:
		tool.append_from(cube, 0, Transform3D(Basis.from_scale(size), at)))
	return tool.commit()


# ------------------------------------------------------------- shaping land
## The cells a land tool's brush is over, each green where it would change and red where it would not.
func show_land_brush(cells: Array[Vector2i], fits: Array[bool]) -> void:
	_show_tiles(cells, OK)
	for index: int in range(cells.size()):
		if not fits[index]:
			_tile_pool[index].material_override = _bad_material


## The proposal of a land stroke before it is let go: for each cell, the earth it adds (raise, green), the earth it
## takes away (lower, amber), the water it lets in (blue) or the earth that fills it (brown), at its real height.
func show_shape(cells: Array, tool: String, level: int) -> void:
	if _shape_root == null:
		_shape_root = Node3D.new()
		_shape_root.name = "LandProposal"
		add_child(_shape_root)
		_shape_materials = {"raise": _flat_material(OK, 0.42), "lower": _flat_material(MOVE, 0.42), "water": _flat_material(Color(0.36, 0.72, 0.96), 0.6), "land": _flat_material(Color(0.62, 0.48, 0.3), 0.55)}
	while _shape_pool.size() < cells.size():
		var box := MeshInstance3D.new()
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE
		box.mesh = cube
		box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_shape_root.add_child(box)
		_shape_pool.append(box)
	var rise: float = TerrainBuilder.LEVEL_RISE
	for index: int in range(_shape_pool.size()):
		var box: MeshInstance3D = _shape_pool[index]
		box.visible = index < cells.size()
		if not box.visible:
			continue
		var cell: Vector2i = cells[index]
		var ground: float = float(view.area.level_at(cell)) * rise
		var span := Vector2(ground, float(level) * rise)
		match tool:
			"lower":
				span = Vector2(float(level) * rise, ground)
			"water":
				span = Vector2(ground + 0.01, ground + 0.08)
			"land":
				span = Vector2(ground - 0.3, ground + 0.04)
		box.material_override = _shape_materials.get(tool, _tile_material)
		box.position = Vector3(cell.x, (span.x + span.y) * 0.5 + 0.01, -cell.y)
		box.scale = Vector3(0.98, maxf(0.02, span.y - span.x), 0.98)


func clear_shape() -> void:
	for box: MeshInstance3D in _shape_pool:
		box.visible = false


## Tints every mesh under `node` with a translucent overlay and stops it casting shadows.
func _mark(node: Node, tint: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_overlay = tint
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_mark(child, tint)


func _show_tiles(cells: Array, color: Color) -> void:
	while _tile_pool.size() < cells.size():
		var tile := MeshInstance3D.new()
		var quad := BoxMesh.new()
		quad.size = Vector3(0.92, 0.02, 0.92)
		tile.mesh = quad
		tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_tiles.add_child(tile)
		_tile_pool.append(tile)
	_tile_material.albedo_color = Color(color, 0.34)
	for index: int in range(_tile_pool.size()):
		var tile: MeshInstance3D = _tile_pool[index]
		tile.visible = index < cells.size()
		if tile.visible:
			tile.scale = Vector3.ONE
			var cell: Vector2i = cells[index]
			tile.position = Vector3(cell.x, view.ground_y(Vector2(cell)) + 0.06, -cell.y)
			tile.material_override = _tile_material


func _show_arrow(door: Vector2i, facing: String, valid: bool) -> void:
	_arrow.visible = door.x >= 0
	if door.x < 0:
		return
	_arrow.position = Vector3(door.x, view.ground_y(Vector2(door)) + 0.075, -door.y)
	_arrow.rotation_degrees.y = float(AreaDef.FACINGS[facing])
	_arrow_material.albedo_color = Color(1.0, 0.86, 0.5, 0.9) if valid else Color(BAD, 0.9)


func _show_ring(at: Vector2, color: Color, radius: float) -> void:
	_ring.visible = true
	_ring.position = Vector3(at.x, view.ground_y(at) + 0.08, -at.y)
	_ring.scale = Vector3(radius, 1.0, radius)
	_ring_material.albedo_color = Color(color, 0.85)


# ------------------------------------------------------------- the selection
## The marker on what the Move tool has chosen: a brass frame round a building or doodad, a ring round a tree or
## lamp. It stays while the pointer wanders and pulses gently. `object` is what pick_object returned.
func show_selection(object: Dictionary) -> void:
	clear_selection()
	if object.is_empty():
		return
	_selection.visible = true
	if object.kind == "building" or object.kind == "prop":
		var body: Dictionary = view.area.building(str(object.id)) if object.kind == "building" else view.area.prop(str(object.id))
		if body.is_empty():
			clear_selection()
			return
		var rect: Rect2 = (body.rect as Rect2).grow(0.3)
		var bars: Array = [
			[Vector3(rect.position.x + rect.size.x * 0.5, 0.0, -rect.position.y), Vector3(rect.size.x + 0.14, 0.1, 0.14)],
			[Vector3(rect.position.x + rect.size.x * 0.5, 0.0, -rect.end.y), Vector3(rect.size.x + 0.14, 0.1, 0.14)],
			[Vector3(rect.position.x, 0.0, -(rect.position.y + rect.size.y * 0.5)), Vector3(0.14, 0.1, rect.size.y + 0.14)],
			[Vector3(rect.end.x, 0.0, -(rect.position.y + rect.size.y * 0.5)), Vector3(0.14, 0.1, rect.size.y + 0.14)],
		]
		for index: int in range(4):
			_selection_bars[index].visible = true
			_selection_bars[index].position = (bars[index][0] as Vector3) + Vector3(0, view.ground_y(body.at) + 0.12, 0)
			(_selection_bars[index].mesh as BoxMesh).size = bars[index][1]
	else:
		var at: Vector2 = object.at
		_selection_ring.visible = true
		_selection_ring.position = Vector3(at.x, view.ground_y(at) + 0.1, -at.y)
		var radius: float = 0.85 * float(object.get("size", 1.0))
		_selection_ring.scale = Vector3(radius, 1.0, radius)


func clear_selection() -> void:
	_selection.visible = false
	for bar: MeshInstance3D in _selection_bars:
		bar.visible = false
	_selection_ring.visible = false


func _make_selection() -> void:
	_selection = Node3D.new()
	_selection.name = "Selection"
	_selection.visible = false
	add_child(_selection)
	_selection_material = _flat_material(Pal.BRASS_HI, 0.95)
	for index: int in range(4):
		var bar := MeshInstance3D.new()
		bar.mesh = BoxMesh.new()
		bar.material_override = _selection_material
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bar.visible = false
		_selection.add_child(bar)
		_selection_bars.append(bar)
	_selection_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.82
	torus.outer_radius = 0.92
	torus.rings = 40
	torus.ring_segments = 6
	_selection_ring.mesh = torus
	_selection_ring.material_override = _selection_material
	_selection_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_selection_ring.visible = false
	_selection.add_child(_selection_ring)


# ---------------------------------------------------------------- the hover
## Marks what the pointer is over: `mode` "move" (amber), "delete" (red) or "locked" (grey). `object` is what
## AreaBuild.object_near or pick_object returned; {} clears it.
func highlight(object: Dictionary, mode: String) -> void:
	clear_highlight()
	if object.is_empty():
		return
	_highlight_color = {"move": MOVE, "delete": BAD, "locked": LOCKED}.get(mode, MOVE)
	_highlight_tint.albedo_color = Color(_highlight_color, 0.4)
	if object.kind == "building" or object.kind == "prop":
		_highlighted = view.building_node(str(object.id))
		if _highlighted != null:
			_mark_highlight(_highlighted, _highlight_tint)
		var building: Dictionary = view.area.building(str(object.id)) if object.kind == "building" else view.area.prop(str(object.id))
		if not building.is_empty():
			_show_tiles(AreaBuild.footprint_cells(building.rect), _highlight_color)
	else:
		_show_ring(object.at, _highlight_color, 0.85 * float(object.get("size", 1.0)))


func clear_highlight() -> void:
	if _highlighted != null and is_instance_valid(_highlighted):
		_mark_highlight(_highlighted, null)
	_highlighted = null
	if not _ghost_root.visible:
		_ring.visible = false
		_show_tiles([], OK)


func _mark_highlight(node: Node, tint: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_overlay = tint
	for child: Node in node.get_children():
		_mark_highlight(child, tint)


## Ghost models that are not on show are kept for reuse but are not in the tree, so nothing else would free them.
func _exit_tree() -> void:
	for model: Variant in _ghost_models.values():
		if model is Node and is_instance_valid(model) and not (model as Node).is_inside_tree():
			(model as Node).free()
	_ghost_models.clear()


func _process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	var pulse: float = 0.5 + 0.5 * sin(_elapsed * 5.0)
	if _selection.visible:
		_selection_material.albedo_color = Color(Pal.BRASS_HI, 0.6 + 0.35 * pulse)
	if _highlighted != null:
		_highlight_tint.albedo_color = Color(_highlight_color, 0.26 + 0.2 * pulse)
	if _ring.visible and not _ghost_root.visible:
		_ring_material.albedo_color = Color(_highlight_color, 0.55 + 0.4 * pulse)


# -------------------------------------------------------------------- picking
## The ground point under a viewport position, as a logical point, or null if the ray misses the ground.
func ground_point(viewport_position: Vector2) -> Variant:
	return view.pick_point(viewport_position)


## The building or tree whose body the camera's ray reaches first, or {}. A building's body is its footprint,
## grown a little for the eaves, up to the top of its model, so pointing at a roof picks the house but the
## overhang of one house does not swallow its neighbour. Every body starts at the height of the ground it stands
## on. Stairs are picked only when `stairs` is set (the Delete tool takes them away; nothing moves them).
func pick_object(viewport_position: Vector2, stairs: bool = false) -> Dictionary:
	var origin: Vector3 = view.camera.project_ray_origin(viewport_position)
	var direction: Vector3 = view.camera.project_ray_normal(viewport_position)
	var best: Dictionary = {}
	var best_distance: float = INF
	for building: Dictionary in view.area.buildings:
		var node: Node3D = view.building_node(building.id)
		if node == null:
			continue
		var rect: Rect2 = (building.rect as Rect2).grow(0.3)
		var base: float = view.ground_y(building.at)
		var top: float = world_aabb(node).end.y
		var body := AABB(Vector3(rect.position.x, base, -rect.end.y), Vector3(rect.size.x, top - base, rect.size.y))
		var hit: Variant = body.intersects_ray(origin, direction)
		if hit != null and origin.distance_to(hit) < best_distance:
			best_distance = origin.distance_to(hit)
			best = {"kind": "building", "id": building.id, "locked": building.locked, "at": building.at}
	# A prop's body is its model: its footprint, grown a little so a small thing is easy to point at.
	for prop: Dictionary in view.area.props:
		var node: Node3D = view.building_node(prop.id)
		if node == null:
			continue
		var rect: Rect2 = (prop.rect as Rect2).grow(0.15)
		var base: float = view.ground_y(prop.at)
		var top: float = world_aabb(node).end.y
		var body := AABB(Vector3(rect.position.x, base, -rect.end.y), Vector3(rect.size.x, top - base, rect.size.y))
		var hit: Variant = body.intersects_ray(origin, direction)
		if hit != null and origin.distance_to(hit) < best_distance:
			best_distance = origin.distance_to(hit)
			best = {"kind": "prop", "id": prop.id, "locked": false, "at": prop.at}
	# Lamps, gates and bridge decks are part of the lessons (they cannot be moved), but they are the things a
	# program can reach, so they can be chosen to see their code.
	for lamp: Dictionary in view.area.lamps:
		var at: Vector2 = lamp.at
		var beacon: bool = str(lamp.get("style", "")) == "beacon"
		var half: float = 0.6 if beacon else 0.34
		var body := AABB(Vector3(at.x - half, view.ground_y(at), -at.y - half), Vector3(half * 2.0, 4.0 if beacon else 2.3, half * 2.0))
		var hit: Variant = body.intersects_ray(origin, direction)
		if hit != null and origin.distance_to(hit) < best_distance:
			best_distance = origin.distance_to(hit)
			best = {"kind": "lamp", "id": lamp.id, "locked": true, "at": at, "size": 0.5}
	for gate: Dictionary in view.area.gates:
		var cell: Vector2i = gate.cell
		var body := AABB(Vector3(cell.x - 0.5, view.ground_y(Vector2(cell)), -cell.y - 0.5), Vector3(1.0, 1.7, 1.0))
		var hit: Variant = body.intersects_ray(origin, direction)
		if hit != null and origin.distance_to(hit) < best_distance:
			best_distance = origin.distance_to(hit)
			best = {"kind": "gate", "id": gate.id, "locked": true, "at": Vector2(cell), "size": 0.6}
	for bridge: Dictionary in view.area.bridges:
		for socket: Vector2i in bridge.sockets:
			var body := AABB(Vector3(socket.x - 0.5, view.ground_y(Vector2(socket)), -socket.y - 0.5), Vector3(1.0, 0.7, 1.0))
			var hit: Variant = body.intersects_ray(origin, direction)
			if hit != null and origin.distance_to(hit) < best_distance:
				best_distance = origin.distance_to(hit)
				best = {"kind": "bridge", "id": bridge.id, "locked": true, "at": Vector2(socket), "size": 0.6}
	for tree: Dictionary in view.area.trees:
		var at: Vector2 = tree.at
		var size: float = float(tree.size)
		var box := AABB(Vector3(at.x - 0.7 * size, view.ground_y(at), -at.y - 0.7 * size), Vector3(1.4 * size, 3.2 * size, 1.4 * size))
		var hit: Variant = box.intersects_ray(origin, direction)
		if hit != null and origin.distance_to(hit) < best_distance:
			best_distance = origin.distance_to(hit)
			best = {"kind": "tree", "at": at, "size": size, "asset": tree.get("asset", ""), "locked": false}
	if stairs:
		for flight: Dictionary in view.area.stairs:
			var cell: Vector2i = flight.at
			var body := AABB(Vector3(cell.x - 0.5, float(flight.level) * TerrainBuilder.LEVEL_RISE - 0.2, -cell.y - 0.5), Vector3(1.0, TerrainBuilder.LEVEL_RISE + 0.3, 1.0))
			var hit: Variant = body.intersects_ray(origin, direction)
			if hit != null and origin.distance_to(hit) < best_distance:
				best_distance = origin.distance_to(hit)
				best = {"kind": "stairs", "at": Vector2(cell), "cell": cell, "up": flight.up, "locked": false, "size": 0.62}
	return best


## The box that holds every mesh under a node, in world space.
static func world_aabb(node: Node3D) -> AABB:
	var box := AABB()
	var started: bool = false
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is MeshInstance3D and (current as MeshInstance3D).mesh != null:
			var part: AABB = (current as MeshInstance3D).global_transform * (current as MeshInstance3D).mesh.get_aabb()
			box = part if not started else box.merge(part)
			started = true
		stack.append_array(current.get_children())
	return box


# ------------------------------------------------------------------- plumbing
func _flat_material(color: Color, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color, alpha)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _overlay_material(color: Color, alpha: float) -> StandardMaterial3D:
	var material := _flat_material(color, alpha)
	material.cull_mode = BaseMaterial3D.CULL_BACK
	return material


## A flat arrow lying on the ground that points along local +Z: out through the door.
func _arrow_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shape: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.34), Vector3(-0.3, 0.0, -0.02), Vector3(-0.12, 0.0, -0.02), Vector3(-0.12, 0.0, -0.3),
		Vector3(0.12, 0.0, -0.3), Vector3(0.12, 0.0, -0.02), Vector3(0.3, 0.0, -0.02),
	]
	var order: Array[int] = [0, 2, 1, 0, 5, 2, 0, 6, 5, 2, 3, 4, 2, 4, 5]
	tool.set_normal(Vector3.UP)
	for index: int in order:
		tool.add_vertex(shape[index])
	return tool.commit()
