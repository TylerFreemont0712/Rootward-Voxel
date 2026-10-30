extends SceneTree
## Rendering selection, source isolation and the existing proposal/undo contract.
## Optional argument: directory for gameplay-scale review images.

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
	var earlier: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/lamppost/manifest.json"))
	_check(FileAccess.get_sha256("res://" + str(earlier.source)) == earlier.source_sha256 and FileAccess.get_sha256("res://" + str(earlier.runtime)) == earlier.runtime_sha256, "The original adopted lamp and export remain intact")
	_check(Assets.area_presentation("kindle-hollow").is_empty(), "The earlier journey retains its selected art")
	_check(Assets.area_presentation("village-morning").post_lamp == "square-lamppost", "The morning presentation explicitly selects its own post lamp")
	# A hull belongs to its instance, follows transforms and casts no dark halo.
	var first := MeshInstance3D.new()
	first.mesh = BoxMesh.new()
	var material := StandardMaterial3D.new()
	first.material_override = material
	root.add_child(first)
	var source_mesh: Mesh = first.mesh
	IllustratedEdges.apply(first)
	var outline := first.get_node("IllustratedOutline") as MeshInstance3D
	_check(first.mesh == source_mesh and first.material_override == material, "Adding ink leaves the original surface and material untouched")
	_check(outline.mesh.get_surface_count() == 1 and outline.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "The joined-corner hull is renderable and cannot cast a shadow")
	var hull_arrays: Array = outline.mesh.surface_get_arrays(0)
	_check((hull_arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array).size() == (hull_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), "The rendering hull also remains valid for the existing geometry audit")
	first.position = Vector3(2, 1, 3)
	first.rotation.y = 0.7
	_check(outline.global_transform.is_equal_approx(first.global_transform), "Ink follows a moving or hinged object's own transform")
	IllustratedEdges.apply(first)
	_check(first.get_child_count() == 1, "Reapplying a finish cannot accumulate outline layers")
	var second := MeshInstance3D.new()
	second.mesh = source_mesh
	second.material_override = material
	root.add_child(second)
	_check(second.get_child_count() == 0 and source_mesh.get_surface_count() == 1, "Another instance sharing the same asset stays unchanged")
	first.queue_free()
	second.queue_free()
	var area: AreaDef = AreaStore.load_area("village-morning")
	var rules := LabWorld.new(area)
	var state: Dictionary = rules.initial_state()
	state.player = [25, 26, 0]
	state.zones_seen = ["rootward-square", "hall-green", "home-lane"]
	view = ClearingView.new()
	root.add_child(view)
	await process_frame
	view.setup(area)
	view.set_camera_mode(ClearingView.CameraMode.FIXED)
	view.set_zoom(13)
	view.camera.size = 13
	view.focus_on(Vector2(24, 26), true)
	view.apply_state(state)
	for lamp: Dictionary in area.lamps:
		var post: Node3D = view._lamps[lamp.id]
		var glass: MeshInstance3D = post.get_meta("glass")
		_check(post.has_meta("lit") and glass.get_active_material(0).resource_name == "lamp_glass", "The square lamp exposes a distinct lightable amber pane: " + str(lamp.id))
		var halo := post.get_node("Halo") as MeshInstance3D
		_check(not halo.visible and (glass.global_transform * glass.get_aabb().get_center()).distance_to(halo.global_position) < 0.001, "An unlit lamp keeps its halo off and anchored to the actual glass")
	_check(not view.building_node("town-hall").find_children("IllustratedOutline", "MeshInstance3D", true, false).is_empty(), "Morning buildings receive the selected fine-line treatment")
	await _shot("square-unlit")
	var before: Dictionary = state.duplicate(true)
	var commands: Array = []
	for lamp: Dictionary in area.lamps:
		commands.append({"op": "set_field", "entity_id": lamp.id, "field": "enabled", "value": true})
	var proposal: Dictionary = rules.propose(state, commands, {})
	_check(proposal.ok and state == before, "The same lamp commands still produce an isolated validated proposal")
	view.apply_state(proposal.state, true)
	var post: Node3D = view._lamps["square-lamp-0"]
	var glass: MeshInstance3D = post.get_meta("glass")
	_check(glass.material_override == post.get_meta("unlit") and not (post.get_node("Halo") as MeshInstance3D).visible and view._ghost.get_child_count() == area.lamps.size(), "Preview remains a proposal marker and cannot turn on the real lamps")
	view.apply_state(state)
	_check(glass.material_override == post.get_meta("unlit") and not (post.get_node("Halo") as MeshInstance3D).visible, "Clearing a proposal restores the original glass and removes its halo")
	view.apply_state(proposal.state)
	_check(glass.material_override == post.get_meta("lit") and (post.get_node("Halo") as MeshInstance3D).visible, "Apply lights the painted pane and existing halo")
	_check((glass.material_override as StandardMaterial3D).albedo_texture != null, "Lighting retains the authored amber gradient")
	await _shot("square-lit")
	if not output.is_empty() and DisplayServer.get_name() != "headless":
		view.set_zoom(7)
		view.camera.size = 7
		view._focus = Vector3(23.8, 1.2, -26)
		view._focus_target = view._focus
		view._place_camera()
		await _shot("lamp-detail")
	var undo: Dictionary = rules.revert(proposal.state, before)
	view.apply_state(undo.state)
	_check(undo.ok and undo.state.lamps == before.lamps and undo.state.player == before.player and glass.material_override == post.get_meta("unlit"), "Undo restores both the world state and lamp appearance without moving the player")
	# Unknown places and a later bad command retain atomic refusal.
	var hidden: Dictionary = before.duplicate(true)
	hidden.zones_seen = []
	_check(not rules.propose(hidden, commands, {}).ok, "A new model cannot grant access to unexplored lamps")
	commands.append({"op": "set_field", "entity_id": "missing", "field": "enabled", "value": true})
	_check(not rules.propose(before, commands, {}).ok and before == state, "A malformed batch cannot partially light the new lamps")
	# A second setup must remove the morning selection on a journey switch.
	view.setup(AreaStore.load_area("rune-mill"))
	_check(not (view._lamps["lamp-west"] as Node3D).has_meta("lit"), "Rebuilding another area restores its original adopted post")
	view.queue_free()
	await process_frame
	if failures.is_empty():
		print("Illustrated square lamps: %d checks passed." % checks)
	else:
		for failure: String in failures:
			printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)


func _shot(name: String) -> void:
	if output.is_empty() or DisplayServer.get_name() == "headless":
		return
	await create_timer(0.6).timeout
	for frame: int in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
