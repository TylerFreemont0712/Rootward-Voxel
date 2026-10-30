class_name WorkshopJobsJournal
extends LearningLesson
## Separate saved job pages over the live room; Test remains a proposal until Apply.
signal greeting_requested
signal story_log_requested
signal destination_requested(id: String)
var _page: String = ""
var _settings: GameSettings
var _stage: WorkshopLoftStage
var _pages: OptionButton
var _contents: VBoxContainer
var _status: Label
var _run: FButton
var _apply: FButton
var _loading: bool = true
var playback: ProgramPlayback
var _hint_index: int = 0
## Where the traveller is writing: {"kind": "device"|"zone", "id", "title"}, or {} for every reached page.
var context: Dictionary = {}

func setup(value: GameSession, settings: GameSettings) -> void:
	session = value
	_settings = settings
	_stage = session.view.stage as WorkshopLoftStage
	theme = PaperTheme.theme()
	var body := UI.vbox(9)
	add_child(body)
	var top := UI.hbox(8)
	var back_label: String = {"haverlund-square":"Back to the square", "haverlund-lane":"Back to the lane"}.get(session.area.id, "Back to the workshop")
	var title := UI.vbox(1)
	title.add_child(UI.label(_caption(), &"LabelCaps", 12, PaperPal.TEAL_DEEP))
	title.add_child(UI.heading("Field Notes", 25))
	top.add_child(UI.fill(title))
	top.add_child(UI.icon_button(&"cross", back_label, close))
	body.add_child(top)
	var known: Array = session.rules.snapshot(session.state).lamps
	if context.get("kind", "") == "device":
		body.add_child(UI.dim("You are beside the " + str(context.get("title", "fitting")).to_lower() + ". Only it answers to your code here.", 16))
	elif not known.is_empty():
		body.add_child(UI.dim("This zone connects " + str(known.size()) + " lamps." + (" Their names are listed on Nell’s ticket." if not session.area.quests.is_empty() else " The screen shows the same connection as your slate."), 16))
	_pages = OptionButton.new()
	_pages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for quest: Dictionary in session.area.quests:
		if quest.id == "say-hello" or (not session.completed.has(quest.id) and quest != session.current_quest()): continue
		if not _belongs_here(quest): continue
		_pages.add_item(str(quest.title) + ("  ✓" if session.completed.has(quest.id) else ""))
		_pages.set_item_metadata(_pages.item_count-1, quest.id)
		if quest == session.current_quest() or session.current_quest().is_empty(): _pages.select(_pages.item_count-1)
	if _pages.item_count == 0:
		_pages.add_item("Connected scratch page" if not context.is_empty() else "Workshop jobs")
		_pages.set_item_metadata(0, "scratch-" + str(context.id) if not context.is_empty() else "")
	body.add_child(_pages)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	_contents = UI.vbox(10)
	_contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contents.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_contents)
	_status = UI.dim("", 16)
	_status.custom_minimum_size.y = 46
	body.add_child(_status)
	var actions := UI.hbox(8)
	_run = UI.button("Test code", &"play", &"ButtonPrimary", preview)
	_apply = UI.button("Apply routine", &"check", &"ButtonStamp", apply_routine)
	actions.add_child(_run)
	actions.add_child(_apply)
	body.add_child(actions)
	var bottom := UI.hbox(8)
	bottom.add_child(UI.button("/00 · Hello, Hotaru", &"", &"ButtonQuiet", func() -> void: greeting_requested.emit()))
	bottom.add_child(UI.button("Story log", &"book", &"ButtonQuiet", func() -> void: story_log_requested.emit()))
	bottom.add_child(UI.button(back_label, &"", &"ButtonQuiet", close))
	body.add_child(bottom)
	test_window = LessonTestWindow.new()
	test_window.hide()
	add_child(test_window)
	_pages.item_selected.connect(func(_index: int) -> void: _show_page())
	session.run_finished.connect(_tested)
	session.preview_changed.connect(func(ready: bool) -> void:
		_apply.disabled = not ready or session.busy)
	session.busy_changed.connect(func(busy: bool) -> void:
		_run.disabled = busy
		_pages.disabled = busy
		_apply.disabled = busy or not session.has_preview())
	settings.changed.connect(func(key: String) -> void:
		if key == "font_size" and is_instance_valid(editor): editor.apply_settings(settings))
	_show_page()

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
	for child: Node in _contents.get_children():
		_contents.remove_child(child)
		child.queue_free()
	_page = str(_pages.get_item_metadata(_pages.selected))
	_hint_index = 0
	var quest: Dictionary = session.area.quest(_page)
	var scratch: bool = quest.is_empty() and _page.begins_with("scratch-")
	var code: bool = scratch or (not quest.is_empty() and quest.goal.type != "inspection_read")
	_run.visible = code
	_apply.visible = code
	_apply.disabled = true
	_status.text = ""
	if quest.is_empty() and not scratch:
		_contents.add_child(UI.dim("The work tickets are downstairs. Your first page and its words are kept separately.", 18))
		_contents.add_child(UI.button("Go downstairs", &"", &"ButtonPrimary", func() -> void: destination_requested.emit("downstairs")))
	elif not code:
		_contents.add_child(UI.heading(str(quest.title), 24))
		_contents.add_child(UI.dim(str(quest.summary), 18))
		_contents.add_child(UI.dim("Read the ticket on the board with F. The job pages will follow it here.", 17))
		_contents.add_child(UI.button("Find the job board", &"", &"ButtonPrimary", func() -> void: destination_requested.emit("job-board")))
	else:
		_contents.add_child(UI.label("CONNECTED PAGE" if scratch else str(quest.concept).to_upper(), &"LabelCaps", 13, PaperPal.TEAL_DEEP))
		_contents.add_child(UI.heading(str(context.get("title", "Scratch page")) if scratch else str(quest.title), 24))
		_contents.add_child(UI.dim("There is no work ticket here yet. This page is yours to try; Test shows a proposal and Apply keeps it." if scratch else str(quest.summary), 18))
		for line: String in str(quest.get("lesson", "")).split("\n"):
			if not line.is_empty(): _contents.add_child(UI.dim(line, 16))
		if _page == "morning-round": _loop_guide()
		editor = CodeEditor.new()
		editor.custom_minimum_size.y = 215
		editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
		editor.apply_settings(_settings)
		editor.text = str(session.workshop_pages.get(_page, quest.get("starter", 'def program(world):\n    print("' + session.area.zone(str(context.get("id", ""))).get("title", "Connected") + '")\n')))
		WorkshopJournal._paper_code(editor)
		_contents.add_child(editor)
		editor.run_requested.connect(preview)
		editor.text_changed.connect(_edited)
		playback = ProgramPlayback.new()
		playback.code.apply_settings(_settings)
		WorkshopJournal._paper_code(playback.code)
		_contents.add_child(playback)
		if not scratch:
			var hint := UI.dim("", 16)
			_contents.add_child(UI.button("A hint", &"", &"ButtonQuiet", func() -> void:
				hint.text = str(quest.hints[mini(_hint_index, quest.hints.size()-1)])
				_hint_index += 1))
			_contents.add_child(hint)
		_status.text = "Test shows the proposed lights in the room. Apply routine keeps that test."
	_loading = false


func _loop_guide() -> void:
	var panel := UI.panel(&"PanelInset")
	_contents.add_child(panel)
	var column := UI.vbox(6)
	panel.add_child(column)
	column.add_child(UI.label("A LOOP, ONE LAMP AT A TIME", &"LabelCaps", 13, PaperPal.TEAL_DEEP))
	column.add_child(UI.dim('The list holds the three lights in this room. "lamp" is a temporary name for one light at a time:', 17))
	var example := UI.label("for lamp in lamps:\n    lamp.set_lit(True)", &"", 17, PaperPal.TEAL_DEEP)
	example.add_theme_font_override("font", UITheme.mono_font())
	column.add_child(example)
	column.add_child(UI.dim("First the stair lantern, then the repair light, then the assembly light. Each gets the same indented instruction. The colon starts the loop; the spaces show what belongs inside it.", 17))

func _edited() -> void:
	if _loading: return
	_save_page()
	session.discard_preview()
	if playback != null: playback.clear()
	_status.text = "Changed · test this page again before applying."
	if is_instance_valid(_stage): _stage.clear_speech()

func preview() -> void:
	if session.busy or not is_instance_valid(editor): return
	_save_page()
	await session.run_preview()

func _tested(result: Dictionary) -> void:
	if not drawer_open or not is_instance_valid(editor): return
	if result.get("stale", false):
		_status.text = "That test is out of date. Test the current page again."
		return
	playback.load_run(session.source, result, editor)
	if not result.get("ok", false):
		var advice: Dictionary = ErrorAdvice.explain(result.get("error", {}), ApiReference.known_names(session.source))
		_status.text = str(result.get("reason", "Check this line.")) if result.get("rejected", false) else str(advice.title)+"\n"+str(advice.body)
		return
	var candidate: Dictionary = session.preview_state()
	var quest: Dictionary = session.area.quest(_page)
	if quest.is_empty():
		_status.text = "Test ready. Apply routine keeps this proposal."
	else:
		var progress: Dictionary = Quests.goal_progress(session.area, candidate, quest.goal)
		_status.text = "Test: %d / %d %s. Apply routine keeps these changes." % [progress.done, progress.total, progress.noun]
	if is_instance_valid(_stage): _stage.play_speech(WorkshopJournal._printed_lines(result), true)
	if is_instance_valid(_stage) and not str(result.get("stdout", "")).strip_edges().is_empty(): _stage.show_output(str(result.stdout), true)

func apply_routine() -> void:
	if not is_instance_valid(editor): return
	if editor.text != session.source:
		_edited()
		return
	if not session.apply_preview(): return
	playback.clear()
	_status.text = "Applied. Your page is saved." if _page.begins_with("scratch-") else ("Applied. Return to the workshop to continue." if session.completed.has(_page) else "Applied. The job is still open; check the ticket and try another routine.")
	applied.emit()

func stop() -> void:
	_save_page()
	session.discard_preview()
	if is_instance_valid(_stage): _stage.clear_speech()
	drop_focus()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
