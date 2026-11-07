class_name DevelopmentMode
extends RefCounted
## Trusted local chapter fixtures; player Python cannot access these tools.
const PATH: String = "res://content/development/sparks-checkpoints.json"

static func available() -> bool:
	return OS.is_debug_build() and bool(ProjectSettings.get_setting("rootward/development/tools_enabled", true))

static func catalog() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return raw if raw is Dictionary else {}

static func chapter(story: Dictionary, quest: String, area: String) -> Dictionary:
	for entry: Dictionary in story.get("chapters", []):
		if quest in entry.quests: return entry
	var chapters: Array=story.get("chapters",[])
	for index: int in range(chapters.size()-1,-1,-1):
		var entry: Dictionary=chapters[index]
		if area in entry.get("areas", []): return entry
	return {}

static func enter(game: Game) -> void:
	game._save_timer.stop()
	game.save_now()
	SaveStore.development = true

static func jump(game: Game, id: String) -> bool:
	if not available() or not game.playing or game._level_id != LevelStore.MAIN_LEVEL or game._flow_busy or game.session.busy: return false
	var entries: Dictionary = catalog().get("checkpoints", {})
	if not entries.has(id): return false
	var point: Dictionary = entries[id]
	# Validate all fixture rooms before exchanging the live session.
	var rooms: Dictionary = {}
	for area_id: String in game._level_spec.room_areas:
		var area: AreaDef = AreaStore.load_area(area_id)
		if area == null: return false
		var rules := LabWorld.new(area)
		var state: Dictionary = rules.initial_state()
		for lamp_id: String in point.get("lamp_programs",{}):
			if state.lamps.has(lamp_id):state.lamp_programs[lamp_id]=point.lamp_programs[lamp_id].duplicate(true)
		var cycle: Dictionary = CityCycle.restore(point.get("city_cycle",{}))
		state.time=CityCycle.time(cycle)
		LampPrograms.refresh(area,state,bool(state.time.is_dark))
		state.hotaru_greeted = bool(point.get("greeted", false))
		if point.get("tablet", false): state.items = ["field-tablet"]
		state.inspections_read = (point.get("inspections", {}).get(area_id, []) as Array).duplicate()
		for lamp: String in point.get("lamps", []):
			if state.lamps.has(lamp): state.lamps[lamp] = true
		if state.inspections_read.has("desk-terminal"): state.terminal_links = ["desk-terminal"]
		if area_id==point.area: state.display_cards=point.get("display_cards",{}).duplicate(true)
		if area_id == point.area:
			var at: Array = point.get("at", [area.spawn.x, area.spawn.y])
			state.player = [int(at[0]), int(at[1]), 0]
			var zone: String=area.zone_at(Vector2i(int(at[0]),int(at[1])))
			if zone!="" and not state.zones_seen.has(zone): state.zones_seen.append(zone)
			if not rules.is_walkable(state, Vector2i(int(at[0]), int(at[1]))): return false
		if rules.normalize_state(state).is_empty(): return false
		rooms[area_id] = {"version":GameSession.SAVE_VERSION, "area":area_id, "area_version":area.version,
			"city_cycle":cycle,"state":state, "completed":_completed(area,state,point.get("completed",{}).get(area_id,[])),
			"source":game.session.source, "workshop_pages":game.session.workshop_pages.duplicate(true),
			"greeting_editor":game.session.greeting_editor.duplicate(true), "edits":[]}
	var source: Dictionary = AreaStore.read_source(str(point.area))
	if not source.get("ok", false): return false
	game._pop_all_modals()
	game.close_notebook(true)
	enter(game)
	game.session.prepare_travel()
	game._journey_rooms = rooms
	game._workshop_dismissed = (point.get("dismissed", []) as Array).duplicate()
	game._workshop_log.clear()
	game._dialogue_read = {"loft-waking":["introduced"]} if point.get("greeted", false) else {}
	game._dialogue_read["workshop-scenes"]=(point.get("read_scenes",[]) as Array).duplicate()
	if game._dialogue_read["workshop-scenes"].has("iona-commission"):
		var grant: Dictionary=PlayerAccounts.change_item(PlayerAccounts.fresh(),"message-card",1)
		var marked: Dictionary=PlayerAccounts.claim(grant.accounts,"welcome-material",0,"Reusable message card from Iona")
		for room: Dictionary in rooms.values():room["accounts"]=marked.accounts.duplicate(true)
	game._pending_room_target = ""
	game._activate_journey_room(source, rooms[point.area])
	if game.hud is PaperHud: (game.hud as PaperHud).reset_pin()
	game.hud.clear_feedback()
	game.hud.show_toast("Dev mode · " + str(point.title))
	game.save_now()
	return true

## The jobs a checkpoint counts as done in one room: what its state already meets, plus the ones it names (build jobs
## are met by edits, which a checkpoint does not carry).
static func _completed(area: AreaDef, state: Dictionary, named: Variant) -> Array:
	var done: Array = Quests.newly_completed(area, state, [])
	if named is Array:
		for id: Variant in named:
			if not area.quest(str(id)).is_empty() and not done.has(str(id)): done.append(str(id))
	return done


static func current_code_job(game: Game) -> Dictionary:
	if game.journal is WorkshopJobsJournal:
		var selected: Dictionary = game.area.quest((game.journal as WorkshopJobsJournal)._page)
		if not selected.is_empty(): return selected
	return game.session.current_quest()

static func fill_solution(game: Game) -> bool:
	if not available() or not game.playing or game.session.busy: return false
	var quest: Dictionary = current_code_job(game)
	var code: String = str(catalog().get("solutions", {}).get(quest.get("id", ""), ""))
	if code.is_empty(): return false
	game._pop_all_modals()
	game.close_notebook(true)
	enter(game)
	game.session.prepare_travel()
	var at: Array = []
	var context: Dictionary = quest.get("access", {})
	var terminal: String = "desk-terminal" if quest.id == "say-hello" else ""
	if quest.id == "say-hello":
		for entry: Dictionary in game.area.terminals:
			if entry.id == terminal: at = entry.at
	elif context.get("kind") == "device":
		at = game.area.lamp(context.id).get("stand", [])
	elif context.get("kind") == "display":
		at=DisplayCards.find(game.area,str(context.id)).get("at",[])
	elif context.get("kind") == "zone":
		var screens: Array[Dictionary] = ZoneTerminals.for_zone(game.area, str(context.id))
		if not screens.is_empty():
			at = screens[0].at
			terminal = screens[0].id
	if at.is_empty() or not game.session.rules.is_walkable(game.session.state, Vector2i(int(at[0]), int(at[1]))): return false
	game.session.state.player = [int(at[0]), int(at[1]), 0]
	var zone: String=game.area.zone_at(Vector2i(int(at[0]),int(at[1])))
	if zone!="" and not game.session.state.zones_seen.has(zone): game.session.state.zones_seen.append(zone)
	if str(quest.goal.get("type", "")).begins_with("doodads"):
		# Arranging jobs reach things across the district; a fixture counts its places as walked through.
		for place: Dictionary in game.area.zones:
			if not game.session.state.zones_seen.has(place.id): game.session.state.zones_seen.append(place.id)
	game.view.sync_player(game.session.state)
	game.session._after_change()
	if quest.id == "say-hello":
		# The note is an earlier discovery in this fixture, not an out-of-range F interaction.
		if not game.session.state.inspections_read.has("nell-note"): game.session.state.inspections_read.append("nell-note")
		game.session.read_inspection("desk-terminal")
	if terminal != "": game.session.connect_terminal(terminal)
	game.session.set_source(code)
	if quest.id == "say-hello":
		game.session.greeting_editor = {"mode":"python", "python":code}
		game._open_workshop_journal(true)
	elif context.get("kind")=="display":
		var display: Dictionary=DisplayCards.find(game.area,str(context.id))
		if not game.session.state.inspections_read.has(display.commission):game.session.state.inspections_read.append(display.commission)
		game._issue_message_card()
		if quest.id == "proper-welcome": game._dialogue_read["workshop-scenes"]=["braum-welcome","iona-commission"]
		game.session.workshop_pages[quest.id]=code
		game.open_display(str(context.id))
	else:
		game.session.workshop_pages[quest.id] = code
		var access: Dictionary = context.duplicate()
		access["title"] = str(FieldAccess.place_for(game.area, quest).get("title", quest.title))
		game._open_workshop_journal(false, access)
		if game.journal is WorkshopJobsJournal:
			var journal := game.journal as WorkshopJobsJournal
			for index: int in range(journal._pages.item_count):
				if journal._pages.get_item_metadata(index) == quest.id:
					journal._pages.select(index)
					journal._show_page()
	game.hud.clear_feedback()
	game.hud.show_toast("Reference code filled · " + str(quest.title))
	return true

static func finish_current(game: Game) -> bool:
	if not available() or not game.playing or game.session.busy: return false
	var quest: Dictionary = current_code_job(game)
	if quest.is_empty(): return false
	if quest.goal.type == "inspection_read":
		game._pop_all_modals()
		game.close_notebook(true)
		enter(game)
		for inspection: Dictionary in game.area.interior.inspections:
			if inspection.id == quest.goal.id:
				game.session.prepare_travel()
				game.session.state.player = [int(inspection.at[0]), int(inspection.at[1]), 0]
				game.view.sync_player(game.session.state)
				return game.session.read_inspection(str(inspection.id))
		return false
	if not fill_solution(game): return false
	# A reference routine goes through the real worker-thread WASI, command
	# validation, preview and Apply; a rejected routine cannot finish a quest.
	if not await game.session.run_preview(): return false
	return game.session.apply_preview()
