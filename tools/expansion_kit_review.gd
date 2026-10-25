extends SceneTree
## Unplaced candidates only. Native Godot review at the game's zoom 13, heading, light and actor scale.
## godot --path . --resolution 1200x1000 -s res://tools/expansion_kit_review.gd -- <output dir> [asset] [yaw]

const Geometry := preload("res://pipeline/world_geometry.gd")
const Actor := preload("res://art/sprite_actor.gd")
const IDS := ["hearth-oak", "ridge-cedar", "river-willow", "hearth-house", "lantern-loft", "brook-mill"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var output: String = args[0] if not args.is_empty() else "res://.cache/world-expansion-v1/renders"
	DirAccess.make_dir_recursive_absolute(output)
	var ids: Array = [args[1]] if args.size() > 1 and args[1] != "all" else IDS
	var yaw: float = float(args[2]) if args.size() > 2 else 0.0
	for id: String in ids:
		var view := ClearingView.new()
		root.add_child(view)
		await process_frame
		view.set_process(false)
		view._apply_warmth(0.65)
		var model: Node3D = Geometry.read_glb(ProjectSettings.globalize_path("res://assets/world/" + id + "/model.glb"))
		if model == null:
			printerr("Missing candidate: ", id)
			quit(1)
			return
		view.add_child(model)
		model.rotation_degrees.y = yaw
		var ground := MeshInstance3D.new()
		var slab := BoxMesh.new()
		slab.size = Vector3(18, 0.12, 18)
		ground.mesh = slab
		ground.position.y = -0.07
		var grass := StandardMaterial3D.new()
		grass.albedo_color = Color("638b41")
		grass.roughness = 1.0
		ground.material_override = grass
		view.add_child(ground)
		for i: int in range(-9, 10):
			for axis: int in range(2):
				var line := MeshInstance3D.new()
				var strip := BoxMesh.new()
				strip.size = Vector3(18, 0.002, 0.012) if axis == 0 else Vector3(0.012, 0.002, 18)
				line.mesh = strip
				line.position = Vector3(0, 0.006, i) if axis == 0 else Vector3(i, 0.006, 0)
				var grid := StandardMaterial3D.new()
				grid.albedo_color = Color("60863f")
				line.material_override = grid
				line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				view.add_child(line)
		var player := Actor.new()
		view.add_child(player)
		player.position = Vector3(-1.15, 0.015, 4.05 if id == "hearth-house" else (5.1 if id == "lantern-loft" else (3.6 if id == "brook-mill" else 2.6)))
		var focus := Vector3(0.5 if id == "brook-mill" else 0, 2.5 if id.begins_with("hearth-") or id == "river-willow" else 3.15, 0.0)
		view.camera.size = 13.0
		view.camera.position = focus + Vector3(21, 17.8, 21)
		view.camera.look_at(focus)
		for _i: int in range(20):
			await process_frame
		await RenderingServer.frame_post_draw
		var path: String = output.path_join(id + ("-rear" if yaw != 0 else "") + ".png")
		root.get_texture().get_image().save_png(path)
		print("CANDIDATE REVIEW: ", path)
		view.queue_free()
		await process_frame
	quit(0)
