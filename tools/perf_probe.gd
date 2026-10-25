extends SceneTree
## Frame-cost probe: plays the real game through everyday scenes (title, standing, walking, zoomed out, inside a
## house) and prints what each frame costs. The first two lines run as shipped (frame rate capped); the rest run
## uncapped, so `frame` is the true cost of one frame. `busy` is how much of each second the GPU spends on the world
## at the shipped frame rate. With `ab`, the standing scene is repeated with one cost changed at a time.
## Columns: script = _process/tweens on the CPU, world_cpu/world_gpu = the 3D viewport's render time,
## draws/objects/prims = draw calls, drawn objects and triangles in the last frame.
## VOXEL_LAB_FRESH=1 scripts/play.sh -s res://tools/perf_probe.gd -- [fullscreen|windowed] [ab]

const SAMPLE_FRAMES: int = 240
var game: Game
var _world_rid: RID
var _script_us: int = 0
var _step_started: int = 0
var _uncapped: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var fullscreen: bool = args.is_empty() or args[0] != "windowed"
	var compare: bool = args.has("ab")
	SaveStore.save_path = "user://perf_save.json"
	SaveStore.profile_path = "user://perf_profile.json"
	SaveStore.force_enabled = true
	SaveStore.delete()
	var boot: int = Time.get_ticks_usec()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	print("PERF boot to title: %.0f ms" % ((Time.get_ticks_usec() - boot) / 1000.0))
	process_frame.connect(func() -> void: _step_started = Time.get_ticks_usec())
	RenderingServer.frame_pre_draw.connect(func() -> void: _script_us += Time.get_ticks_usec() - _step_started)
	await process_frame
	game.settings.set_value("ui_scale", 0.8)
	game.settings.set_value("fullscreen", fullscreen)
	await _frames(30)
	_world_rid = game.world_viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_world_rid, true)
	print("PERF adapter=%s window=%s world=%s msaa=%d" % [RenderingServer.get_video_adapter_name(), str(root.size), str(game.world_viewport.size), game.world_viewport.msaa_3d])
	await _measure("title (as shipped)")
	await game.start_new_game()
	game._hint_timer.stop()
	await _frames(60)
	await _measure("standing (as shipped)")
	_uncapped = true
	await _measure("standing (uncapped)")
	if compare:
		var sun: DirectionalLight3D = game.view._sun
		sun.shadow_enabled = false
		await _measure("  without sun shadow")
		sun.shadow_enabled = true
		var msaa: Viewport.MSAA = game.world_viewport.msaa_3d
		for option: Array in [[Viewport.MSAA_DISABLED, "  MSAA off"], [Viewport.MSAA_2X, "  MSAA 2x"], [Viewport.MSAA_4X, "  MSAA 4x"]]:
			game.world_viewport.msaa_3d = option[0]
			await _measure(option[1])
		game.world_viewport.msaa_3d = msaa
		_breakdown()
	game.view.set_zoom(24.0)
	await _frames(60)
	await _measure("zoomed out")
	game.view.set_zoom(float(game.settings.get_value("zoom")))
	await _frames(30)
	var targets: Array[Vector2i] = [Vector2i(40, 30), Vector2i(20, 20), Vector2i(50, 18)]
	var leg: int = 0
	var started: int = Time.get_ticks_usec()
	_script_us = 0
	for _i: int in range(SAMPLE_FRAMES):
		if not game.session.is_walking():
			game.session.walk_to(targets[leg % targets.size()])
			leg += 1
		await _frame()
	_report("walking (with route finding)", SAMPLE_FRAMES, Time.get_ticks_usec() - started)
	game.session._cancel_route()
	while game.session.is_walking():
		await process_frame
	var door: Vector2i = HouseInstances.door(game.area, "home")
	game.session.prepare_travel()
	game.session.state.player = [door.x, door.y, 0]
	game.view.sync_player(game.session.state)
	game.session._after_change(false)
	game.view.focus_on(Vector2(door), true)
	await _frames(20)
	if await game.enter_house("home"):
		await _frames(60)
		await _measure("inside a house")
	else:
		print("PERF could not enter the house")
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	quit()


## One frame, with the cap lifted (vsync too) when measuring raw cost: the game sets its cap again on focus changes.
func _frame() -> void:
	if _uncapped:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	await process_frame


func _frames(count: int) -> void:
	for _i: int in range(count):
		await _frame()


func _measure(label: String) -> void:
	await _frames(20)
	var started: int = Time.get_ticks_usec()
	_script_us = 0
	for _i: int in range(SAMPLE_FRAMES):
		await _frame()
	_report(label, SAMPLE_FRAMES, Time.get_ticks_usec() - started)


## Which kinds of drawn thing hold the scene's triangles (whole scene, not only what is on screen).
func _breakdown() -> void:
	var totals: Dictionary = {}
	for node: Node in game.world_viewport.find_children("*", "GeometryInstance3D", true, false):
		var instance := node as GeometryInstance3D
		if not instance.is_visible_in_tree():
			continue
		var triangles: int = 0
		var kind: String = instance.get_class()
		if instance is MultiMeshInstance3D:
			var multimesh: MultiMesh = (instance as MultiMeshInstance3D).multimesh
			triangles = _triangles(multimesh.mesh) * multimesh.instance_count
			kind = "%s_%s" % [String(instance.name).get_slice("_", 0), String(instance.name).get_slice("_", 1)]
		elif instance is MeshInstance3D:
			triangles = _triangles((instance as MeshInstance3D).mesh)
			kind = String(instance.get_parent().name).get_slice("_", 0) + "/mesh"
		var entry: Array = totals.get(kind, [0, 0])
		totals[kind] = [int(entry[0]) + 1, int(entry[1]) + triangles]
	var kinds: Array = totals.keys()
	kinds.sort_custom(func(a: String, b: String) -> bool: return int(totals[a][1]) > int(totals[b][1]))
	for kind: String in kinds.slice(0, 12):
		print("PERF   %-30s nodes=%5d triangles=%8d" % [kind, totals[kind][0], totals[kind][1]])


func _triangles(mesh: Mesh) -> int:
	if mesh == null:
		return 0
	var count: int = 0
	for surface: int in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface)
		var indices: Variant = arrays[Mesh.ARRAY_INDEX]
		count += (indices as PackedInt32Array).size() / 3 if indices != null else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return count


func _report(label: String, frames: int, elapsed_us: int) -> void:
	var fps: float = float(frames) / (float(elapsed_us) / 1e6)
	var gpu: float = RenderingServer.viewport_get_measured_render_time_gpu(_world_rid)
	var shipped_fps: float = minf(fps, float(Game.FRAME_RATE))
	print("PERF %-30s fps=%6.1f frame=%5.2fms script=%5.2fms world_cpu=%5.2fms world_gpu=%5.2fms busy=%3.0f%% draws=%d objects=%d prims=%d" % [
		label, fps, 1000.0 / fps, float(_script_us) / float(frames) / 1000.0,
		RenderingServer.viewport_get_measured_render_time_cpu(_world_rid), gpu, gpu * (fps if not _uncapped else shipped_fps) / 10.0,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))])
