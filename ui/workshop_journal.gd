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
var _tablet: TabletScreen
var _python_custom: bool = false
var _last_generated_python: String = ""
var _directions: Label
signal introduction_finished
signal waking_requested
var _writing: Control
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
	# Nell's paper scrolls; the terminal's glass stays whole beneath it.
	var writing := UI.vbox(9)
	writing.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_writing = writing
	body.add_child(writing)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	writing.add_child(scroll)
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
	# The greeting is written on the loft desk's terminal: instructions above on paper, code on its glass.
	_tablet = TabletScreen.new(TabletScreen.Look.TERMINAL)
	_tablet.link = ZoneTerminals.caption(session.area, session.state)
	_tablet.link_kind = TabletScreen.Link.WIRED
	_tablet.set_tabs(["message.blocks", "hello_hotaru.py"], 0, func(index: int) -> void: select_mode("python" if index == 1 else "blocks"))
	_tablet.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tablet.size_flags_stretch_ratio = 2.0
	writing.add_child(_tablet)
	_blocks = UI.vbox(8)
	_tablet.content.add_child(_blocks)
	var block := PanelContainer.new()
	block.add_theme_stylebox_override("panel", CodePalette.glass(CodePalette.BG_RAISED))
	_blocks.add_child(block)
	var block_body := UI.vbox(6)
	block.add_child(block_body)
	block_body.add_child(UI.label("01 · PRINT A MESSAGE", &"LabelCaps", 13))
	var expression := UI.hbox(0)
	expression.add_child(UI.label("print", &"", 19, CodePalette.FUNCTION))
	expression.add_child(UI.label("(", &"", 19, CodePalette.TEXT))
	expression.add_child(UI.label('"', &"", 19, CodePalette.STRING))
	message = LineEdit.new()
	message.max_length = 160
	message.placeholder_text = "Type your message here"
	message.text = str(session.greeting_editor.get("message", "Hello"))
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message.add_theme_font_override("font", UITheme.mono_font())
	expression.add_child(message)
	expression.add_child(UI.label('"', &"", 19, CodePalette.STRING))
	expression.add_child(UI.label(")", &"", 19, CodePalette.TEXT))
	block_body.add_child(expression)
	var comment: Label = UI.label("# The quotation marks hold the words. Change the words inside them and the terminal shows something new.", &"", 15, CodePalette.COMMENT)
	comment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blocks.add_child(comment)
	editor = CodeEditor.new()
	editor.custom_minimum_size.y = 170
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.apply_settings(settings)
	var starter: String = str(session.area.quest("say-hello").get("starter", 'def program(world):\n    print("Hello")'))
	var existing: String = session.source if session.source != CompanionLesson.STARTER else starter
	editor.text = str(session.greeting_editor.get("python", existing))
	_python_custom = bool(session.greeting_editor.get("python_custom", session.greeting_editor.has("python") or session.source != CompanionLesson.STARTER))
	_last_generated_python = editor.text
	editor.tooltip_text = 'On line 2, change the words between the quotation marks. Keep the spaces before print.'
	CodePalette.style(editor)
	_tablet.content.add_child(editor)
	editor.run_requested.connect(preview)
	playback = ProgramPlayback.new()
	playback.replay_started.connect(func() -> void:
		if session.has_preview() and is_instance_valid(_stage): _stage.play_speech(_test_lines, true))
	playback.code.apply_settings(settings)
	playback.use_screen_look()
	_tablet.content.add_child(playback)
	_output = _tablet.output
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
	_tablet.select_tab(0 if mode == "blocks" else 1)
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
	_tablet.set_output("Changed · test again for a fresh output.")
	_tablet.set_state(&"edited")
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
		_tablet.set_output(_output.text, &"error")
		_tablet.set_state(&"error")
		return
	if _output.text == "": _output.text = "Nothing printed. Try print(\"Hello, Hotaru!\")."
	_tablet.set_output(_output.text)
	_tablet.set_state(&"ghost")
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
	_tablet.set_state(&"sent")
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
