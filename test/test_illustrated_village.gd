extends SceneTree
## Art variants preserve existing rules/rooms; the new fence has real occupancy.
## Optional argument: gameplay review capture directory.

const Assets := preload("res://art/world_assets.gd")
var checks: int = 0
var failures: Array[String] = []
var output: String = ""
var view: ClearingView


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
	var source: Dictionary = AreaStore.read_source("village-morning")
	var area: AreaDef = AreaStore.load_area("village-morning")
	var rules := LabWorld.new(area)
	var state: Dictionary = rules.initial_state()
	for key: String in ["logical_footprint", "collision_rects", "entrance"]:
		_check(source.assets["painted-cottage"][key] == source.assets["reference-cottage"][key], "The illustrated house retains its exact existing " + key)
	_check(source.assets["painted-oak"].logical_footprint == source.assets["hearth-oak"].logical_footprint, "The new crown keeps the same root/trunk occupancy")
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/source/world/painted-cottage/v1/provenance.json"))
	_check(FileAccess.get_sha256("res://" + str(original.derived_from)) == original.original_sha256, "The earlier cottage source remains intact")
	for id: String in ["painted-cottage", "painted-oak"]:
		var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/source/world/" + id + "/v1/pass-02.json"))
		_check(FileAccess.get_sha256("res://art/source/world/" + id + "/v1/model.pass-01.blend") == record.before_sha256, "The reviewed first source is preserved: " + id)
	_check(not rules.is_walkable(state, Vector2i(14, 18)) and not rules.is_walkable(state, Vector2i(14, 22)), "Both solid fence spans block walking")
	_check(rules.is_walkable(state, Vector2i(14, 20)) and rules.can_step(state, Vector2i(13, 20), Vector2i(14, 20)), "The opening between the fences remains a usable passage")
	_check(not rules.is_walkable(state, Vector2i(2, 24)) and rules.is_walkable(state, Vector2i(3, 25)), "The tree trunk blocks; the decorative leaf crown does not")
	for house: Dictionary in area.buildings:
		_check(not rules.find_path(state, HouseInstances.door(area, house.id)).is_empty(), "The added garden leaves the doorway reachable: " + str(house.id))
	state.player = [7, 10, 0]
	state.memory = {"home": "kept"}
	state.controls = {"W": "north"}
	_check(rules.normalize_state(state).player == state.player and rules.normalize_state(state).memory == state.memory, "An old home-lane position and program memory survive the garden changes")
	# New standalone models also work through the existing studio and save layer.
	var document: Dictionary = source.document.duplicate(true)
	document.buildings = []
	document.trees = []
	document.props = []
	document.lamps = []
	document.terrain = []
	for row: int in range(area.height):
		document.terrain.append(".".repeat(area.width))
	var catalog: Dictionary = AreaStore.read_build_catalog()
	for item: String in ["painted-cottage", "painted-oak", "painted-garden-fence"]:
		var ledger := BuildLedger.new(document, source.assets, source.quests, catalog)
		var before: Dictionary = ledger.rules.initial_state()
		var placed: Dictionary = ledger.place(item, Vector2(20, 15), "E", before)
		_check(placed.ok, "The illustrated asset can be placed and rotated through the studio: " + item)
		if placed.ok:
			var reloaded := BuildLedger.new(document, source.assets, source.quests, catalog, JSON.parse_string(JSON.stringify(ledger.edits)))
			_check(reloaded.edits == ledger.edits and ledger.undo(before).ok and ledger.redo(before).ok, "Placement round-trips through saved edits and Undo/Redo: " + item)
	view = ClearingView.new()
	root.add_child(view)
	await process_frame
	view.setup(area)
	_check(view._presented_asset("reference-cottage") == "painted-cottage" and view._presented_asset("hearth-oak") == "painted-oak", "Morning explicitly selects the illustrated house and oak")
	_check(view._presented_asset("rootward-tree") == "rootward-tree", "The giant Rootward cutaway retains its adopted presentation")
	var preview: Node3D = view._preview_model({"asset": "reference-cottage", "kind": "building"})
	_check(preview.find_child("Drawn*", true, false) != null, "A construction proposal uses the same illustrated house as its eventual placement")
	preview.free()
	var house: Node3D = view.building_node("concept-comparison")
	var hinge := house.find_child("DoorHinge", true, false) as Node3D
	_check(hinge != null and not hinge.find_children("IllustratedOutline", "MeshInstance3D", true, false).is_empty(), "The real door leaf and its ink remain attached to the original hinge")
	view.open_door("concept-comparison")
	for frame: int in range(60):
		await process_frame
		if hinge != null and hinge.rotation.y > .01:
			break
	_check(hinge != null and hinge.rotation.y > .01, "The illustrated leaf still swings through the normal door adapter")
	if hinge != null:
		for tween: Tween in get_processed_tweens():
			tween.kill()
		hinge.rotation.y = 0
	view.set_camera_mode(ClearingView.CameraMode.FIXED)
	state.player = [11, 20, 0]
	state.lamps["home-garden-lamp"] = true
	view.apply_state(state)
	view.set_zoom(13)
	view.camera.size = 13
	view._focus = Vector3(7.8, 2.2, -21)
	view._focus_target = view._focus
	view._place_camera()
	await _shot("village-set")
	# The tree's complete crown is reviewed separately at the same camera scale.
	state.player = [7, 41, 0]
	view.apply_state(state)
	view._focus = Vector3(5.5, 1.6, -41)
	view._focus_target = view._focus
	view._place_camera()
	await _shot("oak-gameplay")
	view.setup(AreaStore.load_area("rune-mill"))
	_check(view._presented_asset("reference-cottage") == "reference-cottage" and view._presented_asset("hearth-oak") == "hearth-oak", "Switching journeys clears both visual substitutions")
	view.queue_free()
	await process_frame
	if failures.is_empty():
		print("Illustrated cottage, oak and fence: %d checks passed." % checks)
	else:
		for failure: String in failures:
			printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)


func _shot(name: String) -> void:
	if output.is_empty() or DisplayServer.get_name() == "headless":
		return
	await create_timer(.6).timeout
	for frame: int in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
