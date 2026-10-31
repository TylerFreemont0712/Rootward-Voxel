extends SceneTree
## Native gameplay review with scratch progress, controlled service times and actual player input.
var game: Game
var output: String
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()

func _run() -> void:
	output = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("res://.cache/phantom-crowd/native")
	DirAccess.make_dir_recursive_absolute(output)
	SaveStore.save_path = "user://phantom_review_%d.json" % OS.get_process_id()
	SaveStore.profile_path = "user://phantom_review_profile_%d.json" % OS.get_process_id()
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
	await _travel("downstairs", Vector2i(7,5))
	_check(game.view.villagers.actors.is_empty(), "Nell is absent from the workshop")
	await _record("01-workshop-without-nell", Vector2(6,6), 1)
	await _travel("street", Vector2i(13,4))
	await _record("02-tram-three-arrivals", Vector2(16,3), 26)
	_advance_to(24.0)
	await _record("03-lane-kids-and-passengers", Vector2(18,11), 16)
	_advance_to(35.0)
	await _record("04-passengers-toward-gate", Vector2(14,23), 16)
	_advance_to(72.0)
	_check(_passengers() == 0, "First passengers have left through the town gate")
	await _record("05-between-trams", Vector2(14,23), 1)
	_advance_to(87.0)
	await _record("06-next-tram-two-arrivals", Vector2(16,3), 26)
	_check(_passengers() == 2, "Next tram has two passengers, not a uniform repeated group")
	await _travel("town-steps", Vector2i(12,26))
	_check(game.view.villagers.phantoms.size() == 18 and game.view.villagers.actors.size() == 2, "Eighteen square phantoms and exactly Mira/Rowan")
	await _record("07-square-shops", Vector2(25,24), 12)
	await _record("08-square-market", Vector2(30,40), 12)
	await _record("09-square-garden", Vector2(61,24), 12)
	await _record("10-square-rootwell", Vector2(45,29), 12)
	_collision()
	_pause()
	for failure: String in failures: printerr("FAIL: ", failure)
	print("Phantom native review: ", "passed" if failures.is_empty() else "FAILED", " -> ", output)
	quit(0 if failures.is_empty() else 1)

func _travel(link: String, at: Vector2i) -> void:
	game._pop_all_modals()
	game.session.state.player = [at.x,at.y,0]
	game.view.sync_player(game.session.state)
	_check(await game.travel_room_link(link), "Real area travel: " + link)
	game._pop_all_modals()
	game.close_notebook(true)
	game._refresh_interaction()
	await process_frame

func _record(label: String, focus: Vector2, frames: int) -> void:
	game.view.set_camera_mode(ClearingView.CameraMode.FIXED)
	game.view.focus_on(focus, true)
	for index: int in range(frames):
		await create_timer(.25).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("%s-%02d.png" % [label,index]))
	print(label, ": service clock ", VillageLife.clock(game.view.villagers.life), "; active passengers ", _passengers())

func _advance_to(seconds: float) -> void:
	var residents: VillagerView = game.view.villagers
	residents.set_physics_process(false)
	residents.set_process(false)
	var ticks: int = maxi(0, ceili((seconds - VillageLife.clock(residents.life)) * 60.0))
	for tick: int in range(ticks): residents._physics_process(1.0/60.0)
	residents._process(0)
	residents.set_process(true)
	residents.set_physics_process(true)

func _passengers() -> int:
	var count: int = 0
	for id: String in game.view.villagers.life:
		if id.begins_with("tram-") and game.view.villagers.life[id].active: count += 1
	return count

func _collision() -> void:
	var residents: VillagerView = game.view.villagers
	residents.paused = true
	var checked: bool = false
	for id: String in residents.phantoms:
		var target: Vector2i = residents.life[id].at
		for direction: Vector2i in LabWorld.DIRECTIONS:
			var next: Vector2i = target - direction
			if not game.session.rules.can_step(game.session.state, next, target) or game.view.resident_cells().has(next): continue
			game.session.state.player = [next.x,next.y,0]
			game.view.sync_player(game.session.state)
			_check(game.session.request_step(direction), "Actual player input passes through a phantom")
			game.session.advance_walk(LabWorld.STEP_SECONDS)
			checked = true
			break
		if checked: break
	_check(checked, "A real phantom crossing was tested")
	var robot: Dictionary = residents.life["square-pip"]
	for direction: Vector2i in LabWorld.DIRECTIONS:
		var next: Vector2i = robot.at - direction
		if not game.session.rules.can_step(game.session.state, next, robot.at) or game.view.resident_cells().has(next): continue
		game.session.state.player = [next.x,next.y,0]
		game.view.sync_player(game.session.state)
		_check(not game.session.request_step(direction), "Actual player input still collides with a robot")
		break
	residents.paused = false

func _pause() -> void:
	var residents: VillagerView = game.view.villagers
	var before: Dictionary = residents.life.duplicate(true)
	residents.paused = true
	residents._physics_process(1)
	_check(before == residents.life, "A modal freezes crowd and service clocks together")
	residents.paused = false

func _check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures.append(message)
