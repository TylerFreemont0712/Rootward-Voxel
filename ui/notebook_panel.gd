class_name NotebookPanel
extends SideDrawer
## The Village Notebook: the summonable code menu. Four tabs (Code, Lesson, Reference, World), a Run /
## Apply / Undo bar and a result area that explains what happened in plain words. It talks to the
## session; it never touches the world directly.

signal close_requested

const TABS: Array[String] = ["Code", "Lesson", "Reference", "World"]

var session: GameSession
var settings: GameSettings
var editor: CodeEditor
var lesson: LessonView
var reference: ReferenceView
var world_view: WorldView
var _pages: Dictionary = {}
var _tab_buttons: Dictionary = {}
var _badge: Glyph
var _run_button: FButton
var _apply_button: FButton
var _undo_button: FButton
var _result_title: Label
var _result_body: RichTextLabel
var _changes: VBoxContainer
var _output: Label
var _position_label: Label
var _error_button: FButton
var _goal_label: Label
var _goal_progress: Label
var _shown_quest: String = "?"
var _error_line: int = 0


func setup(game_session: GameSession, game_settings: GameSettings) -> void:
	session = game_session
	settings = game_settings
	theme_type_variation = &"PanelDrawer"
	var column := UI.vbox(6)
	add_child(column)
	column.add_child(_header())
	column.add_child(_tab_row())
	var stack := VBoxContainer.new()
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(stack)
	stack.add_child(_code_page())
	lesson = LessonView.new()
	_pages["Lesson"] = lesson
	stack.add_child(lesson)
	reference = ReferenceView.new()
	_pages["Reference"] = reference
	stack.add_child(reference)
	world_view = WorldView.new()
	_pages["World"] = world_view
	stack.add_child(world_view)
	column.add_child(_action_bar())
	column.add_child(_result_area())
	lesson.insert_requested.connect(_insert)
	lesson.starter_requested.connect(_use_starter)
	reference.insert_requested.connect(_insert)
	session.status.connect(_on_status)
	session.run_finished.connect(_on_run_finished)
	session.preview_changed.connect(_on_preview_changed)
	session.source_changed.connect(_on_source_changed)
	session.state_changed.connect(_on_state_changed)
	session.quest_changed.connect(func() -> void: _refresh_lesson(false))
	session.quest_changed.connect(_refresh_unlocks)
	_refresh_unlocks()
	session.busy_changed.connect(func(is_busy: bool) -> void: _run_button.disabled = is_busy)
	settings.changed.connect(func(_key: String) -> void: editor.apply_settings(settings))
	editor.apply_settings(settings)
	editor.text = session.source
	_refresh_lesson(true)
	_show_tab("Code")
	_on_state_changed()
	_set_status("Ready", "Write your program, press Run to preview it, then Apply to make it real.", false)


## Loads a fresh session's source into the editor (after New Game or Continue).
func reload_from_session() -> void:
	editor.text = session.source
	editor.clear_error()
	_refresh_lesson(true)
	_on_state_changed()
	_clear_result()
	_show_tab("Lesson" if is_first_visit() else "Code")


## True until the player has run a program or finished a quest: the first visit opens on the lesson.
func is_first_visit() -> bool:
	return int(session.stats.runs) == 0 and session.completed.is_empty()


func focus_editor() -> void:
	if is_first_visit():
		_show_tab("Lesson")
		return
	_show_tab("Code")
	editor.grab_focus()


func drop_focus() -> void:
	var owner: Control = get_viewport().gui_get_focus_owner()
	if owner != null and is_ancestor_of(owner):
		owner.release_focus()


func has_text_focus() -> bool:
	var owner: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	return owner != null and is_ancestor_of(owner) and (owner is LineEdit or owner is TextEdit)


func show_tab(tab: String) -> void:
	_show_tab(tab)


## Adds a line of code at the caret on the Code tab (used by build mode's "Write code for it").
func insert_snippet(snippet: String) -> void:
	_insert(snippet)


# ------------------------------------------------------------------ layout
func _header() -> Control:
	var row := UI.hbox(12)
	var icon := Glyph.new()
	icon.kind = &"book"
	icon.color = Pal.BRASS
	icon.custom_minimum_size = Vector2(34, 34)
	row.add_child(icon)
	var titles := UI.vbox(0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(UI.heading("Village Notebook", 21))
	titles.add_child(UI.caps("Python · your program changes the world"))
	row.add_child(titles)
	var close := UI.icon_button(&"cross", "Close the notebook (E or Esc)", func() -> void: close_requested.emit())
	close.focus_mode = Control.FOCUS_NONE
	row.add_child(close)
	return row


func _tab_row() -> Control:
	var row := UI.hbox(6)
	var group := ButtonGroup.new()
	for tab: String in TABS:
		var button := UI.button(tab, &"", &"ButtonTab")
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size.y = 30
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_show_tab.bind(tab))
		row.add_child(button)
		_tab_buttons[tab] = button
	_badge = Glyph.new()
	_badge.kind = &"sparkle"
	_badge.color = Pal.BRASS_HI
	_badge.custom_minimum_size = Vector2(16, 16)
	_badge.visible = false
	_badge.position = Vector2(-4, 0)
	(_tab_buttons["Lesson"] as Button).add_child(_badge)
	_badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_badge.offset_left = -20
	_badge.offset_top = -2
	_badge.offset_right = -4
	_badge.offset_bottom = 14
	return row


func _code_page() -> Control:
	var page := UI.vbox(8)
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pages["Code"] = page
	page.add_child(_goal_strip())
	var tools := UI.hbox(8)
	page.add_child(tools)
	var starter := UI.button("Starter", &"scroll", &"ButtonQuiet", func() -> void: _use_starter(str(session.current_quest().get("starter", ""))))
	starter.tooltip_text = "Replace the code with this quest's starter. Ctrl+Z brings your old code back."
	starter.focus_mode = Control.FOCUS_NONE
	tools.add_child(starter)
	var clear := UI.button("Clear", &"reset", &"ButtonQuiet", func() -> void: editor.replace_program(LabProgram.starter_source()); editor.grab_focus())
	clear.tooltip_text = "Start over with an empty program. Ctrl+Z brings your old code back."
	clear.focus_mode = Control.FOCUS_NONE
	tools.add_child(clear)
	tools.add_child(UI.spacer(0, true))
	_position_label = UI.label("Ln 1, Col 1", &"LabelDim", 15)
	tools.add_child(_position_label)
	var smaller := UI.icon_button(&"minus", "Smaller text", func() -> void: settings.set_value("font_size", maxi(12, int(settings.get_value("font_size")) - 1)))
	var larger := UI.icon_button(&"plus", "Larger text", func() -> void: settings.set_value("font_size", mini(26, int(settings.get_value("font_size")) + 1)))
	for button: FButton in [smaller, larger]:
		button.custom_minimum_size = Vector2(34, 34)
		button.focus_mode = Control.FOCUS_NONE
		tools.add_child(button)
	editor = CodeEditor.new()
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.custom_minimum_size.y = 200
	editor.text_changed.connect(_on_editor_changed)
	editor.caret_changed.connect(_update_position)
	editor.run_requested.connect(func() -> void: session.run_preview())
	page.add_child(editor)
	return page


## The current goal stays in view while you write, with a shortcut to its lesson.
func _goal_strip() -> Control:
	var strip := UI.panel(&"PanelCard")
	var row := UI.hbox(10)
	strip.add_child(row)
	var ring := Glyph.new()
	ring.kind = &"ring"
	ring.color = Pal.BRASS
	row.add_child(ring)
	var texts := UI.vbox(0)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(texts)
	_goal_label = UI.label("", &"", 18, Pal.PARCHMENT)
	_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(_goal_label)
	_goal_progress = UI.label("", &"LabelDim", 15)
	texts.add_child(_goal_progress)
	var lesson_button := UI.button("Lesson", &"scroll", &"ButtonQuiet", func() -> void: _show_tab("Lesson"))
	lesson_button.focus_mode = Control.FOCUS_NONE
	row.add_child(lesson_button)
	return strip


func _action_bar() -> Control:
	var row := UI.hbox(10)
	_run_button = UI.button("Run", &"play", &"ButtonPrimary", func() -> void: session.run_preview())
	_run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_run_button.tooltip_text = "Run your Python and preview the changes it proposes (Ctrl+Enter)."
	_run_button.focus_mode = Control.FOCUS_NONE
	row.add_child(_run_button)
	_apply_button = UI.button("Apply", &"check", &"", func() -> void: session.apply_preview())
	_apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button.tooltip_text = "Make the previewed changes real."
	_apply_button.disabled = true
	_apply_button.focus_mode = Control.FOCUS_NONE
	row.add_child(_apply_button)
	_undo_button = UI.icon_button(&"undo", "Undo the last applied program. You stay where you are.", func() -> void: session.undo_apply())
	_undo_button.disabled = true
	_undo_button.focus_mode = Control.FOCUS_NONE
	row.add_child(_undo_button)
	return row


func _result_area() -> Control:
	var panel := UI.panel(&"PanelInset")
	panel.custom_minimum_size = Vector2(0, 130)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column := UI.vbox(6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	_result_title = UI.label("", &"", 19, Pal.BRASS_HI)
	_result_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_result_title)
	_result_body = RichTextLabel.new()
	_result_body.fit_content = true
	_result_body.scroll_active = false
	_result_body.bbcode_enabled = true
	_result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_body.add_theme_color_override("default_color", Pal.PARCH_DIM)
	_result_body.add_theme_font_size_override("normal_font_size", 17)
	column.add_child(_result_body)
	_changes = UI.vbox(2)
	column.add_child(_changes)
	_error_button = UI.button("Show the line", &"chevron", &"ButtonQuiet", func() -> void:
		_show_tab("Code")
		editor.set_caret_line(_error_line - 1)
		editor.center_viewport_to_caret()
		editor.grab_focus())
	_error_button.visible = false
	_error_button.focus_mode = Control.FOCUS_NONE
	column.add_child(_error_button)
	_output = Label.new()
	_output.add_theme_font_override("font", UITheme.mono_font())
	_output.add_theme_font_size_override("font_size", 15)
	_output.add_theme_color_override("font_color", Pal.TEAL)
	_output.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	column.add_child(_output)
	return panel


# ---------------------------------------------------------------- behavior
func _show_tab(tab: String) -> void:
	for name: String in _pages:
		(_pages[name] as Control).visible = name == tab
	for name: String in _tab_buttons:
		(_tab_buttons[name] as Button).set_pressed_no_signal(name == tab)
	if tab == "Lesson":
		_badge.visible = false
	if tab == "World":
		world_view.refresh(session.world_snapshot())


func _insert(snippet: String) -> void:
	_show_tab("Code")
	editor.insert_snippet(snippet)


func _use_starter(text: String) -> void:
	if text == "":
		return
	_show_tab("Code")
	editor.replace_program(text + "\n")
	editor.grab_focus()
	editor.set_caret_line(editor.get_line_count() - 1)


func _on_editor_changed() -> void:
	session.set_source(editor.text)
	_update_position()


func _update_position() -> void:
	_position_label.text = "Ln %d, Col %d" % [editor.get_caret_line() + 1, editor.get_caret_column() + 1]


func _on_source_changed() -> void:
	_clear_result()
	_set_status("Program edited", "Run it to preview what it would change. Your world stays as it is until you Apply.", false)


## The Reference tab dims what the player's code has not learned to do yet, and names the lesson that teaches it.
func _refresh_unlocks() -> void:
	var abilities: Array[String] = session.abilities()
	reference.show_unlocks(abilities, CodeBuild.lessons(session.area, abilities))


func _on_preview_changed(has_preview: bool) -> void:
	_apply_button.disabled = not has_preview


func _on_state_changed() -> void:
	_undo_button.disabled = not session.can_undo()
	if _pages["World"].visible:
		world_view.refresh(session.world_snapshot())


func _refresh_goal(quest: Dictionary) -> void:
	if _goal_label == null:
		return
	if quest.is_empty():
		_goal_label.text = "Kindle Hollow is lit. Experiment freely."
		_goal_progress.text = "No quest remains"
		return
	var progress: Dictionary = session.quest_progress()
	_goal_label.text = str(quest.summary)
	_goal_progress.text = "%s · %d / %d %s" % [str(quest.concept), int(progress.done), int(progress.total), str(progress.noun)] if int(progress.total) > 0 else str(quest.concept)


func _refresh_lesson(force: bool) -> void:
	var quest: Dictionary = session.current_quest()
	var id: String = str(quest.get("id", ""))
	_refresh_goal(quest)
	if force or id != _shown_quest:
		var new_quest: bool = _shown_quest != "?" and id != _shown_quest
		_shown_quest = id
		lesson.show_quest(quest, false, session.quest_progress())
		if new_quest and not _pages["Lesson"].visible:
			_badge.visible = true
	else:
		lesson.update_progress(session.quest_progress())


func _on_status(title: String, detail: String, failed: bool) -> void:
	_set_status(title, detail, failed)


func _set_status(title: String, detail: String, failed: bool) -> void:
	if _result_title == null:
		return
	_result_title.text = title
	_result_title.add_theme_color_override("font_color", Pal.RED if failed else Pal.BRASS_HI)
	_result_body.text = LessonText.to_bbcode(detail)


func _clear_result() -> void:
	for child: Node in _changes.get_children():
		_changes.remove_child(child)
		child.queue_free()
	_output.text = ""
	_error_button.visible = false
	editor.clear_error()


## Adds what a finished run produced: the list of changes, printed output, or the failing line.
func _on_run_finished(result: Dictionary) -> void:
	_clear_result()
	if result.get("stale", false):
		return
	if result.get("ok", false):
		_result_body.text = "[color=#97d474]Nothing is real yet.[/color] Press [b]Apply[/b] to make these changes part of the world."
		var changes: Array = result.get("changes", [])
		if changes.is_empty():
			_result_body.text = "Your program ran, but it did not ask for any changes. Try a line that calls [code]set_lit[/code], [code]set_open[/code] or [code]place_deck[/code]."
		for change: Variant in changes:
			var row := UI.hbox(8)
			var mark := Glyph.new()
			mark.kind = &"plus"
			mark.color = Pal.GREEN
			mark.custom_minimum_size = Vector2(16, 16)
			row.add_child(mark)
			row.add_child(UI.label(str(change), &"", 16, Pal.PARCHMENT))
			_changes.add_child(row)
		_output.text = ("Output\n" + str(result.stdout)) if str(result.get("stdout", "")) != "" else ""
		return
	var error: Dictionary = result.get("error", {})
	var line: int = int(error.get("line", 0))
	var raw: String = ("%s: %s" % [error.get("kind", ""), error.get("message", "")]).strip_edges()
	if line > 0:
		_error_line = line
		editor.mark_error(line)
		_error_button.text = "Go to line %d" % line
		_error_button.visible = true
	var detail: String = str(result.get("advice", {}).get("body", result.get("reason", "")))
	_result_body.text = LessonText.to_bbcode(detail)
	var printed: String = str(result.get("stdout", ""))
	var lines: PackedStringArray = []
	if raw != ":" and raw != "":
		lines.append("Python said: " + raw)
	if printed != "":
		lines.append("Output before the error:\n" + printed)
	_output.text = "\n".join(lines)
