extends SceneTree
## Runtime Blender assets require neither Blender nor procedural regeneration to load, and the view builds
## any area document: placed buildings, mechanisms, generated terrain, picking and the following camera.

const Geometry := preload("res://pipeline/world_geometry.gd")
const View := preload("res://scenes/world_view.gd")
const SurfaceMaterials := preload("res://art/surface_materials.gd")
var _failures: Array[String] = []
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/world-catalog.json"))
	for id: String in catalog.assets:
		var spec: Dictionary = catalog.assets[id]
		var runtime: String = "res://" + str(spec.runtime)
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(runtime.get_base_dir() + "/manifest.json"))
		_check(FileAccess.get_sha256(runtime) == manifest.runtime_sha256, id + " runtime hash matches")
		_check(MediaLock.sha256(str(spec.source)) == manifest.source_sha256, id + " source is the recorded editable blend")
		var asset: Node3D = Geometry.read_glb(ProjectSettings.globalize_path(runtime))
		_check(asset != null, id + " loads as 3D without Blender")
		if asset != null:
			var audit: Dictionary = Geometry.audit(asset)
			_check(audit.geometry_sha256 == manifest.audit.geometry_sha256, id + " imported geometry matches audited artifact")
			asset.free()
	_textures()
	await _lane_view()
	if _failures.is_empty():
		print("World art, area views and projected facing: %d checks passed." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		quit(1)


## The texture catalog, the painted pictures it names and the materials built from them.
func _textures() -> void:
	var catalog: Dictionary = WorldTextures.catalog()
	var palette: Dictionary = preload("res://art/world_palette.gd").COLORS
	_check((catalog.sets as Dictionary).has(catalog.set), "The catalog's default set exists")
	for set_name: String in catalog.sets:
		var missing: Array[String] = []
		for id: String in catalog.materials:
			var path: String = WorldTextures.path_for(str(WorldTextures.entry(id).texture), set_name)
			if not ResourceLoader.exists(path):
				missing.append(path)
		_check(missing.is_empty(), "Every catalogued picture exists and is imported in the %s set %s" % [set_name, str(missing)])
	var unknown: Array[String] = []
	for id: String in catalog.materials:
		if not palette.has(id) and id != "lit":
			unknown.append(id)
	_check(unknown.is_empty(), "Every catalogued material is a palette colour %s" % str(unknown))
	var in_world: Dictionary = SurfaceMaterials.build(palette)
	var on_part: Dictionary = SurfaceMaterials.build(palette, false)
	var grass: StandardMaterial3D = in_world["grass"]
	_check(grass.albedo_texture != null and grass.uv1_triplanar and grass.uv1_world_triplanar and is_equal_approx(grass.uv1_scale.x, 1.0), "Ground and foliage pictures are pinned to the world, one tile per unit")
	_check(not (on_part["oak"] as StandardMaterial3D).uv1_world_triplanar and (on_part["oak"] as StandardMaterial3D).uv1_triplanar, "Parts that move carry their pictures with them")
	_check((in_world["iron"] as StandardMaterial3D).uv1_scale.x > 1.9, "Fine metal repeats twice a unit")
	_check(not (in_world["window"] as StandardMaterial3D).uv1_triplanar and (in_world["window_glow"] as StandardMaterial3D).emission_enabled, "Glass panes show one picture a face, and a lit window glows")
	_check((in_world["grass_light"] as StandardMaterial3D).albedo_color.r > 1.0 and (in_world["grass_dark"] as StandardMaterial3D).albedo_color.r < 1.0, "Light and dark variants are tints of one picture")


func _lane_view() -> void:
	var area: AreaDef = AreaStore.load_area("haverlund-lane")
	var view := View.new()
	root.add_child(view)
	await process_frame
	view.setup(area)
	await process_frame
	_check(view._lamps.size() == area.lamps.size() and view._lamps.size() > 0, "Every lamp in the document is built")
	var state: Dictionary = LabWorld.new(area).initial_state()
	view.apply_state(state)
	var lit: String = str(area.lamps[0].id)
	state.lamps[lit] = true
	view.apply_state(state)
	_check(view._lit_positions.size() >= 1, "A lit fitting is drawn as a light")
	for logical: Vector2 in {Vector2.RIGHT: "se", Vector2.LEFT: "nw", Vector2.UP: "sw", Vector2.DOWN: "ne"}:
		var expected: String = {Vector2.RIGHT: "se", Vector2.LEFT: "nw", Vector2.UP: "sw", Vector2.DOWN: "ne"}[logical]
		view.set_player_motion(logical)
		_check(str(view._body.animation_name) == "walk_" + expected, "Actual camera projection maps logical " + str(logical) + " to " + expected)
		view.set_player_motion(Vector2.ZERO)
		_check(str(view._body.animation_name) == "idle_" + expected, "Projected idle keeps " + expected)
	# Picking inverts the projection: the cell under a cell's screen position is that cell.
	view.set_camera_mode(View.CameraMode.FIXED)
	view.focus_on(Vector2(area.spawn), true)
	await process_frame
	for cell: Vector2i in [area.spawn, area.spawn + Vector2i(3, 2), area.spawn + Vector2i(-2, 3)]:
		var on_screen: Vector2 = view.camera.unproject_position(Vector3(cell.x, view._deck_height(Vector2(cell)), -cell.y))
		_check(view.pick_cell(on_screen) == cell, "Clicking where %s is drawn picks %s" % [str(cell), str(cell)])
	# The follow camera glides to the player and stays inside the area.
	view.set_camera_mode(View.CameraMode.FOLLOW)
	var far: Dictionary = {"player": [area.spawn.x + 6, area.spawn.y + 4, 0], "lamps": {}, "gates": {}, "bridges": {}}
	view.sync_player(far)
	for _i: int in range(120):
		view._process(0.05)
	_check(view._focus.distance_to(view._clamped_focus(view._player.position)) < 0.25, "The follow camera settles on the player")
	view.sync_player({"player": [0, 0, 0]})
	_check(view._clamped_focus(view._player.position).x >= 0.0 and view._clamped_focus(view._player.position).z <= 0.0, "The camera never leaves the area")
	view.set_view_shift(0.2)
	for _i: int in range(60):
		view._process(0.05)
	_check(absf(view.camera.h_offset) > 0.5, "Opening a side panel shifts the view toward the free half")
	view.set_warmth(1.0)
	for _i: int in range(200):
		view._process(0.05)
	_check(view._warmth > 0.99, "Warmth eases toward its target")
	# The free camera stays where it is panned.
	view.set_camera_mode(View.CameraMode.FREE)
	var start: Vector2 = view.focus_point()
	view.pan_focus(Vector2(5, 0))
	for _i: int in range(60):
		view._process(0.05)
	_check(view.focus_point().x > start.x + 4.0 and absf(view.focus_point().y - start.y) < 0.5, "The free camera glides to where it is panned")
	view.pan_focus(Vector2(500, 500))
	for _i: int in range(60):
		view._process(0.05)
	_check(view.focus_point().x <= float(area.width), "...and never leaves the area")
	view.queue_free()
	await process_frame


func _mesh_count(node: Node) -> int:
	var count: int = 1 if node is MeshInstance3D else 0
	for child: Node in node.get_children():
		count += _mesh_count(child)
	return count


func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
