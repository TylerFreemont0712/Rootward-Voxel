extends SceneTree
## The session and the whole game, driven the way a player drives them: grid steps, real Python through the
## notebook, preview/apply/undo, quests, saves, menus and keyboard flow.

const SCRATCH_SAVE: String = "user://test_save.json"
const SCRATCH_PROFILE: String = "user://test_profile.json"
var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _session_tests()
	await _game_tests()
	_cleanup()
	if _failures.is_empty():
		print("Voxel app: %d checks passed (session, grid motion, previews, undo, quests, saves, menus)." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		quit(1)


## The first spot in a region where the rules let this item stand.
func _first_spot(ledger: BuildLedger, item_id: String, region: Rect2i, state: Dictionary) -> Vector2:
	var y: float = float(region.position.y)
	while y < float(region.end.y):
		var x: float = float(region.position.x)
		while x < float(region.end.x):
			if ledger.check_item(item_id, Vector2(x, y), "S", state).ok:
				return Vector2(x, y)
			x += 0.5
		y += 0.5
	return Vector2(-1, -1)


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame


func _session_tests() -> void:
	var area: AreaDef = AreaStore.load_area("rune-mill")
	var view := ClearingView.new()
	root.add_child(view)
	await process_frame
	view.setup(area)
	var session := GameSession.new()
	root.add_child(session)
	session.set_physics_process(false)
	session.begin(area, view)
	await process_frame
	var initial: Dictionary = session.state.duplicate(true)
	_check(view._body is SpriteAdventurer, "The animated sprite is the runtime character")
	var source: String = "def program(world):\n    bridge = world.bridge('bridge')\n    for cell in bridge.cells[:3]:\n        bridge.place_deck(cell)\n    world.gate('gate').set_open(True)\n"
	session.set_source(source)
	var prepared: bool = await session.run_preview()
	_check(prepared and session.has_preview() and session.state == initial, "Real Python produces a detached preview")
	_check(session.apply_preview() and session.state.bridges.bridge == 3, "Apply commits the built crossing")
	_check(session.walk_to(Vector2i(10, 5)) and session._route.size() == 6, "Click target plans the route")
	session._cancel_route()
	_check(session.request_step(Vector2i.RIGHT), "One grid step starts")
	session.advance_walk(LabWorld.STEP_SECONDS * 0.5)
	_check(session.state.player == [4, 5, 0] and view._player.position.x > 4.0 and view._player.position.x < 5.0, "Visual motion is smooth while authoritative coordinates stay on a cell")
	_check(not session.request_step(Vector2i.UP), "Direction changes wait for the current cell step")
	_check(not session.apply_preview(), "A program cannot change support halfway through a step")
	session.advance_walk(LabWorld.STEP_SECONDS * 0.5)
	_check(session.state.player == [5, 5, 0] and not session.is_walking(), "The step settles exactly on its destination")
	for _step: int in range(5):
		_check(session.request_step(Vector2i.RIGHT), "The built bridge permits the next step")
		session.advance_walk(LabWorld.STEP_SECONDS)
	_check(session.state.player == [10, 5, 0], "Repeated steps reach the other bank")
	prepared = await session.run_preview()
	_check(prepared and view._ghost.get_child_count() == 0, "A no-op preview after walking has no phantom changes")
	_check(session.undo_apply() and session.state.bridges.bridge == 0 and session.state.player == [10, 5, 0], "Undo removes the program's work but leaves the player where they stand")
	_check(session.state.memory.is_empty() and not session.state.gates.gate, "Undo restores memory and the gate too")
	session.reset_world()
	_check(session.state.player == [4, 5, 0], "Reset returns the player to the spawn")
	prepared = await session.run_preview()
	_check(prepared, "A fresh preview is available")
	session.request_step(Vector2i.LEFT)
	_check(not session.has_preview(), "Beginning a step immediately invalidates a preview")
	process_frame.connect(func() -> void: session.advance_walk(LabWorld.STEP_SECONDS), CONNECT_ONE_SHOT)
	prepared = await session.run_preview()
	_check(prepared and session.state.player == [3, 5, 0], "Run waits for a step to settle before taking its snapshot")
	session.set_source(source + "\n# edited\n")
	_check(not session.has_preview() and not session.apply_preview(), "Source edits invalidate Apply")
	session.request_step(Vector2i.RIGHT)
	session.reset_world()
	session.advance_walk(LabWorld.STEP_SECONDS)
	_check(session.state == session.rules.initial_state() and not session.is_walking() and session._route.is_empty(), "Reset cancels an in-flight step and route")
	process_frame.connect(func() -> void: session.set_source(source + "\n# changed during execution\n"), CONNECT_ONE_SHOT)
	prepared = await session.run_preview()
	_check(not prepared and not session.has_preview(), "An old worker result cannot restore a stale preview")
	session.set_source('def program(world):\n    return {"commands": [{"op": "unknown"}], "memory": {}}\n')
	prepared = await session.run_preview()
	_check(not prepared and session.state == session.rules.initial_state(), "Rejected commands keep the world intact")
	var failures: Array = []
	session.run_finished.connect(func(result: Dictionary) -> void: failures.append(result))
	session.set_source("def program(world):\n    world.lamp('lamp-west').set_lit(Ture)\n")
	await session.run_preview()
	_check(failures.size() == 1 and not failures[0].ok and failures[0].error.line == 2 and failures[0].advice.body.contains("'True'"), "A typo is reported with its line and a did-you-mean")
	# A blocked step, or a click on a cell that cannot be reached, turns the character toward it instead of doing nothing.
	session.reset_world()
	session.state.player = [6, 5, 0]
	view.sync_player(session.state)
	session.turn_toward(Vector2i.LEFT)
	_check(session.facing == Vector2i.LEFT and view._body.animation_name == "idle_nw", "The character can turn in place")
	_check(not session.request_step(Vector2i.RIGHT) and session.state.player == [6, 5, 0] and session.facing == Vector2i.RIGHT and view._body.animation_name == "idle_se", "Walking into the unbridged river faces the river")
	session.turn_toward(Vector2i.LEFT)
	session.click_cell(Vector2i(7, 5))
	_check(session.facing == Vector2i.RIGHT and view._body.animation_name == "idle_se", "Clicking water faces it")
	session.click_cell(Vector2i(10, 11))
	_check(session.facing == Vector2i(0, 1) and view._body.animation_name == "idle_ne", "Clicking a cell across the river faces its way (north is the larger part of the offset)")
	_check(not session.request_step(Vector2i(0, -1)) or session.facing == Vector2i(0, -1), "A free step still walks and sets the facing")
	session.reset_world()
	session.request_step(Vector2i.RIGHT)
	session.turn_toward(Vector2i.LEFT)
	_check(session.facing == Vector2i.RIGHT, "Turning is ignored while a step is in progress")
	session.advance_walk(LabWorld.STEP_SECONDS)
	var round_trip: Dictionary = JSON.parse_string(JSON.stringify(session.to_save()))
	var restored: Dictionary = session.rules.normalize_state(round_trip.state)
	_check(not restored.is_empty() and restored == session.state, "A state survives a JSON save round trip (floats become integers again)")
	var broken: Dictionary = round_trip.state.duplicate(true)
	broken.player = [400, 5, 0]
	_check(session.rules.normalize_state(broken).is_empty(), "A save with an impossible position is rejected")
	session.queue_free()
	view.queue_free()
	await process_frame


func _game_tests() -> void:
	SaveStore.save_path = SCRATCH_SAVE
	SaveStore.profile_path = SCRATCH_PROFILE
	SaveStore.force_enabled = true
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_PROFILE))
	var game: Game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(6)
	_check(game.title != null and not game.playing and not game.hud.visible, "The game opens on the title screen")
	_check(game.view.camera_mode == ClearingView.CameraMode.CINEMATIC, "The title shows the valley with a drifting camera")
	_check(_find_button(game.title, "Continue") == null and _find_button(game.title, "New journey") != null, "With no save, only a new journey is offered")
	await game.start_new_game()
	await _frames(4)
	_check(game.playing and game.hud.visible and game.title == null, "A new journey enters play")
	_check(game.view.camera_mode == ClearingView.CameraMode.FOLLOW, "Play uses the following camera")
	_check(SaveStore.has_save(), "Starting a journey writes a save")
	var session: GameSession = game.session
	_check(session.current_quest().id == "first-light" and session.state.player == [28, 3, 0], "The first quest is waiting at the landing")
	# The notebook slides over the world and the view makes room.
	game.open_notebook()
	await _frames(20)
	_check(game.notebook_open and game.notebook.visible and game.view._view_shift_target > 0.1, "Opening the notebook shifts the world view")
	_check(game.notebook.editor.text == session.source and game.notebook.lesson != null, "The notebook shows the session's program and lesson")
	# Real Python through the real controls: type a solution, press Ctrl+Enter, then Apply.
	game.notebook.editor.replace_program("def program(world):\n    lamp = world.lamp(\"landing-lamp\")\n    lamp.set_lit(True)\n")
	await _frames(3)
	_check(session.source.contains("set_lit(True)"), "Typing in the editor updates the session's source")
	var finished: Array = []
	session.run_finished.connect(func(result: Dictionary) -> void: finished.append(result))
	game._unhandled_key_input(_key(KEY_ENTER, true))
	while finished.is_empty():
		await process_frame
	_check(finished[0].ok and session.has_preview() and not game.notebook._apply_button.disabled, "Ctrl+Enter runs the program and enables Apply")
	_check(game.view._ghost.get_child_count() == 1, "The preview is drawn in the world as a proposal")
	session.apply_preview()
	await _frames(4)
	_check(session.completed == ["first-light"] and session.current_quest().id == "light-the-green", "Lighting the landing lamp completes the first quest")
	_check(game.view._lit_positions.size() == 1 and game.view._warmth_target > 0.28, "A lit lamp warms the valley")
	game.save_now()
	_check(SaveStore.read().completed == ["first-light"], "Progress is saved")
	# Escape peels back one layer at a time: text focus, then the notebook, then the pause menu.
	game.notebook.editor.grab_focus()
	await process_frame
	game._unhandled_key_input(_key(KEY_ESCAPE))
	_check(not game.notebook.has_text_focus() and game.notebook_open, "Escape first leaves the text field")
	game._unhandled_key_input(_key(KEY_ESCAPE))
	_check(not game.notebook_open and game._modals.is_empty(), "Escape then closes the notebook")
	game._unhandled_key_input(_key(KEY_ESCAPE))
	_check(game._modals.size() == 1 and game._modals[0] is PauseMenu and not session.input_enabled, "Escape then opens the pause menu and freezes walking")
	game._modals[0]._unhandled_key_input(_key(KEY_ESCAPE))
	await process_frame
	_check(game._modals.is_empty() and session.input_enabled, "Escape closes the menu and walking resumes")
	# The other screens open and close cleanly.
	for opener: Callable in [game.open_journal, game.open_map, game.open_settings, func() -> void: game._open_character("view", {})]:
		opener.call()
		await _frames(3)
		_check(game._modals.size() == 1, "A modal screen opens")
		game._modals[-1].close()
		await process_frame
	game.open_pause()
	game.open_settings()
	await _frames(3)
	_check(game._modals.size() == 2 and not game._modals[0].visible and game._modals[1].visible, "Settings opens above the pause menu and hides it")
	game._modals[1].close()
	await process_frame
	_check(game._modals.size() == 1 and game._modals[0].visible, "Closing settings returns to the pause menu")
	game._pop_all_modals()
	await _real_key_tests(game)
	# The character screen renames the hero everywhere.
	game._open_character("view", {})
	await _frames(3)
	var screen := game._modals[-1] as CharacterScreen
	screen._name_edit.text = "Ash"
	screen._commit_name()
	_check(SaveStore.player_name() == "Ash" and session.player_name == "Ash", "A new name is saved and used")
	_check(screen._actor != null and screen._actor.sprite != null, "The character screen shows the painted adventurer")
	screen._turn(1)
	_check(str(screen._actor.animation_name) == "idle_sw", "Turning the character shows another painted view")
	_check(screen._skin_buttons.has("adventurer") and not screen._skin_buttons.has("mira") and not screen._skin_buttons.has("adventurer_twilight"), "The boy is the player; Mira and other residents are not player appearances")
	var before_appearance: Dictionary = session.state.duplicate(true)
	screen._select_skin("mira")
	_check(screen._actor.skin_id == "adventurer" and (game.view._body as SpriteAdventurer).skin_id == "adventurer", "A resident skin cannot replace the playable boy")
	_check(game.settings.get_value("character_skin") == "adventurer" and session.state == before_appearance and session.player_name == "Ash", "Player identity stays separate from world state and chosen name")
	_check(str(screen._actor.animation_name) == "idle_sw", "Appearance selection retains the portrait facing")
	game._pop_all_modals()
	game._open_character("view", {})
	_check((game._modals[-1] as CharacterScreen)._actor.skin_id == "adventurer", "Reopening Character shows the boy")
	game._pop_all_modals()
	game.settings.set_value("character_skin", "unknown")
	game.settings.set_value("character_skin", "adventurer_twilight")
	_check(game.settings.get_value("character_skin") == "adventurer", "Invalid and hidden appearance settings leave the boy unchanged")
	# Walking through the real input path: a click plans a route, steps follow, a zone is discovered.
	game.close_notebook(true)
	var target := Vector2i(29, 14)
	session.click_cell(target)
	_check(not session._route.is_empty(), "A click on the world plans a route")
	var guard: int = 0
	while session.player_cell() != target and guard < 400:
		session._physics_process(1.0 / 60.0)
		guard += 1
	_check(session.player_cell() == target and (session.state.zones_seen as Array).has("green"), "Following the route discovers The Green")
	_check(session.current_zone == "green" and game.hud._location.text.contains("The Green"), "The HUD names the zone you enter")
	# Settings change the world view live.
	game.settings.set_value("zoom", 16.0)
	_check(is_equal_approx(game.view.zoom(), 16.0), "Camera zoom follows the setting")
	# Save, return to the title, continue: the world comes back as it was.
	var lit_before: int = session.lamps_lit()
	await game._return_to_title()
	await _frames(4)
	_check(not game.playing and game.title != null and _find_button(game.title, "Continue") != null, "Returning to the title offers Continue")
	await game.continue_game()
	await _frames(4)
	_check(game.playing and session.lamps_lit() == lit_before and session.completed == ["first-light"] and session.player_cell() == target, "Continue restores the lamps, quests and position")
	_check((session.state.zones_seen as Array).has("green"), "Continue remembers what you discovered")
	_check((game.view._body as SpriteAdventurer).skin_id == "adventurer", "Continue keeps the boy as the player")
	# What the player builds is part of the save: place a house and a tree, leave, come back.
	var base_trees: int = game.area.trees.size()
	var base_buildings: int = game.area.buildings.size()
	var house_result: Dictionary = game.ledger.place("house-hollow", Vector2(34, 4), "S", session.state)
	var oak_spot: Vector2 = _first_spot(game.ledger, "tree-oak", Rect2i(38, 2, 8, 8), session.state)
	var oak_result: Dictionary = game.ledger.place("tree-oak", oak_spot, "S", session.state)
	_check(house_result.ok and oak_result.ok, "The ledger accepts a house and a tree (%s / %s)" % [str(house_result.get("reason")), str(oak_result.get("reason"))])
	game.area = game.ledger.area
	session.replace_area(game.ledger.area, game.ledger.rules)
	game.view.sync_edits(game.area, false)
	_check(session.area == game.ledger.area and session.rules == game.ledger.rules and game.view.building_node("build-1") != null and game.view._drawn_trees.size() == base_trees + 1, "A placed house and tree are drawn, and the session plays by the new world")
	game.save_now()
	_check((SaveStore.read().get("edits", []) as Array).size() == 2, "The edits are written into the save")
	await game._return_to_title()
	await _frames(4)
	await game.continue_game()
	await _frames(4)
	_check(game.ledger.edits.size() == 2 and game.area.buildings.size() == base_buildings + 1 and game.area.building("build-1").asset == "log-cabin-large" and game.view.building_node("build-1") != null, "Continue restores what you built")
	_check(game.area.trees.size() == base_trees + 1 and session.area == game.area and session.lamps_lit() == lit_before, "...with the trees, the new world's rules and the lamps as they were")
	session.reset_world()
	_check(session.lamps_lit() == 0 and session.completed == ["first-light"] and (session.state.zones_seen as Array).has("green") and game.ledger.edits.size() == 2, "Reset darkens the world but keeps progress, discoveries and what you built")
	# Starting over replaces the save.
	await game.start_new_game()
	await _frames(4)
	_check(session.completed.is_empty() and session.state.player == [28, 3, 0], "A new journey starts from the beginning")
	_check(game.ledger.edits.is_empty() and game.area.building("build-1").is_empty() and game.view.building_node("build-1") == null and game.area.trees.size() == base_trees, "...in an unbuilt valley")
	_check((game.view._body as SpriteAdventurer).skin_id == "adventurer", "A new journey keeps the boy as the player")
	game.queue_free()
	await process_frame


## The same shortcuts, but through Godot's real input routing: key events go to the focused control first
## and only reach the game's handlers if nothing consumed them.
func _real_key_tests(game: Game) -> void:
	var session: GameSession = game.session
	await _tap(KEY_E)
	_check(game.notebook_open and game.notebook.editor.has_focus(), "E opens the notebook and puts the cursor in the editor")
	game.notebook.editor.replace_program("def program(world):\n    world.lamp('landing-lamp').set_lit(True)\n")
	await _frames(4)
	await _tap(KEY_ENTER, true)
	var waited: int = 0
	while not session.has_preview() and waited < 300:
		await process_frame
		waited += 1
	_check(session.has_preview(), "Ctrl+Enter typed in the editor runs the program")
	await _tap(KEY_ESCAPE)
	_check(not game.notebook.has_text_focus() and game.notebook_open, "Escape first leaves the editor")
	await _tap(KEY_ESCAPE)
	_check(not game.notebook_open and game._modals.is_empty(), "Escape then closes the notebook")
	await _tap(KEY_ESCAPE)
	_check(game._modals.size() == 1 and game._modals[0] is PauseMenu, "Escape then opens the pause menu")
	await _tap(KEY_ESCAPE)
	_check(game._modals.is_empty(), "Escape closes the pause menu")
	await _tap(KEY_M)
	_check(game._modals.size() == 1 and game._modals[0] is MapPanel, "M opens the map")
	await _tap(KEY_ESCAPE)
	await _tap(KEY_J)
	_check(game._modals.size() == 1 and game._modals[0] is JournalPanel, "J opens the journal")
	await _tap(KEY_ESCAPE)
	_check(game._modals.is_empty(), "Escape closes it again")


func _tap(code: Key, ctrl: bool = false) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.ctrl_pressed = ctrl
		Input.parse_input_event(event)
		await process_frame
	await process_frame


func _find_button(node: Node, label: String) -> FButton:
	if node is FButton and (node as FButton).text == label:
		return node
	for child: Node in node.get_children():
		var found: FButton = _find_button(child, label)
		if found != null:
			return found
	return null


func _key(keycode: Key, ctrl: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.ctrl_pressed = ctrl
	return event


func _cleanup() -> void:
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_PROFILE))
	SaveStore.force_enabled = false


func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
