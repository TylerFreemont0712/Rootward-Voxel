extends SceneTree
## Actual game, normal camera and isolated saves. -- <output directory>

var game: Game
var output: String

func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()

func _run() -> void:
	output = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("res://.cache/town-life/review")
	DirAccess.make_dir_recursive_absolute(output)
	SaveStore.save_path = "user://town_life_review_%d.json" % OS.get_process_id()
	SaveStore.profile_path = "user://town_life_review_profile_%d.json" % OS.get_process_id()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game("sparks-and-machines")
	game._pop_all_modals()
	game.close_notebook(true)
	game.session.state.hotaru_greeted = true
	game.session.completed.append("say-hello")
	game.session.state.items = ["field-tablet"]
	game._dialogue_read["loft-waking"] = ["introduced"]
	game._dialogue_read["workshop-scenes"] = ["waiting-ticket", "tablet-taken", "workshop-arrival", "lane-arrival", "square-arrival"]
	await _record("01-loft", Vector2(7, 6), 1)
	await _travel("downstairs", Vector2i(7, 5))
	await _record("02-workshop", Vector2(6, 6))
	await _travel("street", Vector2i(13, 4))
	await _record("03-lane-garden", Vector2(15, 10))
	await _record("04-lane-neighbours", Vector2(14, 22))
	await _travel("town-steps", Vector2i(12, 26))
	await _record("05-square-shops", Vector2(24, 23))
	await _record("06-square-market", Vector2(30, 39))
	await _record("07-square-garden", Vector2(62, 24))
	await _record("08-square-rootwell", Vector2(46, 29))
	await _collision_review()
	print("Town life native review complete: ", output)
	quit()

func _travel(link: String, at: Vector2i) -> void:
	game._pop_all_modals()
	game.session.state.player = [at.x, at.y, 0]
	game.view.sync_player(game.session.state)
	if not await game.travel_room_link(link):
		printerr("Could not travel: ", link)
		quit(1)
	game._pop_all_modals()
	game.close_notebook(true)
	game._refresh_interaction()
	await process_frame

func _record(label: String, focus: Vector2, frames: int = 14) -> void:
	game.view.set_camera_mode(ClearingView.CameraMode.FIXED)
	game.view.focus_on(focus, true)
	var residents: VillagerView = game.view.villagers
	var before: Dictionary = residents.life.duplicate(true) if residents != null else {}
	for index: int in range(frames):
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("%s-%02d.png" % [label, index]))
	var moved: Array[String] = []
	if residents != null:
		for id: String in residents.life:
			if before[id].at != residents.life[id].at: moved.append(id)
		print(label, ": ", residents.actors.size(), " sprites, ", residents.robots.size(), " robots; moved ", moved)
	else: print(label, ": quiet loft retained")

func _collision_review() -> void:
	var residents: VillagerView = game.view.villagers
	residents.paused = true
	# Walk input must refuse the same reserved cells used by the simulation, including a moving robot's target.
	var robot: Dictionary = residents.life["square-pip"]
	for direction: Vector2i in LabWorld.DIRECTIONS:
		var next: Vector2i = robot.at - direction
		if not game.session.rules.can_step(game.session.state, next, robot.at) or game.view.resident_cells().has(next): continue
		game.session.state.player = [next.x, next.y, 0]
		game.view.sync_player(game.session.state)
		var before: Vector2i = game.session.player_cell()
		var refused: bool = not game.session.request_step(direction)
		print("Player collision with Pip: ", refused and game.session.player_cell() == before)
		if not refused:
			printerr("Player entered a reserved robot cell")
			quit(1)
		return
