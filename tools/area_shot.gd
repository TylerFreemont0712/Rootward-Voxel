extends SceneTree
## Render an area document at gameplay camera scale. Usage:
##   -- <area id> <absolute PNG path> [focus_x focus_y] [zoom] [lit 0|1] [frames] [free]
## It also reports build time and frame rate, so an area that is too heavy shows up here.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <area id> <absolute PNG path> [focus_x focus_y] [zoom] [lit] [frames]")
		quit(2)
		return
	var area: AreaDef = AreaStore.load_area(args[0])
	if area == null:
		quit(1)
		return
	var view := ClearingView.new()
	root.add_child(view)
	await process_frame
	var started: int = Time.get_ticks_msec()
	view.setup(area)
	var build_ms: int = Time.get_ticks_msec() - started
	var focus := Vector2(area.spawn)
	if args.size() >= 4:
		focus = Vector2(float(args[2]), float(args[3]))
	view.set_camera_mode(ClearingView.CameraMode.FIXED)
	view.focus_on(focus, true)
	if args.size() >= 8 and args[7] == "free":
		# The gameplay camera keeps small rooms near their middle; a review can look at any wall.
		view._focus = Vector3(focus.x, 0.0, -focus.y)
		view._focus_target = view._focus
		view._place_camera()
	if args.size() >= 5:
		view.set_zoom(float(args[4]))
		view._zoom_target = float(args[4])  # a review may pull back past the game's own limit
		view.camera.size = float(args[4])
	var rules := LabWorld.new(area)
	var state: Dictionary = rules.initial_state()
	if args.size() >= 6 and args[5] == "1":
		for lamp: Dictionary in area.lamps:
			state.lamps[lamp.id] = true
		for gate: Dictionary in area.gates:
			state.gates[gate.id] = true
		for bridge: Dictionary in area.bridges:
			state.bridges[bridge.id] = bridge.sockets.size()
		view.apply_state(state)
	var frames: int = int(args[6]) if args.size() >= 7 else 90
	for _i: int in range(frames):
		await process_frame
	await RenderingServer.frame_post_draw
	var fps_start: int = Time.get_ticks_msec()
	for _i: int in range(60):
		await process_frame
	var fps: float = 60.0 / maxf(0.001, float(Time.get_ticks_msec() - fps_start) / 1000.0)
	var image: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(args[1].get_base_dir())
	image.save_png(args[1])
	print("area %s: build %d ms, %.0f fps at %dx%d, %d draw calls, %d objects -> %s" % [area.id, build_ms, fps, image.get_width(), image.get_height(),
		int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)), args[1]])
	quit(0)
