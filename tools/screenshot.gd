extends SceneTree
## Screenshot a project scene in an existing display. Usage: -- <scene> <absolute PNG path> [frames]

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <res:// scene> <absolute PNG path> [frames]")
		quit(2)
		return
	var packed: PackedScene = load(args[0]) as PackedScene
	if packed == null:
		printerr("Could not load scene: ", args[0])
		quit(2)
		return
	root.add_child(packed.instantiate())
	_capture.call_deferred(args[1], int(args[2]) if args.size() > 2 else 90)

func _capture(path: String, frames: int) -> void:
	for _i: int in range(frames):
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var error: Error = image.save_png(path)
	if error != OK:
		printerr("Could not save screenshot: ", error_string(error))
		quit(1)
		return
	print("screenshot: %s (%dx%d)" % [path, image.get_width(), image.get_height()])
	quit(0)
