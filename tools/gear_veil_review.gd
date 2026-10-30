extends SceneTree
## Holds the clockwork veil at fixed points of its sweep over the real workshop floor and saves a frame of each:
## growing out of the doorway, nearly closed, closed, opening again. Also reports the veil's frame cost.
##   -- <output directory>

var game: Game
var out: String = ""


func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()


func _run() -> void:
	out = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("res://.cache/gear-veil")
	DirAccess.make_dir_recursive_absolute(out)
	SaveStore.save_path = "user://gear_veil_review_%d.json" % OS.get_process_id()
	SaveStore.profile_path = "user://gear_veil_review_profile_%d.json" % OS.get_process_id()
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
	var origin: Vector2 = game._cell_uv(Vector2(13.6, 4.0))
	var veil: GearVeil = game._veil
	var steps: Array = [["a-closing-10", false, 0.10], ["b-closing-30", false, 0.30], ["c-closing-55", false, 0.55], ["d-closing-80", false, 0.80], ["e-closed", false, 1.0], ["f-opening-20", true, 0.20], ["g-opening-45", true, 0.45], ["h-opening-75", true, 0.75]]
	veil.visible = true
	for step: Array in steps:
		veil._material.set_shader_parameter("origin", origin)
		veil._material.set_shader_parameter("opening", 1.0 if step[1] else 0.0)
		veil.set_front(float(step[2]))
		for _i: int in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join(str(step[0]) + ".png"))
	var started: int = Time.get_ticks_msec()
	veil.set_front(1.0)
	for _i: int in range(120):
		await process_frame
	print("closed veil: ", snappedf(120.0 / maxf(0.001, float(Time.get_ticks_msec() - started) / 1000.0), 0.1), " frames per second")
	veil.visible = false
	SaveStore.delete("sparks-and-machines")
	quit()
