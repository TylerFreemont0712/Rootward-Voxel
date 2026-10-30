extends SceneTree
## Plays the real walk-through scene changes (workshop doors to the lane, the town steps to the square and back) and
## saves frames as they happen: the doors swinging, the walk out under the veil, the walk in and on.
##   -- <output directory>

var game: Game
var out: String = ""
var shots: int = 0


func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()


func _run() -> void:
	out = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("res://.cache/transitions")
	DirAccess.make_dir_recursive_absolute(out)
	SaveStore.save_path = "user://transition_review_%d.json" % OS.get_process_id()
	SaveStore.profile_path = "user://transition_review_profile_%d.json" % OS.get_process_id()
	SaveStore.force_enabled = true
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
	game.session.state.player = [7, 5, 0]
	game.view.sync_player(game.session.state)
	await game.travel_room_link("downstairs")
	game._pop_all_modals()
	await _walk(Vector2i(13, 4))
	await _through(Vector2i(1, 0), "a-floor-to-lane")
	await _walk(Vector2i(13, 25))
	await _walk(Vector2i(13, 26))
	await _through(Vector2i(0, 1), "b-lane-to-square")
	await _walk(Vector2i(0, 9))
	await _through(Vector2i(-1, 0), "c-square-to-lane")
	SaveStore.delete("sparks-and-machines")
	quit()


func _through(direction: Vector2i, name: String) -> void:
	game._pop_all_modals()
	game.session.request_step(direction)
	for frame: int in range(80):
		await process_frame
		if frame in [2, 10, 18, 26, 34, 44, 56, 70]:
			await _shot("%s-%02d" % [name, frame])
	while game._flow_busy:
		await process_frame
	for frame: int in range(60):
		await process_frame
	await _shot(name + "-after")
	print(name, ": now in ", game.area.id, " at ", game.session.player_cell())


func _walk(target: Vector2i) -> void:
	game._pop_all_modals()
	game.session.walk_to(target)
	var guard: int = 0
	while (not game.session._route.is_empty() or game.session.is_walking()) and guard < 900:
		await process_frame
		guard += 1


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	shots += 1
