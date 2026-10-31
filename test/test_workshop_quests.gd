extends SceneTree
## Play the next workshop chapter through the real UI, WASI and saved room state.
var checks: int = 0
var failures: Array[String] = []
var game: Game
var output: String = ""
const LIGHT: String = 'def program(world):\n    world.lamp("landing-lamp").set_lit(True)\n'
const ROUND: String = 'def program(world):\n    for fitting in world.zone("workshop").lamps:\n        fitting.set_lit(True)\n'

func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	go.call_deferred()

func go() -> void:
	if not OS.get_cmdline_user_args().is_empty(): output=OS.get_cmdline_user_args()[0]
	_rules()
	await _play()
	if failures.is_empty(): print("Workshop story and quests: %d checks passed." % checks)
	else:
		for failure: String in failures: printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)

func _rules() -> void:
	var source: Dictionary=AreaStore.read_source("workshop-floor")
	var parsed: Dictionary=AreaDef.parse(source.document,source.assets,source.quests)
	_check(parsed.ok,"The authored quest chain and fixture mappings validate")
	if not parsed.ok:return
	var area: AreaDef=parsed.area
	var rules:=LabWorld.new(area)
	var state: Dictionary=rules.initial_state()
	_check(not rules.read_inspection(state,"job-board").ok,"A ticket cannot be read from the stair landing across the room")
	_check(not rules.read_inspection(state,"missing").ok,"An unknown inspection cannot advance a quest")
	state.player=[12,10,0]
	var read: Dictionary=rules.read_inspection(state,"job-board")
	_check(read.ok and state.inspections_read.is_empty() and read.state.inspections_read==["job-board"],"Reading returns a new bounded discovery without mutating its input")
	state.memory={"inspections_read":["job-board"]}
	_check(not Quests.goal_met(area,state,area.quest("waiting-ticket").goal),"Program memory cannot forge a real inspection")
	var old: Dictionary=state.duplicate(true)
	var legacy: Dictionary = {"area_version":5, "journey_rooms":{"active":"workshop-floor"}, "state":{"hotaru_greeted":true}, "completed":["say-hello"]}
	_check(Game._legacy_workshop_handoff(legacy), "An old save already working downstairs keeps access to the terminal")
	legacy.area_version = 6
	_check(not Game._legacy_workshop_handoff(legacy), "A new save cannot skip the terminal handoff")
	legacy.area_version = "invalid"
	_check(not Game._legacy_workshop_handoff(legacy), "Malformed version data cannot grant the terminal")
	old.erase("inspections_read")
	old.lamps={}
	_check(rules.normalize_state(old).memory==state.memory and rules.normalize_state(old).lamps.size()==3,"An old downstairs save gains the fixtures without losing its memory")
	old.inspections_read=["job-board","foreign","job-board"]
	_check(rules.normalize_state(old).inspections_read==["job-board"],"Saved inspections retain known unique ids only")
	old.inspections_read="job-board"
	_check(rules.normalize_state(old).is_empty(),"Malformed inspection saves are rejected")
	for defect: String in ["missing","duplicate","foreign"]:
		var doc: Dictionary=source.document.duplicate(true)
		if defect=="missing":doc.interior.lamp_fixtures.pop_back()
		elif defect=="duplicate":doc.interior.lamp_fixtures.append(doc.interior.lamp_fixtures[0].duplicate())
		else:doc.interior.lamp_fixtures[0].asset="not-a-room-asset"
		_check(not AreaDef.parse(doc,source.assets,source.quests).ok,"Invalid fixture mapping is rejected: "+defect)
	var scenes: Dictionary=JourneyStory.read("res://content/journeys/sparks-and-machines.json").scenes
	_check(WorkshopStory.valid(scenes),"Every scene has bounded original prose, speaker and reply data")
	_check(WorkshopStory.log_line(scenes, {"scene":"loft-waking", "page":3, "kind":"page"}).text.contains("work ticket downstairs"), "Earlier saved story tokens still point to their original line")
	_check(WorkshopStory.pending(scenes,"workshop-floor",["say-hello"],[])=="workshop-arrival","Committed greeting offers the first downstairs conversation")
	_check(WorkshopStory.pending(scenes,"workshop-floor",["say-hello"],["workshop-arrival"])=="","A lighting preview cannot schedule the completion scene")
	_check(WorkshopStory.pending(scenes,"workshop-floor",["say-hello","landing-light"],["workshop-arrival"],{})=="","Turning a finished light off postpones narration that requires it to be lit")
	_check(WorkshopStory.pending(scenes,"workshop-floor",["say-hello","landing-light"],["workshop-arrival"],{"landing-lamp":true})=="landing-lit","Relighting the fitting makes its unread consequence available again")
	_check(WorkshopStory.restore_read(["round-ready","unknown","round-ready"],scenes)==["round-ready"],"Saved story reads are whitelisted and deduplicated")
	var tokens: Array=WorkshopStory.restore_log([{"scene":"waiting-ticket","page":2,"kind":"choice","choice":1},{"scene":"unknown","page":0,"kind":"page"},{"scene":"waiting-ticket","page":2,"kind":"reply","choice":-1}],scenes)
	_check(tokens.size()==1 and WorkshopStory.log_line(scenes,tokens[0]).speaker=="player","Story logs restore only valid authored choices")
	_check(WorkshopStory.restore_log("unbounded text",scenes).is_empty(),"A malformed story log cannot inject saved prose")
	var broken: Dictionary=scenes.duplicate(true)
	broken["workshop-arrival"].pages[0].text="x".repeat(501)
	_check(not WorkshopStory.valid(broken),"Oversize story pages are rejected")
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/loft-window-life/manifest.json"))
	_check(not manifest.audit.material_records.keys().any(func(key: String) -> bool: return key.contains("leaf") or key.contains("soil")),"Only the windowsill plant is removed from its keepsakes asset")
	_check(manifest.audit.bounds[0]>.03 and manifest.audit.bounds[4]>.3,"The windowsill book and keepsake box remain")
	var ahead: Dictionary=read.state
	ahead.hotaru_greeted=true
	for id: String in ahead.lamps:ahead.lamps[id]=true
	_check(Quests.newly_completed(area,ahead,[])==["say-hello","waiting-ticket","landing-light","morning-round"],"A player who already did the work does not have to repeat it for the quest chain")

func _play() -> void:
	SaveStore.save_path="user://test_workshop_story_"+str(OS.get_process_id())+".json"
	SaveStore.profile_path="user://test_workshop_story_profile_"+str(OS.get_process_id())+".json"
	SaveStore.force_enabled=true
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game("sparks-and-machines")
	game._pop_all_modals();game.close_notebook(true)
	game.session.state.player = [1,8,0]
	game.view.sync_player(game.session.state)
	_check(game.session.connect_terminal("desk-terminal"), "The chapter keeps the loft terminal connection from the opening")
	game.session.set_source(CompanionLesson.STARTER)
	await game.session.run_preview()
	_check(game.session.apply_preview(),"The chapter starts from a real committed WASI greeting")
	game._dialogue_read["loft-waking"]=["introduced"] # The waking exchange has its own end-to-end suite.
	game.session.state.items=["field-tablet"] # So does lifting the slate from the bed.
	game.session.greeting_editor={"mode":"python","python":CompanionLesson.STARTER}
	await shot("01-loft-clear-sill")
	game.session.state.player=[7,5,0]
	game.view.sync_player(game.session.state)
	game.session.request_step(Vector2i(0,-1))
	while game._flow_busy:await process_frame
	game._refresh_interaction()
	_check(game._modals.size()==1 and game._modals[0] is WorkshopScene,"The next conversation starts in the actual workshop after descent")
	_check(not game.workshop_speech.visible,"A dialogue card suppresses the duplicate speech bubble behind it")
	if game._modals.is_empty():return
	var arrival:=game._modals[0] as WorkshopScene
	_check(arrival._portrait.texture!=null,"The story stage uses the selected robot portrait")
	await shot("02-workshop-arrival")
	arrival.close()
	game._refresh_interaction()
	_check(game._modals.is_empty() and not game._dialogue_read.get("workshop-scenes",[]).has("workshop-arrival"),"Leaving a scene does not mark it read or immediately reopen it")
	game.talk_hotaru()
	_drain(game._modals[0] as WorkshopScene,1)
	_check(game._dialogue_read["workshop-scenes"].has("workshop-arrival"),"Returning to Hotaru completes the chosen conversation")
	_check(game._workshop_log.any(func(token: Dictionary) -> bool:return token.kind=="choice") and game._workshop_log.any(func(token: Dictionary) -> bool:return token.kind=="reply"),"The saved log records the chosen player line and its answer")
	_check(game.session.walk_to(Vector2i(12,10)),"The board can be reached from the upper landing by the actual stair route")
	# Drive the authored route through session steps without depending on desktop focus.
	var route: Array[Vector2i]=game.session._route.duplicate()
	game.session._cancel_route()
	for cell: Vector2i in route:
		game.session.request_step(cell-game.session.player_cell())
		game.session.advance_walk(LabWorld.STEP_SECONDS)
	_check(game.session.player_cell()==Vector2i(12,10),"The route descends the flight and reaches the board")
	game.interact()
	var ticket:=game._modals[0] as WorkshopScene
	ticket.close()
	_check(not game.session.completed.has("waiting-ticket"),"Closing the ticket before finishing leaves the reading quest open")
	game.interact()
	ticket=game._modals[0] as WorkshopScene
	for n: int in range(6):ticket.advance()
	await shot("03-ticket-choice")
	_drain(ticket,0)
	for n: int in range(3):await process_frame
	_check(game.session.completed.has("waiting-ticket") and game.session.current_quest().id=="landing-light","Reading the whole ticket unlocks the lamp job")
	_check(game._modals.size()==1 and game._modals[0] is ZoneConnectionPanel, "The ticket points to the stair lantern, where its code is written")
	var connection := game._modals[0] as ZoneConnectionPanel
	(game.hud as PaperHud)._holding_completed = false
	(game.hud as PaperHud)._refresh()
	_check((game.hud as PaperHud).ticket.hint.text.contains("Stand beside the stair lantern and press F"), "The pinned ticket says where to stand")
	await shot("03b-zone-connection")
	_check(connection.card.size.y < game.size.y*.55, "The guidance fits a compact side card")
	var spot: Array = game.session.state.player.duplicate()
	var carried: Array = game.session.state.items.duplicate()
	game.session.state.player = [5,11,0]
	game.view.sync_player(game.session.state)
	game.session.state.items = []
	game._activate_device("landing-lamp")
	_check(not game.notebook_open and game.workshop_speech._inspection.get("id", "") == "landing-lamp", "Without the tablet the lantern's fitting only describes itself")
	game.workshop_speech.dismiss_inspection()
	game.session.state.items = carried
	game.session.state.player = [7,11,0]
	game.view.sync_player(game.session.state)
	game._activate_device("landing-lamp")
	_check(not game.notebook_open, "Two cells from the lantern its code does not open")
	game._refresh_interaction()
	_check(game._interaction.get("kind", "") != "device", "Two cells away, F offers nothing at the lantern")
	game.session.state.player = spot
	game.view.sync_player(game.session.state)
	connection.destination_requested.emit("landing-lamp")
	var lantern_route: Array[Vector2i] = game.session._route.duplicate()
	game.session._cancel_route()
	for cell: Vector2i in lantern_route:
		game.session.request_step(cell-game.session.player_cell())
		game.session.advance_walk(LabWorld.STEP_SECONDS)
	game._process(0)
	_check(game.session.player_cell() == Vector2i(5,11) and game.movement_lesson is WorkshopJobsJournal and game.movement_lesson._page == "landing-light" and game.session.state.terminal_links.is_empty(), "Walking to the lantern opens its job page without linking the zone's screen")
	_check((game.movement_lesson as WorkshopJobsJournal)._pages.item_count == 1, "Beside the lantern only the lantern's page is offered")
	var slate := game.movement_lesson as WorkshopJobsJournal
	_check(slate._tablet.link_kind == TabletScreen.Link.WIRELESS and is_instance_valid(game._slate_link) and not game._slate_link.wired, "Beside a single fitting the slate pairs over the air, and the room shows the signal")
	var pad: Rect2 = slate._notepad.get_global_rect()
	var dock: Rect2 = Rect2(Vector2(game.size.x - slate.drawer_width - SideDrawer.MARGIN, 0), Vector2(slate.drawer_width, game.size.y))
	_check(pad.position.x < dock.position.x and pad.end.x > dock.position.x and pad.end.y > game.size.y * .9 and slate._notepad.current() == &"job", "The notepad is clipped to the slate's lower end, open at the job")
	await shot("03c-connected-terminal")
	var notes:=game.movement_lesson as WorkshopJobsJournal
	await notes.preview()
	_check(game.session.has_preview() and not game.session.preview_state().lamps["landing-lamp"] and not game.session.completed.has("landing-light"),"The unchanged starter leaves the lamp visibly off and the quest incomplete")
	notes.editor.text=LIGHT
	await process_frame
	await notes.preview()
	_check(not game.session.state.lamps["landing-lamp"] and game.session.preview_state().lamps["landing-lamp"],"A successful Test remains a detached world proposal")
	_check(_lamp_light("landing-lamp").visible and not game._dialogue_read["workshop-scenes"].has("landing-lit"),"The preview really lights the lantern without advancing its story")
	await shot("04-lantern-preview")
	_check(_fixture_visible(),"The lantern is unobstructed by the actual stair geometry with Field Notes open")
	var lamp_point: Vector3=(_lamp_light("landing-lamp") as Node3D).global_position
	var canvas_point: Vector2=game.surface.get_global_transform()*(game.view.camera.unproject_position(lamp_point)*game.surface.size/Vector2(game.world_viewport.size))
	_check(canvas_point.x<notes.get_global_rect().position.x-10 and canvas_point.y>20,"The actual code result stays in the visible world beside the editor")
	notes.editor.text=LIGHT+"    # revised\n"
	notes.editor.text_changed.emit()
	await process_frame
	_check(not game.session.has_preview() and notes._apply.disabled and not _lamp_light("landing-lamp").visible,"Editing drops the old proposal and restores the actual dark fixture")
	notes.editor.text="def program(world):\n    world.lamp(\"not-here\").set_lit(True)\n"
	await process_frame
	await notes.preview()
	_check(not game.session.has_preview() and notes._apply.disabled,"An unknown fitting cannot be applied")
	notes.editor.text=LIGHT
	await process_frame
	await notes.preview()
	notes.apply_routine()
	_check(game.session.completed.has("landing-light") and game.session.state.lamps["landing-lamp"] and _lamp_light("landing-lamp").visible,"Applying the tested routine lights the real fixture and completes the job")
	_check(game._modals.is_empty(),"The completion conversation waits until the player leaves the editor")
	_check(notes._done.visible and not notes._run.visible and not notes._apply.visible, "A finished job offers one plain key: put the slate away and carry on")
	game.close_notebook(true)
	game._refresh_interaction()
	var lit:=game._modals[0] as WorkshopScene
	await shot("05-lantern-consequence")
	_drain(lit,2)
	for n: int in range(3):await process_frame
	_check(game._modals.size()==1 and game._modals[0] is ZoneConnectionPanel and _has_text(game._modals[0], "AREA NODE"), "The lit lantern points to the wall screen, where a whole zone is reached")
	game._modals[0].destination_requested.emit("workshop-terminal")
	var screen_route: Array[Vector2i] = game.session._route.duplicate()
	game.session._cancel_route()
	for cell: Vector2i in screen_route:
		game.session.request_step(cell-game.session.player_cell())
		game.session.advance_walk(LabWorld.STEP_SECONDS)
	game._process(0)
	_check(game.session.state.terminal_links.has("workshop-terminal") and game.session.player_cell() == Vector2i(1,2), "Standing at the wall screen with the tablet links the room's zone")
	notes=game.movement_lesson as WorkshopJobsJournal
	_check(notes._page=="morning-round" and notes.editor.text.contains("lamps[0]"),"The screen opens the distinct round starter")
	_check(notes._tablet.link_kind == TabletScreen.Link.WIRED and is_instance_valid(game._slate_link) and game._slate_link.wired, "At a zone's screen the slate is plugged in, and its cord runs to the socket")
	var reserve: float = notes.extra_reserve()
	notes._tuck(true)
	_check(notes.extra_reserve() == 0.0 and not notes._notepad.put_away.visible and reserve > 0.0, "Put away tucks the notes down and gives the room their space")
	notes._notepad.select(&"hints")
	_check(not notes._tucked and not game.session.notes_put_away and notes._notepad.put_away.visible, "Any sticky brings the notes back")
	notes._notepad.select(&"job")
	_check(notes.go_to_definition("lamps") and notes.editor.get_caret_line() == int(CodeLookup.definition(notes.editor.text, "lamps").line) and notes.editor.get_selected_text() == "lamps", "Going to a variable's definition selects it where the program sets it")
	_check(notes._devices.get_child_count() == 4 and notes._tablet._tabs.get_child_count() == 2, "The slate lists the zone's three devices and a file tab for each reached page")
	_check(_has_text(notes, "temporary name") and _has_text(notes, "for lamp in lamps:"), "The loop guide explains the name and shows a concrete worked example")
	await shot("05b-loop-guide")
	await notes.preview()
	_check(not Quests.goal_met(game.area,game.session.preview_state(),game.area.quest("morning-round").goal),"The old one-lamp card does not complete the full round")
	notes.editor.text=ROUND
	await process_frame
	await notes.preview()
	_check(game.session.preview_state().lamps.values().all(func(value: bool) -> bool:return value) and not game.session.completed.has("morning-round"),"A real for loop previews all three fittings without completing the round")
	await shot("06-round-preview")
	notes.apply_routine()
	_check(Quests.main_arc_done(game.area,game.session.completed) and game.session.state.lamps.values().all(func(value: bool) -> bool:return value),"Applying the loop completes the connected chapter against actual light state")
	_check(game.session.workshop_pages["landing-light"]==LIGHT and game.session.workshop_pages["morning-round"]==ROUND and game.session.greeting_editor.python==CompanionLesson.STARTER,"The greeting and both job drafts retain their separate sources")
	game.close_notebook(true);game._refresh_interaction()
	_check(game._slate_link == null and is_equal_approx(game.view.zoom(), game._indoor_zoom(0.0)), "Putting the slate down unplugs it and returns the room's zoom")
	var ending:=game._modals[0] as WorkshopScene
	_drain(ending,1)
	_check(game._dialogue_read["workshop-scenes"].has("round-ready"),"The final reaction and the next complaint have a saved reading boundary")
	game.session.state.player=[8,5,0];game.view.sync_player(game.session.state)
	await shot("07-round-kept")
	var log_size: int=game._workshop_log.size()
	game.session.state.player=[3,10,0];game.view.sync_player(game.session.state)
	game.interact()
	_check(game._modals.is_empty() and game.workshop_speech._inspection.get("id")=="bread-cupboard" and game.session.input_enabled,"Object inspection is a world bubble and keeps movement available")
	_check(game._workshop_log.size()==log_size,"Incidental inspection text stays out of the story log")
	await shot("08-object-bubble")
	game.session.state.player=[8,5,0];game.view.sync_player(game.session.state)
	for frame: int in range(3):await process_frame
	_check(game.workshop_speech._inspection.is_empty(),"Walking away dismisses an object bubble")
	game.talk_hotaru()
	_check(game._modals.is_empty() and (game.view.stage as WorkshopLoftStage).speech_speaker=="hotaru" and game._workshop_log.size()==log_size,"Already-read companion chatter uses one unlogged speech bubble")
	game.open_workshop_log()
	_check(game._modals.size()==1 and game._modals[0] is WorkshopLog,"The saved transcript opens as an intentional side drawer")
	await shot("09-story-log")
	(game._modals[0] as WorkshopLog).close()
	var saved_log: Array=game._workshop_log.duplicate(true)
	game.save_now()
	await game._return_to_title()
	await game.continue_game("sparks-and-machines")
	game._refresh_interaction()
	_check(game.area.id=="workshop-floor" and game.session.completed.has("morning-round") and game.session.state.inspections_read.has("job-board"),"Continue restores the completed chapter and actual ticket discovery")
	_check(game._modals.is_empty() and game._dialogue_read["workshop-scenes"].has("round-ready"),"Read scenes do not replay on Continue")
	_check(game.session.workshop_pages["landing-light"]==LIGHT and game.session.workshop_pages["morning-round"]==ROUND,"Both editable routines survive Continue")
	_check(game._workshop_log==saved_log,"The authored story transcript and selected responses survive Continue")
	_check(game.session.state.terminal_links.has("workshop-terminal"), "The fixed terminal connection survives Continue")
	game.session.state.player=[9,3,0]
	game.view.sync_player(game.session.state)
	game.open_notebook()
	_check(game.movement_lesson is WorkshopJournal and not game.session.rules.snapshot(game.session.state).zones.size() > 0,"Field Notes away from the screen is the plain open page and reaches no zone")
	game.close_notebook(true)
	game.session.state.player=[1,2,0]
	game.view.sync_player(game.session.state)
	game._activate_terminal("workshop-terminal")
	_check(game.movement_lesson is WorkshopJobsJournal,"After the chapter the job pages remain at the screen for experiments")
	_check((game.movement_lesson as WorkshopJobsJournal)._page=="morning-round","The completed chapter opens its most recent routine rather than the old ticket")
	game.close_notebook(true)
	game.session.state.player=[6,8,0]
	game.view.sync_player(game.session.state)
	game.session.request_step(Vector2i(0,-1))
	while game._flow_busy:await process_frame
	_check(game.area.id=="workshop-loft" and game.session.workshop_pages.get("morning-round")==ROUND,"The saved job drafts travel back upstairs with the player")
	game.open_journal()
	_check(game._modals[0] is WorkshopJobLedger and _has_text(game._modals[0], "The morning round"), "The job book keeps reached downstairs work visible after returning upstairs")
	await shot("10-job-book-after-round")
	(game._modals[0] as WorkshopJobLedger).close()
	game.open_notebook()
	_check(game.movement_lesson is WorkshopJournal and game.movement_lesson.editor.text==CompanionLesson.STARTER,"The original greeting remains independently editable after both jobs")
	game.close_notebook(true)
	game.session.request_step(Vector2i(0,-1))
	while game._flow_busy:await process_frame
	_check(game.area.id=="workshop-floor" and game.session.completed.has("morning-round") and game.session.state.lamps.values().all(func(value: bool) -> bool:return value),"Returning downstairs preserves the finished work and its lights")
	SaveStore.delete("sparks-and-machines")
	game.queue_free()
	await process_frame
	await process_frame

func _lamp_light(id: String) -> OmniLight3D:
	return (game.view._lamps[id] as Node3D).get_node("FixtureLight") as OmniLight3D

func _fixture_visible() -> bool:
	var point: Vector3=_lamp_light("landing-lamp").global_position
	for offset: float in [-.06,0.0,.06]:
		var target: Vector3=point+game.view.camera.global_basis.x*offset
		var origin: Vector3=game.view.camera.project_ray_origin(game.view.camera.unproject_position(target))
		var direction: Vector3=(target-origin).normalized()
		var stairs: Node3D=game.view.building_node("stairs")
		for child: Node in stairs.find_children("*","MeshInstance3D",true,false):
			if child.name==&"IllustratedOutline":continue
			var mesh:=child as MeshInstance3D
			for surface: int in range(mesh.mesh.get_surface_count()):
				var arrays: Array=mesh.mesh.surface_get_arrays(surface)
				var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
				var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
				for n: int in range(0,indices.size(),3):
					var hit: Variant=Geometry3D.ray_intersects_triangle(origin,direction,mesh.global_transform*verts[indices[n]],mesh.global_transform*verts[indices[n+1]],mesh.global_transform*verts[indices[n+2]])
					if hit!=null and origin.distance_to(hit)<origin.distance_to(target)-.03:return false
	return true

func _drain(scene: WorkshopScene, choice: int = 0) -> void:
	for n: int in range(60):
		if not is_instance_valid(scene) or scene.is_queued_for_deletion():return
		if scene._choices.visible:scene._choose(scene._page.choices[mini(choice,scene._page.choices.size()-1)])
		else:scene.advance()

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message)

func _has_text(node: Node, value: String) -> bool:
	if node is Label and (node as Label).text.contains(value): return true
	if node is TextEdit and (node as TextEdit).text.contains(value): return true
	for child: Node in node.get_children():
		if _has_text(child, value): return true
	return false

func shot(name: String) -> void:
	if output=="" or DisplayServer.get_name()=="headless":return
	for frame: int in range(6 if OS.get_environment("VOXEL_REVIEW_QUICK") == "1" else 25):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
