extends SceneTree
## Finds surfaces that share a depth and flicker against each other as the camera follows the apprentice.
## The camera is orthographic, so sliding it along its view axis changes no pixel except where two surfaces sit in one
## plane. Each frame is rendered with the camera unmoved twice (what moves by itself is animation, and is ignored) and
## then slid 4 cm forward and 2 cm back; what differs is a depth fight. Shadows are off, so only depth can differ.
##
##   -- scan <area id> <out dir> [zoom 14] [step 12]
##        renders the area on a grid and saves a picture per focus with fighting pixels in red (animation in blue),
##        printing the worst ones.
##   -- hide <area id> <placement id> <focus x> <focus y> [zoom 3.2] [rect x y w h]
##        hides each mesh of one placed model in turn and prints those whose hiding removes most of the fight in the
##        screen rectangle: the meshes that fight each other. ZF_SAVE=<png> also saves the fighting pixels in magenta.
##
## The gold power strips, banners, robots and string lights animate on their own clock and can still show a little.

var _view: ClearingView
var _save_path: String = ""


func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 3:
		printerr("usage: -- scan <area> <out dir> [zoom] [step]  |  -- hide <area> <placement> <fx> <fy> [zoom] [x y w h]")
		quit(2)
		return
	var area: AreaDef = AreaStore.load_area(args[1])
	if area == null:
		quit(1)
		return
	_view = ClearingView.new()
	root.add_child(_view)
	await process_frame
	_view.setup(area)
	_view._sun.shadow_enabled = false
	_view.set_camera_mode(ClearingView.CameraMode.FIXED)
	if args[0] == "scan":
		await _scan(area, args[2], float(args[3]) if args.size() > 3 else 14.0, float(args[4]) if args.size() > 4 else 12.0)
	else:
		await _hide(args)
	quit()


func _frame_setup(zoom: float) -> void:
	_view.set_zoom(zoom)
	_view._zoom_target = zoom
	_view.camera.size = zoom
	for _i: int in range(6):
		await process_frame
	# The view moves the camera every frame; frozen, the camera stays where the probe puts it.
	_view.set_process(false)


func _focus(x: float, y: float) -> void:
	_view._focus = Vector3(x, 0.0, -y)
	_view._focus_target = _view._focus
	_view._place_camera()


func _render(position: Vector3) -> Image:
	_view.camera.position = position
	for _i: int in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


## The unmoved frame, an unmoved repeat, and the frames slid forward and back.
func _four_frames() -> Array[Image]:
	_view._place_camera()
	var base: Vector3 = _view.camera.position
	var forward: Vector3 = -_view.camera.global_basis.z
	var frames: Array[Image] = []
	frames.append(await _render(base))
	frames.append(await _render(base))
	frames.append(await _render(base + forward * 0.0371))
	frames.append(await _render(base - forward * 0.0213))
	return frames


func _differs(p: Color, q: Color, limit: float) -> bool:
	return maxf(absf(p.r - q.r), maxf(absf(p.g - q.g), absf(p.b - q.b))) > limit


func _scan(area: AreaDef, out: String, zoom: float, step: float) -> void:
	DirAccess.make_dir_recursive_absolute(out)
	await _frame_setup(zoom)
	var report: Array[Array] = []
	var x: float = step * 0.5
	while x < float(area.width):
		var y: float = step * 0.5
		while y < float(area.height):
			_focus(x, y)
			var frames: Array[Image] = await _four_frames()
			var width: int = frames[0].get_width()
			var height: int = frames[0].get_height()
			var picture := Image.create(width, height, false, Image.FORMAT_RGB8)
			var moving: PackedByteArray = PackedByteArray()
			moving.resize(width * height)
			for py: int in range(height):
				for px: int in range(width):
					if _differs(frames[0].get_pixel(px, py), frames[1].get_pixel(px, py), 0.03):
						for oy: int in range(-2, 3):
							for ox: int in range(-2, 3):
								if px + ox >= 0 and py + oy >= 0 and px + ox < width and py + oy < height:
									moving[(py + oy) * width + px + ox] = 1
			var fighting: int = 0
			for py: int in range(height):
				for px: int in range(width):
					var here: Color = frames[0].get_pixel(px, py)
					if moving[py * width + px] == 1:
						picture.set_pixel(px, py, here * 0.25 + Color(0, 0, 0.35))
					elif _differs(here, frames[2].get_pixel(px, py), 0.04) or _differs(here, frames[3].get_pixel(px, py), 0.04):
						fighting += 1
						picture.set_pixel(px, py, Color(1, 0, 0))
					else:
						picture.set_pixel(px, py, here * 0.5)
			report.append([x, y, fighting])
			if fighting > 40:
				picture.save_png(out.path_join("fight_%d_%d.png" % [x, y]))
			y += step
		x += step
	report.sort_custom(func(l: Array, r: Array) -> bool: return l[2] > r[2])
	for row: Array in report.slice(0, 16):
		print("focus %d,%d  fighting px %d" % [row[0], row[1], row[2]])


func _fight_count(frames: Array[Image], rect: Rect2i, picture: Image) -> int:
	var count: int = 0
	for py: int in range(rect.position.y, rect.end.y):
		for px: int in range(rect.position.x, rect.end.x):
			var here: Color = frames[0].get_pixel(px, py)
			if _differs(here, frames[1].get_pixel(px, py), 0.03):
				continue
			if _differs(here, frames[2].get_pixel(px, py), 0.04) or _differs(here, frames[3].get_pixel(px, py), 0.04):
				count += 1
				if picture != null:
					picture.set_pixel(px, py, Color(1, 0, 1))
	return count


func _hide(args: PackedStringArray) -> void:
	var zoom: float = float(args[5]) if args.size() > 5 else 3.2
	await _frame_setup(zoom)
	_focus(float(args[3]), float(args[4]))
	var size: Vector2i = root.size
	var rect := Rect2i(0, 0, size.x, size.y)
	if args.size() > 9:
		rect = Rect2i(int(args[6]), int(args[7]), int(args[8]), int(args[9]))
	var node: Node3D = _view.building_node(args[2])
	if node == null:
		node = _view.find_child(args[2], true, false) as Node3D
	if node == null:
		printerr("No placed model called ", args[2])
		return
	var frames: Array[Image] = await _four_frames()
	var picture: Image = frames[0].duplicate()
	var baseline: int = _fight_count(frames, rect, picture)
	var save: String = OS.get_environment("ZF_SAVE")
	if save != "":
		picture.save_png(save)
	print("fighting px in the rectangle: ", baseline)
	for mesh_node: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		mesh_instance.visible = false
		var without: int = _fight_count(await _four_frames(), rect, null)
		mesh_instance.visible = true
		if without < baseline * 0.6:
			print("  hiding %s (in %s) leaves %d" % [mesh_instance.name, mesh_instance.get_parent().name, without])
