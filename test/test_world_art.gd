extends SceneTree
## Runtime Blender assets require neither Blender nor procedural regeneration to load, and the view builds
## any area document: placed buildings, mechanisms, generated terrain, picking and the following camera.

const Geometry := preload("res://pipeline/world_geometry.gd")
const View := preload("res://scenes/clearing_view.gd")
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
		_check(FileAccess.get_sha256("res://" + str(spec.source)) == manifest.source_sha256, id + " source is the recorded editable blend")
		var asset: Node3D = Geometry.read_glb(ProjectSettings.globalize_path(runtime))
		_check(asset != null, id + " loads as 3D without Blender")
		if asset != null:
			var audit: Dictionary = Geometry.audit(asset)
			_check(audit.geometry_sha256 == manifest.audit.geometry_sha256, id + " imported geometry matches audited artifact")
			asset.free()
	_textures()
	await _rune_mill()
	await _hollow()
	await _edits()
	if _failures.is_empty():
		print("World art, area views and projected facing: %d checks passed." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		quit(1)


## The player's edits reach the picture by touching only what changed.
func _edits() -> void:
	var source: Dictionary = AreaStore.read_source("kindle-hollow")
	var ledger := BuildLedger.new(source.document, source.assets, source.quests, AreaStore.read_build_catalog())
	var state: Dictionary = ledger.rules.initial_state()
	var view := View.new()
	root.add_child(view)
	await process_frame
	view.setup(ledger.area)
	await process_frame
	var trees: int = ledger.area.trees.size()
	_check(view._drawn_trees.size() == trees and view._tree_root.get_child_count() > 20, "Trees are drawn in chunks under their own node (%d nodes)" % view._tree_root.get_child_count())
	var before: Dictionary = {}
	for chunk: Vector2i in view._tree_nodes:
		before[chunk] = (view._tree_nodes[chunk] as Array)[0].get_instance_id() if not (view._tree_nodes[chunk] as Array).is_empty() else 0
	var house_at := Vector2(34, 4)
	_check(ledger.place("house-hollow", house_at, "S", state).ok, "The ledger takes a house")
	view.sync_edits(ledger.area, false)
	var node: Node3D = view.building_node("build-1")
	_check(node != null and node.get_parent() == view.get_node("Area_kindle_hollow") and node.position.is_equal_approx(Vector3(34, 0, -4)), "A placed house appears where it was put")
	var oak: Vector2 = Vector2(36.5, 9.5)
	for attempt: int in range(40):
		if ledger.check_item("tree-oak", oak, "S", state).ok:
			break
		oak += Vector2(0.5, 0.0)
	_check(ledger.place("tree-oak", oak, "S", state).ok, "The ledger takes an oak")
	view.sync_edits(ledger.area, false)
	var redrawn: int = 0
	for chunk: Vector2i in before:
		var nodes: Array = view._tree_nodes[chunk]
		if before[chunk] != 0 and (nodes.is_empty() or nodes[0].get_instance_id() != before[chunk]):
			redrawn += 1
	_check(view._drawn_trees.size() == trees + 1 and redrawn <= 1, "A new tree redraws only its own chunk (%d redrawn)" % redrawn)
	var moved_to := Vector2(-1, -1)
	for x: int in range(31, 38):
		if moved_to.x < 0.0 and ledger.check_move_building("build-1", Vector2(x, 5), "E", state).ok:
			moved_to = Vector2(x, 5)
	_check(moved_to.x > 0.0 and ledger.move_building("build-1", moved_to, "E", state).ok, "The house moves and turns")
	view.sync_edits(ledger.area, false)
	_check(view.building_node("build-1").position.is_equal_approx(Vector3(moved_to.x, 0, -moved_to.y)) and is_equal_approx(view.building_node("build-1").rotation_degrees.y, 90.0), "...and the picture follows")
	ledger.undo(state)
	ledger.undo(state)
	ledger.undo(state)
	view.sync_edits(ledger.area, false)
	_check(view.building_node("build-1") == null and view._drawn_trees.size() == trees, "Undoing everything takes them out of the picture again")
	# A ghost or a thumbnail is one merged mesh.
	var crown: ArrayMesh = view.build_tree_mesh(1.0, 3)
	_check(crown.get_surface_count() >= 3 and crown.get_aabb().size.y > 2.5 and crown.get_aabb().size.y < 4.5, "A tree can be made as one mesh with a trunk and leaf surfaces")
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
	_check(view.focus_point().x <= float(ledger.area.width), "...and never leaves the valley")
	view.queue_free()
	await process_frame


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


func _rune_mill() -> void:
	var area: AreaDef = AreaStore.load_area("rune-mill")
	var view := View.new()
	root.add_child(view)
	await process_frame
	view.setup(area)
	await process_frame
	_check(view.get_node_or_null("Area_rune_mill/cottage") != null and view.get_node_or_null("Area_rune_mill/mill_house") != null, "Rune Mill uses the Blender house instances")
	_check(view.get_node_or_null("Area_rune_mill/workshop") != null, "The workshop is a second, scaled placement of the cottage asset")
	_check(view.get_node_or_null("Area_rune_mill/clearing_ground") != null, "Rune Mill uses the editable Blender land")
	_check(view._decks.size() == 3 and view._gates.size() == 1 and view._lamps.size() == 3 and view._wheels.size() == 1, "Mechanisms come from the document: three decks, a gate, three lamps and the wheel")
	var rules := LabWorld.new(area)
	var state: Dictionary = rules.initial_state()
	view.apply_state(state)
	var hidden: bool = true
	for deck: Node3D in view._decks.values():
		hidden = hidden and not deck.visible
	_check(hidden, "No deck is drawn before it is built")
	state.bridges.bridge = 2
	state.lamps["lamp-west"] = true
	state.gates.gate = true
	view.apply_state(state)
	var visible_decks: int = 0
	for deck: Node3D in view._decks.values():
		visible_decks += 1 if deck.visible else 0
	_check(visible_decks == 2, "Built decks become visible in socket order")
	_check(not view._gates["gate"].rotation.y == 0.0, "An open gate swings")
	_check((view._lamps["lamp-west"].get_node("Halo") as Node3D).visible and not (view._lamps["lamp-mill"].get_node("Halo") as Node3D).visible, "Only lit lamps glow")
	# Post lamps are the adopted Blender lamppost: its lantern glass is its own material, found and lit through metadata.
	var west: Node3D = view._lamps["lamp-west"]
	var dark: Node3D = view._lamps["lamp-mill"]
	var west_glass: MeshInstance3D = west.get_meta("glass")
	_check(west_glass.mesh.surface_get_material(0).resource_name == "lamp_glass", "A post lamp's lantern is the lamppost model's lamp_glass mesh")
	_check(west_glass.material_override != null and (dark.get_meta("glass") as MeshInstance3D).material_override == null, "A lit lamp swaps its glass for the lit material; a dark one keeps the model's own")
	var halo := west.get_node("Halo") as Node3D
	_check((west_glass.global_transform * west_glass.get_aabb().get_center()).distance_to(halo.global_position) < 0.01 and halo.position.y > 0.5, "The halo and light hang at the lantern glass, wherever the model puts it")
	var proposed: Dictionary = state.duplicate(true)
	proposed.bridges.bridge = 3
	view.apply_state(proposed, true)
	_check(view._ghost.get_child_count() == 1, "A proposed deck is drawn as one translucent ghost")
	view.apply_state(state)
	_check(view._ghost.get_child_count() == 0, "Committing clears the ghosts")
	for logical: Vector2 in {Vector2.RIGHT: "se", Vector2.LEFT: "nw", Vector2.UP: "sw", Vector2.DOWN: "ne"}:
		var expected: String = {Vector2.RIGHT: "se", Vector2.LEFT: "nw", Vector2.UP: "sw", Vector2.DOWN: "ne"}[logical]
		view.set_player_motion(logical)
		_check(str(view._body.animation_name) == "walk_" + expected, "Actual camera projection maps logical " + str(logical) + " to " + expected)
		view.set_player_motion(Vector2.ZERO)
		_check(str(view._body.animation_name) == "idle_" + expected, "Projected idle keeps " + expected)
	view.queue_free()
	await process_frame


func _hollow() -> void:
	var area: AreaDef = AreaStore.load_area("kindle-hollow")
	var view := View.new()
	root.add_child(view)
	await process_frame
	view.setup(area)
	await process_frame
	var content: Node = view.get_node("Area_kindle_hollow")
	_check(view.get_node_or_null("Area_kindle_hollow/clearing_ground") == null, "Kindle Hollow's land is generated from its document, not the old clearing model")
	for building: Dictionary in area.buildings:
		_check(content.get_node_or_null(String(building.id).replace("-", "_")) != null, "Building %s is placed" % building.id)
	_check(view._lamps.size() == area.lamps.size() and view._gates.size() == 1 and view._decks.size() == 4, "The valley builds every lamp, the gate and four bridge decks")
	var cabins: int = 0
	for building: Dictionary in area.buildings:
		if building.asset == "log-cabin":
			cabins += 1
			_check(_mesh_count(content.get_node(String(building.id).replace("-", "_"))) >= 8, "%s is the log cabin model, with its roof, walls, masonry and glass meshes" % building.id)
	_check(cabins >= 1, "Kindle Hollow places the adopted log cabin")
	var houses: int = 0
	for building: Dictionary in area.buildings:
		if building.asset.begins_with("log-cabin-large"):
			houses += 1
			var rect: Rect2 = building.rect
			_check(rect.size.x >= 4.6 and rect.size.y >= 4.6, "%s is a five-cell house" % building.id)
	_check(houses >= 4, "Kindle Hollow's homes are the large houses (%d)" % houses)
	var lanterns: int = 0
	for lamp: Node3D in view._lamps.values():
		lanterns += 1 if lamp.has_meta("glass") else 0
	_check(lanterns == view._lamps.size(), "Every lamp, post or beacon, can be lit")
	var chunks: int = 0
	for child: Node in content.get_children():
		chunks += 1 if child is MultiMeshInstance3D else 0
	_check(chunks > 40, "Terrain and trees are batched into chunked MultiMeshes (%d)" % chunks)
	var flat_shadows: bool = true
	for child: Node in content.get_children():
		if child is MultiMeshInstance3D and child.name.begins_with("Blocks_grass_") and (child as MultiMeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			flat_shadows = false
	_check(flat_shadows, "Flat ground does not spend time in the shadow pass")
	# Picking inverts the projection: the cell under a cell's screen position is that cell.
	view.set_camera_mode(View.CameraMode.FIXED)
	view.focus_on(Vector2(29, 19), true)
	await process_frame
	for cell: Vector2i in [Vector2i(29, 19), Vector2i(25, 21), Vector2i(34, 15)]:
		var on_screen: Vector2 = view.camera.unproject_position(Vector3(cell.x, 0, -cell.y))
		_check(view.pick_cell(on_screen) == cell, "Clicking where %s is drawn picks %s" % [str(cell), str(cell)])
	# The follow camera glides to the player and stays inside the valley.
	view.set_camera_mode(View.CameraMode.FOLLOW)
	var far := {"player": [50, 40, 0], "lamps": {}, "gates": {}, "bridges": {}}
	view.sync_player(far)
	for _i: int in range(120):
		view._process(0.05)
	_check(view._focus.distance_to(view._clamped_focus(view._player.position)) < 0.25, "The follow camera settles on the player")
	view.sync_player({"player": [0, 0, 0]})
	_check(view._clamped_focus(view._player.position).x >= 5.0 and view._clamped_focus(view._player.position).z <= -5.0, "The camera never frames the very edge of the valley")
	view.set_view_shift(0.2)
	for _i: int in range(60):
		view._process(0.05)
	_check(absf(view.camera.h_offset) > 0.5, "Opening the notebook shifts the view toward the free half")
	view.set_warmth(1.0)
	for _i: int in range(200):
		view._process(0.05)
	_check(view._warmth > 0.99, "Warmth eases toward its target")
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
