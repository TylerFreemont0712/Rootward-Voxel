extends SceneTree
## The session and the whole game, driven the way a player drives them: grid steps, saves, menus and keyboard flow,
## over Sparks & Machines (the only journey that ships). Python, previews and quests are proved in the room tests.

var SCRATCH_SAVE: String = "user://test_save_%d.json" % OS.get_process_id()
var SCRATCH_PROFILE: String = "user://test_profile_%d.json" % OS.get_process_id()
var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _session_tests()
	await _game_tests()
	_cleanup()
	if _failures.is_empty():
		print("Voxel app: %d checks passed (session, grid motion, saves, menus, character, keyboard)." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		quit(1)


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame


func _session_tests() -> void:
	var area: AreaDef = AreaStore.load_area("shop-bakery")
	var view := ClearingView.new()
	root.add_child(view)
	await process_frame
	view.setup(area)
	var session := GameSession.new()
	root.add_child(session)
	session.set_physics_process(false)
	session.begin(area, view)
	await process_frame
	var start: Vector2i = session.player_cell()
	_check(view._body is SpriteAdventurer, "The animated sprite is the runtime character")
	var step: Vector2i = _open_step(session)
	_check(step != Vector2i.ZERO and session.walk_to(start + step * 2) and session._route.size() == 2, "Click target plans the route")
	session._cancel_route()
	_check(session.request_step(step), "One grid step starts")
	session.advance_walk(LabWorld.STEP_SECONDS * 0.5)
	_check(session.player_cell() == start and view._player.position.distance_to(Vector3(start.x, view._player.position.y, -start.y)) > 0.1, "Visual motion is smooth while authoritative coordinates stay on a cell")
	_check(not session.request_step(Vector2i(-step.y, step.x)), "Direction changes wait for the current cell step")
	session.advance_walk(LabWorld.STEP_SECONDS * 0.5)
	_check(session.player_cell() == start + step and not session.is_walking(), "The step settles exactly on its destination")
	session.reset_world()
	_check(session.player_cell() == start, "Reset returns the player to the spawn")
	session.request_step(step)
	session.reset_world()
	session.advance_walk(LabWorld.STEP_SECONDS)
	_check(session.player_cell() == start and not session.is_walking() and session._route.is_empty(), "Reset cancels an in-flight step and route")
	# A blocked step turns the character toward it instead of doing nothing.
	session.turn_toward(Vector2i.LEFT)
	_check(session.facing == Vector2i.LEFT and view._body.animation_name == "idle_nw", "The character can turn in place")
	session.request_step(step)
	session.turn_toward(-step)
	_check(session.facing == step, "Turning is ignored while a step is in progress")
	session.advance_walk(LabWorld.STEP_SECONDS)
	var round_trip: Dictionary = JSON.parse_string(JSON.stringify(session.to_save()))
	var restored: Dictionary = session.rules.normalize_state(round_trip.state)
	_check(not restored.is_empty() and restored.player == session.state.player and restored.lamps == session.state.lamps, "A state survives a JSON save round trip (floats become integers again)")
	var broken: Dictionary = round_trip.state.duplicate(true)
	broken.player = [400, 5, 0]
	_check(session.rules.normalize_state(broken).is_empty(), "A save with an impossible position is rejected")
	session.queue_free()
	view.queue_free()
	await process_frame


## A direction the traveller can walk twice from where they stand.
func _open_step(session: GameSession) -> Vector2i:
	for step: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
		var first: Dictionary = session.rules.move(session.state, step)
		if first.ok and session.rules.move(first.state, step).ok:
			return step
	return Vector2i.ZERO


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
	_check(game.area.id == "workshop-loft" and game.view.camera_mode == ClearingView.CameraMode.FIXED, "The title opens over the Sparks loft")
	_check(_find_button(game.title, "Continue") == null and _find_button(game.title, "New game") != null, "The main title offers a new Sparks game")
	_check(LevelStore.entries().size() == 1 and LevelStore.entries()[0].id == LevelStore.MAIN_LEVEL, "Sparks & Machines is the only journey")
	await game.start_new_game(LevelStore.MAIN_LEVEL)
	await _frames(4)
	_check(game.playing and game.hud.visible and game.title == null, "A new journey enters play")
	_check(game.view.camera_mode == ClearingView.CameraMode.FOLLOW, "Play uses the following camera")
	_check(SaveStore.has_save(LevelStore.MAIN_LEVEL), "Starting a journey writes a save")
	var session: GameSession = game.session
	game._pop_all_modals()
	game.close_notebook(true)
	# Escape peels back one layer at a time and walking freezes while a menu is up.
	game._unhandled_key_input(_key(KEY_ESCAPE))
	_check(game._modals.size() == 1 and game._modals[0] is PauseMenu and not session.input_enabled, "Escape opens the pause menu and freezes walking")
	game._modals[0]._unhandled_key_input(_key(KEY_ESCAPE))
	await process_frame
	_check(game._modals.is_empty() and session.input_enabled, "Escape closes the menu and walking resumes")
	# The other screens open and close cleanly.
	for opener: Callable in [game.open_map, game.open_settings, func() -> void: game._open_character("view", {})]:
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
	_check(screen._skin_buttons.has("adventurer") and not screen._skin_buttons.has("mira") and not screen._skin_buttons.has("adventurer_twilight"), "The boy is the player; the residents are not player appearances")
	var before_appearance: Dictionary = session.state.duplicate(true)
	screen._select_skin("mira")
	_check(screen._actor.skin_id == "adventurer" and (game.view._body as SpriteAdventurer).skin_id == "adventurer", "A resident skin cannot replace the playable boy")
	_check(game.settings.get_value("character_skin") == "adventurer" and session.state == before_appearance and session.player_name == "Ash", "Player identity stays separate from world state and chosen name")
	game._pop_all_modals()
	game.settings.set_value("character_skin", "unknown")
	game.settings.set_value("character_skin", "adventurer_twilight")
	_check(game.settings.get_value("character_skin") == "adventurer", "Invalid and hidden appearance settings leave the boy unchanged")
	# Settings change the world view live.
	game.settings.set_value("zoom", 16.0)
	_check(game._indoors() or is_equal_approx(game.view.zoom(), 16.0), "Camera zoom follows the setting outdoors")
	# Walking through the real input path, then save, return to the title and continue.
	var step: Vector2i = _open_step(session)
	var target: Vector2i = session.player_cell() + step * 2
	session.click_cell(target)
	_check(not session._route.is_empty(), "A click on the world plans a route")
	var guard: int = 0
	while session.player_cell() != target and guard < 400:
		session._physics_process(1.0 / 60.0)
		guard += 1
	_check(session.player_cell() == target, "Following the route reaches the target")
	session.state.memory = {"kept": 7}
	game.save_now()
	await game._return_to_title()
	await _frames(4)
	_check(not game.playing and game.title != null and _find_button(game.title, "Continue") != null, "A saved journey offers Continue")
	await game.continue_game()
	await _frames(4)
	_check(game.playing and game.session.player_cell() == target and game.session.state.memory.get("kept") == 7, "Continue restores the position and program memory")
	_check((game.view._body as SpriteAdventurer).skin_id == "adventurer", "Continue keeps the boy as the player")
	# Starting over replaces the save.
	await game.start_new_game(LevelStore.MAIN_LEVEL)
	await _frames(4)
	_check(game.session.state.memory.is_empty() and game.session.player_cell() != target, "A new journey starts from the beginning")
	game.queue_free()
	await process_frame


## The same shortcuts, but through Godot's real input routing: key events go to the focused control first
## and only reach the game's handlers if nothing consumed them.
func _real_key_tests(game: Game) -> void:
	game._pop_all_modals()
	await _tap(KEY_ESCAPE)
	_check(game._modals.size() == 1 and game._modals[0] is PauseMenu, "Escape opens the pause menu")
	await _tap(KEY_ESCAPE)
	_check(game._modals.is_empty(), "Escape closes the pause menu")
	await _tap(KEY_M)
	_check(game._modals.size() == 1 and game._modals[0] is MapPanel, "M opens the map")
	await _tap(KEY_ESCAPE)
	_check(game._modals.is_empty(), "Escape closes the map again")


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
	SaveStore.delete(LevelStore.MAIN_LEVEL)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_PROFILE))
	SaveStore.force_enabled = false


func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
