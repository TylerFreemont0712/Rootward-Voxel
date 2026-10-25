extends SceneTree
## Current exported building kit, front/rear, with the approved actor at gameplay scale.

const WorldAssets := preload("res://art/world_assets.gd")

const IDS: Array[String] = ["cottage","mill-house","log-cabin","log-cabin-large","log-cabin-large-teal","hearth-house","lantern-loft","brook-mill","lamppost","hollow-bakery","hollow-smithy","concept-cottage"]

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var output: String = args[0] if not args.is_empty() else ".cache/building-polish/review"
	for id: String in IDS:
		if not ResourceLoader.exists("res://assets/world/"+id+"/model.glb"):continue
		for yaw: int in [0,180]:
			var view := ClearingView.new()
			root.add_child(view)
			await process_frame
			view.set_process(false)
			view.set_camera_mode(ClearingView.CameraMode.FIXED)
			view._apply_warmth(0.6)
			var asset: Node3D = WorldAssets.instantiate(id)
			view.add_child(asset)
			asset.rotation_degrees.y = yaw
			var box := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(18,0.1,18)
			box.mesh = mesh
			box.position.y = -0.06
			box.material_override = view._materials.grass
			view.add_child(box)
			var boy := SpriteAdventurer.new()
			view.add_child(boy)
			var footprint: Array = WorldAssets.entry(id).get("logical_footprint") if WorldAssets.entry(id).get("logical_footprint") is Array else [-1.8,-1.8,3.6,3.6]
			boy.position = Vector3(-maxf(2.5,float(footprint[2])*0.5+0.7),0.055,maxf(3.5,float(footprint[3])*0.5+0.8))
			var focus := Vector3(0,2.6 if id in ["lantern-loft","brook-mill"] else 1.7,0)
			view.camera.size = 13
			view.camera.position = focus + Vector3(21,17.8,21)
			view.camera.look_at(focus)
			for frame: int in range(24):await process_frame
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute(output)
			root.get_texture().get_image().save_png(output.path_join(id+("-rear" if yaw else "")+".png"))
			view.queue_free()
			await process_frame
	print("Building kit reviewed at gameplay scale.")
	quit()
