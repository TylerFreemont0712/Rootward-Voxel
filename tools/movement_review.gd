extends SceneTree
## Review actual mouse/held-key input against the grid controller in the real game, not a scripted teleport:
## click-walk to the river, build the bridge through the notebook, click across it, then hold a key,
## release it, and check that typing in the editor does not move the player.

var game: Game
var session: GameSession


func _initialize() -> void:
	_review.call_deferred()


func _review() -> void:
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await physics_frame
	await game.start_new_game("kindle-hollow")
	session = game.session
	root.grab_focus()
	game.surface.grab_focus()
	var directory: String = ProjectSettings.globalize_path("res://.cache/grid-review")
	DirAccess.make_dir_recursive_absolute(directory)
	# 1. Clicks on visible cells plan routes; the camera follows, so the way to the river is a few clicks.
	var click_planned: bool = false
	var captured: int = 0
	var frame: int = 0
	var reached_bank: bool = true
	for waypoint: Vector2i in [Vector2i(29, 11), Vector2i(29, 18), Vector2i(36, 19), Vector2i(42, 19)]:
		_click_cell(waypoint)
		for _wait: int in range(5):
			await physics_frame
			if not session._route.is_empty() or session.is_walking():
				click_planned = true
				break
		var limit: int = frame + 600
		while session.player_cell() != waypoint and frame < limit:
			await physics_frame
			await RenderingServer.frame_post_draw
			if frame % 20 == 0:
				game.world_viewport.get_texture().get_image().save_png(directory.path_join("frame-%03d.png" % captured))
				captured += 1
			frame += 1
		reached_bank = reached_bank and session.player_cell() == waypoint
	# 2. The notebook's program builds the bridge; Apply commits that exact preview.
	game.open_notebook()
	game.notebook.editor.replace_program("def program(world):\n    bridge = world.bridge(\"mill-bridge\")\n    deck_count = 4\n    for cell in bridge.cells[:deck_count]:\n        bridge.place_deck(cell)\n")
	for _wait: int in range(3):
		await physics_frame
	var prepared: bool = await session.run_preview()
	var applied: bool = prepared and session.apply_preview()
	game.close_notebook()
	for _frame: int in range(20):
		await physics_frame
	# 3. Click the far bank; the route crosses the new decks.
	_click_cell(Vector2i(48, 19))
	frame = 0
	while session.player_cell() != Vector2i(48, 19) and frame < 900:
		await physics_frame
		frame += 1
	var crossed: bool = session.player_cell() == Vector2i(48, 19)
	# 4. Holding a key repeats steps; releasing stops on a cell; the editor takes the keyboard.
	var before: Vector2i = session.player_cell()
	_key(KEY_S, true)
	for _frame: int in range(49):
		await physics_frame
	_key(KEY_S, false)
	while session.is_walking():
		await physics_frame
	var held_repeat: bool = before.y - session.player_cell().y >= 2 and before.x == session.player_cell().x
	var stable: Vector2i = session.player_cell()
	for _frame: int in range(10):
		await physics_frame
	var stops_on_release: bool = session.player_cell() == stable
	game.open_notebook()
	game.notebook.editor.grab_focus()
	_key(KEY_W, true)
	for _frame: int in range(18):
		await physics_frame
	_key(KEY_W, false)
	var typing_safe: bool = session.player_cell() == stable
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://evidence/sprite-movement.png"))
	print("Live grid review: click planned=", click_planned, ", reached bank=", reached_bank, ", bridge applied=", applied, ", crossed by click=", crossed,
		", held key repeats=", held_repeat, ", release stops on cell=", stops_on_release, ", editor focus prevents movement=", typing_safe, ", final cell=", session.player_cell(), ", captures=", captured)
	quit(0 if click_planned and reached_bank and applied and crossed and held_repeat and stops_on_release and typing_safe else 1)


func _click_cell(cell: Vector2i) -> void:
	var projected: Vector2 = game.view.camera.unproject_position(Vector3(cell.x, 0.05, -cell.y))
	var point: Vector2 = game.surface.global_position + projected * game.surface.size / Vector2(game.world_viewport.size)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
