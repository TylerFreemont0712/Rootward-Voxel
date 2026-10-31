class_name Game
extends Control
## The whole game: one persistent 3D valley behind a title screen, a play HUD, the notebook drawer and
## a stack of modal screens. It owns flow (title, new game, continue, pause, quit) and saving; the
## GameSession owns what happens inside the world.

const AREA_ID: String = "kindle-hollow"
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
var workshop_speech: WorkshopSpeech
var notebook: NotebookPanel
var movement_lesson: LearningLesson
var title: TitleScreen
var surface: SubViewportContainer
var world_viewport: SubViewport
var playing: bool = false
var notebook_open: bool = false
var _overlay: Control
var _veil: GearVeil
var _veil_open_origin: Variant = null
var _modals: Array[Modal] = []
var _save_timer: Timer
var _flow_busy: bool = false
var _hint_timer: Timer
var _opened_once: bool = false
var _source: Dictionary = {}
var _build_catalog: Dictionary = {}
var _interior_catalog: Dictionary = {}
var _people: Dictionary = {}
var _rooms: Dictionary = {}
var _journey_rooms: Dictionary = {}
var _inside_id: String = ""
var _outer_ledger: BuildLedger
var _outer_save: Dictionary = {}
var _outer_source: Dictionary = {}
var _met_villagers: Dictionary = {}
var _dialogue_read: Dictionary = {}
var _workshop_dismissed: Array = []
var _workshop_log: Array = []
var _banter_index: int = 0
var _interaction: Dictionary = {}
var _interaction_clock: float = 0.0
var _pending_room_target: String = ""
var _slate_link: SlateLink
var _level_id: String = LevelStore.MAIN_LEVEL
var _root_area_id: String = "workshop-loft"
var _pending_level_id: String = LevelStore.MAIN_LEVEL
## The playing journey's catalog entry and story file. Optional entry fields (look, companion, journal, story,
## build, character) default to the original behaviour when absent.
var _level_spec: Dictionary = {}
var _story: Dictionary = {}
var _stairs_said: float = -10.0
## A room that authors its own interior zoom is scaled by how far the player has wheeled in or out. The factor is
## remembered across that journey's rooms for the session only; the Camera zoom setting stays the outdoor choice.
var _room_zoom_scale: float = 1.0

const ROOM_ZOOM_RANGE: Vector2 = Vector2(0.55, 1.4)
const ROOM_ZOOM_NOTCH: float = 0.92
## While the field slate is up the room draws back a little, so it fits between the notepad and the slate.
const SLATE_PULL_BACK: float = 1.24
## How far, in cells, Hotaru can be from the traveller and still be spoken to. She sits on furniture.
const COMPANION_REACH: float = 1.6
## The clockwork veil between places: how long it takes to grow over the scene, to sit there while the next one is
## made, and to open on the new one.
const VEIL_CLOSE_SECONDS: float = 0.55
const VEIL_OPEN_SECONDS: float = 0.7
## The veil stays closed at least this long, the time the next place takes to build included, so the gears are
## always seen turning before the way opens.
const VEIL_CLOSED_SECONDS: float = 0.55
## Walking through a doorway: how long the doors swing before the traveller steps into them, how long the traveller
## is seen walking before the veil starts to grow, and how far behind the arrival cell they come from.
const DOOR_LEAD_SECONDS: float = 0.18
const WALK_LEAD_SECONDS: float = 0.16
const ARRIVE_CELLS: float = 0.9


func _ready() -> void:
	theme = UITheme.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings.load_file()
	settings.changed.connect(_on_setting_changed)
	_level_id=LevelStore.default_id()
	_pending_level_id=_level_id
	_root_area_id=str(LevelStore.entry(_level_id).area)
	_source = AreaStore.read_source(_root_area_id)
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
			push_error("Area '%s': %s" % [_root_area_id, problem])
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
	session.room_link_requested.connect(travel_room_link)
	session.state_changed.connect(func() -> void:
		if view != null and view.stage != null:
			view.stage.sync_progress(session.state, session.completed))
	session.ledger = ledger
	session.extra_abilities = _granted_abilities()
	session.build_changed.connect(_on_build_edited)
	session.progress_saved.connect(_queue_save.bind(0.4))
	session.source_changed.connect(_queue_save.bind(1.6))
	_wire_hud(Hud.new())
	prompts = WorldPrompts.new()
	prompts.setup(view, surface, world_viewport)
	prompts.pressed.connect(interact)
	hud.add_child(prompts)
	hud.move_child(prompts, 0)
	workshop_speech = WorkshopSpeech.new()
	workshop_speech.setup(view, surface, world_viewport)
	add_child(workshop_speech)
	notebook = NotebookPanel.new()
	notebook.setup(session, settings)
	notebook.visible = false
	notebook.close_requested.connect(close_notebook)
	notebook.extent_changed.connect(_drawer_extent_changed)
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
	_veil = GearVeil.new()
	UI.full_rect(_veil)
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


func _wire_hud(next: Hud) -> void:
	hud = next
	hud.setup(session, settings)
	hud.visible = false
	hud.notebook_requested.connect(toggle_notebook)
	hud.journal_requested.connect(open_journal)
	hud.map_requested.connect(open_map)
	hud.menu_requested.connect(open_pause)
	hud.build_requested.connect(open_build)
	add_child(hud)


## A journey with "look": "paper" gets the paper-and-enamel HUD; every other journey keeps the default one.
func _ensure_hud(look: String) -> void:
	if (look == "paper") == (hud is PaperHud):
		return
	var old: Hud = hud
	var index: int = old.get_index()
	var visible_before: bool = old.visible
	_wire_hud(PaperHud.new() if look == "paper" else Hud.new())
	move_child(hud, index)
	prompts.reparent(hud, false)
	hud.move_child(prompts, 0)
	hud.visible = visible_before
	old.queue_free()


func _apply_level_spec(spec: Dictionary) -> void:
	_level_spec = spec
	_story = JourneyStory.read(str(spec.get("story", "")))
	_ensure_hud(str(spec.get("look", "")))
	view.set_marker_style("paper" if str(spec.get("look", "")) == "paper" else "")
	if hud is PaperHud:
		(hud as PaperHud).story = _story


func _journal_kind() -> String:
	return str(_level_spec.get("journal", ""))


## The room's zoom and warmth also suit a journey whose first area is itself a room.
func _indoors() -> bool:
	return inside_house() or not area.interior.is_empty()


# -------------------------------------------------------------------- flow
func show_title() -> void:
	close_build()
	playing = false
	close_notebook(true)
	hud.visible = false
	if title != null:
		title.queue_free()
	view.set_camera_mode(ClearingView.CameraMode.FIXED if not area.interior.is_empty() else ClearingView.CameraMode.CINEMATIC)
	if not area.interior.is_empty():view.focus_on(Vector2(area.width*.5,area.height*.5),true)
	view.set_zoom(14.0)
	view.set_quest_marker(null)
	_hint_timer.stop()
	_apply_level_spec(LevelStore.entry(LevelStore.default_id()))
	view.apply_state(_celebration_state())
	var resume_level: String = LevelStore.resumable()
	var save: Dictionary = SaveStore.read(resume_level)
	var summary: String = ""
	if not save.is_empty():
		var burning: int = _saved_lamps(save)
		var main_quests: Array[Dictionary] = Quests.main(area)
		var main_done: int = main_quests.filter(func(entry: Dictionary) -> bool: return (save.get("completed", []) as Array).has(entry.id)).size()
		summary = "%s · %d of %d quests · %d %s burning" % [str(save.get("name", SaveStore.DEFAULT_NAME)), main_done, main_quests.size(), burning, "lamp" if burning == 1 else "lamps"]
		if resume_level != AREA_ID:
			summary = "%s · %s" % [str(save.get("name",SaveStore.DEFAULT_NAME)),str(LevelStore.entry(resume_level).get("title",resume_level))]
	title = TitleScreen.new()
	title.setup(not save.is_empty(), summary)
	title.continue_requested.connect(continue_game)
	title.new_game_requested.connect(_new_game_flow)
	title.character_requested.connect(func() -> void: _open_character("view", save))
	title.settings_requested.connect(open_settings)
	title.showcase_requested.connect(open_asset_showcase)
	title.quit_requested.connect(quit_game)
	add_child(title)
	move_child(title, _overlay.get_index())
	title.focus_first.call_deferred()
	_update_input_gate()


func continue_game(level: String = "") -> void:
	if level=="":level=LevelStore.resumable()
	var spec: Dictionary = LevelStore.entry(level)
	var save: Dictionary = SaveStore.read(level)
	if spec.is_empty() or save.is_empty() or str(save.get("area",""))!=str(spec.area):
		return
	_pending_room_target = ""
	await _fade(func() -> void:
		_level_id=level
		_root_area_id=str(spec.area)
		_journey_rooms.clear()
		_apply_level_spec(spec)
		SaveStore.set_last_level(level)
		session.player_name = str(save.get("name", SaveStore.player_name()))
		_load_edits(save.get("edits", []))
		session.begin(area, view, save)
		_restore_places(save)
		_enter_play())


func start_new_game(level: String = "") -> void:
	if level=="":level=LevelStore.default_id()
	var spec: Dictionary = LevelStore.entry(level)
	if spec.is_empty():return
	_pending_room_target = ""
	SaveStore.delete(level)
	await _fade(func() -> void:
		_level_id=level
		_root_area_id=str(spec.area)
		_journey_rooms.clear()
		_apply_level_spec(spec)
		SaveStore.set_last_level(level)
		session.player_name = SaveStore.player_name()
		_load_edits([])
		session.begin(area, view)
		_rooms.clear()
		_met_villagers.clear()
		_dialogue_read.clear()
		_workshop_dismissed.clear()
		_workshop_log.clear()
		_banter_index = 0
		_room_zoom_scale = 1.0
		if str(spec.get("opening_house",""))!="":
			_start_in_home(str(spec.opening_house))
		_enter_play())
	if level=="village-morning":
		talk_hotaru()
	elif not (_story.get("opening", {}) as Dictionary).is_empty():
		_play_opening()


## A journey's own opening: prose pages and a note, then whatever its journal shows first.
func _play_opening() -> void:
	if not playing or not _modals.is_empty():return
	var card := OpeningCard.new()
	var workshop: bool = _journal_kind() == "workshop"
	card.setup(_story.opening, workshop)
	if not workshop: card.finished.connect(func() -> void: open_notebook.call_deferred())
	_push_modal(card)

func _new_game_flow() -> void:
	_choose_level(LevelStore.default_id(),false)


func open_asset_showcase()->void:
	if playing or _flow_busy or title==null or not _modals.is_empty() or not AssetShowcase.enabled():return
	var display:=AssetShowcase.new()
	display.setup()
	var previous_update:=world_viewport.render_target_update_mode
	var previous_process:=view.process_mode
	surface.visible=false
	title.visible=false
	world_viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	view.process_mode=Node.PROCESS_MODE_DISABLED
	display.closed.connect(func()->void:
		surface.visible=true
		if is_instance_valid(title):title.visible=true
		world_viewport.render_target_update_mode=previous_update
		view.process_mode=previous_process)
	_push_modal(display)


func _choose_level(level: String, resume: bool) -> void:
	if resume:
		continue_game(level)
		return
	_pending_level_id=level
	if SaveStore.has_save(level):
		var confirm := ConfirmDialog.new()
		confirm.ask("Begin a new journey?", "Only your saved journey in %s will be replaced. Your other levels, name and settings stay." % str(LevelStore.entry(level).title), "Replace it", true)
		confirm.confirmed.connect(func() -> void: _open_character("new", {}))
		_push_modal(confirm)
	else:
		_open_character("new", {})


func _start_in_home(house: String) -> void:
	var at: Vector2i=HouseInstances.door(area,house)
	session.state.player=[at.x,at.y,0]
	var entry: Dictionary=HouseInstances.check_enter(area,session.rules,session.state,house,_interior_catalog)
	if not entry.ok:
		push_error(str(entry.reason))
		return
	var source: Dictionary=_room_source(entry)
	_outer_ledger=ledger
	_outer_source=_source
	_outer_save=session.to_save()
	_outer_save["edits"]=ledger.edits.duplicate(true)
	_activate_room(entry,source)


func _enter_play() -> void:
	playing = true
	if title != null:
		title.queue_free()
		title = null
	hud.visible = true
	hud.set_notebook_open(false)
	view.set_camera_mode(ClearingView.CameraMode.FOLLOW)
	view.set_zoom(_indoor_zoom(11.0) if _indoors() else float(settings.get_value("zoom")))
	view.set_warmth(0.75 if _indoors() else 0.28, not _indoors())
	view.apply_state(session.state)
	view.focus_on(Vector2(session.player_cell()), true)
	_sync_pickups()
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
			_carry_movement(_outer_save)
			_cache_room()
			data = _outer_save.duplicate(true)
			data.source = session.source
			data.stats = session.stats.duplicate()
			data.name = session.player_name
		else:
			data = session.to_save()
			data["edits"] = ledger.edits.duplicate(true)
		if not (_level_spec.get("room_areas", []) as Array).is_empty():
			_cache_journey_room()
			data = (_journey_rooms.get(_root_area_id, data) as Dictionary).duplicate(true)
			data["journey_rooms"] = {"version": 1, "active": area.id, "rooms": _journey_rooms.duplicate(true)}
		data["travel"] = {"version": 1, "active": _inside_id, "rooms": _rooms.duplicate(true)}
		data["met_villagers"] = _met_villagers.duplicate()
		data["dialogue_read"] = _dialogue_read.duplicate(true)
		if _journal_kind() == "workshop": data["workshop_log"] = _workshop_log.duplicate(true)
		data["level"]=_level_id
		SaveStore.write(data,_level_id)


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
	_source = AreaStore.read_source(_root_area_id)
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
	if _pending_room_target != "" and not session.is_walking() and session._route.is_empty() and not session.busy:
		var target: String = _pending_room_target
		_pending_room_target = ""
		if not notebook_open and _modals.is_empty() and not _flow_busy:
			var at: Vector2i = _room_target_approach(target)
			if at.x >= 0 and Vector2(session.player_cell()).distance_to(Vector2(at)) < FieldAccess.RANGE:
				if target == "nell-note": _activate_loft_desk(target)
				elif not PlayerItems.find(area, target).is_empty(): _activate_pickup(target)
				elif not area.lamp(target).is_empty(): _activate_device(target)
				else: _activate_terminal(target)
	_interaction_clock += delta
	if _interaction_clock >= 0.12:
		_interaction_clock = 0.0
		_sync_pickups()
		_refresh_interaction()


func _refresh_interaction() -> void:
	_interaction = {}
	prompts.set_markers(_resident_marks())
	if not playing or builder.active or notebook_open or not _modals.is_empty() or _flow_busy:
		view.set_target_highlight("")
		prompts.set_target("")
		if view.villagers != null:
			view.villagers.paused = true
		return
	if _journal_kind() == "workshop" and not session.busy and not session.is_walking() and _dialogue_read.get("loft-waking", []).has("introduced"):
		var seen: Array = (_dialogue_read.get("workshop-scenes", []) as Array) + _workshop_dismissed
		var next: String = WorkshopStory.pending(_story.get("scenes", {}), area.id, _journey_completed(), seen, session.state.lamps)
		if next != "":
			_show_workshop_scene(next)
			return
	if view.villagers != null:
		view.villagers.paused = false
	if view.villagers != null:
		var resident: String = view.villagers.near(Vector2(session.player_cell()))
		if resident != "" and _people.has(resident):
			_interaction = {"kind": "talk", "id": resident, "label": "Talk to " + str(_people[resident].name)}
	if _interaction.is_empty() and _journal_kind() == "workshop":
		if area.id == "workshop-loft" and Vector2(session.player_cell()).distance_to(Vector2(_room_target_approach("nell-note"))) < FieldAccess.RANGE and not (session.state.inspections_read as Array).has("nell-note") and not CompanionLesson.has_voice(session.state, session.completed):
			_interaction = {"kind":"loft-desk", "id":"nell-note", "label":"Read Nell’s note"}
		else:
			var pickup: Dictionary = PlayerItems.nearest(area, session.state, Vector2(session.player_cell()))
			if not pickup.is_empty() and _pickup_offered(pickup):
				_interaction = {"kind":"pickup", "id":pickup.id, "label":"Pick up " + str(pickup.title)}
			else:
				var terminal: Dictionary = ZoneTerminals.nearest(area, Vector2(session.player_cell()))
				if not terminal.is_empty(): _interaction = {"kind":"terminal", "id":terminal.id, "label":str(terminal.get("prompt", "Use " + str(terminal.title)))}
				else:
					var device: Dictionary = _device_here()
					if not device.is_empty(): _interaction = {"kind":"device", "id":device.id, "label":"Open the %s’s code" % str(device.get("title", device.id)).to_lower()}

	if _interaction.is_empty():
		var inspection: Dictionary = RoomLinks.nearest(area, Vector2(session.player_cell()), "inspections", _interact_radius())
		if not inspection.is_empty() and inspection.id not in ["nell-note", "desk-terminal"]: _interaction = {"kind": "inspection", "id": inspection.id, "label": "Look at " + str(inspection.title)}
	if _interaction.is_empty():
		var link: Dictionary = RoomLinks.nearest(area, Vector2(session.player_cell()), "links", _interact_radius())
		if not link.is_empty(): _interaction = {"kind": "room-link", "id": link.id, "label": str(link.get("label", "Take the stairs"))}
	if _interaction.is_empty():
		var prop: Dictionary = PropInteractions.nearest(session.rules, session.state)
		if not prop.is_empty():
			_interaction = {"kind": "prop", "id": prop.id, "label": PropInteractions.label(prop, bool((session.state.get("props", {}) as Dictionary).get(prop.id, false)))}
	if _interaction.is_empty() and view.companion_present() and _companion_in_reach():
		_interaction={"kind":"talk","id":"hotaru","label":"Talk to Hotaru"}
	var kind: String = str(_interaction.get("kind", ""))
	var prompt_id: String = str(_interaction.get("id", ""))
	if kind == "terminal": prompt_id = str(ZoneTerminals.find(area, prompt_id).get("object", ""))
	elif kind == "device": prompt_id = _fixture_for(prompt_id)
	elif kind == "pickup": prompt_id = str(PlayerItems.find(area, prompt_id).get("object", ""))
	var lit: String = _object_for_target(_pending_room_target) if _pending_room_target != "" else (prompt_id if kind in ["loft-desk", "terminal", "pickup", "device"] else "")
	view.set_target_highlight(lit)
	prompts.set_target("prop" if kind in ["inspection", "room-link", "loft-desk", "terminal", "pickup", "device"] else kind, prompt_id, str(prompts.markers.get(_interaction.get("id", ""), "")) if kind == "talk" else "", "F  ·  " + str(_interaction.label) if kind != "" else "")


## The mark over each resident here: "?" when they can help with the current lesson and "!" when they have
## something you have not heard (VillageDialogue.marker); residents with nothing new get none.
func _resident_marks() -> Dictionary:
	var marks: Dictionary = {}
	if view.villagers == null or session == null:
		return marks
	var quest: String = str(session.current_quest().get("id", ""))
	for id: String in view.villagers.speakers:
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
		"terminal":
			_activate_terminal(str(_interaction.id))
		"pickup":
			_activate_pickup(str(_interaction.id))
		"device":
			_activate_device(str(_interaction.id))
		"loft-desk":
			_activate_loft_desk(str(_interaction.id))
		"room-link":
			session.walk_to_link(str(_interaction.id))
		"inspection":
			for item: Dictionary in area.interior.get("inspections", []):
				if str(item.id) == str(_interaction.id):
					if _journal_kind() == "workshop" and item.id == "job-board" and CompanionLesson.has_voice(session.state, session.completed) and _dialogue_read.get("loft-waking", []).has("introduced") and not _dialogue_read.get("workshop-scenes", []).has("waiting-ticket"):
						_show_workshop_scene("waiting-ticket", "job-board")
						return
					if _journal_kind() == "workshop":
						if session.read_inspection(str(item.id)): workshop_speech.inspect(str(item.id), str(item.title), str(item.text))
						return
					var panel := Modal.new()
					panel.theme = PaperTheme.theme()
					panel.card.theme_type_variation = &"PanelCard"
					panel.card.custom_minimum_size.x = 560
					panel.title_row(str(item.title))
					panel.body.add_child(UI.dim(str(item.text), 20))
					panel.body.add_child(UI.button("Back to the workshop", &"", &"ButtonPrimary", panel.close))
					panel.closed.connect(func() -> void: session.read_inspection(str(item.id)))
					_push_modal(panel)
					return
		"prop":
			if session.use_prop(str(_interaction.id)):
				save_now()
				_refresh_interaction()
		"talk":
			var id: String = str(_interaction.id)
			if id=="hotaru":
				talk_hotaru()
				return
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


func _activate_loft_desk(id: String) -> void:
	if id == "nell-note":
		if (session.state.inspections_read as Array).has("nell-note"): return
		var note := NellNote.new()
		note.setup(_story.opening.note)
		note.read.connect(func() -> void:
			if session.read_inspection("nell-note"):
				_dialogue_read["nell-note"] = ["read"]
				save_now()
				hud.show_toast("The desk terminal is ready to use."))
		_push_modal(note)
	elif id == "desk-terminal": _activate_terminal(id)


func _activate_terminal(id: String) -> void:
	var terminal: Dictionary = ZoneTerminals.find(area, id)
	if terminal.is_empty(): return
	if area.id == "workshop-loft" and not (session.state.inspections_read as Array).has("nell-note") and not CompanionLesson.has_voice(session.state, session.completed):
		hud.show_toast("There’s a note under the mug.")
		return
	if area.id != "workshop-loft" and not _dialogue_read.get("loft-waking", []).has("introduced"):
		hud.show_toast("Your first page is at the terminal upstairs.")
		return
	if terminal.has("requires") and not PlayerItems.has(session.state, str(terminal.requires)):
		workshop_speech.inspect(id, str(terminal.title), str(terminal.get("locked", "Nothing you carry fits it.")))
		return
	if not session.connect_terminal(id): return
	if id == "desk-terminal": session.read_inspection(id)
	save_now()
	_open_workshop_journal(area.id == "workshop-loft", {"kind":"zone", "id":str(terminal.zone), "title":str(terminal.title), "terminal":id})


## Nell's tablet lies on the bed from the first moment, but it is Hotaru's waking conversation that sends the
## traveller to it; until she has spoken it is part of the room.
func _pickup_offered(pickup: Dictionary) -> bool:
	return not PlayerItems.has(session.state, str(pickup.item)) and _dialogue_read.get("loft-waking", []).has("introduced")


func _activate_pickup(id: String) -> void:
	var pickup: Dictionary = PlayerItems.find(area, id)
	if pickup.is_empty() or not _pickup_offered(pickup): return
	if not session.take_item(id): return
	_animate_pickup(pickup)
	save_now()
	var scene: String = str(((_story.get("items", {}) as Dictionary).get(str(pickup.item), {}) as Dictionary).get("scene", ""))
	if scene != "": _show_workshop_scene(scene)


## Rooms hide the objects whose items the traveller already carries. One being lifted finishes its short
## animation first.
func _sync_pickups() -> void:
	for pickup: Dictionary in area.pickups:
		var node: Node3D = view.building_node(str(pickup.object))
		if node != null and not node.has_meta("lifting"): node.visible = not PlayerItems.has(session.state, str(pickup.item))


func _animate_pickup(pickup: Dictionary) -> void:
	var node: Node3D = view.building_node(str(pickup.object))
	if node == null: return
	var home: Vector3 = node.position
	var size: Vector3 = node.scale
	node.set_meta("lifting", true)
	var lift: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	lift.tween_property(node, "position:y", home.y + .45, .3)
	lift.tween_property(node, "scale", size * .2, .3)
	lift.chain().tween_callback(func() -> void:
		if not is_instance_valid(node): return
		node.visible = false
		node.position = home
		node.scale = size
		node.remove_meta("lifting"))


## How near the traveller must stand for F. This journey asks for arm's length; the others keep their older reach.
func _interact_radius() -> float:
	return FieldAccess.RANGE if _journal_kind() == "workshop" else 1.6


## Hotaru sits on a shelf or a table; she can be spoken to from the nearest place to stand beside it.
func _companion_in_reach() -> bool:
	if _journal_kind() != "workshop": return true
	var anchor: Vector3 = view.companion_anchor()
	return Vector2(session.player_cell()).distance_to(Vector2(anchor.x, -anchor.z)) < COMPANION_REACH


## The lamp whose code the traveller is standing beside, with what it needs in hand, or {}.
func _device_here() -> Dictionary:
	for lamp: Dictionary in area.lamps:
		if lamp.get("stand") is Array and FieldAccess.near(session.state, lamp.stand) and (not lamp.has("requires") or PlayerItems.has(session.state, str(lamp.requires))):
			return lamp
	return {}


## The placed fixture that shows a lamp, so a prompt and a click can find it.
func _fixture_for(lamp_id: String) -> String:
	for fixture: Dictionary in area.interior.get("lamp_fixtures", []):
		if str(fixture.id) == lamp_id: return str(fixture.asset)
	return ""


func _activate_device(id: String) -> void:
	var lamp: Dictionary = area.lamp(id)
	if lamp.is_empty() or not lamp.get("stand") is Array: return
	var title: String = str(lamp.get("title", id))
	if lamp.has("requires") and not PlayerItems.has(session.state, str(lamp.requires)):
		workshop_speech.inspect(id, title, "A fitting with a socket for something you are not carrying.")
		return
	if not FieldAccess.near(session.state, lamp.stand):
		hud.show_toast("Stand beside the %s to open its code." % title.to_lower())
		return
	if _job_pages_for("device", id).is_empty():
		workshop_speech.inspect(id, title, "Nothing has been asked of it yet. Nell’s ticket will say what she wants.")
		return
	_open_workshop_journal(false, {"kind":"device", "id":id, "title":title})


## The reached job pages whose code works on this lamp or zone, in quest order.
func _job_pages_for(kind: String, id: String) -> Array[Dictionary]:
	var pages: Array[Dictionary] = []
	for quest: Dictionary in area.quests:
		var access: Variant = quest.get("access")
		if not access is Dictionary or access.kind != kind or str(access.id) != id: continue
		if session.completed.has(quest.id) or quest == session.current_quest(): pages.append(quest)
	return pages


## The placed object a walk-to target stands for, so the walk can light it: the note, a terminal's screen, a
## pickup's object or a lamp's fixture.
func _object_for_target(id: String) -> String:
	if id == "nell-note": return id
	var terminal: Dictionary = ZoneTerminals.find(area, id)
	if not terminal.is_empty(): return str(terminal.object)
	var pickup: Dictionary = PlayerItems.find(area, id)
	if not pickup.is_empty(): return str(pickup.object)
	return _fixture_for(id)


func _room_target_approach(id: String) -> Vector2i:
	var lamp: Dictionary = area.lamp(id)
	if not lamp.is_empty() and lamp.get("stand") is Array: return Vector2i(int(lamp.stand[0]), int(lamp.stand[1]))
	var terminal: Dictionary = ZoneTerminals.find(area, id)
	if not terminal.is_empty(): return Vector2i(int(terminal.at[0]), int(terminal.at[1]))
	var pickup: Dictionary = PlayerItems.find(area, id)
	if not pickup.is_empty(): return Vector2i(int(pickup.at[0]), int(pickup.at[1]))
	for item: Dictionary in area.interior.get("inspections", []):
		if item.id == id: return Vector2i(int(item.at[0]), int(item.at[1]))
	return Vector2i(-1, -1)


func _walk_to_room_target(id: String) -> void:
	var at: Vector2i = _room_target_approach(id)
	if at.x < 0: return
	_pending_room_target = id
	if not session.walk_to(at): _pending_room_target = ""


## After a ticket or a result is read, say where the next piece of code is written, and offer to walk there.
func _offer_job_place() -> void:
	if not playing or not _modals.is_empty() or notebook_open: return
	var quest: Dictionary = session.current_quest()
	var access: Variant = quest.get("access")
	if not access is Dictionary: return
	var panel := ZoneConnectionPanel.new()
	if access.kind == "device":
		var lamp: Dictionary = area.lamp(str(access.id))
		if lamp.is_empty(): return
		panel.setup_device(lamp)
	else:
		var terminals: Array[Dictionary] = ZoneTerminals.for_zone(area, str(access.id))
		if terminals.is_empty(): return
		panel.setup(terminals[0])
	panel.destination_requested.connect(func(id: String) -> void:
		panel.close()
		_walk_to_room_target(id))
	_push_modal(panel)


func _offer_zone_connection(terminal: Dictionary) -> void:
	if terminal.has("requires") and not PlayerItems.has(session.state, str(terminal.requires)):
		hud.show_toast(str(terminal.get("locked", "Nothing you carry fits it.")))
		return
	var panel := ZoneConnectionPanel.new()
	panel.setup(terminal)
	panel.destination_requested.connect(func(id: String) -> void:
		panel.close()
		close_notebook(true)
		_walk_to_room_target(id))
	_push_modal(panel)


func _house_title(id: String) -> String:
	for resident: Dictionary in (_outer_ledger.area if inside_house() else area).villagers:
		if resident.home == id and _people.has(resident.id):
			return str(_people[resident.id].name) + "'s home"
	var house: Dictionary = (_outer_ledger.area if inside_house() else area).building(id)
	return ledger.title_for_asset(str(house.get("asset", "")))


func _on_doorway_requested(house: String) -> void:
	if _flow_busy or not playing or notebook_open or builder.active or not _modals.is_empty():
		return
	if area.movement_lesson and not MovementBindings.finished(session.state):
		hud.show_toast("Try every movement direction once before stepping outside. E opens your notebook.")
		return
	if house == "" and not inside_house():
		# A journey that starts in a room has no outside yet; its stairs answer with a line instead.
		var stairs: Dictionary = _story.get("stairs", {})
		if not stairs.is_empty() and Time.get_ticks_msec() * 0.001 - _stairs_said > 3.0:
			_stairs_said = Time.get_ticks_msec() * 0.001
			hud.show_toast(str(_story.get("street_doors", "")) if area.interior.get("style") == "workshop-floor" else str(stairs.get("awake" if CompanionLesson.has_voice(session.state, session.completed) else "dormant", "")))
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
	session.prepare_travel(true)
	_outer_ledger = ledger
	_outer_source = _source
	_outer_save = session.to_save()
	_outer_save["edits"] = ledger.edits.duplicate(true)
	# The landing is outside the closed leaf. Returning never occupies the threshold.
	_outer_save.state.player = [entry.return_cell[0], entry.return_cell[1], 0]
	# The next inward step would meet the closed frame: open it here, before
	# travel. Merely approaching the landing is an ordinary walking step.
	view.open_door(id)
	await _fade(func() -> void: _activate_room(entry,source))
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
	if _root_area_id=="village-morning" and str(entry.house)=="morning-home":source.document.title="Your room"
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
	if area.movement_lesson:
		if not saved.get("state") is Dictionary:saved["state"]=ledger.rules.initial_state()
		_carry_movement(saved)
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
	session.prepare_travel(true)
	_cache_room()
	_outer_save.source = session.source
	_outer_save.stats = session.stats.duplicate()
	_carry_movement(_outer_save)
	await _fade(_activate_exterior)
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


func _carry_movement(saved: Dictionary) -> void:
	if not area.movement_lesson:return
	if saved.get("state") is Dictionary:
		saved.state["spoken"]=session.state.get("spoken", "")
		saved.state["hotaru_greeted"]=CompanionLesson.has_voice(session.state,session.completed)
		saved.state["controls"]=session.state.get("controls",{}).duplicate(true)
		saved.state["movement_used"]=session.state.get("movement_used",[]).duplicate()
	saved["movement_editor"]=session.movement_editor.duplicate(true)
	saved["greeting_editor"]=session.greeting_editor.duplicate(true)


func _restore_places(save: Dictionary) -> void:
	_workshop_dismissed.clear()
	_workshop_log = WorkshopStory.restore_log(save.get("workshop_log", []), _story.get("scenes", {})) if _journal_kind() == "workshop" else []
	_banter_index = 0
	_met_villagers = save.get("met_villagers", {}).duplicate(true) if save.get("met_villagers") is Dictionary else {}
	var speakers: Dictionary=_people.duplicate()
	speakers["hotaru"]=HotaruDialogue.person(session.player_name,_root_area_id=="village-morning")
	_dialogue_read = VillageDialogue.restore_read(save.get("dialogue_read", {}), speakers)
	# The loft's world-anchored introduction has one authored read marker rather
	# than resident topic pages. Restore only that known marker, within its journey.
	var read: Variant = save.get("dialogue_read", {})
	if _journal_kind() == "workshop" and read is Dictionary and read.get("loft-waking") is Array:
		if "introduced" in read["loft-waking"]:
			_dialogue_read["loft-waking"] = ["introduced"]
	if _journal_kind() == "workshop" and read is Dictionary and read.get("nell-note") is Array and "read" in read["nell-note"]:
		_dialogue_read["nell-note"] = ["read"]
	if _journal_kind() == "workshop" and not _dialogue_read.get("loft-waking", []).has("introduced") and _legacy_workshop_handoff(save):
		_dialogue_read["loft-waking"] = ["introduced"]
	if _journal_kind() == "workshop" and read is Dictionary:
		_dialogue_read["workshop-scenes"] = WorkshopStory.restore_read(read.get("workshop-scenes", []), _story.get("scenes", {}))
	if not (_level_spec.get("room_areas", []) as Array).is_empty():
		_restore_journey_rooms(save)
		return
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


## Earlier loft saves could already be working downstairs before the hand terminal existed.
static func _legacy_workshop_handoff(save: Dictionary) -> bool:
	var rooms: Variant = save.get("journey_rooms", {})
	var version: Variant = save.get("area_version", 0)
	var state: Variant = save.get("state", {})
	var completed: Variant = save.get("completed", [])
	if not AreaDef._whole(version) or not rooms is Dictionary or not state is Dictionary or not completed is Array: return false
	return int(version) < 6 and rooms.get("active", "") == "workshop-floor" and CompanionLesson.has_voice(state, completed)


## Jobs finished anywhere on this journey. A room with no jobs of its own (the lane) still follows the story that
## the jobs in the other rooms have moved on.
func _journey_completed() -> Array:
	var done: Array = session.completed.duplicate()
	for id: String in _journey_rooms:
		var saved: Variant = (_journey_rooms[id] as Dictionary).get("completed", [])
		if not saved is Array: continue
		for quest: Variant in saved:
			if quest is String and not done.has(quest): done.append(quest)
	return done


## Only shared notebook/voice progress crosses floors. World memory, objects,
## player position and completed local work remain in their own room snapshot.
func _share_journey_progress(saved: Dictionary) -> void:
	saved["source"] = session.source
	saved["stats"] = session.stats.duplicate(true)
	saved["greeting_editor"] = session.greeting_editor.duplicate(true)
	saved["workshop_pages"] = session.workshop_pages.duplicate(true)
	if not saved.get("state") is Dictionary: return
	saved.state["spoken"] = str(session.state.get("spoken", ""))
	saved.state["items"] = PlayerItems.merge(saved.state.get("items", []), session.state.get("items", []))
	var voiced: bool = CompanionLesson.has_voice(session.state, session.completed)
	saved.state["hotaru_greeted"] = voiced
	if voiced:
		if not saved.get("completed") is Array: saved["completed"] = []
		if not saved.completed.has("say-hello"): saved.completed.append("say-hello")


func _cache_journey_room() -> void:
	var saved: Dictionary = session.to_save()
	saved["edits"] = ledger.edits.duplicate(true)
	_journey_rooms[area.id] = saved
	for id: String in _journey_rooms: _share_journey_progress(_journey_rooms[id])


func _activate_journey_room(source: Dictionary, saved: Dictionary) -> void:
	_source = source
	ledger = BuildLedger.new(source.document, source.assets, source.quests, _build_catalog, saved.get("edits", []), build_policy, AreaStore.ground_materials())
	area = ledger.area
	view.setup(area)
	view.set_character_skin(str(settings.get_value("character_skin")))
	session.begin(area, view, saved)
	view.set_zoom(_indoor_zoom(12.5))
	view.set_warmth(.75, false)
	_sync_pickups()
	builder.ledger = ledger
	notebook.reload_from_session()
	_refresh_interaction()


func travel_room_link(id: String) -> bool:
	if _flow_busy or not playing or notebook_open or builder.active or not _modals.is_empty() or session.busy or session.is_walking(): return false
	var link: Dictionary = RoomLinks.find(area, id)
	if link.is_empty() or not RoomLinks.cells(link).has(session.player_cell()): return false
	var allowed: Array = _level_spec.get("room_areas", [])
	if not allowed.has(str(link.to)): return false
	if area.pickups.any(_pickup_offered):
		# Hotaru has asked for the slate; the stairs wait until it is in hand.
		hud.show_toast(str((_story.get("stairs", {}) as Dictionary).get("tablet", "Something of Nell’s is still waiting here.")))
		return false
	var source: Dictionary = AreaStore.read_source(str(link.to))
	if not source.get("ok", false):
		hud.show_toast("The door won't open. Try again in a moment.")
		return false
	var target: Vector2i = RoomLinks.arrival(link, session.player_cell())
	var parsed: Dictionary = AreaDef.parse(source.document, source.assets, source.quests, AreaStore.ground_materials())
	if not parsed.ok: return false
	var target_rules := LabWorld.new(parsed.area)
	if not target_rules.is_walkable(target_rules.initial_state(), target): return false
	session.prepare_travel(true)
	_cache_journey_room()
	var saved: Dictionary = (_journey_rooms.get(str(link.to), {}) as Dictionary).duplicate(true)
	if not saved.get("state") is Dictionary: saved["state"] = target_rules.initial_state()
	_share_journey_progress(saved)
	saved.state.player = [target.x, target.y, 0]
	var walking: bool = bool(link.get("walk_through", false))
	var facing: Vector2i = AreaDef.STEPS[link.get("facing", "S")]
	var from_area: String = area.id
	if not walking:
		await _fade(func() -> void:
			_activate_journey_room(source, saved)
			session.turn_toward(facing))
		save_now()
		return true
	# Walking through: the doors swing open, the traveller walks into the doorway and the clockwork veil grows out of
	# it. In the next scene the veil opens on the arrival while they walk out of its open doors (or up its steps),
	# straight on to where the link leaves them, and the doors close behind.
	_flow_busy = true
	_update_input_gate()
	var doors: Node3D = view.link_doors(str(link.get("doors", "")))
	if DoorSwing.set_open(doors, true) != null:
		await get_tree().create_timer(DOOR_LEAD_SECONDS).timeout
	_flow_busy = false
	var out: Vector2 = Vector2(AreaDef.STEPS[link.direction])
	var start: Vector2 = Vector2(session.player_cell())
	var onward: Vector2i = target + facing * int(link.get("enter", 0))
	if onward != target and not target_rules.is_walkable(target_rules.initial_state(), onward):
		onward = target
	saved.state.player = [onward.x, onward.y, 0]
	var arrive_from: Vector2 = Vector2(target) - Vector2(facing) * ARRIVE_CELLS
	var arrive_cells: float = ARRIVE_CELLS + Vector2(onward - target).length()
	var back: Dictionary = {}
	# They walk at walking pace the whole way; once the veil has them, the floor beyond the doorway does not matter.
	var leave_cells: float = (WALK_LEAD_SECONDS + VEIL_CLOSE_SECONDS) / LabWorld.STEP_SECONDS
	var leaving: Callable = func(fraction: float) -> void: view.walk_player_visual(start, start + out * leave_cells, fraction)
	var arriving: Callable = func(fraction: float) -> void: view.walk_player_visual(arrive_from, Vector2(onward), fraction)
	view.set_player_motion(out / LabWorld.STEP_SECONDS)
	await _fade(func() -> void:
		_activate_journey_room(source, saved)
		session.turn_toward(facing)
		back.merge(RoomLinks.back_to(area, from_area))
		DoorSwing.set_open(view.link_doors(str(back.get("doors", ""))), true, 0.0)
		_veil_open_origin = _cell_uv(Vector2(target))
		view.walk_player_visual(arrive_from, Vector2(onward), 0.0)
		view.set_player_motion(Vector2(facing) / LabWorld.STEP_SECONDS),
		VEIL_CLOSE_SECONDS, leaving, arriving, _cell_uv(start + out * 0.6),
		maxf(VEIL_OPEN_SECONDS, arrive_cells * LabWorld.STEP_SECONDS), WALK_LEAD_SECONDS)
	view.sync_player(session.state)
	view.set_player_motion(Vector2.ZERO)
	if back.has("doors"):
		DoorSwing.set_open(view.link_doors(str(back.doors)), false)
	save_now()
	return true


func _restore_journey_rooms(save: Dictionary) -> void:
	var travel: Variant = save.get("journey_rooms", {})
	var allowed: Array = _level_spec.get("room_areas", [])
	_journey_rooms = RoomLinks.restore(travel.get("rooms", {}) if travel is Dictionary and travel.get("version") == 1 else {}, allowed)
	var root_save: Dictionary = save.duplicate(true)
	root_save.erase("journey_rooms")
	_journey_rooms[_root_area_id] = root_save
	var active: String = str(travel.get("active", _root_area_id)) if travel is Dictionary else _root_area_id
	if active == _root_area_id or not allowed.has(active) or not _journey_rooms.has(active): return
	var source: Dictionary = AreaStore.read_source(active)
	if source.get("ok", false): _activate_journey_room(source, _journey_rooms[active])


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
	if not playing or notebook_open or not _modals.is_empty():return
	if _journal_kind()=="workshop":
		if area.id != "workshop-loft" and not _dialogue_read.get("loft-waking", []).has("introduced"):
			hud.show_toast("Your first page is at the terminal upstairs.")
			return
		if area.id == "workshop-loft" and not CompanionLesson.has_voice(session.state, session.completed):
			var read: Array = session.state.get("inspections_read", [])
			if not read.has("nell-note"):
				hud.show_toast("There’s a note under the mug on the desk.")
				return
			if not read.has("desk-terminal"):
				hud.show_toast("Use the terminal on the desk to open your first page.")
				return
		# Field Notes anywhere is the plain open page. A zone's or a lamp's code is reached by standing at it.
		_open_workshop_journal(true)
		return
	notebook_open=true
	_opened_once=true
	if area.movement_lesson:
		movement_lesson=MovementLesson.new() if CompanionLesson.has_voice(session.state,session.completed) else GreetingLesson.new()
		movement_lesson.setup(session,settings)
		movement_lesson.applied.connect(save_now)
		movement_lesson.next_lesson.connect(_hotaru_next_lesson)
		movement_lesson.closed.connect(close_notebook)
		movement_lesson.extent_changed.connect(_drawer_extent_changed)
		add_child(movement_lesson)
		move_child(movement_lesson,_overlay.get_index())
		add_child(movement_lesson.test_window)
		move_child(movement_lesson.test_window,_overlay.get_index())
		var window: LessonTestWindow=movement_lesson.test_window
		movement_lesson.tree_exiting.connect(func() -> void:
			if is_instance_valid(window):window.queue_free())
		movement_lesson.fit_drawer()
		movement_lesson.show_drawer(true)
	else:
		notebook.fit_drawer()
		notebook.show_drawer(true)
	hud.set_notebook_open(true)
	_update_input_gate()


## The Sparks loft's first page; it uses the same session and sandbox as every lesson.
func _open_workshop_journal(greeting_page: bool = false, context: Dictionary = {}) -> void:
	notebook_open = true
	_opened_once = true
	var introduction_seen: bool = _dialogue_read.get("loft-waking", []).has("introduced")
	var jobs: bool = not greeting_page and introduction_seen and CompanionLesson.has_voice(session.state, session.completed)
	if jobs and session.greeting_editor.is_empty(): session.greeting_editor = {"mode":"python", "python":session.source}
	movement_lesson = WorkshopJobsJournal.new() if jobs else WorkshopJournal.new()
	if jobs: (movement_lesson as WorkshopJobsJournal).context = context
	movement_lesson.setup(session, settings)
	movement_lesson.applied.connect(save_now)
	if jobs:
		(movement_lesson as WorkshopJobsJournal).story_log_requested.connect(open_workshop_log)
		(movement_lesson as WorkshopJobsJournal).greeting_requested.connect(func() -> void:
			close_notebook(true)
			_open_workshop_journal(true))
		(movement_lesson as WorkshopJobsJournal).destination_requested.connect(_workshop_destination)
	else:
		(movement_lesson as WorkshopJournal).waking_requested.connect(func() -> void: _workshop_waking.call_deferred())
		(movement_lesson as WorkshopJournal).introduction_finished.connect(func() -> void:
			_dialogue_read["loft-waking"] = ["introduced"]
			save_now())
	movement_lesson.closed.connect(close_notebook)
	movement_lesson.extent_changed.connect(_drawer_extent_changed)
	add_child(movement_lesson)
	move_child(movement_lesson, _overlay.get_index())
	movement_lesson.fit_drawer()
	movement_lesson.show_drawer(true)
	if not jobs: (movement_lesson as WorkshopJournal).restore_story(introduction_seen)
	hud.set_notebook_open(true)
	if jobs:
		if _authored_zoom() > 0.0: view.set_zoom(_indoor_zoom(0.0) * SLATE_PULL_BACK)
		_show_slate_link(context)
	_update_input_gate()


## While the slate's code is open the room shows how it reaches what it works on: its cord running to a zone
## screen's socket, or signal sparks hopping over the air to the single fitting beside it.
func _show_slate_link(context: Dictionary) -> void:
	_clear_slate_link()
	if context.is_empty() or view.player_node() == null: return
	var target: Node3D = null
	var wired: bool = str(context.get("kind", "")) == "zone"
	if wired:
		var terminal: Dictionary = ZoneTerminals.find(area, str(context.get("terminal", "")))
		if not terminal.is_empty(): target = view.building_node(str(terminal.object))
	elif view._lamps.has(str(context.get("id", ""))):
		target = (view._lamps[str(context.id)] as Node3D).get_node_or_null("Halo") as Node3D
	if target == null: return
	_slate_link = SlateLink.new()
	view.add_child(_slate_link)
	_slate_link.setup(view.player_node(), target, wired)


func _clear_slate_link() -> void:
	if is_instance_valid(_slate_link): _slate_link.queue_free()
	_slate_link = null


func _hotaru_next_lesson() -> void:
	close_notebook(true)
	talk_hotaru("movement")


func _workshop_destination(id: String) -> void:
	close_notebook(true)
	if not ZoneTerminals.find(area, id).is_empty() or not area.lamp(id).is_empty():
		_walk_to_room_target(id)
		return
	if not RoomLinks.find(area, id).is_empty():
		session.walk_to_link(id)
		return
	for item: Dictionary in area.interior.get("inspections", []):
		if item.id == id:
			session.walk_to(Vector2i(roundi(item.at[0]), roundi(item.at[1])))
			return


func _show_workshop_scene(id: String, inspection: String = "") -> void:
	if not (_story.get("scenes", {}) as Dictionary).has(id) or not _modals.is_empty(): return
	var scene := WorkshopScene.new()
	scene.logged.connect(func(token: Dictionary) -> void:
		var entry: Dictionary = token.duplicate()
		entry["scene"] = id
		if WorkshopStory.log_line(_story.scenes, entry).is_empty(): return
		if _workshop_log.is_empty() or _workshop_log[-1] != entry:
			_workshop_log.append(entry)
			if _workshop_log.size() > 128: _workshop_log.pop_front()
		_queue_save(.4))
	scene.log_requested.connect(open_workshop_log)
	scene.setup(_story.scenes[id], view.stage as WorkshopLoftStage, settings)
	if not _workshop_dismissed.has(id): _workshop_dismissed.append(id)
	var room_id: String = area.id
	scene.finished.connect(func() -> void:
		if area.id != room_id: return
		var read: Array = _dialogue_read.get("workshop-scenes", [])
		if not read.has(id): read.append(id)
		_dialogue_read["workshop-scenes"] = read
		if id == "loft-waking": _dialogue_read["loft-waking"] = ["introduced"]
		if inspection != "": session.read_inspection(inspection)
		save_now()
		if id in ["waiting-ticket", "landing-lit"]: _offer_job_place.call_deferred())
	_push_modal(scene)


func _workshop_waking() -> void:
	if not playing or not _modals.is_empty(): return
	close_notebook(true)
	_show_workshop_scene("loft-waking")


func open_workshop_log() -> void:
	if _journal_kind() != "workshop" or (_modals.size() > 0 and _modals[-1] is WorkshopLog): return
	var log := WorkshopLog.new()
	log.setup(_workshop_log, _story.get("scenes", {}), _story.get("opening", {}).get("note", {}), _dialogue_read.get("nell-note", []).has("read"))
	_push_modal(log)


func talk_hotaru(topic: String="") -> void:
	if not playing or not _modals.is_empty():return
	if _journal_kind() == "workshop":
		if area.id in ["workshop-floor", "haverlund-lane", "haverlund-square"] and _dialogue_read.get("loft-waking", []).has("introduced"):
			var next: String = WorkshopStory.pending(_story.get("scenes", {}), area.id, _journey_completed(), _dialogue_read.get("workshop-scenes", []), session.state.lamps)
			if next != "": _show_workshop_scene(next)
			else:
				# Outside she talks about the street; indoors, about the job in hand.
				var key: String = area.id if area.id in ["haverlund-lane", "haverlund-square"] else str(session.current_quest().get("id", "finished"))
				var remarks: Array = (_story.get("banter", {}) as Dictionary).get(key, ["I’ll stay by the table."])
				(view.stage as WorkshopLoftStage).play_speech([{"speaker":"hotaru", "text":remarks[_banter_index % remarks.size()]}])
				_banter_index += 1
		else: open_notebook()
		return
	var person: Dictionary=HotaruDialogue.person(session.player_name,area.movement_lesson,CompanionLesson.has_voice(session.state,session.completed),topic)
	var conversation:=VillageConversation.new()
	conversation.setup(person,settings,_dialogue_read.get("hotaru",[]))
	conversation.settings_requested.connect(open_settings)
	conversation.notebook_requested.connect(func() -> void:
		conversation.close()
		open_notebook())
	conversation.read_changed.connect(func(keys: Array) -> void:
		_dialogue_read["hotaru"]=keys.duplicate()
		_queue_save(.4))
	_push_modal(conversation)


func close_notebook(instant: bool = false) -> void:
	if not notebook_open and not instant:return
	notebook_open=false
	if movement_lesson!=null:
		var panel: LearningLesson=movement_lesson
		movement_lesson=null
		panel.stop()
		panel.show_drawer(false,instant)
		if instant:panel.queue_free()
		else:get_tree().create_timer(.26).timeout.connect(panel.queue_free)
	notebook.drop_focus()
	notebook.show_drawer(false,instant)
	if is_instance_valid(_slate_link) and playing: _apply_room_zoom()
	_clear_slate_link()
	if hud!=null:hud.set_notebook_open(false)
	_drawer_extent_changed(0.0)
	_update_input_gate()


func _place_notebook(opened: bool) -> void:
	notebook.fit_drawer()
	notebook.show_drawer(opened,true)


func _drawer_extent_changed(pixels: float) -> void:
	var inset: float=pixels if notebook_open else 0.0
	if workshop_speech != null: workshop_speech.right_inset = inset
	if hud!=null:hud.set_right_inset(inset)
	# The field slate's notepad reaches further into the room than the slate, so the room is framed left of both.
	var extra: float=(movement_lesson as WorkshopJobsJournal).extra_reserve() if notebook_open and movement_lesson is WorkshopJobsJournal else 0.0
	view.set_view_shift((inset+extra)/maxf(1.0,size.x)*.5)


func _first_run_hint() -> void:
	if playing and not _opened_once and _modals.is_empty():
		if _journal_kind() == "workshop" and area.id == "workshop-loft" and not (session.state.inspections_read as Array).has("desk-terminal"):
			hud.show_toast("Nell left a note under the mug on the desk." if not (session.state.inspections_read as Array).has("nell-note") else "Use the terminal on the desk to open your first page.")
		else: hud.show_toast("Press E to open your Field Notes" if _journal_kind()!="" else "Press E to open your notebook")


## The last quest sets off a ring of light from the beacon, then an epilogue.
func _on_quest_completed(quest: Dictionary) -> void:
	if _journal_kind()=="workshop":
		return
	if area.movement_lesson:
		if quest.id!="say-hello":
			hud.show_toast('Hotaru: “You’re walking! I’ll follow you into the lane.”')
		return
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
	if not bool(_level_spec.get("build", true)):
		hud.show_toast(str(_story.get("no_build", "There's nothing to build up here yet.")))
		return
	if area.movement_lesson:
		hud.show_toast("This first slice is about your movement keys. Building comes later.")
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
	pause.setup(session.player_name, area.title if inside_house() else str(zone.get("title", area.title)), inside_house(), str(LevelStore.entry(_level_id).title))
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
	if _journal_kind() == "workshop":
		if not playing or not _modals.is_empty(): return
		var jobs := WorkshopJobLedger.new()
		jobs.setup(session, _story, _workshop_reached_jobs())
		jobs.notes_requested.connect(func() -> void:
			jobs.close()
			open_notebook.call_deferred())
		jobs.destination_requested.connect(func(id: String) -> void:
			jobs.close()
			if id == "nell-note" or not ZoneTerminals.find(area, id).is_empty() or not area.lamp(id).is_empty():
				_walk_to_room_target(id)
			else: _workshop_destination(id))
		_push_modal(jobs)
		return
	if area.movement_lesson or _journal_kind()!="":
		open_notebook()
		return
	if not playing:
		return
	var journal := JournalPanel.new()
	journal.setup(session)
	journal.notebook_requested.connect(func() -> void:
		_pop_all_modals()
		open_notebook())
	_push_modal(journal)


## The job book includes reached work from each visited room without revealing future jobs.
func _workshop_reached_jobs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var by_id: Dictionary = {}
	for id: String in _level_spec.get("room_areas", []):
		if id != area.id and not _journey_rooms.has(id): continue
		var room: AreaDef = area if id == area.id else AreaStore.load_area(id)
		if room == null: continue
		var completed: Array = session.completed
		if id != area.id:
			var saved_completed: Variant = _journey_rooms[id].get("completed", [])
			completed = saved_completed if saved_completed is Array else []
		var current: Dictionary = Quests.current(room, completed)
		for quest: Dictionary in room.quests:
			var done: bool = completed.has(quest.id)
			if not done and quest != current: continue
			if by_id.has(quest.id):
				if done: result[int(by_id[quest.id])].done = true
				continue
			by_id[quest.id] = result.size()
			result.append({"quest":quest, "done":done, "room":id})
	return result


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
	var choice: Dictionary=LevelStore.entry(_pending_level_id if mode=="new" else (_level_id if playing else str(save.get("level",LevelStore.default_id()))))
	var home_save: Dictionary={}
	if not choice.is_empty():
		if mode=="new" or not playing:journey_area=AreaStore.load_area(str(choice.area))
		var home: String=str(choice.get("opening_house",""))
		if journey_area.movement_lesson and home!="":
			var template: String=HouseInstances.template_for(journey_area,home,_interior_catalog)
			var rooms: Dictionary=_rooms if playing else save.get("travel",{}).get("rooms",{})
			home_save=rooms.get(journey_area.id+"/"+home,{}).get("save",{})
			journey_area=AreaStore.load_area(template)
			if not playing and mode=="view" and not home_save.is_empty():save=home_save
	var options: Dictionary = {"mode": mode, "area": journey_area, "name": SaveStore.player_name(), "completed": [], "stats": {}, "lamps_lit": 0, "zones_found": 0}
	options.skin = settings.get_value("character_skin")
	var character: Variant = choice.get("character", {})
	if character is Dictionary:
		options.merge(character, true)
	if playing and mode == "view":
		options.merge({"name": session.player_name, "completed": session.completed, "stats": session.stats, "lamps_lit": session.lamps_lit(), "zones_found": (session.state.zones_seen as Array).size()}, true)
		if journey_area.movement_lesson:
			if not inside_house():options.completed=home_save.get("completed",[])
		elif inside_house():
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
		start_new_game(_pending_level_id))
	_push_modal(screen)


func _confirm_reset() -> void:
	var confirm := ConfirmDialog.new()
	if area.movement_lesson:
		confirm.ask("Reset this area?", "The room's objects and program memory start fresh. Your keys, movement practice, notebook and finished quest are kept.", "Reset area", true)
	elif inside_house():
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
	if workshop_speech != null: workshop_speech.visible = not _modals.any(func(modal: Modal) -> bool: return modal is WorkshopScene or modal is WorkshopLog or modal is AssetShowcase)
	if playing and hud != null and not (builder != null and builder.active):
		hud.visible = not _modals.any(func(modal: Modal) -> bool: return modal is VillageConversation)
	if session != null:
		session.input_enabled = playing and not _flow_busy and _modals.is_empty() and movement_lesson==null and not (builder != null and builder.active)
		if view.villagers != null:
			view.villagers.paused = not session.input_enabled


# -------------------------------------------------------------------- input
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or not playing or _flow_busy or not _modals.is_empty():
		return
	var key: Key = (event as InputEventKey).keycode
	var typing: bool = movement_lesson.has_text_focus() if movement_lesson!=null else notebook.has_text_focus()
	if builder.active and key != KEY_F11:
		if builder.handle_key(event as InputEventKey):
			get_viewport().set_input_as_handled()
		return
	if not typing and session.input_enabled and key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT]:
		_pending_room_target = ""
	match key:
		KEY_ESCAPE:
			if workshop_speech != null and workshop_speech.dismiss_inspection():
				get_viewport().set_input_as_handled()
				return
			get_viewport().set_input_as_handled()
			if typing:
				if movement_lesson!=null:movement_lesson.drop_focus()
				else:notebook.drop_focus()
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
					if not area.movement_lesson and _journal_kind()=="":notebook.focus_editor.call_deferred()
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
				if movement_lesson!=null:movement_lesson.preview()
				else:session.run_preview()


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
			if not notebook_open and _journal_kind() == "workshop":
				var picked: String = _pick_workshop_object(view_point)
				if picked != "":
					_walk_to_room_target(picked)
					return
			_pending_room_target = ""
			var doorway: Dictionary = view.pick_door(view_point)
			if not notebook_open and not doorway.is_empty():
				session.walk_to_door(str(doorway.house))
				return
			var cell: Vector2i = view.pick_cell(view_point)
			if cell.x >= 0:
				if movement_lesson==null:session.click_cell(cell)
				hud.show_inspection(describe_cell(cell))
		elif button == MOUSE_BUTTON_WHEEL_UP or button == MOUSE_BUTTON_WHEEL_DOWN:
			if _authored_zoom() > 0.0:
				# High-resolution wheels report a fraction of a notch; a plain wheel reports 0 or 1.
				var notches: float = clampf(event.factor if event.factor > 0.0 else 1.0, 0.05, 3.0)
				_zoom_room(notches if button == MOUSE_BUTTON_WHEEL_UP else -notches)
			else:
				var step: float = -0.75 if button == MOUSE_BUTTON_WHEEL_UP else 0.75
				settings.set_value("zoom", clampf(float(settings.get_value("zoom")) + step, 8.0, 20.0))
	elif event is InputEventMagnifyGesture and _authored_zoom() > 0.0:
		_zoom_room(log(maxf(0.1, event.factor)) / log(1.0 / ROOM_ZOOM_NOTCH))


## The room's own interior zoom, or 0 when the area has none and the Camera zoom setting applies.
func _authored_zoom() -> float:
	return float(area.interior.get("zoom", 0.0)) if area != null else 0.0


## Positive notches zoom in. Every notch is the same proportion, so the first one moves the view from where it
## already is instead of jumping to a stored value.
func _zoom_room(notches: float) -> void:
	_room_zoom_scale = clampf(_room_zoom_scale * pow(ROOM_ZOOM_NOTCH, notches), ROOM_ZOOM_RANGE.x, ROOM_ZOOM_RANGE.y)
	_apply_room_zoom()


func _apply_room_zoom() -> void:
	if _authored_zoom() > 0.0 and view != null:
		view.set_zoom(_indoor_zoom(0.0))


## Where the camera sits on entering a room: its authored zoom, scaled by the player's wheel preference.
func _indoor_zoom(fallback: float) -> float:
	var authored: float = _authored_zoom()
	return authored * _room_zoom_scale if authored > 0.0 else fallback


## Use projected authored meshes for clicking; navigation and proximity remain world rules.
func _pick_workshop_object(point: Vector2) -> String:
	var targets: Array = [["nell-note", "nell-note"]]
	for terminal: Dictionary in area.terminals: targets.append([terminal.object, terminal.id])
	for pickup: Dictionary in area.pickups:
		if _pickup_offered(pickup): targets.append([pickup.object, pickup.id])
	for lamp: Dictionary in area.lamps:
		if lamp.get("stand") is Array and _fixture_for(lamp.id) != "" and (not lamp.has("requires") or PlayerItems.has(session.state, str(lamp.requires))):
			targets.append([_fixture_for(lamp.id), lamp.id])
	for target: Array in targets:
		var node: Node3D = view.building_node(target[0])
		if node == null or not node.visible: continue
		var rect := Rect2()
		var first: bool = true
		for child: Node in node.find_children("*", "MeshInstance3D", true, false):
			if child.name == &"IllustratedOutline": continue
			var box: AABB = BuildOverlay.world_aabb(child as Node3D)
			for i: int in range(8):
				var projected: Vector2 = view.camera.unproject_position(box.get_endpoint(i))
				if first:
					rect = Rect2(projected, Vector2.ZERO)
					first = false
				else: rect = rect.expand(projected)
		if not first and rect.grow(8).has_point(point): return target[1]
	return ""


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
	state.player = [29, 21, 0] if area.id==AREA_ID else [area.spawn.x,area.spawn.y,0]
	return state


func _saved_lamps(save: Dictionary) -> int:
	var count: int = 0
	for lit: Variant in ((save.get("state", {}) as Dictionary).get("lamps", {}) as Dictionary).values():
		if lit == true:
			count += 1
	return count


## Covers the screen with the clockwork veil, runs `action` while nothing shows, and opens the veil on what it made.
## The veil grows out of the traveller (or `origin`, a point in 0..1 of the screen) and opens out of where `action`
## leaves them (or `_veil_open_origin`). `during_down` and `during_up` receive 0..1 as each half plays, so a walk can
## carry on through it; `lead_in` is how long the first plays, seen, before the veil starts to grow.
func _fade(action: Callable, down_seconds: float = VEIL_CLOSE_SECONDS, during_down: Callable = Callable(), during_up: Callable = Callable(), origin: Variant = null, up_seconds: float = VEIL_OPEN_SECONDS, lead_in: float = 0.0) -> void:
	if _flow_busy:
		return
	_flow_busy = true
	_update_input_gate()
	var from: Vector2 = origin if origin is Vector2 else _player_uv()
	var walk: Tween = null
	if during_down.is_valid():
		walk = create_tween()
		walk.tween_method(during_down, 0.0, 1.0, lead_in + down_seconds)
	if lead_in > 0.0:
		await get_tree().create_timer(lead_in).timeout
	await _veil.close(from, down_seconds)
	if walk != null and walk.is_running():
		await walk.finished
	var closed_at: int = Time.get_ticks_msec()
	# The next place is built in one go; the veil redraws itself between pieces so its gears keep turning, and the
	# world underneath, which nobody can see, is not drawn.
	var world_update: int = world_viewport.render_target_update_mode
	world_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	BuildPump.tick = _veil.keep_turning
	action.call()
	BuildPump.tick = Callable()
	world_viewport.render_target_update_mode = world_update as SubViewport.UpdateMode
	await get_tree().process_frame
	var remaining: float = VEIL_CLOSED_SECONDS - float(Time.get_ticks_msec() - closed_at) / 1000.0
	if remaining > 0.0:
		await get_tree().create_timer(remaining).timeout
	var to: Vector2 = _veil_open_origin if _veil_open_origin is Vector2 else _player_uv()
	_veil_open_origin = null
	await _veil.open(to, up_seconds, during_up)
	_flow_busy = false
	_update_input_gate()


## Where the traveller stands on the screen, as 0..1 of its width and height: the veil grows out of that point.
func _player_uv() -> Vector2:
	if not playing or view == null or view.player_node() == null:
		return Vector2(0.5, 0.5)
	return _screen_uv(view.player_screen_position())


## Where a cell's ground falls on the screen, even a cell just beyond the area's edge.
func _cell_uv(cell: Vector2) -> Vector2:
	return _screen_uv(view.screen_position_of_cell(cell))


func _screen_uv(viewport_point: Vector2) -> Vector2:
	return (viewport_point / Vector2(world_viewport.size)).clamp(Vector2(0.04, 0.04), Vector2(0.96, 0.96))


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
			# A room with its own zoom keeps it; the slider is the outdoor choice.
			if playing and _authored_zoom() <= 0.0:
				view.set_zoom(float(settings.get_value("zoom")))
		"character_skin":
			view.set_character_skin(str(settings.get_value("character_skin")))
