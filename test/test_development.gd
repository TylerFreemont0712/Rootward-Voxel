extends SceneTree
## Chapter fixture integrity, isolated saves, real WASI solutions and pinned-card context.
var checks: int = 0
var failures: Array[String] = []
var game: Game
func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()
func _run() -> void:
	SaveStore.save_path = "user://development_test_%d.json" % OS.get_process_id()
	SaveStore.profile_path = "user://development_profile_test_%d.json" % OS.get_process_id()
	SaveStore.force_enabled = true
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game()
	game._pop_all_modals()
	game.close_notebook(true)
	game.save_now()
	var ordinary: String = FileAccess.get_file_as_string(SaveStore.level_path(LevelStore.MAIN_LEVEL))
	var normal_path: String = SaveStore.level_path(LevelStore.MAIN_LEVEL)
	var fixtures: Dictionary = DevelopmentMode.catalog().checkpoints
	for id: String in fixtures:
		_check(DevelopmentMode.jump(game,id), id + " checkpoint loads")
		_check(SaveStore.development and SaveStore.level_path(LevelStore.MAIN_LEVEL) != normal_path, "Checkpoint saves are separate from ordinary Continue")
		_check(game.area.id == fixtures[id].area and game.session.rules.is_walkable(game.session.state, game.session.player_cell()), "Checkpoint has legal support in its intended area")
		_check(FileAccess.get_file_as_string(normal_path) == ordinary, "Chapter jumps preserve ordinary progress byte for byte")
	# Chapter 05: every Public Works job finishes through real Python, the builder's rules, preview and Apply.
	_check(DevelopmentMode.jump(game,"works-start") and game.session.current_quest().get("id") == "band-seats", "Public Works opens with the band's benches")
	for job: String in ["band-seats", "room-on-the-walk", "two-parks", "market-day", "own-corner"]:
		game._pop_all_modals()
		_check(game.session.current_quest().get("id") == job and await DevelopmentMode.finish_current(game) and game.session.completed.has(job), "Public Works job finishes in play: " + job)
		game.close_notebook(true)
	_check(game.session.current_quest().is_empty() and game.ledger.edits.size() >= 10, "The square keeps the code's arrangement as layout edits")
	# Chapter 06: a shop job plays its scene, then finishes through the board's real preview and Apply.
	_check(DevelopmentMode.jump(game,"market-start") and game.session.current_quest().get("id") == "next-batch", "Market Street opens at Morning Loaf")
	game._pop_all_modals()
	_check(await DevelopmentMode.finish_current(game) and game.session.state.inspections_read.has("bake-order"), "The board job's note is read in play")
	game._pop_all_modals()
	_check(await DevelopmentMode.finish_current(game) and game.session.completed.has("next-batch") and game.session.state.display_cards.get("bake-board", []).size() == 3, "Ada's board shows three batches after Apply")
	game.close_notebook(true)
	var before: Dictionary = game.session.to_save()
	_check(not DevelopmentMode.jump(game,"invented") and game.session.to_save() == before, "An unknown checkpoint is rejected without changing progress")
	_check(DevelopmentMode.jump(game,"hello-start"), "Return to first greeting")
	_check(await DevelopmentMode.finish_current(game), "Auto finish greeting executes and applies the reference Python")
	_check(game.session.state.hotaru_greeted and game.session.completed.has("say-hello"), "Greeting completion comes from committed output")
	_check(game.session.stats.runs == 1 and game.session.stats.applies == 1, "Auto finish uses real preview and Apply")
	game.close_notebook(true)
	_check(DevelopmentMode.jump(game,"workshop-start"), "Jump to workshop chapter")
	game._pop_all_modals()
	_check(await DevelopmentMode.finish_current(game), "A ticket completes through the bounded inspection")
	_check(game.session.completed.has("waiting-ticket"), "The ticket inspection unlocks the landing job")
	game._pop_all_modals()
	_check(DevelopmentMode.fill_solution(game), "The landing reference fills its own notebook page")
	_check(not game.session.state.lamps["landing-lamp"] and not game.session.has_preview(), "Filling code alone never applies or previews it")
	_check(game.session.workshop_pages["landing-light"].contains("set_lit(True)"), "Reference is stored on the selected fitting's page")
	_check(await DevelopmentMode.finish_current(game), "The landing solution uses WASI and real fitting access")
	_check(game.session.state.lamps["landing-lamp"], "Landing job lights its actual fitting")
	game.close_notebook(true)
	_check(DevelopmentMode.jump(game,"round-start"), "Jump to morning-round start")
	game._pop_all_modals()
	_check(await DevelopmentMode.finish_current(game), "The round solution uses WASI and its connected zone screen")
	_check(game.session.completed.has("morning-round") and game.session.lamps_lit() == 3, "Morning round finishes all three lights")
	game._pop_all_modals()
	_check(DevelopmentMode.jump(game,"welcome-start"),"Jump to the outdoor commission")
	_check(await DevelopmentMode.finish_current(game),"The sign reference executes through its actual display context")
	_check(game.session.completed.has("proper-welcome") and game.session.state.display_cards["tram-welcome"].size()==3 and game.session.accounts.wallet==43 and game.session.accounts.inventory.get("message-card")==1,"Dev completion installs all messages and records real wages and materials")
	game.close_notebook(true)
	game._pop_all_modals()
	_check(DevelopmentMode.jump(game,"hello-start"), "Reset the chapter without changing ordinary progress")
	var hud := game.hud as PaperHud
	_check(hud.ticket.custom_minimum_size.x == 380 and hud.ticket.chapter.text.contains("CHAPTER 00") and hud.ticket.concept.text == "print and words", "The wider pin shows the chapter and learning concept")
	game.open_development()
	_check(game._modals[-1] is DevelopmentPanel, "Dev controls open through the game's actual modal flow")
	game._pop_all_modals()
	_check(DevelopmentMode.jump(game,"square"), "Prepare a different area for the actual chapter buttons")
	game.open_development()
	var starts: Array[FButton] = []
	for node: Node in game._modals[-1].find_children("*", "", true, false):
		if node is FButton and node.text == "Start": starts.append(node as FButton)
	_check(starts.size() == 7, "Each implemented chapter has its own Start button")
	if not starts.is_empty(): starts[0].pressed.emit()
	_check(game.area.id == "workshop-loft" and not game.session.state.hotaru_greeted, "The first Start button loads Chapter 00 rather than the last loop entry")
	game.open_development()
	var ends: Array[FButton] = []
	for node: Node in game._modals[-1].find_children("*", "", true, false):
		if node is FButton and node.text == "End": ends.append(node as FButton)
	if not ends.is_empty(): ends[0].pressed.emit()
	_check(game.area.id == "workshop-loft" and game.session.state.hotaru_greeted, "The first End button loads the completed greeting")
	game.open_development()
	for node: Node in game._modals[-1].find_children("*", "", true, false):
		if node is FButton and node.text == "Return to regular game":
			node.pressed.emit()
			break
	while game._flow_busy: await process_frame
	var expected: Dictionary = game.session.rules.normalize_state(JSON.parse_string(ordinary).state)
	# Derived clock/power mirrors advance during exploration; the saved journey clock is checked separately.
	var actual: Dictionary=game.session.state.duplicate(true)
	for key: String in ["time","city_power"]:
		expected.erase(key)
		actual.erase(key)
	var ordinary_clock: Dictionary=CityCycle.restore(JSON.parse_string(ordinary).get("city_cycle",{}))
	_check(not SaveStore.development and game.area.id == "workshop-loft" and actual == expected and game.session.cycle.day==ordinary_clock.day and absf(float(game.session.cycle.minute)-float(ordinary_clock.minute))<1.0, "Return restores ordinary device state and resumes its own clock, without inheriting dev time")
	ProjectSettings.set_setting("rootward/development/tools_enabled", false)
	before = game.session.to_save()
	_check(not DevelopmentMode.jump(game,"square") and not DevelopmentMode.fill_solution(game) and game.session.to_save() == before, "Disabling dev tools rejects actions without mutation")
	ProjectSettings.set_setting("rootward/development/tools_enabled", true)
	game.show_title()
	_check(not SaveStore.development and SaveStore.read(LevelStore.MAIN_LEVEL).state.player == JSON.parse_string(ordinary).state.player, "Title restores the regular Continue slot")
	SaveStore.delete(LevelStore.MAIN_LEVEL)
	SaveStore.development = true
	SaveStore.delete(LevelStore.MAIN_LEVEL)
	SaveStore.development = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	for failure: String in failures: printerr("FAIL: ",failure)
	print("Development tools: %d checks, %d failures." % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
