class_name Game
extends Control
## The whole game: one persistent 3D valley behind a title screen, a play HUD, the notebook drawer and
## a stack of modal screens. It owns flow (title, new game, continue, pause, quit) and saving; the
## GameSession owns what happens inside the world.

const AREA_ID: String = "kindle-hollow"
const DRAWER_WIDTH: float = 620.0
const DRAWER_MARGIN: float = 16.0
const TERRAIN_NAMES: Array[String] = ["grass", "dirt path", "cobbles", "water", "rock"]
## The world moves at 60 Hz, so drawing more often (a 165 Hz screen would) only works the graphics card harder.
## Behind another window the valley keeps going at half that.
const FRAME_RATE: int = 60
const BACKGROUND_FRAME_RATE: int = 30

var settings := GameSettings.new()
var area: AreaDef
## The player's edits over the area document (build mode). `area` is always `ledger.area`.
var ledger: BuildLedger:
	set(value):
		ledger = value
		if session != null:
			session.ledger = value
## Who is building: "studio" (everything) or "player" (the open items and allowances). VOXEL_BUILD_POLICY=player tries the latter.
var build_policy: String = "studio"
var view: ClearingView
var session: GameSession
var builder: BuildMode
var hud: Hud
## What F would do, shown over the resident or the thing itself, and the marks over residents with something to say.
var prompts: WorldPrompts
var notebook: NotebookPanel
var title: TitleScreen
var surface: SubViewportContainer
var world_viewport: SubViewport
var playing: bool = false
var notebook_open: bool = false
var _overlay: Control
var _veil: ColorRect
var _modals: Array[Modal] = []
var _save_timer: Timer
var _drawer_tween: Tween
var _flow_busy: bool = false
var _hint_timer: Timer
var _opened_once: bool = false
var _source: Dictionary = {}
var _build_catalog: Dictionary = {}
var _interior_catalog: Dictionary = {}
var _people: Dictionary = {}
var _rooms: Dictionary = {}
var _inside_id: String = ""
var _outer_ledger: BuildLedger
var _outer_save: Dictionary = {}
var _outer_source: Dictionary = {}
var _met_villagers: Dictionary = {}
var _dialogue_read: Dictionary = {}
var _interaction: Dictionary = {}
var _interaction_clock: float = 0.0


func _ready() -> void:
	theme = UITheme.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings.load_file()
	settings.changed.connect(_on_setting_changed)
	_source = AreaStore.read_source(AREA_ID)
	_build_catalog = AreaStore.read_build_catalog()
	_interior_catalog = AreaStore.read_interiors()
	_people = AreaStore.read_villagers()
	if OS.get_environment("VOXEL_BUILD_POLICY") == "player":
		build_policy = "player"
	if _source.ok:
		ledger = _new_ledger([])
		area = ledger.area
	else:
		for problem: String in _source.errors:
			push_error("Area '%s': %s" % [AREA_ID, problem])
	if area == null:
		var message := UI.label("The area document could not be loaded. See the console for details.", &"", 24, Pal.RED)
		message.position = Vector2(40, 40)
		add_child(message)
		return
	_build_world()
	view.set_character_skin(str(settings.get_value("character_skin")))
	session = GameSession.new()
	session.name = "Session"
	add_child(session)
	session.player_name = SaveStore.player_name()
	session.begin(area, view)
	session.door_catalog = _interior_catalog
	session.doorway_requested.connect(_on_doorway_requested)
	session.ledger = ledger
	session.extra_abilities = _granted_abilities()
	session.build_changed.connect(_on_build_edited)
	session.progress_saved.connect(_queue_save.bind(0.4))
	session.source_changed.connect(_queue_save.bind(1.6))
	hud = Hud.new()
	hud.setup(session, settings)
	hud.visible = false
	hud.notebook_requested.connect(toggle_notebook)
	hud.journal_requested.connect(open_journal)
	hud.map_requested.connect(open_map)
	hud.menu_requested.connect(open_pause)
	hud.build_requested.connect(open_build)
	add_child(hud)
	prompts = WorldPrompts.new()
	prompts.setup(view, surface, world_viewport)
	prompts.pressed.connect(interact)
	hud.add_child(prompts)
	hud.move_child(prompts, 0)
	notebook = NotebookPanel.new()
	notebook.setup(session, settings)
	notebook.visible = false
	notebook.close_requested.connect(close_notebook)
	add_child(notebook)
	_place_notebook(false)
	builder = BuildMode.new()
	builder.name = "Build"
	add_child(builder)
	builder.setup(view, session, surface, world_viewport, self, ledger)
	builder.exit_requested.connect(close_build)
	builder.edited.connect(_on_build_edited)
	builder.code_requested.connect(_on_build_code)
	title = null
	_overlay = Control.new()
	_overlay.name = "Overlay"
	UI.full_rect(_overlay)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_veil = ColorRect.new()
	_veil.color = Color(0.04, 0.03, 0.02, 1.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(_veil)
	_veil.modulate.a = 0.0
	add_child(_veil)
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.timeout.connect(save_now)
	add_child(_save_timer)
	_hint_timer = Timer.new()
	_hint_timer.one_shot = true
	_hint_timer.timeout.connect(_first_run_hint)
	add_child(_hint_timer)
	session.quest_completed.connect(_on_quest_completed)
	_apply_display()
	view.set_zoom(float(settings.get_value("zoom")))
	get_tree().set_auto_accept_quit(false)
	show_title()


# -------------------------------------------------------------------- flow
func show_title() -> void:
	close_build()
	playing = false
	close_notebook(true)
	hud.visible = false
	if title != null:
		title.queue_free()
	view.set_camera_mode(ClearingView.CameraMode.CINEMATIC)
	view.set_zoom(14.0)
	view.set_quest_marker(null)
	_hint_timer.stop()
	view.apply_state(_celebration_state())
	var save: Dictionary = SaveStore.read()
	var summary: String = ""
	if not save.is_empty():
		var burning: int = _saved_lamps(save)
		var main_quests: Array[Dictionary] = Quests.main(area)
		var main_done: int = main_quests.filter(func(entry: Dictionary) -> bool: return (save.get("completed", []) as Array).has(entry.id)).size()
		summary = "%s · %d of %d quests · %d %s burning" % [str(save.get("name", SaveStore.DEFAULT_NAME)), main_done, main_quests.size(), burning, "lamp" if burning == 1 else "lamps"]
	title = TitleScreen.new()
	title.setup(not save.is_empty(), summary)
	title.continue_requested.connect(continue_game)
	title.new_game_requested.connect(_new_game_flow)
	title.character_requested.connect(func() -> void: _open_character("view", save))
	title.settings_requested.connect(open_settings)
	title.quit_requested.connect(quit_game)
	add_child(title)
	move_child(title, _overlay.get_index())
	title.focus_first.call_deferred()
	_update_input_gate()


func continue_game() -> void:
	var save: Dictionary = SaveStore.read()
	if save.is_empty():
		return
	await _fade(func() -> void:
		session.player_name = str(save.get("name", SaveStore.player_name()))
		_load_edits(save.get("edits", []))
		session.begin(area, view, save)
		_restore_places(save)
		_enter_play())


func start_new_game() -> void:
	SaveStore.delete()
	await _fade(func() -> void:
		session.player_name = SaveStore.player_name()
		_load_edits([])
		session.begin(area, view)
		_rooms.clear()
		_met_villagers.clear()
		_dialogue_read.clear()
		_enter_play())


func _new_game_flow() -> void:
	if SaveStore.has_save():
		var confirm := ConfirmDialog.new()
		confirm.ask("Begin a new journey?", "Your saved journey in Kindle Hollow will be replaced. Your name and settings stay.", "Replace it", true)
		confirm.confirmed.connect(func() -> void: _open_character("new", {}))
		_push_modal(confirm)
	else:
		_open_character("new", {})


func _enter_play() -> void:
	playing = true
	if title != null:
		title.queue_free()
		title = null
	hud.visible = true
	hud.set_notebook_open(false)
	view.set_camera_mode(ClearingView.CameraMode.FOLLOW)
	view.set_zoom(11.0 if inside_house() else float(settings.get_value("zoom")))
	view.set_warmth(0.75 if inside_house() else 0.28, not inside_house())
	view.apply_state(session.state)
	view.focus_on(Vector2(session.player_cell()), true)
	notebook.reload_from_session()
	close_notebook(true)
	_update_input_gate()
	save_now()
	_opened_once = false
	if session.completed.is_empty() and int(session.stats.runs) == 0:
		_hint_timer.start(22.0)


func quit_game() -> void:
	if playing:
		save_now()
	get_tree().quit()


func save_now() -> void:
	if playing and session != null:
		var data: Dictionary
		if _inside_id != "":
			_cache_room()
			data = _outer_save.duplicate(true)
			data.source = session.source
			data.stats = session.stats.duplicate()
			data.name = session.player_name
		else:
			data = session.to_save()
			data["edits"] = ledger.edits.duplicate(true)
		data["travel"] = {"version": 1, "active": _inside_id, "rooms": _rooms.duplicate(true)}
		data["met_villagers"] = _met_villagers.duplicate()
		data["dialogue_read"] = _dialogue_read.duplicate(true)
		SaveStore.write(data)


## VOXEL_CODE_ABILITIES=all (or a comma list such as read,turn) lets the player's code use the building API before
## the lessons that teach it exist, the way VOXEL_BUILD_POLICY=player lets you try the villager's allowances.
func _granted_abilities() -> Array[String]:
	var granted: Array[String] = []
	var wanted: String = OS.get_environment("VOXEL_CODE_ABILITIES").strip_edges()
	for ability: String in AreaDef.CAPABILITIES:
		if wanted == "all" or wanted.split(",").has(ability):
			granted.append(ability)
	return granted


func _new_ledger(saved: Array) -> BuildLedger:
	return BuildLedger.new(_source.document, _source.assets, _source.quests, _build_catalog, saved, build_policy, AreaStore.ground_materials())


## Rebuilds the world from the base document and a list of saved edits (or none, for a new game), and draws it.
func _load_edits(saved: Variant) -> void:
	close_build()
	_source = AreaStore.read_source(AREA_ID)
	_inside_id = ""
	_outer_ledger = null
	_outer_save.clear()
	ledger = _new_ledger(saved as Array if saved is Array else [])
	if builder != null:
		builder.ledger = ledger
	for problem: String in ledger.problems:
		push_warning(problem)
	area = ledger.area
	if view.area.id != area.id:
		view.setup(area)
	else:
		view.sync_edits(area, false)
	view.set_character_skin("adventurer")


# ------------------------------------------------------------ houses and residents
func inside_house() -> bool:
	return _inside_id != ""


func _process(delta: float) -> void:
	if not playing or hud == null:
		return
	_interaction_clock += delta
	if _interaction_clock >= 0.12:
		_interaction_clock = 0.0
		_refresh_interaction()


func _refresh_interaction() -> void:
	_interaction = {}
	prompts.set_markers(_resident_marks())
	if not playing or builder.active or notebook_open or not _modals.is_empty() or _flow_busy:
		prompts.set_target("")
		if view.villagers != null:
			view.villagers.paused = true
		return
	if view.villagers != null:
		view.villagers.paused = false
	if view.villagers != null:
		var resident: String = view.villagers.near(Vector2(session.player_cell()))
		if resident != "" and _people.has(resident):
			_interaction = {"kind": "talk", "id": resident, "label": "Talk to " + str(_people[resident].name)}
	if _interaction.is_empty():
		var prop: Dictionary = PropInteractions.nearest(session.rules, session.state)
		if not prop.is_empty():
			_interaction = {"kind": "prop", "id": prop.id, "label": PropInteractions.label(prop, bool((session.state.get("props", {}) as Dictionary).get(prop.id, false)))}
	var kind: String = str(_interaction.get("kind", ""))
	prompts.set_target(kind, str(_interaction.get("id", "")), str(prompts.markers.get(_interaction.get("id", ""), "")) if kind == "talk" else "", "F  ·  " + str(_interaction.label) if kind != "" else "")


## The mark over each resident here: "?" when they can help with the current lesson and "!" when they have
## something you have not heard (VillageDialogue.marker); residents with nothing new get none.
func _resident_marks() -> Dictionary:
	var marks: Dictionary = {}
	if view.villagers == null or session == null:
		return marks
	var quest: String = str(session.current_quest().get("id", ""))
	for id: String in view.villagers.actors:
		if _people.has(id):
			var mark: String = VillageDialogue.marker(_people[id], _dialogue_read.get(id, []), _met_villagers.has(id), quest)
			if mark != "":
				marks[id] = mark
	return marks


func interact() -> void:
	if not playing or _flow_busy or session.busy or session.is_walking() or notebook_open or builder.active or not _modals.is_empty():
		return
	_refresh_interaction()
	match str(_interaction.get("kind", "")):
		"prop":
			if session.use_prop(str(_interaction.id)):
				save_now()
				_refresh_interaction()
		"talk":
			var id: String = str(_interaction.id)
			# Face each other before the conversation opens.
			var other: Vector3 = (view.villagers.actors[id] as Node3D).position
			session.turn_toward(session._direction_toward(session.player_cell(), Vector2i(Vector2(other.x, -other.z).round())))
			view.villagers.face(id, Vector2(session.player_cell()))
			var conversation := VillageConversation.new()
			conversation.setup(_people[id], settings, _dialogue_read.get(id, []))
			conversation.settings_requested.connect(open_settings)
			conversation.notebook_requested.connect(func() -> void:
				conversation.close()
				open_notebook())
			conversation.read_changed.connect(func(keys: Array) -> void:
				_dialogue_read[id] = keys.duplicate()
				_queue_save(0.4))
			_met_villagers[id] = true
			_push_modal(conversation)
			if view.villagers != null:
				view.villagers.paused = true
			save_now()


func _house_title(id: String) -> String:
	for resident: Dictionary in (_outer_ledger.area if inside_house() else area).villagers:
		if resident.home == id and _people.has(resident.id):
			return str(_people[resident.id].name) + "'s home"
	var house: Dictionary = (_outer_ledger.area if inside_house() else area).building(id)
	return ledger.title_for_asset(str(house.get("asset", "")))


func _on_doorway_requested(house: String) -> void:
	if _flow_busy or not playing or notebook_open or builder.active or not _modals.is_empty():
		return
	if house == "":
		leave_house()
	else:
		enter_house(house)


func enter_house(id: String) -> bool:
	if inside_house() or session.busy or session.is_walking() or _flow_busy or not playing:
		return false
	var entry: Dictionary = HouseInstances.check_enter(area, session.rules, session.state, id, _interior_catalog)
	if not entry.ok:
		hud.show_toast(str(entry.reason))
		return false
	var source: Dictionary = _room_source(entry)
	if not source.get("ok", false):
		hud.show_toast("This home could not be opened.")
		return false
	session.prepare_travel()
	_outer_ledger = ledger
	_outer_source = _source
	_outer_save = session.to_save()
	_outer_save["edits"] = ledger.edits.duplicate(true)
	# Store the actual doorstep, so Continue/exit returns safely even if arrival was from its neighbor.
	_outer_save.state.player = [entry.return_cell[0], entry.return_cell[1], 0]
	var house: Dictionary = area.building(id)
	var outward := Vector2(HouseInstances.OUTWARD[house.facing])
	var approach := Vector2(float(entry.return_cell[0]), float(entry.return_cell[1]))
	var half: float = house.rect.size.x * 0.5 if outward.x != 0.0 else house.rect.size.y * 0.5
	var threshold: Vector2 = house.at + outward * (half - 0.25 * float(house.scale))
	await _fade(func() -> void: _activate_room(entry, source), approach, threshold, id)
	save_now()
	return true


func _room_source(entry: Dictionary) -> Dictionary:
	var id: String = str(_interior_catalog.templates.get(entry.template, ""))
	if id == "":
		return {"ok": false}
	var source: Dictionary = AreaStore.read_source(id)
	if not source.ok:
		return source
	source.document = source.document.duplicate(true)
	source.document.title = _house_title(str(entry.house))
	var parent: AreaDef = _outer_ledger.area if inside_house() else area
	for resident: Dictionary in parent.villagers:
		if resident.home == entry.house and source.document.interior.has("host"):
			var host: Dictionary = source.document.interior.host
			source.document["villagers"] = [{"id": resident.id, "at": host.at.duplicate(), "route": host.route.duplicate(true), "home": ""}]
	return source


func _activate_room(entry: Dictionary, source: Dictionary) -> void:
	var saved: Dictionary = (_rooms.get(entry.instance, {}) as Dictionary).get("save", {}).duplicate(true)
	saved.source = session.source
	saved.stats = session.stats.duplicate()
	_rooms[entry.instance] = {"house": entry.house, "template": entry.template, "save": saved}
	_inside_id = str(entry.instance)
	_source = source
	var room_edits: Array = saved.get("edits", []) if saved.get("edits", []) is Array else []
	ledger = BuildLedger.new(source.document, source.assets, source.quests, _build_catalog, room_edits, build_policy, AreaStore.ground_materials())
	area = ledger.area
	view.setup(area)
	view.set_character_skin("adventurer")
	session.begin(area, view, saved)
	view.set_zoom(11.0)
	view.set_warmth(0.75)
	notebook.reload_from_session()
	_refresh_interaction()


func _cache_room() -> void:
	if _inside_id != "" and _rooms.has(_inside_id):
		_rooms[_inside_id].save = session.to_save()
		_rooms[_inside_id].save["edits"] = ledger.edits.duplicate(true)


func leave_house() -> bool:
	if not inside_house() or session.busy or session.is_walking() or _flow_busy or not HouseInstances.can_exit(area, session.state):
		return false
	session.prepare_travel()
	_cache_room()
	_outer_save.source = session.source
	_outer_save.stats = session.stats.duplicate()
	var exit: Array = area.interior.exit
	var start := Vector2(float(exit[0]), float(exit[1]))
	await _fade(_activate_exterior, start, start + Vector2(0, -0.8))
	save_now()
	return true


func _activate_exterior() -> void:
	_source = _outer_source
	ledger = _outer_ledger
	area = ledger.area
	_inside_id = ""
	view.setup(area)
	view.set_character_skin("adventurer")
	session.begin(area, view, _outer_save)
	view.set_zoom(float(settings.get_value("zoom")))
	view.set_warmth(0.28, true)
	builder.ledger = ledger
	notebook.reload_from_session()
	_refresh_interaction()


func _restore_places(save: Dictionary) -> void:
	_met_villagers = save.get("met_villagers", {}).duplicate(true) if save.get("met_villagers") is Dictionary else {}
	_dialogue_read = VillageDialogue.restore_read(save.get("dialogue_read", {}), _people)
	var travel: Variant = save.get("travel", {})
	_rooms = HouseInstances.valid_saved_rooms(travel.get("rooms", {}), area, _interior_catalog) if travel is Dictionary and travel.get("version") == 1 else {}
	var active: String = str(travel.get("active", "")) if travel is Dictionary else ""
	if not _rooms.has(active):
		return
	var room: Dictionary = _rooms[active]
	var entry: Dictionary = {"house": room.house, "template": room.template, "instance": active}
	var source: Dictionary = _room_source(entry)
	if not source.ok:
		return
	_outer_ledger = ledger
	_outer_source = _source
	_outer_save = save.duplicate(true)
	_activate_room(entry, source)


func _queue_save(delay: float) -> void:
	if playing and _save_timer != null:
		_save_timer.start(delay)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			quit_game()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_apply_frame_rate(true)
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_apply_frame_rate(false)


# ----------------------------------------------------------------- notebook
func toggle_notebook() -> void:
	if notebook_open:
		close_notebook()
	else:
		open_notebook()


func open_notebook() -> void:
	if not playing or notebook_open or not _modals.is_empty():
		return
	notebook_open = true
	_opened_once = true
	notebook.visible = true
	_place_notebook(true)
	hud.set_notebook_open(true)
	hud.set_right_inset(DRAWER_WIDTH + DRAWER_MARGIN)
	view.set_view_shift(DRAWER_WIDTH / maxf(1.0, size.x) * 0.5)


func close_notebook(instant: bool = false) -> void:
	if not notebook_open and not instant:
		return
	notebook_open = false
	notebook.drop_focus()
	if hud != null:
		hud.set_notebook_open(false)
		hud.set_right_inset(0.0)
	view.set_view_shift(0.0)
	if instant:
		notebook.visible = false
		_place_notebook(false)
	else:
		_place_notebook(false)


func _place_notebook(open: bool) -> void:
	notebook.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	notebook.offset_top = DRAWER_MARGIN
	notebook.offset_bottom = -DRAWER_MARGIN
	var shown_left: float = -(DRAWER_WIDTH + DRAWER_MARGIN)
	var shown_right: float = -DRAWER_MARGIN
	var hidden_shift: float = DRAWER_WIDTH + DRAWER_MARGIN * 2.0
	var from_left: float = notebook.offset_left
	var target_left: float = shown_left if open else shown_left + hidden_shift
	var target_right: float = shown_right if open else shown_right + hidden_shift
	if _drawer_tween != null:
		_drawer_tween.kill()
	if not is_inside_tree() or not notebook.visible:
		notebook.offset_left = target_left
		notebook.offset_right = target_right
		return
	if open and from_left == 0.0:
		notebook.offset_left = shown_left + hidden_shift
		notebook.offset_right = shown_right + hidden_shift
	_drawer_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_drawer_tween.tween_property(notebook, "offset_left", target_left, 0.26)
	_drawer_tween.tween_property(notebook, "offset_right", target_right, 0.26)
	if not open:
		_drawer_tween.chain().tween_callback(func() -> void:
			if not notebook_open:
				notebook.visible = false)


func _first_run_hint() -> void:
	if playing and not _opened_once and _modals.is_empty():
		hud.show_toast("Press E to open your notebook")


## The last quest sets off a ring of light from the beacon, then an epilogue.
func _on_quest_completed(quest: Dictionary) -> void:
	# The epilogue belongs to the main arc: finishing a later, optional chapter never repeats it.
	if bool(quest.get("optional", false)) or not Quests.main_arc_done(area, session.completed):
		return
	var beacon: Dictionary = area.lamp("beacon")
	if not beacon.is_empty():
		view.celebrate(beacon.at)
	await get_tree().create_timer(3.4).timeout
	if playing and _modals.is_empty():
		close_notebook()
		var epilogue := EpilogueScreen.new()
		epilogue.setup(area, session.stats, session.player_name, session.current_quest())
		epilogue.title_requested.connect(_return_to_title)
		_push_modal(epilogue)


# -------------------------------------------------------------- build mode
## Build mode: the camera frees itself, the play HUD steps aside and the builder takes the pointer and keys.
func open_build() -> void:
	if not playing or builder.active or not _modals.is_empty():
		return
	if inside_house():
		_open_room_finishes()
		return
	close_notebook(true)
	hud.visible = false
	builder.ledger = ledger
	builder.enter()
	_update_input_gate()


func _open_room_finishes() -> void:
	close_notebook(true)
	session.prepare_travel()
	var panel := RoomFinishes.new()
	panel.setup(area, ledger)
	panel.finish_chosen.connect(func(slot: String, material: String) -> void:
		_commit_room_finish(panel, ledger.finish("room", "", slot, material, session.state)))
	panel.undo_requested.connect(func() -> void: _commit_room_finish(panel, ledger.undo(session.state)))
	panel.redo_requested.connect(func() -> void: _commit_room_finish(panel, ledger.redo(session.state)))
	_push_modal(panel)


func _commit_room_finish(panel: RoomFinishes, result: Dictionary) -> void:
	if result.ok:
		area = ledger.area
		session.replace_area(area, ledger.rules)
		view.setup(area)
		view.apply_state(session.state)
		view.set_camera_mode(ClearingView.CameraMode.FOLLOW)
		view.set_zoom(11.0)
		view.set_warmth(0.75)
		view.focus_on(Vector2(session.player_cell()), true)
		_update_input_gate()
		save_now()
	panel.refresh(area, ledger, "Saved this home's materials." if result.ok else str(result.reason))


func close_build() -> void:
	if builder == null or not builder.active:
		return
	builder.leave()
	if playing:
		hud.visible = true
		view.set_camera_mode(ClearingView.CameraMode.FOLLOW)
		view.set_zoom(float(settings.get_value("zoom")))
		view.focus_on(Vector2(session.player_cell()))
		save_now()
	_update_input_gate()


func _on_build_edited(_label: String) -> void:
	area = ledger.area
	_queue_save(0.4)


## "Write code for it" in the details panel: leave building, open the notebook and add the line that fetches the thing.
func _on_build_code(snippet: String) -> void:
	close_build()
	open_notebook()
	notebook.insert_snippet(snippet)


# ------------------------------------------------------------------- modals
func open_pause() -> void:
	if not playing or not _modals.is_empty():
		return
	save_now()
	var pause := PauseMenu.new()
	var zone: Dictionary = area.zone(session.current_zone) if session.current_zone != "" else {}
	pause.setup(session.player_name, area.title if inside_house() else str(zone.get("title", area.title)), inside_house())
	pause.resume_requested.connect(pause.close)
	pause.journal_requested.connect(open_journal)
	pause.map_requested.connect(open_map)
	pause.character_requested.connect(func() -> void: _open_character("view", {}))
	pause.settings_requested.connect(open_settings)
	pause.reset_requested.connect(_confirm_reset)
	pause.title_requested.connect(func() -> void:
		pause.close()
		_return_to_title())
	pause.quit_requested.connect(quit_game)
	_push_modal(pause)


func open_journal() -> void:
	if not playing:
		return
	var journal := JournalPanel.new()
	journal.setup(session)
	journal.notebook_requested.connect(func() -> void:
		_pop_all_modals()
		open_notebook())
	_push_modal(journal)


func open_map() -> void:
	if not playing:
		return
	var map := MapPanel.new()
	map.setup(session)
	_push_modal(map)


func open_settings() -> void:
	var panel := SettingsPanel.new()
	panel.setup(settings)
	_push_modal(panel)


func _open_character(mode: String, save: Dictionary) -> void:
	var screen := CharacterScreen.new()
	var journey_area: AreaDef = _outer_ledger.area if inside_house() else area
	var options: Dictionary = {"mode": mode, "area": journey_area, "name": SaveStore.player_name(), "completed": [], "stats": {}, "lamps_lit": 0, "zones_found": 0}
	options.skin = settings.get_value("character_skin")
	if playing and mode == "view":
		options.merge({"name": session.player_name, "completed": session.completed, "stats": session.stats, "lamps_lit": session.lamps_lit(), "zones_found": (session.state.zones_seen as Array).size()}, true)
		if inside_house():
			options.completed = _outer_save.completed
			options.lamps_lit = _saved_lamps(_outer_save)
			options.zones_found = (_outer_save.state.zones_seen as Array).size()
	elif not save.is_empty():
		options.merge({"name": str(save.get("name", SaveStore.player_name())), "completed": save.get("completed", []), "stats": save.get("stats", {}),
			"lamps_lit": _saved_lamps(save), "zones_found": ((save.get("state", {}) as Dictionary).get("zones_seen", []) as Array).size()}, true)
	screen.setup(options)
	screen.skin_changed.connect(func(id: String) -> void: settings.set_value("character_skin", id))
	screen.name_changed.connect(func(new_name: String) -> void:
		if session != null:
			session.player_name = new_name)
	screen.begin_requested.connect(func() -> void:
		_pop_all_modals()
		start_new_game())
	_push_modal(screen)


func _confirm_reset() -> void:
	var confirm := ConfirmDialog.new()
	if inside_house():
		confirm.ask("Reset this room?", "This home's lamp goes dark and its program memory clears. Your notebook, discoveries and the village stay as they are.", "Reset room", true)
	else:
		confirm.ask("Start the hollow over?", "Every lamp goes dark, the bridge washes away and the gate shuts. Your code and the quests you have finished are kept.", "Start over", true)
	confirm.confirmed.connect(func() -> void:
		_pop_all_modals()
		session.reset_world())
	_push_modal(confirm)


func _return_to_title() -> void:
	await _fade(func() -> void:
		_pop_all_modals()
		save_now()
		if inside_house():
			_activate_exterior()
		show_title())


func _push_modal(modal: Modal) -> void:
	if not _modals.is_empty():
		_modals[-1].visible = false
	_modals.append(modal)
	_overlay.add_child(modal)
	modal.closed.connect(_on_modal_closed.bind(modal))
	modal.open()
	_update_input_gate()


func _on_modal_closed(modal: Modal) -> void:
	_modals.erase(modal)
	if not _modals.is_empty():
		_modals[-1].visible = true
		if _modals[-1] is PauseMenu:
			(_modals[-1] as PauseMenu).open()
	elif title != null:
		title.focus_first.call_deferred()
	_update_input_gate()


func _pop_all_modals() -> void:
	for modal: Modal in _modals.duplicate():
		_modals.erase(modal)
		modal.queue_free()
	_update_input_gate()


func _update_input_gate() -> void:
	if playing and hud != null and not (builder != null and builder.active):
		hud.visible = not _modals.any(func(modal: Modal) -> bool: return modal is VillageConversation)
	if session != null:
		session.input_enabled = playing and not _flow_busy and _modals.is_empty() and not (builder != null and builder.active)
		if view.villagers != null:
			view.villagers.paused = not session.input_enabled


# -------------------------------------------------------------------- input
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or not playing or _flow_busy or not _modals.is_empty():
		return
	var key: Key = (event as InputEventKey).keycode
	var typing: bool = notebook.has_text_focus()
	if builder.active and key != KEY_F11:
		if builder.handle_key(event as InputEventKey):
			get_viewport().set_input_as_handled()
		return
	match key:
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			if typing:
				notebook.drop_focus()
			elif notebook_open:
				close_notebook()
			else:
				open_pause()
		KEY_E:
			if not typing:
				get_viewport().set_input_as_handled()
				if notebook_open:
					close_notebook()
				else:
					open_notebook()
					notebook.focus_editor.call_deferred()
		KEY_M:
			if not typing:
				get_viewport().set_input_as_handled()
				open_map()
		KEY_B:
			if not typing:
				get_viewport().set_input_as_handled()
				open_build()
		KEY_J:
			if not typing:
				get_viewport().set_input_as_handled()
				open_journal()
		KEY_F:
			if not typing and not event.ctrl_pressed:
				get_viewport().set_input_as_handled()
				interact()
		KEY_F11:
			get_viewport().set_input_as_handled()
			settings.set_value("fullscreen", not bool(settings.get_value("fullscreen")))
		KEY_ENTER, KEY_KP_ENTER:
			if event.ctrl_pressed and notebook_open:
				get_viewport().set_input_as_handled()
				session.run_preview()


func _on_world_input(event: InputEvent) -> void:
	if not playing or _flow_busy or not _modals.is_empty():
		return
	if builder.active:
		builder.handle_world_input(event)
		return
	if event is InputEventMouseButton and event.pressed:
		var button: MouseButton = event.button_index
		if button == MOUSE_BUTTON_LEFT:
			surface.grab_focus()
			var view_point: Vector2 = event.position * Vector2(world_viewport.size) / surface.size
			var doorway: Dictionary = view.pick_door(view_point)
			if not notebook_open and not doorway.is_empty():
				session.walk_to_door(str(doorway.house))
				return
			var cell: Vector2i = view.pick_cell(view_point)
			if cell.x >= 0:
				session.click_cell(cell)
				hud.show_inspection(describe_cell(cell))
		elif button == MOUSE_BUTTON_WHEEL_UP or button == MOUSE_BUTTON_WHEEL_DOWN:
			var step: float = -0.75 if button == MOUSE_BUTTON_WHEEL_UP else 0.75
			settings.set_value("zoom", clampf(float(settings.get_value("zoom")) + step, 8.0, 20.0))


## One line about a cell, so players can read terrain, zones and the ids their code uses.
func describe_cell(cell: Vector2i) -> String:
	var parts: PackedStringArray = ["[%d, %d]" % [cell.x, cell.y]]
	var zone_id: String = area.zone_at(cell)
	if zone_id != "":
		parts.append(str(area.zone(zone_id).title))
	parts.append(TERRAIN_NAMES[maxi(0, area.terrain_at(cell))])
	for lamp: Dictionary in area.lamps:
		if lamp.cell == cell:
			parts.append("lamp \"%s\" · %s" % [lamp.id, "lit" if session.state.lamps[lamp.id] else "dark"])
	for gate: Dictionary in area.gates:
		if gate.cell == cell:
			parts.append("gate \"%s\" · %s" % [gate.id, "open" if session.state.gates[gate.id] else "shut"])
	var socket: Dictionary = area.socket(cell)
	if not socket.is_empty():
		parts.append("bridge \"%s\" socket %d · %s" % [socket.bridge, int(socket.order) + 1, "deck down" if session.rules.deck_built(session.state, cell) else "no deck"])
	if not session.rules.is_walkable(session.state, cell):
		parts.append("blocked")
	return "  ·  ".join(parts)


# ------------------------------------------------------------------ plumbing
func _build_world() -> void:
	surface = SubViewportContainer.new()
	surface.name = "World"
	surface.stretch = true
	surface.focus_mode = Control.FOCUS_ALL
	UI.full_rect(surface)
	surface.gui_input.connect(_on_world_input)
	add_child(surface)
	world_viewport = SubViewport.new()
	world_viewport.own_world_3d = true
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# 2x looks the same as 4x at this camera scale and costs about a third as much on an integrated GPU.
	world_viewport.msaa_3d = Viewport.MSAA_2X
	world_viewport.size = Vector2i(1600, 1000)
	surface.add_child(world_viewport)
	view = ClearingView.new()
	world_viewport.add_child(view)
	view.setup(area)


func _celebration_state() -> Dictionary:
	var rules := session.rules if session != null else LabWorld.new(area)
	var state: Dictionary = rules.initial_state()
	for lamp: Dictionary in area.lamps:
		state.lamps[lamp.id] = true
	for gate: Dictionary in area.gates:
		state.gates[gate.id] = true
	for bridge: Dictionary in area.bridges:
		state.bridges[bridge.id] = (bridge.sockets as Array).size()
	state.player = [29, 21, 0]
	return state


func _saved_lamps(save: Dictionary) -> int:
	var count: int = 0
	for lit: Variant in ((save.get("state", {}) as Dictionary).get("lamps", {}) as Dictionary).values():
		if lit == true:
			count += 1
	return count


func _fade(action: Callable, approach: Vector2 = Vector2.INF, threshold: Vector2 = Vector2.INF, house: String = "") -> void:
	if _flow_busy:
		return
	_flow_busy = true
	_update_input_gate()
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	if approach.is_finite():
		if house != "":
			view.open_door(house)
		view.set_player_motion(threshold - approach)
		var walk := create_tween()
		walk.tween_method(func(t: float) -> void: view.interpolate_player(approach, threshold, t), 0.0, 1.0, 0.38)
		await walk.finished
		view.set_player_motion(Vector2.ZERO)
	var down := create_tween()
	down.tween_property(_veil, "modulate:a", 1.0, 0.25)
	await down.finished
	action.call()
	await get_tree().process_frame
	var up := create_tween()
	up.tween_property(_veil, "modulate:a", 0.0, 0.4)
	await up.finished
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flow_busy = false
	_update_input_gate()


func _apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var window: Window = get_window()
	window.content_scale_factor = float(settings.get_value("ui_scale"))
	window.mode = Window.MODE_FULLSCREEN if bool(settings.get_value("fullscreen")) else Window.MODE_WINDOWED
	_apply_frame_rate(DisplayServer.window_is_focused())


func _apply_frame_rate(focused: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	Engine.max_fps = FRAME_RATE if focused else BACKGROUND_FRAME_RATE


func _on_setting_changed(key: String) -> void:
	match key:
		"fullscreen", "ui_scale":
			_apply_display()
		"zoom":
			if playing:
				view.set_zoom(float(settings.get_value("zoom")))
		"character_skin":
			view.set_character_skin(str(settings.get_value("character_skin")))
