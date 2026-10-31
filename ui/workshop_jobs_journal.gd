class_name WorkshopJobsJournal
extends LearningLesson
## Separate saved job pages over the live room; a debug run remains a proposal until Apply.
## Two things open together, beside the room. On the right is Nell's field slate, held up and working: a file tab
## per job page, the devices it reaches with their state, the program's variables, the editor (hover a name to see
## what it is, Ctrl+click to go to where it is set), its output and the Debug and Apply keys on the bezel. Plugged into a zone's screen its cord hangs from its edge; beside a single fitting it pairs
## over the air. Clipped to the slate's lower left is the Field Notes notepad: an index of the lessons reached, the
## job in Nell's words, the names on the link and in your code, and the hints. The drawer this class inherits is the
## slate's dock.
signal greeting_requested
signal story_log_requested
signal destination_requested(id: String)
var _page: String = ""
var _settings: GameSettings
var _stage: WorkshopLoftStage
var _tablet: TabletScreen
var _notepad: FieldNotepad
var _editor_column: VBoxContainer
var _devices: VBoxContainer
var _variables: VBoxContainer
var _pages: OptionButton
var _status: Label
var _run: FButton
var _apply: FButton
var _done: FButton
var _apply_glow: Tween
var _hover: CodeHoverCard
var _expanded: Dictionary = {}
var _shown_names: Dictionary = {}
var _final_names: Dictionary = {}
## Put away stays put away for the rest of the play session (`GameSession.notes_put_away`), so the notes are a
## guide the player can dismiss.
var _tucked: bool = false
var _loading: bool = true
var playback: ProgramPlayback
var _hint_index: int = 0
var _last_values: Dictionary = {}
var _notes_slide: Tween
## Where the traveller is writing: {"kind": "device"|"zone", "id", "title"}, or {} for every reached page.
var context: Dictionary = {}

func setup(value: GameSession, settings: GameSettings) -> void:
	session = value
	_settings = settings
	_tucked = session.notes_put_away
	_stage = session.view.stage as WorkshopLoftStage
	theme = PaperTheme.theme()
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var back_label: String = {"haverlund-square":"Back to the square", "haverlund-lane":"Back to the lane"}.get(session.area.id, "Back to the workshop")
	_pages = OptionButton.new()
	_pages.visible = false
	for quest: Dictionary in session.area.quests:
		if quest.id == "say-hello" or (not session.completed.has(quest.id) and quest != session.current_quest()): continue
		if not _belongs_here(quest): continue
		_pages.add_item(str(quest.title) + ("  ✓" if session.completed.has(quest.id) else ""))
		_pages.set_item_metadata(_pages.item_count-1, quest.id)
		if quest == session.current_quest() or session.current_quest().is_empty(): _pages.select(_pages.item_count-1)
	if _pages.item_count == 0:
		_pages.add_item("Connected scratch page" if not context.is_empty() else "Workshop jobs")
		_pages.set_item_metadata(0, "scratch-" + str(context.id) if not context.is_empty() else "")
	# The slate.
	_tablet = TabletScreen.new(TabletScreen.Look.SLATE)
	_tablet.link_kind = TabletScreen.Link.NONE if context.is_empty() else (TabletScreen.Link.WIRED if context.get("kind", "") == "zone" else TabletScreen.Link.WIRELESS)
	_tablet.link = _link_words()
	_tablet.header_end.add_child(UI.icon_button(&"cross", back_label, close))
	add_child(_tablet)
	_tablet.add_child(_pages)
	var tab_names: Array[String] = []
	for index: int in range(_pages.item_count):
		var id: String = str(_pages.get_item_metadata(index))
		tab_names.append("scratch.py" if id.begins_with("scratch-") or id == "" else id.replace("-", "_") + ".py")
	_tablet.set_tabs(tab_names, _pages.selected, func(index: int) -> void:
		if session.busy: return
		_pages.select(index)
		_show_page())
	var row := UI.hbox(0)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tablet.content.add_child(row)
	var device_panel := PanelContainer.new()
	var device_box: StyleBoxFlat = CodePalette.glass(CodePalette.BG_RAISED)
	device_box.content_margin_left = 12.0
	device_box.content_margin_top = 10.0
	device_panel.add_theme_stylebox_override("panel", device_box)
	device_panel.custom_minimum_size.x = 236
	var side := UI.vbox(14)
	device_panel.add_child(side)
	_devices = UI.vbox(8)
	side.add_child(_devices)
	_variables = UI.vbox(4)
	side.add_child(_variables)
	row.add_child(device_panel)
	_editor_column = UI.vbox(4)
	_editor_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_editor_column)
	_run = UI.button("Debug", &"debug", &"ButtonPrimary", preview)
	_run.tooltip_text = "Debug (F5 or Ctrl+Enter): run the routine as a ghost in the room"
	_apply = UI.button("Apply routine", &"check", &"ButtonStamp", apply_routine)
	_done = UI.button("Job done  ·  put the slate away", &"check", &"ButtonPrimary", close)
	_done.visible = false
	_tablet.add_key(_run)
	_tablet.add_key(_apply)
	_tablet.add_key(_done)
	# The notepad is clipped to the slate's lower left, outside the dock's own layout.
	_notepad = FieldNotepad.new()
	_notepad.top_level = true
	add_child(_notepad)
	_notepad.add_page(&"index", "Index", Color("f2d98b"))
	_notepad.add_page(&"job", "Job", Color("9ad6cf"))
	_notepad.add_page(&"names", "Names", Color("ecc988"))
	_notepad.add_page(&"hints", "Hints", Color("f2a89a"))
	_notepad.select(&"job")
	_notepad.put_away.visible = not _tucked
	_notepad.put_away_requested.connect(func() -> void: _tuck(true))
	_notepad.page_selected.connect(func(_id: StringName) -> void: if _tucked: _tuck(false))
	_status = _notepad.note
	_hover = CodeHoverCard.new()
	add_child(_hover)
	_notepad.footer.add_child(UI.button("/00 · Hello", &"", &"ButtonQuiet", func() -> void: greeting_requested.emit()))
	_notepad.footer.add_child(UI.button("Story log", &"book", &"ButtonQuiet", func() -> void: story_log_requested.emit()))
	test_window = LessonTestWindow.new()
	test_window.hide()
	add_child(test_window)
	_pages.item_selected.connect(func(_index: int) -> void: _show_page())
	session.run_finished.connect(_tested)
	session.preview_changed.connect(func(ready: bool) -> void:
		_apply.disabled = not ready or session.busy
		_refresh_devices())
	session.busy_changed.connect(func(busy: bool) -> void:
		_run.disabled = busy
		_pages.disabled = busy
		_apply.disabled = busy or not session.has_preview())
	settings.changed.connect(func(key: String) -> void:
		if key == "font_size" and is_instance_valid(editor): editor.apply_settings(settings))
	_show_page()


## The slate takes a larger share of the screen than the paper drawer did.
func _wanted_width() -> float:
	return clampf(get_viewport_rect().size.x * .41, 640.0, 840.0)


func fit_drawer() -> void:
	super.fit_drawer()
	_place_notepad()


## How far the notepad reaches into the room beyond the slate, weighted because it covers only the lower part of
## the screen; the room is framed in what is left.
func extra_reserve() -> float:
	return (_notepad.size.x - CLIP_OVERLAP) * .55 if is_instance_valid(_notepad) and drawer_open and not _tucked else 0.0


const CLIP_OVERLAP: float = 8.0

func _notepad_rest() -> Vector2:
	var screen: Vector2 = get_viewport_rect().size
	# Put away, only the stickies stand above the bottom of the screen.
	var y: float = screen.y - FieldNotepad.STICKY_OUT - 14.0 if _tucked else screen.y - _notepad.size.y - MARGIN - 4.0
	return Vector2(screen.x - drawer_width - MARGIN - _notepad.size.x + CLIP_OVERLAP, y)


func _place_notepad() -> void:
	if not is_instance_valid(_notepad): return
	var screen: Vector2 = get_viewport_rect().size
	_notepad.size = Vector2(clampf(screen.x * .25, 440.0, 520.0), clampf(screen.y * .55, 460.0, 640.0))
	var rest: Vector2 = _notepad_rest()
	_notepad.position = rest if drawer_open else Vector2(rest.x, screen.y + 20.0)


func show_drawer(opened: bool, instant: bool = false) -> void:
	super.show_drawer(opened, instant)
	if not is_instance_valid(_notepad): return
	_place_notepad()
	if _notes_slide != null: _notes_slide.kill()
	var shown: float = _notepad_rest().y
	var hidden: float = get_viewport_rect().size.y + 20.0
	if instant or not is_inside_tree():
		_notepad.position.y = shown if opened else hidden
		return
	# The pad comes up with the slate, as if lifted with it.
	_notepad.position.y = hidden if opened else shown
	_notes_slide = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_notes_slide.tween_property(_notepad, "position:y", shown if opened else hidden, .3)


func _draw() -> void:
	pass


## Tucks the notes down to their stickies, or brings them back, and lets the room use the space.
func _tuck(on: bool) -> void:
	if not is_instance_valid(_notepad) or on == _tucked: return
	_tucked = on
	session.notes_put_away = on
	_notepad.put_away.visible = not on
	if _notes_slide != null: _notes_slide.kill()
	_notes_slide = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_notes_slide.tween_property(_notepad, "position:y", _notepad_rest().y, .28)
	extent_changed.emit(drawer_width + MARGIN)


func _process(_delta: float) -> void:
	if is_instance_valid(_hover) and _hover.visible and not _hover.pinned and not _hover.near(get_global_mouse_position()):
		_hover.dismiss()


## What the editor's lookups know about the link: each visited zone's lamps, each lamp's title and state, and the
## values the last debug run saw.
func _link_picture() -> Dictionary:
	var zones: Dictionary = {}
	var lamps: Dictionary = {}
	for lamp: Dictionary in session.rules.snapshot(session.state).lamps:
		if not zones.has(str(lamp.zone)): zones[str(lamp.zone)] = []
		(zones[str(lamp.zone)] as Array).append(str(lamp.id))
		lamps[str(lamp.id)] = {"title": str(session.area.lamp(str(lamp.id)).get("title", lamp.id)), "lit": bool(lamp.lit)}
	for zone: Dictionary in session.rules.snapshot(session.state).get("zones", []):
		if not zones.has(str(zone.id)): zones[str(zone.id)] = []
	return {"zones": zones, "lamps": lamps, "values": _last_values}


## The hover card for the name under the pointer, as a code editor shows one.
func _symbol_hovered(_symbol: String, line: int, column: int) -> void:
	if not is_instance_valid(editor) or line < 0 or line >= editor.get_line_count(): return
	if _hover.pinned: return
	var expression: String = CodeLookup.expression_at(editor.get_line(line), column)
	var description: Dictionary = CodeLookup.describe(editor.text, expression, _link_picture()) if expression != "" else {}
	if description.is_empty():
		_hover.dismiss()
		return
	_hover.present(description, get_global_mouse_position())


## Ctrl+click: a variable jumps to where it is set; anything else pins its card.
func _symbol_lookup(symbol: String, line: int, column: int) -> void:
	if not is_instance_valid(editor): return
	var expression: String = CodeLookup.expression_at(editor.get_line(line), column) if line >= 0 and line < editor.get_line_count() else symbol
	if not expression.contains(".") and go_to_definition(expression): return
	var description: Dictionary = CodeLookup.describe(editor.text, expression, _link_picture())
	if not description.is_empty(): _hover.present(description, get_global_mouse_position(), true)


## Puts the caret on the name where it is first set and selects it, as an editor's go-to-definition does.
func go_to_definition(name: String) -> bool:
	if not is_instance_valid(editor): return false
	var where: Dictionary = CodeLookup.definition(editor.text, name)
	if where.is_empty(): return false
	_hover.dismiss()
	editor.grab_focus()
	editor.select(int(where.line), int(where.column), int(where.line), int(where.column) + name.length())
	editor.set_caret_line(int(where.line))
	editor.set_caret_column(int(where.column) + name.length())
	editor.center_viewport_to_caret()
	return true


## A page is written where its code works: a lamp's page beside the lamp, a zone's at its screen. Standing at a
## zone's screen also reaches that zone's lamps, so their pages stay open there.
func _belongs_here(quest: Dictionary) -> bool:
	if context.is_empty(): return true
	var access: Variant = quest.get("access")
	if not access is Dictionary: return false
	if context.kind == "device": return access.kind == "device" and str(access.id) == str(context.id)
	if access.kind == "zone": return str(access.id) == str(context.id)
	var lamp: Dictionary = session.area.lamp(str(access.id))
	return not lamp.is_empty() and str(lamp.zone) == str(context.id)


func _caption() -> String:
	if context.get("kind", "") == "device": return "BESIDE · " + str(context.get("title", "fitting")).to_upper()
	return ZoneTerminals.caption(session.area, session.state)


## What the slate's lamp says: plugged into a zone's screen, paired with one fitting, or not linked.
func _link_words() -> String:
	var reach: Array[Dictionary] = _reach()
	match str(context.get("kind", "")):
		"zone":
			return "Jacked in  ·  %s  ·  %d device%s" % [str(context.id), reach.size(), "" if reach.size() == 1 else "s"]
		"device":
			return "Paired  ·  " + str(context.get("title", context.id))
	return "No link  ·  stand at a screen or a fitting"


## The lamps this link reaches, as the rules see them.
func _reach() -> Array[Dictionary]:
	var lamps: Array[Dictionary] = []
	if context.is_empty(): return lamps
	for lamp: Dictionary in session.rules.snapshot(session.state).lamps:
		if (context.kind == "zone" and str(lamp.zone) == str(context.id)) or (context.kind == "device" and str(lamp.id) == str(context.id)):
			lamps.append(lamp)
	return lamps


func _save_page() -> void:
	if is_instance_valid(editor) and _page != "":
		session.workshop_pages[_page] = editor.text
		session.set_source(editor.text)
		session.source_changed.emit()

func _show_page() -> void:
	_loading = true
	_save_page()
	session.discard_preview()
	if is_instance_valid(_stage): _stage.clear_speech()
	editor = null
	playback = null
	for child: Node in _editor_column.get_children():
		_editor_column.remove_child(child)
		child.queue_free()
	_notepad.clear_pages()
	_page = str(_pages.get_item_metadata(_pages.selected))
	_tablet.select_tab(_pages.selected)
	_hint_index = 0
	_last_values.clear()
	var quest: Dictionary = session.area.quest(_page)
	var scratch: bool = quest.is_empty() and _page.begins_with("scratch-")
	var code: bool = scratch or (not quest.is_empty() and quest.goal.type != "inspection_read")
	var job: VBoxContainer = _notepad.page(&"job")
	_set_done(false)
	_run.visible = code
	_apply.visible = code
	_apply.disabled = true
	_glow_apply(false)
	_hover.dismiss()
	_expanded.clear()
	_status.text = ""
	_tablet.set_output("No output yet.")
	_tablet.set_state(&"ready")
	if quest.is_empty() and not scratch:
		job.add_child(UI.dim("The work tickets are downstairs. Your first page and its words are kept separately.", 18))
		job.add_child(UI.button("Go downstairs", &"", &"ButtonPrimary", func() -> void: destination_requested.emit("downstairs")))
		_editor_column.add_child(_glass_note("# Nothing is open on the slate yet."))
	elif not code:
		job.add_child(UI.heading(str(quest.title), 24))
		job.add_child(UI.dim(str(quest.summary), 18))
		job.add_child(UI.dim("Read the ticket on the board with F. The job pages will follow it here.", 17))
		job.add_child(UI.button("Find the job board", &"", &"ButtonPrimary", func() -> void: destination_requested.emit("job-board")))
		_editor_column.add_child(_glass_note("# This page is a ticket to read, not a routine."))
	else:
		job.add_child(UI.label("CONNECTED PAGE" if scratch else str(quest.concept).to_upper(), &"LabelCaps", 13, PaperPal.TEAL_DEEP))
		job.add_child(UI.heading(str(context.get("title", "Scratch page")) if scratch else str(quest.title), 24))
		job.add_child(UI.dim("There is no work ticket here yet. This page is yours to try; Debug shows a proposal and Apply keeps it." if scratch else str(quest.summary), 18))
		for line: String in str(quest.get("lesson", "")).split("\n"):
			if not line.is_empty(): job.add_child(UI.dim(line, 16))
		if _page == "morning-round": _loop_guide(job)
		editor = CodeEditor.new()
		editor.custom_minimum_size.y = 150
		editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
		editor.apply_settings(_settings)
		editor.text = str(session.workshop_pages.get(_page, quest.get("starter", 'def program(world):\n    print("' + session.area.zone(str(context.get("id", ""))).get("title", "Connected") + '")\n')))
		CodePalette.style(editor)
		_editor_column.add_child(editor)
		editor.run_requested.connect(preview)
		editor.text_changed.connect(_edited)
		editor.symbol_tooltip_on_hover = true
		editor.symbol_lookup_on_click = true
		editor.symbol_hovered.connect(_symbol_hovered)
		editor.symbol_lookup.connect(_symbol_lookup)
		editor.symbol_validate.connect(func(symbol: String) -> void:
			editor.set_symbol_lookup_word_as_valid(not CodeLookup.definition(editor.text, symbol).is_empty() or ApiReference.known_names("").has(symbol)))
		editor.mouse_exited.connect(func() -> void: if not _hover.pinned: _hover.dismiss())
		editor.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and not event.ctrl_pressed: _hover.dismiss())
		playback = ProgramPlayback.new()
		playback.code.apply_settings(_settings)
		playback.use_screen_look()
		playback.variables_changed.connect(_show_variables)
		_editor_column.add_child(playback)
		if not scratch: _fill_hints(quest)
		_status.text = "Debug runs the routine as a ghost in the room. Apply routine keeps it."
	_fill_names()
	_fill_index()
	_show_variables({})
	_refresh_devices()
	_loading = false


## A comment-like line on empty glass.
func _glass_note(words: String) -> Label:
	var note: Label = UI.label(words, &"", 15, CodePalette.COMMENT)
	note.add_theme_font_override("font", UITheme.mono_font())
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return note


func _loop_guide(job: VBoxContainer) -> void:
	var panel := UI.panel(&"PanelInset")
	job.add_child(panel)
	var column := UI.vbox(6)
	panel.add_child(column)
	column.add_child(UI.label("A LOOP, ONE LAMP AT A TIME", &"LabelCaps", 13, PaperPal.TEAL_DEEP))
	column.add_child(UI.dim('The list holds the three lights in this room. "lamp" is a temporary name for one light at a time:', 17))
	column.add_child(CodePalette.snippet("for lamp in lamps:\n    lamp.set_lit(True)", 17))
	column.add_child(UI.dim("First the stair lantern, then the repair light, then the assembly light. Each gets the same indented instruction. The colon starts the loop; the spaces show what belongs inside it.", 17))


## The hints page: one more each time it is asked, the earlier ones kept in view.
func _fill_hints(quest: Dictionary) -> void:
	var hints: VBoxContainer = _notepad.page(&"hints")
	var hint_list: Array = quest.get("hints", [])
	hints.add_child(UI.label("HINTS FOR THIS PAGE", &"LabelCaps", 13, PaperPal.RED_DEEP))
	var shown := UI.vbox(8)
	hints.add_child(shown)
	var more: FButton = UI.button("A hint", &"", &"ButtonQuiet", Callable())
	more.pressed.connect(func() -> void:
		if hint_list.is_empty() or _hint_index >= hint_list.size(): return
		shown.add_child(UI.dim("%d · %s" % [_hint_index + 1, str(hint_list[_hint_index])], 16))
		_hint_index += 1
		more.text = "Another hint" if _hint_index < hint_list.size() else "That's every hint"
		more.disabled = _hint_index >= hint_list.size())
	hints.add_child(more)


## The names page: the addresses this link reaches, and the names the program on the slate makes up, with the
## last value a debug run saw for each.
func _fill_names() -> void:
	var names: VBoxContainer = _notepad.page(&"names")
	for child: Node in names.get_children():
		names.remove_child(child)
		child.queue_free()
	names.add_child(UI.label("ON THIS LINK", &"LabelCaps", 13, PaperPal.BRASS_LO))
	match str(context.get("kind", "")):
		"zone": names.add_child(_name_line('world.zone("%s")' % str(context.id), "the screen's zone"))
		"device": names.add_child(_name_line('world.lamp("%s")' % str(context.id), "the fitting beside you"))
		_: names.add_child(UI.dim("Nothing. Stand at a screen or beside a fitting.", 16))
	for lamp: Dictionary in _reach():
		var fitting: Dictionary = session.area.lamp(str(lamp.id))
		names.add_child(_name_line('"%s"' % str(lamp.id), str(fitting.get("title", "a lamp"))))
	if not is_instance_valid(editor): return
	names.add_child(UI.label("IN YOUR CODE", &"LabelCaps", 13, PaperPal.BRASS_LO))
	var found: Array[String] = CodePalette.names_in(editor.text)
	if found.is_empty(): names.add_child(UI.dim("No names yet.", 16))
	for name: String in found:
		var seen: String = str(_last_values.get(name, ""))
		names.add_child(_name_line(name, ("last seen  " + seen) if seen != "" else ("given to your program" if name == "world" else "made up on this page")))


## A name in code type with a few words beside it, or under it when the name is long.
func _name_line(code: String, gloss: String) -> Control:
	var line: BoxContainer = UI.vbox(0) if code.length() > 16 else UI.hbox(10)
	var word: Label = UI.label(code, &"", 15, PaperPal.TEAL_DEEP)
	word.add_theme_font_override("font", UITheme.mono_font())
	line.add_child(word)
	line.add_child(UI.fill(UI.dim(gloss, 15)))
	return line


## The devices column on the glass: each lamp the link reaches, lit or dark, and blue where a Test proposes a change.
func _refresh_devices() -> void:
	if not is_instance_valid(_devices): return
	for child: Node in _devices.get_children():
		_devices.remove_child(child)
		child.queue_free()
	_devices.add_child(UI.label("DEVICES", &"LabelCaps", 11))
	var reach: Array[Dictionary] = _reach()
	if reach.is_empty():
		_devices.add_child(UI.label("None in reach", &"LabelDim", 13))
		return
	var proposed: Dictionary = session.preview_state().get("lamps", {}) if session.has_preview() else {}
	for lamp: Dictionary in reach:
		var lit: bool = bool(session.state.get("lamps", {}).get(lamp.id, false))
		var ghost: bool = proposed.has(lamp.id) and bool(proposed[lamp.id]) != lit
		var row := UI.hbox(8)
		var dot := Control.new()
		dot.custom_minimum_size = Vector2(14, 30)
		dot.draw.connect(func() -> void:
			var at := Vector2(7, 9)
			dot.draw_circle(at, 4.5, CodePalette.LIT if lit else CodePalette.DIM)
			if ghost: dot.draw_arc(at, 6.5, 0.0, TAU, 16, PaperPal.GHOST, 1.6, true))
		row.add_child(dot)
		var words := UI.vbox(0)
		var id_label: Label = UI.label(str(lamp.id), &"", 13, CodePalette.VARIABLE)
		id_label.add_theme_font_override("font", UITheme.mono_font())
		words.add_child(id_label)
		var fitting: Dictionary = session.area.lamp(str(lamp.id))
		var state: String = ("on" if lit else "off") + ("  →  " + ("on" if bool(proposed[lamp.id]) else "off") if ghost else "")
		words.add_child(UI.label("%s · %s" % [str(fitting.get("title", "lamp")), state], &"", 11, PaperPal.GHOST if ghost else CodePalette.DIM))
		row.add_child(words)
		_devices.add_child(row)


## The VARIABLES column under the devices: the program's own names as a debugger shows them, paused at the step
## the replay is on, then as they stood when the program finished.
## A list opens to show its items, one per row with its index, and a name goes to where the program sets it.
func _show_variables(names: Dictionary) -> void:
	if not is_instance_valid(_variables): return
	_shown_names = names
	for child: Node in _variables.get_children():
		_variables.remove_child(child)
		child.queue_free()
	_variables.add_child(UI.label("VARIABLES", &"LabelCaps", 11))
	if names.is_empty():
		_variables.add_child(UI.label("Debug to see them.", &"LabelDim", 12))
		return
	for key: String in names:
		var value: String = str(names[key])
		var items: Array[String] = CodeLookup.list_items(value)
		var row := UI.hbox(2)
		var open: bool = bool(_expanded.get(key, false))
		var arrow: FButton = UI.button("▾" if open else "▸", &"", &"ButtonQuiet", func() -> void:
			_expanded[key] = not bool(_expanded.get(key, false))
			_show_variables(_shown_names))
		arrow.custom_minimum_size = Vector2(18, 0)
		arrow.visible = not items.is_empty()
		arrow.tooltip_text = "Show the items"
		row.add_child(arrow)
		if items.is_empty(): row.add_child(UI.spacer(0.0))
		var name: FButton = UI.button(key, &"", &"ButtonQuiet", func() -> void: go_to_definition(key))
		name.add_theme_color_override("font_color", CodePalette.VARIABLE)
		name.add_theme_color_override("font_hover_color", CodePalette.VARIABLE.lightened(0.2))
		name.tooltip_text = "Go to where %s is set" % key
		row.add_child(name)
		var shown: Label = UI.label("list[%d]" % items.size() if not items.is_empty() else value, &"", 12, CodePalette.DIM if not items.is_empty() else _value_color(value))
		shown.add_theme_font_override("font", UITheme.mono_font())
		shown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		shown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(shown)
		_variables.add_child(row)
		if open:
			for index: int in range(items.size()):
				var item: Label = UI.label("    [%d]  %s" % [index, items[index]], &"", 12, CodePalette.TEXT)
				item.add_theme_font_override("font", UITheme.mono_font())
				item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				_variables.add_child(item)


static func _value_color(value: String) -> Color:
	if value.begins_with("'") or value.begins_with("\""): return CodePalette.STRING
	if value in ["True", "False", "None"]: return CodePalette.KEYWORD
	if value.is_valid_float(): return CodePalette.NUMBER
	return CodePalette.TEXT


## The index of lessons, which grows as they are reached: each with its idea, whether it is done, and a way to it.
func _fill_index() -> void:
	var index: VBoxContainer = _notepad.page(&"index")
	for child: Node in index.get_children():
		index.remove_child(child)
		child.queue_free()
	index.add_child(UI.label("INDEX", &"LabelCaps", 13, PaperPal.BRASS_LO))
	var number: int = 0
	for quest: Dictionary in session.area.quests:
		var reached: bool = session.completed.has(quest.id) or quest == session.current_quest()
		if not reached: continue
		var line := UI.hbox(8)
		var mark: Label = UI.label("%02d" % number, &"", 14, PaperPal.PENCIL)
		mark.add_theme_font_override("font", UITheme.mono_font())
		line.add_child(mark)
		var words := UI.vbox(0)
		var here: int = -1
		for slot: int in range(_pages.item_count):
			if str(_pages.get_item_metadata(slot)) == str(quest.id): here = slot
		var title: FButton = UI.button(str(quest.title), &"", &"ButtonQuiet", Callable())
		title.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var quest_id: String = str(quest.id)
		title.pressed.connect(func() -> void:
			if quest_id == "say-hello": greeting_requested.emit()
			elif here >= 0 and not session.busy:
				_pages.select(here)
				_show_page()
				_notepad.select(&"job")
			else: _status.text = FieldAccess.place_hint(session.area, session.area.quest(quest_id)) if FieldAccess.place_hint(session.area, session.area.quest(quest_id)) != "" else "That page is written somewhere else.")
		words.add_child(title)
		words.add_child(UI.dim(str(quest.get("concept", "")).to_lower() + ("  ·  open here" if here >= 0 else ""), 14))
		line.add_child(UI.fill(words))
		line.add_child(UI.label("✓" if session.completed.has(quest.id) else "•", &"", 18, PaperPal.GREEN if session.completed.has(quest.id) else PaperPal.RED))
		index.add_child(line)
		number += 1
	index.add_child(UI.dim("New lessons are added here as Nell's tickets reach you.", 14))


func _edited() -> void:
	if _loading: return
	_save_page()
	session.discard_preview()
	if playback != null: playback.clear()
	_status.text = "Changed · debug this page again before applying."
	_show_variables({})
	_hover.dismiss()
	_set_done(false)
	_glow_apply(false)
	_tablet.set_output("Changed. Debug again for a fresh result.")
	_tablet.set_state(&"edited")
	_fill_names()
	if is_instance_valid(_stage): _stage.clear_speech()

func preview() -> void:
	if session.busy or not is_instance_valid(editor): return
	_save_page()
	await session.run_preview()

func _tested(result: Dictionary) -> void:
	if not drawer_open or not is_instance_valid(editor): return
	if result.get("stale", false):
		_status.text = "That debug run is out of date. Debug the current page again."
		return
	playback.load_run(session.source, result, editor)
	for event: Dictionary in result.get("trace", []):
		for key: String in event.get("vars", {}): _last_values[key] = str(event.vars[key])
	for key: String in result.get("locals", {}): _last_values[key] = str(result.locals[key])
	_final_names = result.get("locals", {})
	_fill_names()
	if not result.get("ok", false):
		var advice: Dictionary = ErrorAdvice.explain(result.get("error", {}), ApiReference.known_names(session.source))
		_status.text = str(result.get("reason", "Check this line.")) if result.get("rejected", false) else str(advice.title)+"\n"+str(advice.body)
		_tablet.set_output(_status.text.split("\n")[0], &"error")
		_tablet.set_state(&"error")
		return
	var candidate: Dictionary = session.preview_state()
	var quest: Dictionary = session.area.quest(_page)
	var printed: String = str(result.get("stdout", "")).strip_edges()
	if quest.is_empty():
		_status.text = "Debug run ready. Apply routine keeps this proposal."
		_tablet.set_output(printed if printed != "" else "Debug run ready.")
	else:
		var progress: Dictionary = Quests.goal_progress(session.area, candidate, quest.goal)
		var met: bool = int(progress.total) > 0 and int(progress.done) >= int(progress.total) and not session.completed.has(_page)
		_status.text = ("Debug: %d / %d %s. That does the job: Apply routine keeps it." if met else "Debug: %d / %d %s. Apply routine keeps these changes.") % [progress.done, progress.total, progress.noun]
		var tally: String = ("✓ %d / %d %s. Apply routine to keep it." if met else "%d / %d %s") % [progress.done, progress.total, progress.noun]
		_tablet.set_output((printed + "\n" if printed != "" else "") + tally, &"ok" if met else &"")
		_glow_apply(met)
	_tablet.set_state(&"debug")
	_refresh_devices()
	if is_instance_valid(_stage): _stage.play_speech(WorkshopJournal._printed_lines(result), true)
	if is_instance_valid(_stage) and not str(result.get("stdout", "")).strip_edges().is_empty(): _stage.show_output(str(result.stdout), true)

func apply_routine() -> void:
	if not is_instance_valid(editor): return
	if editor.text != session.source:
		_edited()
		return
	var was_done: bool = session.completed.has(_page)
	if not session.apply_preview(): return
	playback.clear()
	_show_variables(_final_names)
	_glow_apply(false)
	_tablet.set_state(&"ok")
	_refresh_devices()
	_fill_index()
	_status.text = "Applied. Your page is saved." if _page.begins_with("scratch-") else ("Applied. Return to the workshop to continue." if session.completed.has(_page) else "Applied. The job is still open; check the ticket and try another routine.")
	if not was_done and session.completed.has(_page): _set_done(true)
	applied.emit()


## The job is finished: the keys give way to one that puts the slate away and lets the story go on.
func _set_done(done: bool) -> void:
	if not is_instance_valid(_done): return
	_done.visible = done
	if done:
		_run.visible = false
		_apply.visible = false
		var quest: Dictionary = session.area.quest(_page)
		_tablet.set_output("✓ %s: done." % str(quest.get("title", "The job")), &"ok")
		_tablet.set_state(&"done")
		_status.text = "Nell's ticket is done. Put the slate away to carry on."
		var glow: Tween = create_tween().set_loops(4)
		glow.tween_property(_done, "modulate", Color(1.25, 1.25, 1.25), .35)
		glow.tween_property(_done, "modulate", Color.WHITE, .35)
	else:
		_done.modulate = Color.WHITE


## Apply glows while a debug run would finish the job, so the next step is plain.
func _glow_apply(on: bool) -> void:
	if _apply_glow != null: _apply_glow.kill()
	_apply_glow = null
	if not is_instance_valid(_apply): return
	_apply.modulate = Color.WHITE
	if not on: return
	_apply_glow = create_tween().set_loops()
	_apply_glow.tween_property(_apply, "modulate", Color(1.3, 1.3, 1.3), .5)
	_apply_glow.tween_property(_apply, "modulate", Color.WHITE, .5)

func stop() -> void:
	_save_page()
	session.discard_preview()
	if is_instance_valid(_stage): _stage.clear_speech()
	drop_focus()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(_notepad): _notepad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(_hover): _hover.dismiss()
	_glow_apply(false)
