extends SceneTree
## Review one world asset in the game's camera, light and materials, beside the painted character for scale.
##   -- <asset id> <absolute PNG path> [recipe|runtime] [zoom] [yaw degrees] [lit 0|1] [focus_y] [focus_x] [focus_z] [frames]
## `recipe` draws the one-time procedural seed (before `seed`/`init`); `runtime` loads the exported GLB the game uses; a path ending
## in `.glb` shows a candidate export before it is promoted (see `pipeline/BLENDER.md`).
## Zoom 13 is the gameplay camera; smaller is a close-up. `lit` swaps the lantern glass for the lit material.

const Seed := preload("res://pipeline/world_seed.gd")
const Geometry := preload("res://pipeline/world_geometry.gd")
const WorldAssets := preload("res://art/world_assets.gd")
const SpriteActor := preload("res://art/sprite_actor.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <asset id> <absolute PNG path> [recipe|runtime] [zoom] [yaw] [lit] [focus_y] [focus_x] [focus_z] [frames]")
		quit(2)
		return
	var source: String = args[2] if args.size() > 2 else "runtime"
	var view := ClearingView.new()
	root.add_child(view)
	await process_frame
	view.set_camera_mode(ClearingView.CameraMode.FIXED)
	var asset: Node3D
	if source == "recipe":
		var maker := Seed.new()
		asset = maker.create_asset(args[0])
		maker.free()
	elif source.ends_with(".glb"):
		asset = Geometry.read_glb(source)
	else:
		asset = WorldAssets.instantiate(args[0])
	if asset == null:
		printerr("No such asset or output: ", args[0], " (", source, ")")
		quit(1)
		return
	asset.rotation_degrees.y = float(args[4]) if args.size() > 4 else 0.0
	view.add_child(asset)
	var grass := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(14.0, 0.1, 14.0)
	grass.mesh = slab
	grass.material_override = view._materials["grass"]
	grass.position = Vector3(0, -0.05, 0)
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.add_child(grass)
	var player := Node3D.new()
	var footprint: Array = WorldAssets.entry(args[0]).get("logical_footprint") if WorldAssets.entry(args[0]).get("logical_footprint") is Array else [-1.8,-1.8,3.6,3.6]
	player.position = Vector3(maxf(2.4, float(footprint[2])*0.5+0.7), 0.055, maxf(3.1,float(footprint[3])*0.5+0.8))
	view.add_child(player)
	player.add_child(SpriteActor.new())
	var lit: bool = args.size() > 5 and args[5] == "1"
	var glass: Array[MeshInstance3D] = []
	_find_glass(asset, glass)
	for pane: MeshInstance3D in glass:
		pane.material_override = view._materials["lit" if lit else "lamp_glass"]
	if lit:
		var light := OmniLight3D.new()
		light.light_color = Color("ffcf86")
		light.omni_range = 3.4
		light.light_energy = 0.9
		view.add_child(light)
		light.position = (glass[0].global_transform * glass[0].get_aabb().get_center()) if not glass.is_empty() else Vector3(0, 1.7, 0)
		view.set_warmth(0.1)
	var zoom: float = float(args[3]) if args.size() > 3 else 7.0
	view.set_zoom(zoom)
	view.camera.size = zoom
	var focus_height: float = float(args[6]) if args.size() > 6 else 1.6
	view._focus = Vector3(float(args[7]) if args.size() > 7 else 0.0, focus_height, float(args[8]) if args.size() > 8 else 0.0)
	view._focus_target = view._focus
	view._place_camera()
	view.camera.look_at(view._focus)
	for _i: int in range(int(args[9]) if args.size() > 9 else 40):
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(args[1].get_base_dir())
	image.save_png(args[1])
	print("asset %s (%s): %dx%d, %d objects -> %s" % [args[0], source, image.get_width(), image.get_height(), int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)), args[1]])
	quit(0)


func _find_glass(node: Node, found: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null and instance.mesh.get_surface_count() > 0:
			var material: Material = instance.get_active_material(0)
			if material != null and material.resource_name == "lamp_glass":
				found.append(instance)
	for child: Node in node.get_children():
		_find_glass(child, found)
