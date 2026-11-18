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
	var view := WorldView.new()
	root.add_child(view)
	await process_frame
	view.setup(area)
	var session := GameSession.new()
	root.add_child(session)
	session.set_physics_process(false)
	session.begin(area, view)
	await process_frame
	var start: Vector2i = session.player_cell()
	_check(view._body is SpriteActor, "The animated sprite is the runtime character")
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
	SaveRepo.root = SCRATCH_SAVE
	SaveRepo.force_enabled = true
	SaveRepo.wipe()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_PROFILE))
	var game: Game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(6)
	_check(game.title != null and not game.playing and not game.hud.visible, "The game opens on the title screen")
	_check(game.area.id == "workshop-loft" and game.view.camera_mode == WorldView.CameraMode.FIXED, "The title opens over the Sparks loft")
	_check(_find_button(game.title, "Load game") == null and _find_button(game.title, "Continue") == null and _find_button(game.title, "New game") != null, "The main title offers a new Sparks game and nothing to load")
	_check(LevelStore.entries().size() == 1 and LevelStore.entries()[0].id == LevelStore.MAIN_LEVEL, "Sparks & Machines is the only journey")
	await game.start_new_game(LevelStore.MAIN_LEVEL)
	await _frames(4)
	_check(game.playing and game.hud.visible and game.title == null, "A new journey enters play")
	_check(game.view.camera_mode == WorldView.CameraMode.FOLLOW, "Play uses the following camera")
	_check(SaveRepo.has_journey(), "Starting a journey writes a save")
	var session: GameSession = game.session
	game._pop_all_modals()
	game.close_notebook(true)
	# Before the tablet is picked up, Escape only asks whether to leave.
	game._unhandled_key_input(_key(KEY_ESCAPE))
	_check(game._modals.size() == 1 and not (game._modals[0] is TabletShell) and _find_button(game._modals[0], "Keep playing") != null, "Without the tablet, Escape offers only to keep playing, return or quit")
	game._pop_all_modals()
	session.state.items = ["field-tablet"]
	# Escape peels back one layer at a time and walking freezes while a menu is up.
	game._unhandled_key_input(_key(KEY_ESCAPE))
	_check(game._modals.size() == 1 and game._modals[0] is TabletShell and not session.input_enabled, "Escape opens the pause menu and freezes walking")
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
	game.open_tablet()
	game.open_settings()
	await _frames(3)
	_check(game._modals.size() == 2 and not game._modals[0].visible and game._modals[1].visible, "A modal above the tablet hides it")
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
	_check(SaveRepo.player_name() == "Ash" and session.player_name == "Ash", "A new name is saved and used")
	_check(screen._actor != null and screen._actor.sprite != null, "The character screen shows the painted adventurer")
	screen._turn(1)
	_check(str(screen._actor.animation_name) == "idle_sw", "Turning the character shows another painted view")
	_check(screen._skin_buttons.has("adventurer") and not screen._skin_buttons.has("village_mira") and not screen._skin_buttons.has("adventurer_twilight"), "The boy is the player; the residents are not player appearances")
	var before_appearance: Dictionary = session.state.duplicate(true)
	screen._select_skin("village_mira")
	_check(screen._actor.skin_id == "adventurer" and (game.view._body as SpriteActor).skin_id == "adventurer", "A resident skin cannot replace the playable boy")
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
	game.commit_progress("test save")
	await game._return_to_title()
	await _frames(4)
	_check(not game.playing and game.title != null and _find_button(game.title, "Load game") != null and _find_button(game.title, "Continue") == null, "A committed journey offers Load game, never Continue")
	await game.continue_game()
	await _frames(4)
	_check(game.playing and game.session.player_cell() == target and game.session.state.memory.get("kept") == 7, "Continue restores the position and program memory")
	_check((game.view._body as SpriteActor).skin_id == "adventurer", "Continue keeps the boy as the player")
	await _terminal_tests(game)
	# Starting over replaces the save.
	await game.start_new_game(LevelStore.MAIN_LEVEL)
	await _frames(4)
	_check(game.session.state.memory.is_empty() and game.session.player_cell() != target, "A new journey starts from the beginning")
	game.queue_free()
	await process_frame


## Saving is git: the tablet's terminal commits, branches and switches, the load screen graphs it,
## and leaving with uncommitted work asks first (docs/concept/save-vcs/PLAN.md).
func _terminal_tests(game: Game) -> void:
	game.open_tablet()
	await _frames(2)
	var tablet := game._modals[-1] as TabletShell
	_check(tablet != null, "The menu is the field tablet")
	tablet.open_terminal()
	await _frames(2)
	var terminal := tablet._app as TerminalApp
	_check(terminal != null, "The tablet opens its terminal")
	tablet.open_settings()
	await _frames(2)
	_check(tablet._app is SettingsSheet, "Settings is an app on the tablet")
	tablet.show_home()
	tablet.open_saves()
	await _frames(2)
	var saves := tablet._app as SavesBrowser
	_check(saves != null and saves.portrait and saves._command.text == "git switch main" and saves._repo_title.text.contains("current"), "Saves is an app on the tablet, showing the current repository and HEAD's branch")
	var window: Window = game.get_window()
	var before: Vector2 = tablet.card.custom_minimum_size * window.content_scale_factor
	game.settings.set_value("ui_scale", 1.4)
	await _frames(2)
	var after: Vector2 = tablet.card.custom_minimum_size * window.content_scale_factor
	_check(absf(before.x - after.x) < 1.0 and absf(before.x - TabletShell.slate_size(game.get_viewport_rect().size * window.content_scale_factor).x) < 1.0, "The slate keeps its width on screen across an interface scale change")
	var journal := JobsJournal.new()
	game.add_child(journal)
	_check(absf(journal._wanted_width() - tablet.card.custom_minimum_size.x) < 1.0, "The code slate and the menu slate share one width rule")
	journal.queue_free()
	game.settings.set_value("ui_scale", 1.0)
	tablet.show_home()
	tablet.open_terminal()
	await _frames(2)
	terminal = tablet._app as TerminalApp
	var status: String = GitShell.plain(terminal.run_line("git status").output)
	_check(status.contains("On branch main") and not status.contains("state.json") and not status.contains("Untracked"), "A freshly continued journey has nothing changed but the clock: " + status)
	game.session.state.lamps[game.session.state.lamps.keys()[0]] = true
	_check(GitShell.plain(terminal.run_line("reset").output).begins_with("Room reset") and not game.session.state.lamps.values().has(true), "reset is a terminal command that darkens the room")
	game.session.state.memory = {"kept": 8}
	status = GitShell.plain(terminal.run_line("git status").output)
	_check(status.contains("modified:") and status.contains("rooms/workshop-loft/state.json"), "A world change shows as a modified room file: " + status)
	_check(GitShell.plain(terminal.run_line("git diff").output).contains("\"kept\": 8"), "git diff shows the changed memory")
	_check(terminal.run_line("git add .").ok and GitShell.plain(terminal.run_line("git commit -m \"remember eight\"").output).contains("remember eight"), "add and commit save the change")
	_check(SaveRepo.uncommitted_changes().is_empty(), "After the commit nothing is uncommitted")
	_check(terminal.run_line("git switch -c experiment").ok, "A branch is made for an experiment")
	await _frames(4)
	while game._flow_busy: await process_frame
	_check(game._modals.is_empty() and game.playing and SaveRepo.repo().status().branch == "experiment", "Moving the tree reloads the game and puts the tablet away")
	game.session.state.memory = {"kept": 99}
	_check(game.commit_progress("ninety-nine").ok, "The game can commit directly")
	game.open_tablet()
	await _frames(2)
	(game._modals[-1] as TabletShell).open_terminal()
	await _frames(2)
	_check(((game._modals[-1] as TabletShell)._app as TerminalApp).run_line("git switch main").ok, "Switching back to main")
	await _frames(4)
	while game._flow_busy: await process_frame
	_check(game.session.state.memory.get("kept") == 8, "The world reloads from main's commit")
	game.session.state.memory = {"kept": 7}
	_check(game.commit_progress("seven").ok, "Main moves on: the histories fork")
	# Uncommitted work: leaving asks first; the load screen can still take you elsewhere (and loses it).
	game.session.state.memory = {"kept": 5}
	game.open_tablet()
	await _frames(2)
	(game._modals[-1] as TabletShell).title_requested.emit()
	await _frames(2)
	_check(game._modals[-1] is ConfirmDialog and game.playing, "Leaving with uncommitted changes asks first")
	game._pop_all_modals()
	game.open_load()
	await _frames(3)
	var modal := game._modals[-1] as LoadModal
	_check(modal != null and modal._graph.rows.size() == 5 and HistoryLanes.width(modal._graph.rows) == 2, "The load screen graphs every commit on both branches: %d rows, %d lanes" % [modal._graph.rows.size() if modal != null else -1, HistoryLanes.width(modal._graph.rows) if modal != null else -1])
	_check(modal._command.text == "git switch main", "The command line is filled for the selected commit")
	modal._command.text = "git switch experiment"
	modal.run_command()
	await _frames(2)
	_check(game.playing and game._modals[-1] == modal and GitShell.plain(modal._output.text).contains("would be overwritten"), "A dirty tree refuses the switch with git's words, in the load screen too")
	modal._command.text = "git reset --hard"
	modal.run_command()
	await _frames(6)
	while game._flow_busy: await process_frame
	_check(game.playing and game.session.state.memory.get("kept") == 7 and game._modals.is_empty(), "reset --hard in the load screen loads HEAD again: the uncommitted change is gone")
	game.open_load()
	await _frames(3)
	modal = game._modals[-1] as LoadModal
	modal._command.text = "git switch experiment"
	modal.run_command()
	await _frames(6)
	while game._flow_busy: await process_frame
	_check(game.playing and game.session.state.memory.get("kept") == 99 and SaveRepo.repo().status().branch == "experiment", "Now the switch loads the branch")
	# The same browser as the tablet's Saves app.
	game.open_tablet()
	await _frames(2)
	(game._modals[-1] as TabletShell).open_saves()
	await _frames(2)
	var app := (game._modals[-1] as TabletShell)._app as SavesBrowser
	_check(app._graph.rows.size() == 5 and app._command.text == "git switch experiment", "The tablet's Saves app shows the same five commits and fills the command for the current branch")
	app._command.text = "git switch main"
	app.run_command()
	await _frames(6)
	while game._flow_busy: await process_frame
	_check(game.playing and game.session.state.memory.get("kept") == 7 and SaveRepo.repo().status().branch == "main" and game._modals.is_empty(), "Switching from the tablet's Saves app loads main and puts the tablet away")
	await _lesson_tests(game)


## Hotaru's hand-held lesson (docs/concept/v0.9/tablet-tutorial.md): the offer's two answers, every
## step advancing only on its own condition, a wrong command waiting, and resuming after the slate is
## put away and taken out again.
func _lesson_tests(game: Game) -> void:
	game._dialogue_read.erase("tablet-tutorial")
	game.offer_lesson("tablet-tutorial")
	await _frames(2)
	var decline: FButton = _find_button(game._modals[-1], "I already know how to use the tablet.")
	_check(decline != null and _find_button(game._modals[-1], "Please show me.") != null, "Hotaru offers the lesson with two answers")
	decline.pressed.emit()
	await _frames(2)
	_check(game._dialogue_read.get("tablet-tutorial", []) == ["skipped"] and game._lesson == null and game._modals.is_empty(), "Declining marks the lesson skipped and gets out of the way")
	game._dialogue_read.erase("tablet-tutorial")
	game.offer_lesson("tablet-tutorial")
	await _frames(2)
	_find_button(game._modals[-1], "Please show me.").pressed.emit()
	await _frames(2)
	var lesson: TabletLesson = game._lesson
	_check(lesson != null and lesson.active and lesson.step == 0 and game._modals.is_empty(), "Accepting starts the lesson, waiting for the slate to be taken out")
	game.open_tablet()
	await _frames(2)
	var tablet := game._modals[-1] as TabletShell
	_check(lesson.step == 1 and tablet._strip.visible and tablet._overlay.target == tablet._home_key, "Taking the slate out advances to the home key, ringed, with Hotaru's line on the strip")
	tablet.lesson_next_pressed.emit()
	_check(lesson.step == 2 and tablet._overlay.target == tablet._icons["saves"], "Next moves on and rings the Saves app")
	tablet.open_terminal()
	await _frames(2)
	_check(lesson.step == 2, "Opening the wrong app does not advance the lesson")
	tablet.show_home()
	tablet.open_saves()
	await _frames(2)
	var saves := tablet._app as SavesBrowser
	_check(lesson.step == 3 and saves._phantom and saves._graph.rows.size() == 4 and saves._run.disabled, "Saves opens on the example tree: four invented commits, Run disabled")
	tablet.lesson_next_pressed.emit()
	tablet.lesson_next_pressed.emit()
	tablet.lesson_next_pressed.emit()
	_check(lesson.step == 6 and tablet._overlay.target == saves._graph, "Three explanations later the lesson waits for a tap on the graph")
	tablet.lesson_next_pressed.emit()
	_check(lesson.step == 6, "Next does nothing while a tap is awaited")
	saves._graph.select(SavesBrowser.PHANTOM_IDS[1])
	_check(lesson.step == 7 and saves._command.text == "git switch try-something", "Tapping the side branch advances and fills its switch command")
	tablet.lesson_next_pressed.emit()
	_check(lesson.step == 8 and not saves._phantom and saves._graph.rows.size() == 5, "The example gives way to the player's own tree")
	# Put the slate away and take it out again: the same step waits.
	tablet.close()
	await _frames(2)
	_check(lesson.active and lesson.tablet == null and lesson.step == 8, "Putting the slate away keeps the lesson at its step")
	game.open_tablet()
	await _frames(2)
	tablet = game._modals[-1] as TabletShell
	_check(lesson.step == 8 and tablet._strip.visible, "Taking it out again resumes the same step")
	tablet.lesson_next_pressed.emit()
	_check(lesson.step == 10, "Next after the resume; the home step is already met because the slate opened on home")
	tablet.open_saves()
	await _frames(2)
	_check(lesson.step == 10, "The Terminal is awaited, not Saves")
	tablet.show_home()
	_check(lesson.step == 10, "Going home again changes nothing")
	tablet.open_terminal()
	await _frames(2)
	var terminal := tablet._app as TerminalApp
	_check(lesson.step == 11 and terminal.ghost == "git status", "The Terminal opens with the suggested command as ghost text")
	game.session.state.memory = {"lesson": 1}
	terminal.run_line("git log")
	_check(lesson.step == 11 and tablet._strip_note.visible and tablet._strip_note.text.contains("git status"), "A different command does not advance; Hotaru nudges")
	terminal.run_line("git status")
	_check(lesson.step == 12 and terminal.ghost == "git add .", "git status advances to add")
	terminal.run_line("git add .")
	terminal.run_line("git commit")
	_check(lesson.step == 13, "A failed commit (no message) does not count")
	terminal.run_line("git commit -m \"Picked up Nell's slate\"")
	_check(lesson.step == 14, "A real commit advances")
	terminal.run_line("git log --oneline")
	_check(lesson.step == 15, "log advances to the lesson's rule")
	tablet.lesson_next_pressed.emit()
	tablet.show_home()
	tablet.open_saves()
	await _frames(2)
	_check(lesson.step == 18 and (tablet._app as SavesBrowser)._graph.rows.size() == 6, "Back in Saves the new commit is on the real tree")
	tablet.lesson_next_pressed.emit()
	tablet.show_home()
	tablet.open_settings()
	await _frames(2)
	_check(lesson.step == 21 and tablet._overlay.target == (tablet._app as SettingsSheet).rows["ui_scale"], "Settings rings the interface size")
	tablet.lesson_next_pressed.emit()
	_check(not lesson.active and game._lesson == null and game._dialogue_read.get("tablet-tutorial", []) == ["done"] and not tablet._strip.visible, "The last Next finishes the lesson and marks it done")
	# Replaying from the terminal, and skipping the rest.
	tablet.show_home()
	tablet.open_terminal()
	await _frames(2)
	(tablet._app as TerminalApp).run_line("tutorial tablet")
	await _frames(2)
	_check(game._lesson != null and game._lesson.active and game._lesson.step >= 1, "tutorial tablet replays the lesson on the open slate")
	tablet.lesson_skip_pressed.emit()
	_check(game._lesson == null and game._dialogue_read.get("tablet-tutorial", []) == ["done"], "Skip the rest ends it; done stays done")
	game._pop_all_modals()


## The same shortcuts, but through Godot's real input routing: key events go to the focused control first
## and only reach the game's handlers if nothing consumed them.
func _real_key_tests(game: Game) -> void:
	game._pop_all_modals()
	await _tap(KEY_ESCAPE)
	_check(game._modals.size() == 1 and game._modals[0] is TabletShell, "Escape opens the pause menu")
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
	SaveRepo.wipe()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_PROFILE))
	SaveRepo.force_enabled = false


func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
