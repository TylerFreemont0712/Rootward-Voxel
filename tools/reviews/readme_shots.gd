extends SceneTree
## The README's screenshots, from the real game at 1600x1000, as a player sees it: the development button, the dev
## jumps' notices and the title's asset-showcase entry are hidden. Saves are scratch files. Usage:
##   scripts/readme-shots.sh            (writes docs/images/*.jpg)
var game: Game
var output: String = ""


func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	output = args[0] if not args.is_empty() else ProjectSettings.globalize_path("res://.cache/readme-shots")
	DirAccess.make_dir_recursive_absolute(output)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 1000)
	root.content_scale_size = root.size
	ProjectSettings.set_setting(AssetShowcase.SETTING, false)
	SaveStore.save_path = "user://readme_%d.json" % OS.get_process_id()
	SaveStore.profile_path = "user://readme_profile_%d.json" % OS.get_process_id()
	SaveStore.force_enabled = true
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(60)
	await shot("title")
	await game.start_new_game(LevelStore.default_id())
	game.settings.set_value("dialogue_speed", 0)
	game._pop_all_modals()
	await _frames(30)
	await shot("loft")
	for checkpoint: String in ["workshop-start", "lane", "square"]:
		if checkpoint == "square":
			await _backdrop()
		DevelopmentMode.jump(game, checkpoint)
		SaveStore.development = false
		game._dialogue_read["workshop-scenes"] = game._story.scenes.keys()
		game._dismissed_scenes = game._story.scenes.keys()
		game._pop_all_modals()
		game.close_notebook(true)
		await _frames(50)
		await shot(checkpoint)
	await _sign_code()
	DevelopmentMode.jump(game, "square")
	SaveStore.development = false
	game._pop_all_modals()
	game.close_notebook(true)
	await _frames(30)
	game.open_build()
	await _frames(40)
	await shot("layout-studio")
	game.close_build()
	SaveStore.delete(LevelStore.default_id())
	print("README shots in %s" % output)
	quit(0)


## The installer's backdrop: Spindle Lane with no interface over it (scripts/build.py copies it into the installer).
func _backdrop() -> void:
	game.hud.visible = false
	await _frames(20)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(output.path_join("installer-backdrop.jpg"), 0.88)
	print("shot: installer-backdrop")
	game.hud.visible = true


## Chapter 03's tram sign: a list of messages and a for loop, previewed with the line debugger on the real slate.
func _sign_code() -> void:
	DevelopmentMode.jump(game, "welcome-start")
	SaveStore.development = false
	for frame: int in range(4):
		await process_frame
	game.session.accounts.inventory["message-card"] = 1
	if not game.session.state.inspections_read.has("sign-commission"):
		game.session.state.inspections_read.append("sign-commission")
	game._pop_all_modals()
	game.open_journal()
	if game._modals.is_empty() or not game._modals[-1] is JobLedger:
		printerr("readme shots: the job book did not open")
		return
	(game._modals[-1] as JobLedger).destination_requested.emit("tram-welcome")
	var route: Array[Vector2i] = game.session._route.duplicate()
	game.session._cancel_route()
	for cell: Vector2i in route:
		game.session.request_step(cell - game.session.player_cell())
		game.session.advance_walk(LabWorld.STEP_SECONDS)
	game._process(0)
	if not game.journal is JobsJournal:
		printerr("readme shots: the sign's editor did not open")
		return
	var editor: JobsJournal = game.journal
	editor.editor.text = 'def program(world):\n    messages = [\n        "Welcome to Spindle Lane",\n        "No. 7 stops here",\n        "Tea first. Tram second.",\n    ]\n    for message in messages:\n        print(message)\n'
	editor.editor.text_changed.emit()
	await editor.preview()
	await _frames(90)
	await shot("first-code")
	game.close_notebook(true)
	await _frames(10)


func _frames(n: int) -> void:
	for _i: int in range(n):
		await process_frame


func _clean_hud() -> void:
	var hud := game.hud as PaperHud
	if hud != null and hud._dev_button != null:
		hud._dev_button.visible = false
	if game.hud != null:
		for toast: Node in game.hud._toast_box.get_children():
			(toast as CanvasItem).visible = false


func shot(name: String) -> void:
	_clean_hud()
	await _frames(2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(output.path_join(name + ".jpg"), 0.86)
	print("shot: " + name)
