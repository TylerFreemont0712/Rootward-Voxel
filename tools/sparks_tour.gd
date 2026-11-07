extends SceneTree
## A tour of the real game at 1600x1000 for human review: title, naming, the opening, each room at its checkpoint,
## the pause menu, map, job book and the layout studio. Saves are scratch files. Usage:
##   scripts/screenshot.sh [dir]          (default .cache/tour)
var game: Game
var output: String = ""
var count: int = 0


func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	output = args[0] if not args.is_empty() else "res://.cache/tour"
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 1000)
	root.content_scale_size = root.size
	SaveStore.save_path = "user://tour_%d.json" % OS.get_process_id()
	SaveStore.profile_path = "user://tour_profile_%d.json" % OS.get_process_id()
	SaveStore.force_enabled = true
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(40)
	await shot("title")
	game._new_game_flow()
	await _frames(20)
	await shot("naming")
	game._pop_all_modals()
	await game.start_new_game(LevelStore.default_id())
	await _frames(30)
	await shot("opening")
	game._pop_all_modals()
	await _frames(10)
	await shot("loft")
	for checkpoint: String in ["workshop-start", "lane", "square", "city-hall"]:
		DevelopmentMode.jump(game, checkpoint)
		SaveStore.development = false
		game._dialogue_read["workshop-scenes"] = game._story.scenes.keys()
		game._workshop_dismissed = game._story.scenes.keys()
		game._pop_all_modals()
		game.close_notebook(true)
		await _frames(40)
		await shot(checkpoint)
	DevelopmentMode.jump(game, "square")
	SaveStore.development = false
	game._pop_all_modals()
	await _frames(30)
	game.open_pause()
	await _frames(15)
	await shot("pause")
	game._pop_all_modals()
	game.open_map()
	await _frames(15)
	await shot("map")
	game._pop_all_modals()
	game.open_journal()
	await _frames(15)
	await shot("job-book")
	game._pop_all_modals()
	game.open_build()
	await _frames(40)
	await shot("layout-studio")
	game.close_build()
	await _frames(10)
	SaveStore.delete(LevelStore.default_id())
	print("Tour: %d screens in %s" % [count, output])
	quit(0)


func _frames(n: int) -> void:
	for _i: int in range(n):
		await process_frame


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	count += 1
	root.get_texture().get_image().save_png(output.path_join("%02d-%s.png" % [count, name]))
