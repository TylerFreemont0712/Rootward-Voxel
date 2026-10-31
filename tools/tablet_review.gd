extends SceneTree
## Review of the tablet screen, the VS Code editor, the debugger replay and the blue ghost previews at gameplay scale.
## Usage: scripts/play.sh --resolution 1600x1000 -s res://tools/tablet_review.gd -- <absolute output dir>

const LIGHT: String = 'def program(world):\n    lamp = world.lamp("landing-lamp")\n    lamp.set_lit(True)\n'
const ROUND: String = 'def program(world):\n    lamps = world.zone("workshop").lamps\n    for lamp in lamps:\n        lamp.set_lit(True)\n'
var game: Game
var output: String = ""


func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage: -- <absolute output dir>")
		quit(2)
		return
	output = args[0]
	SaveStore.save_path = "user://tablet_review_" + str(OS.get_process_id()) + ".json"
	SaveStore.profile_path = "user://tablet_review_profile_" + str(OS.get_process_id()) + ".json"
	SaveStore.force_enabled = true
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game("sparks-and-machines")
	game._pop_all_modals()
	game.close_notebook(true)
	# The greeting page on the loft terminal, after the note and the terminal have been read.
	game.session.state.inspections_read = ["nell-note", "desk-terminal"]
	game.session.connect_terminal("desk-terminal")
	game.open_notebook()
	await _frames(20)
	var notes := game.movement_lesson as WorkshopJournal
	await _shot("01-greeting-blocks")
	notes.message.text = "Hello, Hotaru!"
	await notes.preview()
	await _frames(50)
	await _shot("02-greeting-ghost")
	notes.select_mode("python")
	await _frames(5)
	await notes.preview()
	await _frames(70)
	await _shot("03-greeting-python-replay")
	await _frames(40)
	await _shot("03b-greeting-python-replay-later")
	game.close_notebook(true)
	# Commit the greeting and go downstairs with the slate.
	game.session.connect_terminal("desk-terminal")
	game.session.set_source(CompanionLesson.STARTER)
	await game.session.run_preview()
	game.session.apply_preview()
	game._dialogue_read["loft-waking"] = ["introduced"]
	game.session.state.items = ["field-tablet"]
	game.session.greeting_editor = {"mode": "python", "python": CompanionLesson.STARTER}
	game.session.state.player = [7, 5, 0]
	game.view.sync_player(game.session.state)
	game.session.request_step(Vector2i(0, -1))
	while game._flow_busy: await process_frame
	game._pop_all_modals()
	game.session.state.player = [12, 10, 0]
	game.view.sync_player(game.session.state)
	game.session.read_inspection("job-board")
	game._pop_all_modals()
	# The stair lantern's page.
	game.session.state.player = [5, 11, 0]
	game.view.sync_player(game.session.state)
	game._activate_device("landing-lamp")
	await _frames(20)
	var jobs := game.movement_lesson as WorkshopJobsJournal
	if jobs == null:
		printerr("The lantern page did not open")
		quit(1)
		return
	await _shot("04-lantern-page")
	await jobs.preview()
	await _frames(60)
	await _shot("05-lantern-starter-replay")
	jobs.editor.text = LIGHT
	await process_frame
	await jobs.preview()
	await _frames(60)
	await _shot("06-lantern-ghost")
	jobs.apply_routine()
	game.close_notebook(true)
	game._pop_all_modals()
	# The whole round at the wall screen.
	game.session.state.player = [1, 2, 0]
	game.view.sync_player(game.session.state)
	game._activate_terminal("workshop-terminal")
	await _frames(20)
	jobs = game.movement_lesson as WorkshopJobsJournal
	await _shot("07-round-page")
	await jobs.preview()
	await _frames(80)
	await _shot("08-round-starter-replay")
	jobs.editor.text = ROUND
	await process_frame
	await jobs.preview()
	await _frames(100)
	await _shot("09-round-ghost")
	jobs._notepad.select(&"names")
	await _shot("10-round-names")
	jobs._notepad.select(&"hints")
	for button: Node in jobs._notepad.page(&"hints").find_children("*", "FButton", true, false):
		(button as FButton).pressed.emit()
		(button as FButton).pressed.emit()
	await _shot("11-round-hints")
	jobs._notepad.select(&"index")
	await _shot("12-round-index")
	# The real starter, as a new player sees it: a TODO marks the area to fix.
	jobs._notepad.select(&"job")
	jobs.editor.text = str(game.area.quest("morning-round").starter)
	await process_frame
	await jobs.preview()
	await _frames(40)
	await _shot("13-round-starter-todo")
	# What a name is: the hover card over workshop.lamps, and the lamps list opened in VARIABLES.
	await _frames(60)
	var spot: Rect2i = jobs.editor.get_rect_at_line_column(5, 25)
	var description: Dictionary = CodeLookup.describe(jobs.editor.text, "workshop.lamps", jobs._link_picture())
	jobs._expanded["lamps"] = true
	jobs._show_variables(jobs._shown_names)
	jobs._hover.present(description, jobs.editor.get_global_rect().position + Vector2(spot.position) + Vector2(0, 14), true)
	await _shot("14-hover-and-list")
	jobs._hover.dismiss()
	# The finished job, then the notes put away.
	jobs.editor.text = ROUND
	await process_frame
	await jobs.preview()
	await _frames(30)
	await _shot("15-debug-would-finish")
	jobs.apply_routine()
	await _frames(20)
	await _shot("16-job-done")
	jobs._tuck(true)
	await _frames(30)
	await _shot("17-notes-put-away")
	jobs._tuck(false)
	SaveStore.delete("sparks-and-machines")
	quit(0)


func _frames(count: int) -> void:
	for _i: int in range(count): await process_frame


func _shot(name: String) -> void:
	await _frames(6)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))
	print("shot ", name)
