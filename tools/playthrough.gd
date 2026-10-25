extends SceneTree
## Plays the whole level through the real game: walk to each place, type the reference solution into
## the notebook, Run, Apply, and watch the quest complete. Saves a PNG after every quest, then the
## finale and the epilogue. It is the end-to-end proof that the level can be finished.
## Usage: -- <absolute output directory>

const Solutions := preload("res://test/test_area.gd")
var game: Game
var session: GameSession
var out: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "/tmp/playthrough"
	DirAccess.make_dir_recursive_absolute(out)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await physics_frame
	await game.start_new_game()
	session = game.session
	var step: int = 1
	var failed: bool = false
	for quest: Dictionary in Quests.main(session.area):
		var id: String = quest.id
		for cell: Vector2i in Solutions.VISITS.get(id, []):
			await _walk(cell)
		game.open_notebook()
		game.notebook.editor.replace_program(Solutions.SOLUTIONS[id])
		await _frames(4)
		await session.run_preview()
		await _frames(8)
		await _shot("%02d-%s-preview" % [step, id])
		session.apply_preview()
		if id == "mill-bridge":
			game.close_notebook()
			await _walk(Vector2i(48, 19))
		await _frames(40)
		if not session.completed.has(id):
			printerr("Quest %s did not complete" % id)
			failed = true
		await _shot("%02d-%s-done" % [step, id])
		step += 1
	game.close_notebook()
	await _frames(70)
	await _shot("%02d-celebration-ring" % step)
	var waited: int = 0
	while game._modals.is_empty() and waited < 600:
		await process_frame
		waited += 1
	await _frames(25)
	await _shot("%02d-epilogue" % (step + 1))
	if not game._modals.is_empty():
		game._modals[-1].close()
	await _frames(5)
	# The optional second chapter, taken after the epilogue.
	for quest: Dictionary in session.area.quests:
		if not quest.optional:
			continue
		var chapter_id: String = quest.id
		for cell: Vector2i in Solutions.VISITS.get(chapter_id, []):
			await _walk(cell)
		game.open_notebook()
		game.notebook.editor.replace_program(Solutions.SOLUTIONS[chapter_id])
		await _frames(4)
		await session.run_preview()
		await _frames(8)
		await _shot("%02d-%s-preview" % [step + 3, chapter_id])
		session.apply_preview()
		await _frames(40)
		if not session.completed.has(chapter_id):
			printerr("Quest %s did not complete" % chapter_id)
			failed = true
		await _shot("%02d-%s-done" % [step + 3, chapter_id])
		game.close_notebook()
		step += 1
	await _walk(Vector2i(30, 43))
	await _frames(150)
	await _shot("%02d-beacon-lit" % (step + 2))
	print("Playthrough: ", session.completed.size(), " of ", session.area.quests.size(), " quests complete, ", session.lamps_lit(), " lamps lit, failed=", failed)
	quit(1 if failed or session.completed.size() != session.area.quests.size() else 0)


func _walk(cell: Vector2i) -> void:
	Engine.time_scale = 5.0
	var route_started: bool = session.walk_to(cell)
	var guard: int = 0
	while session.player_cell() != cell and guard < 3000 and route_started:
		await physics_frame
		guard += 1
	Engine.time_scale = 1.0
	await _frames(6)


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("shot ", name)
