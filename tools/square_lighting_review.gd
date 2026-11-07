extends SceneTree
## Reproducible native lighting/performance comparison, without touching player saves.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var output: String = args[0] if not args.is_empty() else "res://evidence/square-renewal/after"
	DirAccess.make_dir_recursive_absolute(output)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 1000)
	root.content_scale_size = root.size
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var view := ClearingView.new()
	root.add_child(view)
	await process_frame
	var started: int = Time.get_ticks_msec()
	view.setup(AreaStore.load_area("haverlund-square"))
	var report: Dictionary = {"build_ms": Time.get_ticks_msec()-started, "renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(), "samples": []}
	view.set_camera_mode(ClearingView.CameraMode.FIXED)
	view.set_zoom(16)
	view.camera.size = 16
	var state: Dictionary = LabWorld.new(view.area).initial_state()
	for id: String in state.lamps: state.lamps[id] = true
	var cycle := CityCycle.fresh()
	CityCycle.at_hour(cycle, 22)
	view.set_city_cycle(CityCycle.time(cycle), CityCycle.power(cycle))
	view.apply_state(state)
	for point: Dictionary in [{"id":"steps","at":Vector2(9,8)}, {"id":"shops","at":Vector2(21,23)}, {"id":"hall","at":Vector2(41,49)}, {"id":"well","at":Vector2(42,24)}]:
		state.player = [47,19,0] if point.id == "well" else [int(point.at.x),int(point.at.y),0]
		view.sync_player(state)
		view.focus_on(point.at, true)
		for n: int in range(30): await process_frame
		var times: Array[float] = []
		var last: int = Time.get_ticks_usec()
		for n: int in range(120):
			await process_frame
			var now: int = Time.get_ticks_usec()
			times.append(float(now-last)/1000.0)
			last = now
		times.sort()
		var sample: Dictionary = {"id": point.id, "median_ms": times[60], "p95_ms": times[114], "draw_calls": int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)), "objects": int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME))}
		report.samples.append(sample)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(point.id+"-night.png"))
		print(JSON.stringify(sample))
	report.nodes = get_node_count()
	report.meshes = view.find_children("*", "MeshInstance3D", true, false).size()
	report.lights = view.find_children("*", "OmniLight3D", true, false).size()
	CityCycle.set_pressure(cycle,15)
	view.set_city_cycle(CityCycle.time(cycle), CityCycle.power(cycle))
	for n: int in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("well-tripped.png"))
	CityCycle.at_hour(cycle,12)
	cycle.tripped = false
	CityCycle.set_pressure(cycle,5.6)
	view.set_city_cycle(CityCycle.time(cycle), CityCycle.power(cycle))
	view.focus_on(Vector2(9,8),true)
	for n: int in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("steps-day.png"))
	FileAccess.open(output.path_join("metrics.json"), FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit()
