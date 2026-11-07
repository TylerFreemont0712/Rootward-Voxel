extends SceneTree
## The fastest end-to-end check: does the game boot, does every room of the journey load and draw, and does the
## journey survive a save and Continue? Nothing here asserts story detail; the flow tests do that.
## `scripts/test.sh smoke` also fails on any script error printed while it runs.
var checks: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()


func _run() -> void:
	var started: int = Time.get_ticks_msec()
	var spec: Dictionary = LevelStore.entry(LevelStore.default_id())
	_check(not spec.is_empty(), "The level catalog names a default journey")
	var rooms: Array = spec.get("room_areas", [])
	_check(rooms.size() >= 10 and rooms.has(spec.area), "The journey lists its rooms, starting with its first area")
	var parsed: Dictionary = {}
	for id: String in rooms:
		var result: Dictionary = AreaStore.read(id)
		_check(result.ok, "%s validates %s" % [id, str(result.get("errors", []))])
		if result.ok:
			parsed[id] = result.area
	# Every doorway and stair leads to a room that exists, and arrives on a walkable cell.
	for id: String in parsed:
		var area: AreaDef = parsed[id]
		for link: Dictionary in area.interior.get("links", []):
			var target: AreaDef = parsed.get(str(link.to))
			_check(target != null, "%s: the link '%s' leads to a room of the journey (%s)" % [id, str(link.id), str(link.to)])
			if target != null:
				var arrival := Vector2i(int(link.arrival[0]), int(link.arrival[1]))
				_check(LabWorld.new(target).is_walkable(LabWorld.new(target).initial_state(), arrival), "%s: arriving from '%s' lands on a walkable cell" % [target.id, str(link.id)])
	# Each room builds and draws a frame.
	for id: String in parsed:
		var view := ClearingView.new()
		root.add_child(view)
		await process_frame
		var began: int = Time.get_ticks_msec()
		view.setup(parsed[id])
		await process_frame
		_check(view._content != null and view._content.get_child_count() > 3, "%s builds a populated view (%d ms)" % [id, Time.get_ticks_msec() - began])
		view.queue_free()
		await process_frame
	# The real game boots, starts, saves and continues.
	SaveStore.save_path = "user://smoke_%d.json" % OS.get_process_id()
	SaveStore.profile_path = "user://smoke_profile_%d.json" % OS.get_process_id()
	SaveStore.force_enabled = true
	var game: Game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	for _i: int in range(6):
		await process_frame
	_check(game.title != null and not game.playing, "The game opens on the title")
	await game.start_new_game(LevelStore.default_id())
	for _i: int in range(4):
		await process_frame
	_check(game.playing and game.area.id == str(spec.area), "A new game starts in the first room")
	game.save_now()
	_check(SaveStore.has_save(LevelStore.default_id()), "Starting a journey writes its save")
	await game._return_to_title()
	await game.continue_game()
	for _i: int in range(4):
		await process_frame
	_check(game.playing and game.area.id == str(spec.area), "Continue returns to the saved room")
	SaveStore.delete(LevelStore.default_id())
	game.queue_free()
	await process_frame
	print("Smoke: %d checks in %.1f s." % [checks, float(Time.get_ticks_msec() - started) / 1000.0], "" if failures.is_empty() else " Failures: %d" % failures.size())
	for issue: String in failures:
		printerr("FAIL: ", issue)
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
