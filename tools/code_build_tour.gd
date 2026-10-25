extends SceneTree
## Drives "code that builds" through the real game and saves a PNG of each state, for review at gameplay size:
## the optional second chapter's lesson and its journal heading, the notebook's World tab listing houses, a Run
## preview with ghosts for the houses that would turn, the applied result, and build mode's Code section for a
## house. The five main lessons are marked finished first, so "Face the lane" is the current lesson (it hands over
## the abilities). Usage: -- <absolute output directory>

const PROGRAM: String = "def program(world):\n    row = world.zone(\"cottage-row\")\n    for house in row.houses:\n        if house.cell[1] < 18:\n            house.face(\"north\")\n"
var game: Game
var out: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "/tmp/code_build_tour"
	DirAccess.make_dir_recursive_absolute(out)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(30)
	await game.start_new_game()
	await _frames(40)
	var session: GameSession = game.session
	session.completed.assign(["first-light", "light-the-green", "mill-bridge", "night-gate", "kindle-the-hollow"])
	session._after_change()
	session.state.zones_seen.append("cottage-row")
	game.view.set_camera_mode(ClearingView.CameraMode.FREE)
	game.view.focus_on(Vector2(13, 18.5), true)
	game.view.set_zoom(12.0)
	await _frames(30)
	game.open_notebook()
	session.set_source(PROGRAM)
	game.notebook.reload_from_session()
	await _frames(40)
	game.notebook.show_tab("Lesson")
	await _frames(20)
	await _shot("36-lesson")
	game.notebook.show_tab("World")
	await _frames(20)
	await _shot("30-world-tab")
	game.notebook.show_tab("Reference")
	await _frames(20)
	await _shot("31-reference")
	game.notebook.show_tab("Code")
	await _frames(10)
	session.set_source(PROGRAM)
	await session.run_preview()
	await _frames(40)
	await _shot("32-preview")
	session.apply_preview()
	await _frames(60)
	await _shot("33-applied")
	session.undo_apply()
	await _frames(40)
	await _shot("34-undone")
	game.close_notebook(true)
	await _frames(10)
	game.open_journal()
	await _frames(30)
	await _shot("37-journal")
	game._pop_all_modals()
	await _frames(10)
	game.open_build()
	await _frames(40)
	var builder: BuildMode = game.builder
	builder.set_tool(BuildMode.Tool.MOVE)
	var house: Dictionary = game.area.building("row-south-a")
	builder._select({"kind": "building", "id": "row-south-a", "locked": false, "at": house.at})
	game.view.focus_on(house.at, true)
	await _frames(50)
	await _shot("35-build-code")
	print("Code-build tour saved to ", out)
	quit(0)


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
