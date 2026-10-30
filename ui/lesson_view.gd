class_name LessonView
extends ScrollContainer
## One quest as a small lesson: what to try, the idea behind it, runnable examples, a hint ladder and
## a starter you can drop into the editor. Reads quest data; it never changes the world.

signal insert_requested(snippet: String)
signal starter_requested(text: String)

var _body: VBoxContainer
var _quest: Dictionary = {}
var _hints_shown: Dictionary = {}
var _progress_row: HBoxContainer
var _interactive: bool = true


func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body = UI.vbox(8)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_body)


## `interactive` adds the starter button and the hint ladder (the notebook); the journal reads only.
func show_quest(quest: Dictionary, finished: bool, progress: Dictionary, interactive: bool = true) -> void:
	_quest = quest
	_interactive = interactive
	for child: Node in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	if quest.is_empty():
		_epilogue()
		return
	if str(quest.get("chapter", "")) != "":
		_body.add_child(UI.caps(str(quest.chapter), Pal.BRASS))
	_body.add_child(UI.caps(str(quest.concept), Pal.VIOLET))
	_body.add_child(UI.heading(str(quest.title), 22))
	if finished:
		var done_row := UI.hbox(8)
		var tick := Glyph.new()
		tick.kind = &"check"
		tick.color = Pal.GREEN
		done_row.add_child(tick)
		done_row.add_child(UI.label("Complete", &"", 17, Pal.GREEN))
		_body.add_child(done_row)
	else:
		_body.add_child(UI.dim(str(quest.summary), 16))
		_progress_row = UI.hbox(8)
		_body.add_child(_progress_row)
		update_progress(progress)
	_body.add_child(UI.rule())
	for block: Dictionary in LessonText.blocks(str(quest.lesson)):
		if block.type == "code":
			_body.add_child(_code_block(str(block.text)))
		else:
			_body.add_child(_paragraph(str(block.text)))
	if finished and str(quest.done) != "":
		_body.add_child(UI.rule())
		var note := _paragraph("**" + str(quest.done) + "**")
		note.add_theme_color_override("default_color", Pal.GREEN)
		_body.add_child(note)
	if _interactive and not finished:
		_body.add_child(UI.rule())
		_starter_and_hints()


func update_progress(progress: Dictionary) -> void:
	if _progress_row == null or not is_instance_valid(_progress_row):
		return
	for child: Node in _progress_row.get_children():
		_progress_row.remove_child(child)
		child.queue_free()
	var total: int = int(progress.get("total", 0))
	var done: int = int(progress.get("done", 0))
	if total <= 0:
		return
	var marker := Glyph.new()
	marker.kind = &"ring"
	marker.color = Pal.BRASS
	_progress_row.add_child(marker)
	_progress_row.add_child(UI.label("%d / %d %s" % [done, total, str(progress.get("noun", ""))], &"", 17, Pal.BRASS_HI))


func _epilogue() -> void:
	_body.add_child(UI.caps("The journey so far", Pal.VIOLET))
	_body.add_child(UI.heading("Kindle Hollow is lit", 26))
	_body.add_child(UI.rule())
	_body.add_child(_paragraph("Every lantern burns, the bridge is up and the gate stands open. You wrote method calls, loops, variables, conditions and a function of your own."))
	_body.add_child(_paragraph("The notebook stays open. Experiment: put the lamps out, rebuild the bridge with fewer decks, or write a program that lights only the lamps in the zone you are standing in using `world.here`."))


func _paragraph(text: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = LessonText.to_bbcode(text)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _code_block(code: String) -> Control:
	var panel := UI.panel(&"PanelInset")
	var row := UI.hbox(8)
	panel.add_child(row)
	var text := Label.new()
	text.text = code
	text.add_theme_font_override("font", UITheme.mono_font())
	text.add_theme_font_size_override("font_size", 15)
	text.add_theme_color_override("font_color", Color("e0cfa3"))
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	if _interactive:
		var insert := UI.icon_button(&"plus", "Add this code to your notebook at the cursor", func() -> void: insert_requested.emit(code))
		insert.custom_minimum_size = Vector2(28, 28)
		insert.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(insert)
	return panel


func _starter_and_hints() -> void:
	var starter: String = str(_quest.starter)
	if starter != "":
		var button := UI.button("Use the starter code", &"scroll", &"", func() -> void: starter_requested.emit(starter))
		button.tooltip_text = "Replaces the notebook's code with this quest's starter. Ctrl+Z in the editor brings your old code back."
		_body.add_child(button)
	var hints: Array = _quest.hints
	if hints.is_empty():
		return
	_body.add_child(UI.heading("Need a nudge?", 20))
	var shown: int = int(_hints_shown.get(_quest.id, 0))
	for index: int in range(mini(shown, hints.size())):
		var hint_row := UI.hbox(10)
		var number := UI.label(str(index + 1), &"LabelHeading", 20)
		number.custom_minimum_size.x = 18
		hint_row.add_child(number)
		var text := _paragraph(str(hints[index]))
		hint_row.add_child(text)
		_body.add_child(hint_row)
	if shown < hints.size():
		var reveal := UI.button("Show hint %d of %d" % [shown + 1, hints.size()], &"lamp", &"", func() -> void:
			_hints_shown[_quest.id] = shown + 1
			show_quest(_quest, false, {}, _interactive))
		reveal.tooltip_text = "Hints get more direct each time. Try the lesson first."
		_body.add_child(reveal)
