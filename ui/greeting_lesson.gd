class_name GreetingLesson
extends LearningLesson
## Field Notes / 00: both authoring modes compile to real Python print.
var mode: String="blocks"
var message: LineEdit
var playback: ProgramPlayback
var _block: PanelContainer
var _blocks: VBoxContainer
var _status: Label
var _speech: Label
var _run: FButton
var _speak: FButton
var _blocks_tab: FButton
var _python_tab: FButton
var _work: ScrollContainer
var _loading: bool=true

func setup(value: GameSession, settings: GameSettings) -> void:
	session=value
	var body:=UI.vbox(7)
	add_child(body)
	var heading:=UI.hbox(8)
	var titles:=UI.vbox(0)
	titles.add_child(UI.caps("FIELD NOTES / 00",Pal.TEAL))
	titles.add_child(UI.heading("Saying Hello",21))
	heading.add_child(UI.fill(titles))
	heading.add_child(UI.icon_button(&"cross","Back to the room",close))
	body.add_child(heading)
	body.add_child(UI.dim('Hotaru: “I’m right here! Can you say hello to me?”',19))
	body.add_child(UI.dim("print gives your program a voice. Put the words you want to say between quotation marks.",17))
	var tabs:=UI.hbox(6)
	_blocks_tab=UI.button("Blocks",&"cube",&"ButtonTab",func() -> void:select_mode("blocks"))
	_python_tab=UI.button("Python",&"code",&"ButtonTab",func() -> void:select_mode("python"))
	for button: FButton in [_blocks_tab,_python_tab]:button.toggle_mode=true;tabs.add_child(button)
	body.add_child(tabs)
	_work=ScrollContainer.new()
	_work.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	_work.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_child(_work)
	var page:=UI.vbox(7)
	page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_work.add_child(page)
	_blocks=UI.vbox(8)
	page.add_child(_blocks)
	_block=UI.panel(&"PanelInset")
	_blocks.add_child(_block)
	var block_body:=UI.vbox(6)
	_block.add_child(block_body)
	block_body.add_child(UI.caps("01 · YOUR VOICE",Pal.TEAL))
	var expression:=UI.hbox(4)
	expression.add_child(UI.label('print("',&"",19,CodeEditor.BUILTIN_COLOR))
	message=LineEdit.new()
	message.max_length=160
	message.text=str(session.greeting_editor.get("message","Hello, Hotaru!"))
	message.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	message.add_theme_font_override("font",UITheme.mono_font())
	expression.add_child(message)
	expression.add_child(UI.label('")',&"",19,CodeEditor.BUILTIN_COLOR))
	expression.add_child(UI.icon_button(&"play","Test this print block",preview))
	block_body.add_child(expression)
	_blocks.add_child(UI.dim("Quotation marks make this text. Change your greeting and listen to the difference.",16))
	editor=CodeEditor.new()
	editor.custom_minimum_size.y=320
	editor.apply_settings(settings)
	editor.text=str(session.greeting_editor.get("python",CompanionLesson.STARTER))
	page.add_child(editor)
	editor.run_requested.connect(preview)
	playback=ProgramPlayback.new()
	playback.code.apply_settings(settings)
	page.add_child(playback)
	playback.command_reached.connect(_replay_command)
	message.text_changed.connect(func(_text: String) -> void:_edited())
	editor.text_changed.connect(func() -> void:
		if not _loading and session.source!=editor.text:_edited())
	_status=UI.dim("Test your greeting, then Speak to make it part of the room.",17)
	_status.custom_minimum_size.y=36
	body.add_child(_status)
	var actions:=UI.hbox(8)
	_run=UI.button("Test code",&"play",&"ButtonPrimary",preview)
	_speak=UI.button("Speak",&"check",&"",speak)
	_speak.disabled=true
	actions.add_child(_run);actions.add_child(_speak)
	body.add_child(actions)
	body.add_child(UI.button("Back to the room",&"",&"ButtonQuiet",close))
	test_window=LessonTestWindow.new()
	test_window.body.add_child(UI.heading("Your voice · test",20))
	var portrait:=TextureRect.new()
	portrait.texture=load(HotaruFairy.TEXTURE)
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size.y=110
	portrait.size_flags_vertical=Control.SIZE_EXPAND_FILL
	test_window.body.add_child(portrait)
	test_window.body.add_child(UI.caps("HOTARU",Pal.TEAL))
	_speech=UI.dim("Waiting to hear you…",20)
	_speech.custom_minimum_size.y=55
	test_window.body.add_child(_speech)
	session.preview_changed.connect(func(ready: bool) -> void:_speak.disabled=not ready)
	session.busy_changed.connect(func(busy: bool) -> void:_run.disabled=busy)
	session.run_finished.connect(_tested)
	session.state_changed.connect(func() -> void:
		playback.clear()
		_speech.text="Waiting to hear you…")
	settings.changed.connect(func(key: String) -> void:
		if key=="font_size":editor.apply_settings(settings);playback.code.apply_settings(settings))
	_loading=false
	select_mode(str(session.greeting_editor.get("mode","blocks")),false)

func select_mode(next: String, invalidate: bool=true) -> void:
	mode="python" if next=="python" else "blocks"
	_blocks.visible=mode=="blocks"
	editor.visible=mode=="python"
	_blocks_tab.button_pressed=mode=="blocks"
	_python_tab.button_pressed=mode=="python"
	if invalidate:_edited()

func _remember() -> void:
	if _loading:return
	session.greeting_editor={"mode":mode,"message":message.text,"python":editor.text}
	session.source_changed.emit()

func _edited() -> void:
	if _loading:return
	session.discard_preview()
	playback.clear()
	_remember()
	if mode=="python":session.set_source(editor.text)
	_status.text="Changed · test your words again before speaking."
	_speech.text="Waiting to hear you…"
	_block.remove_theme_stylebox_override("panel")

func preview() -> void:
	if session.busy:return
	_remember()
	playback.clear()
	session.set_source('def program(world):\n    print(%s)\n' % JSON.stringify(message.text) if mode=="blocks" else editor.text)
	await session.run_preview()

func _tested(result: Dictionary) -> void:
	if result.get("stale",false):playback.clear();return
	playback.load_run(session.source,result,editor if mode=="python" else null)
	var said: bool=false
	var greeted: bool=false
	for command: Variant in result.get("commands",[]):
		if command is Dictionary and command.get("op")=="say":
			said=true
			greeted=greeted or CompanionLesson.is_greeting(str(command.get("text","")))
	var passed: bool=result.ok and said and greeted
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(Pal.GREEN if passed else Pal.RED,.12)
	style.border_color=Pal.GREEN if passed else Pal.RED
	style.border_width_left=4
	style.content_margin_left=12;style.content_margin_right=12;style.content_margin_top=10;style.content_margin_bottom=10
	_block.add_theme_stylebox_override("panel",style)
	_status.text="✓ Greeting ready. Speak to Hotaru to begin your first steps." if passed else ("Your words ran. Try saying hello and include Hotaru’s name." if result.ok else str(result.get("reason","Check your code.")))
	_status.add_theme_color_override("font_color",Pal.GREEN if passed else Pal.RED)
	if not said:_speech.text="No voice reached Hotaru. Check the code in your notes."

func _replay_command(index: int) -> void:
	var commands: Array=session.last_run.get("commands",[])
	if index<commands.size() and commands[index] is Dictionary and commands[index].get("op")=="say":
		_speech.text='You: “%s”' % str(commands[index].get("text",""))

func speak() -> void:
	if session.apply_preview():
		playback.clear()
		_status.text='Hotaru: “I can hear you! Now let’s give those feet a little direction.”' if session.state.hotaru_greeted else 'Hotaru: “Try hello and my name. I’d love to meet you!”'
		_speech.text='Hotaru: “Hello! It’s lovely to hear your voice.”' if session.state.hotaru_greeted else 'Hotaru: “I heard you. Try saying hello with my name!”'
		applied.emit()
		if session.state.hotaru_greeted:
			next_lesson.emit()

func stop() -> void:
	_remember()
	session.discard_preview()
	playback.clear()
	test_window.hide()
	drop_focus()
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func fit_drawer() -> void:
	super.fit_drawer()
	if test_window.is_inside_tree():test_window.place_beside(get_viewport_rect().size.x-drawer_width-SideDrawer.MARGIN)
