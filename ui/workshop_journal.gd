class_name WorkshopJournal
extends LearningLesson
## Sparks /00. Real WASI Python, provisional screen output, and explicit Send to commit.

var playback: ProgramPlayback
var _run: FButton
var _speak: FButton
var _status: Label
var _output: RichTextLabel
var _stage: WorkshopLoftStage
var _loading: bool = true
var mode: String = "blocks"
var message: LineEdit
var _blocks: VBoxContainer
var _blocks_tab: FButton
var _python_tab: FButton
var _python_custom: bool = false
var _last_generated_python: String = ""
var _directions: Label
signal introduction_finished
signal waking_requested
var _writing: ScrollContainer
var _conversation: VBoxContainer
var _choices: VBoxContainer
var _continue: FButton
var _in_conversation: bool = false
var _answered: bool = false
var _introduced: bool = false
var _test_lines: Array[Dictionary] = []
const REPLIES: Array[String] = ["I got in last night.", "Nell said you could show me around.", "Have you been asleep all week?"]
const ANSWERS: Array[String] = ["I heard your bag on the stairs. I thought Nell was moving things again.", "Of course. She’s left a few things here for you. Have you found the paper drawer?", "Most of it. Nell’s been taking the calls herself. Is it still morning?"]


func _init() -> void:
	theme = PaperTheme.theme()


func setup(value: GameSession, settings: GameSettings) -> void:
	session = value
	_stage = session.view.stage as WorkshopLoftStage
	var body := UI.vbox(9)
	add_child(body)
	var row := UI.hbox(8)
	var titles := UI.vbox(1)
	titles.add_child(UI.label("FIELD NOTES / 00", &"LabelCaps", 13, PaperPal.TEAL_DEEP))
	titles.add_child(UI.heading("Hello, Hotaru", 25))
	titles.add_child(UI.label(ZoneTerminals.caption(session.area, session.state), &"LabelCaps", 12, PaperPal.TEAL_DEEP))
	row.add_child(UI.fill(titles))
	row.add_child(UI.icon_button(&"cross", "Back to the loft", close))
	body.add_child(row)
	var scroll := ScrollContainer.new()
	_writing = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	var page := UI.vbox(9)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page)
	var note := UI.panel(&"PanelCard")
	var note_body := UI.vbox(4)
	note.add_child(note_body)
	note_body.add_child(UI.label("A NOTE FROM NELL", &"LabelCaps", 13, PaperPal.RED))
	note_body.add_child(UI.dim("Hotaru has been dozing while Nell is out on calls.\nA greeting addressed to her rings her message bell.", 17))
	page.add_child(note)
	_directions = UI.dim("", 18)
	page.add_child(_directions)
	var tabs := UI.hbox(6)
	_blocks_tab = UI.button("Blocks", &"cube", &"ButtonTab", func() -> void: select_mode("blocks"))
	_python_tab = UI.button("Python", &"code", &"ButtonTab", func() -> void: select_mode("python"))
	for tab: FButton in [_blocks_tab, _python_tab]:
		tab.toggle_mode = true
		tabs.add_child(tab)
	page.add_child(tabs)
	_blocks = UI.vbox(8)
	page.add_child(_blocks)
	var block := UI.panel(&"PanelInset")
	_blocks.add_child(block)
	var block_body := UI.vbox(6)
	block.add_child(block_body)
	block_body.add_child(UI.label("01 · PRINT A MESSAGE", &"LabelCaps", 13, PaperPal.TEAL_DEEP))
	var expression := UI.hbox(4)
	expression.add_child(UI.label('print("', &"", 19, PaperPal.TEAL_DEEP))
	message = LineEdit.new()
	message.max_length = 160
	message.placeholder_text = "Type your message here"
	message.text = str(session.greeting_editor.get("message", "Hello"))
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message.add_theme_font_override("font", UITheme.mono_font())
	expression.add_child(message)
	expression.add_child(UI.label('")', &"", 19, PaperPal.TEAL_DEEP))
	block_body.add_child(expression)
	_blocks.add_child(UI.dim("The quotation marks hold the words. Change the words inside them and the terminal shows something new.", 16))
	editor = CodeEditor.new()
	editor.custom_minimum_size.y = 225
	editor.apply_settings(settings)
	var starter: String = str(session.area.quest("say-hello").get("starter", 'def program(world):\n    print("Hello")'))
	var existing: String = session.source if session.source != CompanionLesson.STARTER else starter
	editor.text = str(session.greeting_editor.get("python", existing))
	_python_custom = bool(session.greeting_editor.get("python_custom", session.greeting_editor.has("python") or session.source != CompanionLesson.STARTER))
	_last_generated_python = editor.text
	editor.tooltip_text = 'On line 2, change the words between the quotation marks. Keep the spaces before print.'
	_paper_code(editor)
	page.add_child(editor)
	editor.run_requested.connect(preview)
	playback = ProgramPlayback.new()
	playback.replay_started.connect(func() -> void:
		if session.has_preview() and is_instance_valid(_stage): _stage.play_speech(_test_lines, true))
	playback.code.apply_settings(settings)
	_paper_code(playback.code)
	page.add_child(playback)
	page.add_child(UI.label("TERMINAL OUTPUT", &"LabelCaps", 13, PaperPal.TEAL_DEEP))
	var output_panel := UI.panel(&"PanelInset")
	_output = RichTextLabel.new()
	_output.fit_content = true
	_output.scroll_active = false
	_output.custom_minimum_size.y = 48
	_output.add_theme_font_override("normal_font", UITheme.MONO)
	_output.add_theme_font_size_override("normal_font_size", 17)
	_output.add_theme_color_override("default_color", PaperPal.INK)
	_output.text = "No output yet."
	output_panel.add_child(_output)
	page.add_child(output_panel)
	_status = UI.dim("Try a greeting with her name. Test code shows your words; Send message delivers them.", 17)
	_status.custom_minimum_size.y = 58
	body.add_child(_status)
	_conversation = UI.vbox(12)
	_conversation.hide()
	_conversation.add_child(UI.dim("Hotaru stirs at the terminal’s message chime. Her light comes on and she looks towards the desk.", 20))
	_choices = UI.vbox(8)
	for index: int in range(REPLIES.size()):
		_choices.add_child(UI.button(REPLIES[index], &"", &"ButtonQuiet", _reply.bind(index)))
	_choices.hide()
	_conversation.add_child(_choices)
	_continue = UI.button("Continue", &"", &"ButtonPrimary", _advance_conversation)
	_conversation.add_child(_continue)
	body.add_child(_conversation)
	var actions := UI.hbox(9)
	_run = UI.button("Test code", &"play", &"ButtonPrimary", preview)
	_speak = UI.button("Send message", &"check", &"ButtonStamp", speak)
	_speak.disabled = true
	actions.add_child(_run)
	actions.add_child(_speak)
	actions.add_child(UI.button("Back to the loft", &"", &"ButtonQuiet", close))
	body.add_child(actions)
	# Shared lesson lifecycle owns this hidden node; the real desk is our test view.
	test_window = LessonTestWindow.new()
	test_window.hide()
	add_child(test_window)
	message.text_changed.connect(func(_value: String) -> void: _edited())
	editor.text_changed.connect(func() -> void:
		if not _loading and mode == "python" and editor.text != str(session.greeting_editor.get("python", "")):
			if editor.text != _last_generated_python: _python_custom = true
			_edited())
	session.run_finished.connect(_tested)
	session.preview_changed.connect(func(ready: bool) -> void:
		_speak.disabled = not ready
		if not ready and is_instance_valid(_stage): _stage.clear_test_output())
	session.busy_changed.connect(func(busy: bool) -> void:
		_run.disabled = busy
		_speak.disabled = busy or not session.has_preview())
	settings.changed.connect(func(key: String) -> void:
		if key == "font_size":
			editor.apply_settings(settings)
			playback.code.apply_settings(settings))
	_loading = false
	select_mode(str(session.greeting_editor.get("mode", "blocks")), false)
	if CompanionLesson.has_voice(session.state, session.completed):
		_status.text = "Hotaru is awake. Your first page is saved; you can try more words here."
		_output.text = str(session.state.get("spoken", "No output yet."))
	if is_instance_valid(_stage): _stage.speech_finished.connect(_speech_finished)


func restore_story(seen: bool) -> void:
	_introduced = seen
	if not seen and CompanionLesson.has_voice(session.state, session.completed):
		_begin_waking([])


static func _printed_lines(result: Dictionary) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for command: Dictionary in result.get("commands", []):
		if command.get("op") == "say":
			lines.append({"speaker": "player", "text": str(command.text)})
	return lines


static func _paper_code(code: CodeEditor) -> void:
	for style: String in ["normal", "focus", "read_only"]:
		code.add_theme_stylebox_override(style, PaperTheme.panel("inset"))
	for property: String in ["font_color", "font_readonly_color", "caret_color"]:
		code.add_theme_color_override(property, PaperPal.INK)
	code.add_theme_color_override("line_number_color", PaperPal.PENCIL)
	code.add_theme_color_override("current_line_color", Color(PaperPal.TEAL, .08))
	code.add_theme_color_override("selection_color", Color(PaperPal.TEAL, .22))
	code.add_theme_color_override("completion_background_color", PaperPal.PAPER_HI)
	code.add_theme_color_override("completion_existing_color", PaperPal.PAPER_DIM)
	var syntax := CodeHighlighter.new()
	syntax.number_color = Color("8e442b")
	syntax.symbol_color = PaperPal.INK_SOFT
	syntax.function_color = PaperPal.TEAL_DEEP
	syntax.member_variable_color = PaperPal.INK
	for word: String in ApiReference.KEYWORDS: syntax.add_keyword_color(word, Color("79516c"))
	for word: String in ApiReference.BUILTINS: syntax.add_keyword_color(word, PaperPal.TEAL_DEEP)
	syntax.add_color_region('"', '"', Color("3c7047"))
	syntax.add_color_region("'", "'", Color("3c7047"))
	syntax.add_color_region("#", "", PaperPal.PENCIL, true)
	code.syntax_highlighter = syntax


func _selected_source() -> String:
	return 'def program(world):\n    print(%s)\n' % JSON.stringify(message.text) if mode == "blocks" else editor.text


func select_mode(next: String, invalidate: bool = true) -> void:
	if mode == "python" and editor.text != _last_generated_python: _python_custom = true
	mode = "python" if next == "python" else "blocks"
	if mode == "python" and not _python_custom:
		_loading = true
		_last_generated_python = 'def program(world):\n    print(%s)\n' % JSON.stringify(message.text)
		editor.text = _last_generated_python
		_loading = false
	_blocks.visible = mode == "blocks"
	editor.visible = mode == "python"
	_directions.text = "1 · In the message box, change Hello to Hello, Hotaru!\n2 · Test code shows your words in the room.\n3 · Send message delivers the greeting to Hotaru." if mode == "blocks" else "1 · On line 2, put Hello, Hotaru! between the quotation marks.\n2 · Leave the spaces before print in place.\n3 · Test your words, then Send message to deliver the greeting."
	_blocks_tab.button_pressed = mode == "blocks"
	_python_tab.button_pressed = mode == "python"
	if invalidate: _edited()


func _remember() -> void:
	if mode == "python" and editor.text != _last_generated_python: _python_custom = true
	session.greeting_editor = {"mode":mode, "message":message.text, "python":editor.text, "python_custom":_python_custom}
	session.set_source(_selected_source())
	session.source_changed.emit()


func _edited() -> void:
	if _loading: return
	_remember()
	session.discard_preview()
	playback.clear()
	_test_lines.clear()
	_output.text = "Changed · test again for a fresh output."
	_status.text = "Your edit is saved. Test it before sending."
	_status.add_theme_color_override("font_color", PaperPal.INK_SOFT)


func preview() -> void:
	if session.busy or _in_conversation: return
	_remember()
	playback.clear()
	if is_instance_valid(_stage): _stage.clear_speech()
	await session.run_preview()


func _tested(result: Dictionary) -> void:
	if not drawer_open: return
	if result.get("stale", false):
		_output.text = "That test is out of date. Test your current page again."
		return
	_test_lines.clear()
	if result.get("ok", false): _test_lines.assign(_printed_lines(result))
	playback.load_run(session.source, result, editor if mode == "python" else null)
	_output.text = str(result.get("stdout", "")).strip_edges()
	if not result.get("ok", false):
		var error: Dictionary = result.get("error", {})
		var advice: Dictionary = ErrorAdvice.explain(error, ApiReference.known_names(session.source))
		_status.text = str(result.get("reason", "Check this line.")) if bool(result.get("rejected", false)) or str(error.get("kind", "")) == "" else str(advice.title) + "\n" + str(advice.body)
		_status.add_theme_color_override("font_color", PaperPal.RED_DEEP)
		if _output.text == "": _output.text = "The program stopped before it displayed anything."
		return
	if _output.text == "": _output.text = "Nothing printed. Try print(\"Hello, Hotaru!\")."
	_status.text = "Test ready. Send message delivers these words to Hotaru." if CompanionLesson.has_voice(session.state, session.completed) else "Test ready. Send message delivers it; a greeting with Hotaru’s name rings her bell."
	_status.add_theme_color_override("font_color", PaperPal.TEAL_DEEP)
	if is_instance_valid(_stage):
		_stage.show_output(str(result.get("stdout", "")), true)
		_stage.play_speech(_printed_lines(result), true)


func speak() -> void:
	if _in_conversation: return
	# Also guard the same input frame, before TextEdit's deferred change signal.
	if _selected_source() != session.source:
		_edited()
		return
	var was_awake: bool = CompanionLesson.has_voice(session.state, session.completed)
	if not session.apply_preview(): return
	playback.clear()
	if is_instance_valid(_stage): _stage.show_output(str(session.last_run.get("stdout", "")), false)
	if CompanionLesson.has_voice(session.state, session.completed):
		_status.text = "Hotaru: “I heard that. Send me another message whenever you like.”" if was_awake else "Hotaru: “Oh. Morning. You’re the one in the loft, then? I’m Hotaru.”"
		_status.add_theme_color_override("font_color", PaperPal.TEAL_DEEP)
		if not was_awake or not _introduced:
			_begin_waking(_printed_lines(session.last_run))
		elif is_instance_valid(_stage):
			var lines := _printed_lines(session.last_run)
			lines.append({"speaker": "hotaru", "text": "I heard that. Send me another message whenever you like."})
			_stage.play_speech(lines)
	else:
		_status.text = "Your words appear on the screen. A greeting with Hotaru’s name will ring her message bell."
		_status.add_theme_color_override("font_color", PaperPal.INK_SOFT)
		if is_instance_valid(_stage): _stage.play_speech(_printed_lines(session.last_run))
	applied.emit()


func _begin_waking(lines: Array[Dictionary]) -> void:
	if waking_requested.has_connections():
		waking_requested.emit()
		return
	_in_conversation = true
	_answered = false
	_writing.hide()
	_conversation.show()
	_choices.hide()
	_continue.show()
	_continue.text = "Continue"
	_run.disabled = true
	_speak.disabled = true
	_run.hide()
	_speak.hide()
	_status.text = "Hotaru: “Oh. Morning. You’re the one in the loft, then? I’m Hotaru.”"
	lines.append({"speaker": "hotaru", "text": "Oh. Morning."})
	lines.append({"speaker": "hotaru", "text": "You’re the one in the loft, then? I’m Hotaru."})
	if is_instance_valid(_stage): _stage.play_speech(lines, false, true)


func _advance_conversation() -> void:
	if not _in_conversation: return
	if is_instance_valid(_stage) and _stage.speech_text != "" and not _stage.speech_complete:
		_stage.advance_speech()
	elif _answered:
		_in_conversation = false
		_writing.show()
		_conversation.hide()
		_run.disabled = false
		_run.show()
		_speak.show()
		if is_instance_valid(_stage): _stage.clear_speech()
		_status.text = "Your first page is saved. A work ticket is waiting downstairs. You can return here to try more words."


func _reply(index: int) -> void:
	if not _in_conversation or _answered or not _choices.visible: return
	_answered = true
	_choices.hide()
	_continue.show()
	_status.text = "You and Hotaru · a first conversation"
	var lines: Array[Dictionary] = [{"speaker": "player", "text": REPLIES[index]},
		{"speaker": "hotaru", "text": ANSWERS[index]},
		{"speaker": "hotaru", "text": "Nell left you the desk. The drawers stick a little; lift them as you pull."},
		{"speaker": "hotaru", "text": "I’ll be here if you need me. Nell should be back for lunch."}]
	if is_instance_valid(_stage): _stage.play_speech(lines, false, true)


func _speech_finished() -> void:
	if not _in_conversation: return
	if not _answered:
		_choices.show()
		_continue.hide()
		_status.text = "Hotaru is waiting for your answer."
	else:
		_introduced = true
		_continue.text = "Keep experimenting"
		_status.text = "Hotaru is awake. Your page is saved. Nell has left a work ticket downstairs; this page stays here for more experiments."
		introduction_finished.emit()


func stop() -> void:
	_remember()
	session.discard_preview()
	playback.clear()
	if is_instance_valid(_stage): _stage.clear_speech()
	drop_focus()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
