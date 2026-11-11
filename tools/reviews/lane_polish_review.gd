extends SceneTree
## Real gameplay review: changed lane, gate travel both ways, errands, chapters and dev controls.
var game: Game
var output: String
var failures: Array[String] = []

func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()

func _run() -> void:
	output = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("res://.cache/lane-life/native")
	DirAccess.make_dir_recursive_absolute(output)
	SaveStore.save_path = "user://lane_polish_review_%d.json" % OS.get_process_id()
	SaveStore.profile_path = "user://lane_polish_profile_%d.json" % OS.get_process_id()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game()
	game._pop_all_modals()
	game.close_notebook(true)
	if OS.get_cmdline_user_args().size() > 1 and OS.get_cmdline_user_args()[1] == "layout":
		await _layout()
		quit(0 if failures.is_empty() else 1)
		return
	_check(DevelopmentMode.jump(game,"lane"), "Lane checkpoint")
	game.view.residents.paused = true
	await _shot("01-lane-gate-closed",Vector2(14,24))
	game.open_development()
	await _shot("02-dev-panel",Vector2(14,24))
	game._pop_all_modals()
	game.session.state.player = [13,26,0]
	game.view.sync_player(game.session.state)
	game.session.request_step(Vector2i(0,1))
	await create_timer(.16).timeout
	_check(DoorSwing.leaves(game.view.link_doors("shell")).any(func(leaf: Node3D) -> bool: return absf(leaf.rotation.y) > .3), "Actual down-stair input swings the gate")
	await _shot_now("03-gate-opening")
	while game._flow_busy: await process_frame
	_check(game.area.id == "haverlund-square", "Down the stairs reaches the square")
	game._pop_all_modals()
	game.session.state.player = [0,8,0]
	game.view.sync_player(game.session.state)
	game.session.request_step(Vector2i(-1,0))
	while game.area.id != "haverlund-lane": await process_frame
	await process_frame
	_check(DoorSwing.is_open(game.view.link_doors("shell")), "The return walk arrives through an open gate")
	while game._flow_busy: await process_frame
	await create_timer(.5).timeout
	_check(not DoorSwing.is_open(game.view.link_doors("shell")), "Gate closes behind the returning traveller")
	game.view.set_camera_mode(WorldView.CameraMode.FIXED)
	game.view.focus_on(Vector2(18,11),true)
	for tick: int in range(480): game.view.residents._physics_process(1.0/60.0)
	game.view.residents._process(0)
	await _shot("04-lane-errands-and-crowd",Vector2(18,11))
	_check(DevelopmentMode.jump(game,"square"), "Square checkpoint")
	for tick: int in range(1800): game.view.residents._physics_process(1.0/60.0)
	game.view.residents._process(0)
	await _shot("05-square-errands",Vector2(28,37))
	await _shot("06-square-garden",Vector2(60,24))
	_check(DevelopmentMode.jump(game,"hello-start"), "First chapter checkpoint")
	await _shot("07-chapter-00-pin",Vector2(7,6))
	_check(DevelopmentMode.fill_solution(game), "Fill the reference code from dev tools")
	await create_timer(.5).timeout
	_check_pin_layout()
	await _shot_now("08-reference-code")
	game.close_notebook(true)
	_check(DevelopmentMode.jump(game,"round-start"), "Morning round checkpoint")
	game._pop_all_modals()
	await _shot("09-chapter-02-pin",Vector2(7,6))
	for failure: String in failures: printerr("FAIL: ",failure)
	print("Lane polish native review: ", "passed" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)

func _layout() -> void:
	_check(DevelopmentMode.jump(game,"hello-start"), "Chapter layout fixture")
	await _shot("07-chapter-00-pin",Vector2(7,6))
	_check(DevelopmentMode.fill_solution(game), "Reference-code layout")
	await create_timer(.5).timeout
	_check_pin_layout()
	await _shot_now("08-reference-code")
	game.close_notebook(true)
	_check(DevelopmentMode.jump(game,"round-start"), "Longer chapter pin")
	game._pop_all_modals()
	await _shot("09-chapter-02-pin",Vector2(7,6))
	game.open_development()
	await _shot_now("10-dev-chapter-panel")
	print("Native chapter layout: ", "passed" if failures.is_empty() else "FAILED")

func _check_pin_layout() -> void:
	var paper := game.hud as PaperHud
	var pin: Rect2 = paper.ticket.get_global_rect()
	print("Pin layout: hud=",paper.size," ticket=",paper.ticket.size," minimum=",paper.ticket.get_combined_minimum_size()," group=",paper._quest_group.get_rect()," local=",paper.ticket.get_rect()," buttons=",paper._notebook_button.get_global_rect())
	_check(pin.end.y <= paper._notebook_button.get_global_rect().position.y - 8, "The expanded pin clears the bottom buttons while code is open")
	_check(paper._toast_box.get_global_rect().end.y < pin.position.y, "Feedback sits above the expanded pin")

func _shot(label: String, focus: Vector2) -> void:
	game.view.set_camera_mode(WorldView.CameraMode.FIXED)
	game.view.focus_on(focus,true)
	for frame: int in range(3): await process_frame
	await _shot_now(label)

func _shot_now(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func _check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures.append(message)
