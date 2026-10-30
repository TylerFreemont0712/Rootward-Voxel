extends SceneTree
## Review a modular house in the game's camera, light and materials, beside the painted character for scale; several
## placed side by side show its per-placement variety.
##   -- <asset id[,id...]> <absolute PNG path> [zoom] [yaw degrees] [count] [seed] [candidate .glb] [focus height]
## Zoom 13 is the gameplay camera; smaller is a close-up. With count 1 and no seed (or seed -1) the house shows its
## authored look; otherwise house i shows HouseVariants.pick(seed + i). Several ids make a mixed street, house i being
## ids[i % n], standing side by side along their footprints. A candidate .glb shows a draft before it is built and
## promoted (the catalog entry still supplies its variants).

const Geometry := preload("res://pipeline/world_geometry.gd")
const WorldAssets := preload("res://art/world_assets.gd")
const SpriteActor := preload("res://art/sprite_actor.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <asset id> <absolute PNG path> [zoom] [yaw] [count] [seed] [candidate .glb] [focus height]")
		quit(2)
		return
	var ids: PackedStringArray = args[0].split(",")
	var zoom: float = float(args[2]) if args.size() > 2 else 13.0
	var yaw: float = float(args[3]) if args.size() > 3 else 0.0
	var count: int = int(args[4]) if args.size() > 4 else 1
	var seed: int = int(args[5]) if args.size() > 5 else -1
	var candidate: String = args[6] if args.size() > 6 else ""
	var view := ClearingView.new()
	root.add_child(view)
	await process_frame
	view.set_camera_mode(ClearingView.CameraMode.FIXED)
	var gap: float = 1.9 if ids.size() == 1 else 0.6
	var row := Node3D.new()
	view.add_child(row)
	var cursor: float = 0.0
	var first: Array = []
	for index: int in range(count):
		var id: String = ids[index % ids.size()]
		var spec: Dictionary = WorldAssets.entry(id)
		var footprint: Array = spec.get("logical_footprint") if spec.get("logical_footprint") is Array else [-3, -3, 6, 6]
		if first.is_empty():
			first = footprint
		var house: Node3D
		var variant: Dictionary = HouseVariants.authored(spec) if seed < 0 and index == 0 else HouseVariants.pick(spec, maxi(seed, 0) + index)
		if candidate.is_empty():
			house = WorldAssets.instantiate(id, ResourceLoader.CACHE_MODE_REUSE, variant)
		else:
			house = Geometry.read_glb(candidate)
			if house != null:
				IllustratedEdges.apply(house)
				WorldAssets.light_power(house)
				HouseVariants.apply(house, spec, variant)
		if house == null:
			printerr("No such house or candidate: ", id, " ", candidate)
			quit(1)
			return
		house.rotation_degrees.y = yaw
		house.position.x = cursor - float(footprint[0])
		cursor += float(footprint[2]) + gap
		row.add_child(house)
		print("house %d %s: %s" % [index, id, HouseVariants.summary(spec, variant)])
	var width: float = cursor - gap
	row.position.x = -width * 0.5
	var grass := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(width + 16.0, 0.1, 22.0)
	grass.mesh = slab
	grass.material_override = view._materials["grass"]
	grass.position = Vector3(0, -0.05, 0)
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.add_child(grass)
	var player := Node3D.new()
	player.position = Vector3(-width * 0.5 + float(first[2]) + 0.9, 0.055, float(first[3]) * 0.5 + 1.3)
	view.add_child(player)
	player.add_child(SpriteActor.new())
	view.set_zoom(zoom)
	view._zoom_target = zoom
	view.camera.size = zoom
	view._focus = Vector3(0, float(args[7]) if args.size() > 7 else 3.0, 0)
	view._focus_target = view._focus
	view._place_camera()
	view.camera.look_at(view._focus)
	for _i: int in range(40):
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(args[1].get_base_dir())
	image.save_png(args[1])
	print("Saved %s (%d triangles drawn)" % [args[1], RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
	quit(0)
