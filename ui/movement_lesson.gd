class_name MovementLesson
extends LearningLesson
## Event blocks and Python share the real WASI run, diagnostics and test viewport.
var playback: ProgramPlayback
var _continue: FButton
var _run_commands: Array=[]
var generated_editor: CodeEditor
var demo: MovementTestView
var _block_results: Array[Label]=[]
var _results: Dictionary={}
var mode: String="blocks"
var key_fields: Array[OptionButton]=[]
var direction_fields: Array[OptionButton]=[]
var amount_fields: Array[SpinBox]=[]
var _block_panels: Array[PanelContainer]=[]
var _blocks: VBoxContainer
var _work: ScrollContainer
var _status_label: Label
var _demo_label: Label
var _apply: FButton
var _run: FButton
var _undo: FButton
var _loading: bool=true
var _blocks_tab: FButton
var _python_tab: FButton
var _source_button: FButton
var _test_keys: HFlowContainer
var _requested_key: String=""

func setup(value: GameSession, settings: GameSettings) -> void:
	session=value
	var body:=UI.vbox(6)
	add_child(body)
	var heading:=UI.hbox(8)
	var titles:=UI.vbox(0)
	titles.add_child(UI.caps("FIELD NOTES / 01",Pal.TEAL))
	titles.add_child(UI.heading("Your first steps",20))
	heading.add_child(UI.fill(titles))
	heading.add_child(UI.icon_button(&"cross","Close notebook (E or Esc)",close))
	body.add_child(heading)
	var tabs:=UI.hbox(6)
	_blocks_tab=UI.button("Blocks",&"cube",&"ButtonTab",func() -> void:select_mode("blocks"))
	_python_tab=UI.button("Python",&"code",&"ButtonTab",func() -> void:select_mode("python"))
	for button: FButton in [_blocks_tab,_python_tab]:
		button.toggle_mode=true
		tabs.add_child(button)
	tabs.add_child(UI.fill(UI.spacer()))
	_source_button=UI.button("See Python",&"code",&"ButtonQuiet",_toggle_source)
	_source_button.toggle_mode=true
	tabs.add_child(_source_button)
	body.add_child(tabs)
	body.add_child(UI.dim("One press → one step. x goes ↘ / ↖; y goes ↗ / ↙.",16))
	_work=ScrollContainer.new()
	_work.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	_work.custom_minimum_size.y=160
	_work.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_child(_work)
	var page:=UI.vbox(7)
	page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	page.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_work.add_child(page)
	_blocks=UI.vbox(7)
	page.add_child(_blocks)
	var draft: Dictionary=session.movement_editor
	var keys: Array=["W","A","S","D"]
	var directions: Array=["north","west","south","east"]
	var amounts: Array=[1,0,0,0]
	if draft.get("keys") is Array and draft["keys"].size()==4 and draft.get("directions") is Array and draft.directions.size()==4:
		keys=draft["keys"]
		for index: int in range(4):
			if MovementBindings.DIRECTIONS.has(str(draft.directions[index])):directions[index]=draft.directions[index]
		if draft.get("amounts") is Array and draft.amounts.size()==4:amounts=draft.amounts
		else:
			for index: int in range(4):amounts[index]=1 if str(draft.directions[index])!="" else 0
	elif not session.state.controls.is_empty():
		var bound: Array=session.state.controls.keys()
		for index: int in range(mini(4,bound.size())):
			keys[index]=bound[index]
			directions[index]=session.state.controls[bound[index]]
			amounts[index]=1
	for index: int in range(4):_event(index,str(keys[index]),str(directions[index]),clampi(int(amounts[index]),0,4))
	generated_editor=CodeEditor.new()
	generated_editor.editable=false
	generated_editor.custom_minimum_size.y=100
	generated_editor.size_flags_vertical=Control.SIZE_EXPAND_FILL
	generated_editor.apply_settings(settings)
	generated_editor.run_requested.connect(preview)
	generated_editor.visible=false
	page.add_child(generated_editor)
	editor=CodeEditor.new()
	editor.custom_minimum_size.y=100
	editor.size_flags_vertical=Control.SIZE_EXPAND_FILL
	editor.apply_settings(settings)
	editor.text=str(draft.get("python",session.source if session.source.contains("world.controls.") else MovementBindings.STARTER)).left(GameSession.MAX_SOURCE)
	page.add_child(editor)
	editor.text_changed.connect(func() -> void:
		if _loading:return
		# CodeEdit can deliver this after Test already captured the same text.
		# Only a genuinely newer edit should invalidate that in-flight run.
		if session.source==editor.text:return
		session.set_source(editor.text)
		_edited("Your Python changed. Test again."))
	editor.run_requested.connect(preview)
	playback=ProgramPlayback.new()
	body.add_child(playback)
	playback.command_reached.connect(_replay_command)
	test_window=LessonTestWindow.new()
	var bench:=UI.hbox(8)
	var bench_title:=UI.heading("Movement test",18)
	bench_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	bench.add_child(bench_title)
	bench.add_child(UI.caps("PREVIEW",Pal.TEAL))
	test_window.body.add_child(bench)
	var frame:=UI.panel(&"PanelInset")
	frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
	demo=MovementTestView.new()
	demo.custom_minimum_size.y=72
	demo.size_flags_vertical=Control.SIZE_EXPAND_FILL
	demo.setup(session.area,session.state)
	frame.add_child(demo)
	test_window.body.add_child(frame)
	_test_keys=HFlowContainer.new()
	_test_keys.add_theme_constant_override("h_separation",6)
	_test_keys.add_theme_constant_override("v_separation",4)
	test_window.body.add_child(_test_keys)
	_key_buttons(keys)
	demo.demonstrated.connect(_show_trial)
	_demo_label=UI.dim("Test a key to see its movement.\nYour real character stays in the room.",16)
	_demo_label.custom_minimum_size.y=42
	test_window.body.add_child(_demo_label)
	var feedback:=ScrollContainer.new()
	feedback.custom_minimum_size.y=32
	feedback.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	_status_label=UI.dim("",14)
	_status_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	feedback.add_child(_status_label)
	body.add_child(feedback)
	var actions:=UI.hbox(8)
	_run=UI.button("Test code",&"play",&"ButtonPrimary",preview)
	_apply=UI.button("Apply",&"check",&"",apply_bindings)
	_undo=UI.icon_button(&"undo","Undo applied bindings",session.undo_apply)
	_undo.disabled=not session.can_undo()
	_apply.disabled=true
	actions.add_child(_run)
	actions.add_child(_apply)
	actions.add_child(UI.fill(UI.spacer()))
	actions.add_child(_undo)
	body.add_child(actions)
	_continue=UI.button("Continue · try my keys",&"arrow_right",&"ButtonPrimary",close)
	_continue.disabled=MovementBindings.mapped(session.state)!=4
	body.add_child(_continue)
	session.preview_changed.connect(func(ready: bool) -> void:_apply.disabled=not ready)
	session.state_changed.connect(func() -> void:
		_undo.disabled=not session.can_undo()
		demo.clear()
		playback.clear()
		_fit_workspace.call_deferred()
		_continue.disabled=MovementBindings.mapped(session.state)!=4
		_continue.text="Finish · back to the room" if MovementBindings.finished(session.state) else "Continue · try my keys")
	session.busy_changed.connect(func(busy: bool) -> void:_run.disabled=busy)
	session.status.connect(func(title: String,detail: String,failed: bool) -> void:
		_status_label.text=title+("\n"+detail if detail!="" else "")
		_status_label.add_theme_color_override("font_color",Pal.RED if failed else Pal.PARCHMENT))
	session.run_finished.connect(_tested)
	_loading=false
	select_mode(str(draft.get("mode","blocks")),false)
	settings.changed.connect(func(key: String) -> void:
		if key=="font_size":
			editor.apply_settings(settings);generated_editor.apply_settings(settings);playback.code.apply_settings(settings)
			_fit_workspace.call_deferred())
	_status_label.text="W is an example. Change the other amounts from 0 to 1, or try 3 and watch the test."
	_update_source()
	playback.code.apply_settings(settings)

func _event(index: int,key_name: String,direction: String,amount: int) -> void:
	var panel:=PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_block_style(false))
	_block_panels.append(panel)
	var row:=HFlowContainer.new()
	row.add_theme_constant_override("h_separation",8)
	row.add_theme_constant_override("v_separation",3)
	panel.add_child(row)
	var head:=UI.hbox(4)
	head.add_child(_mono("%02d" % (index+1),Pal.MUTED))
	head.add_child(_mono("when key",CodeEditor.KEYWORD_COLOR))
	var key:=OptionButton.new()
	key.add_theme_font_override("font",UITheme.mono_font())
	key.add_theme_font_size_override("font_size",14)
	for name: String in MovementBindings.KEYS:key.add_item(name)
	key.select(maxi(0,MovementBindings.KEYS.find(key_name)))
	head.add_child(key)
	head.add_child(_mono(":",Pal.PARCHMENT))
	row.add_child(head)
	key_fields.append(key)
	var expression:=UI.hbox(4)
	var axis:=OptionButton.new()
	axis.add_theme_font_override("font",UITheme.mono_font())
	axis.add_theme_font_size_override("font_size",14)
	for name: String in ["axis…","y +=","x -=","y -=","x +="]:axis.add_item(name)
	axis.select(MovementBindings.DIRECTIONS.keys().find(direction)+1)
	axis.custom_minimum_size.x=74
	expression.add_child(axis)
	direction_fields.append(axis)
	var distance:=SpinBox.new()
	distance.min_value=0;distance.max_value=4;distance.step=1;distance.value=amount
	distance.custom_minimum_size.x=64
	distance.get_line_edit().add_theme_font_override("font",UITheme.mono_font())
	distance.get_line_edit().add_theme_font_size_override("font_size",14)
	distance.get_line_edit().add_theme_color_override("font_color",CodeEditor.NUMBER_COLOR)
	expression.add_child(distance)
	amount_fields.append(distance)
	row.add_child(expression)
	var feedback:=UI.hbox(5)
	var result:=_mono("· Untested",Pal.MUTED)
	result.add_theme_font_size_override("font_size",12)
	_block_results.append(result)
	feedback.add_child(result)
	var run:=UI.icon_button(&"play","Compile and test this key",func() -> void:test_section(index))
	run.custom_minimum_size=Vector2(24,26)
	feedback.add_child(run)
	row.add_child(feedback)
	_blocks.add_child(panel)
	key.item_selected.connect(func(_i: int) -> void:_changed())
	axis.item_selected.connect(func(_i: int) -> void:_changed())
	distance.value_changed.connect(func(_v: float) -> void:_changed())

func _mono(text: String,color: Color) -> Label:
	var label:=UI.label(text,&"",14,color)
	label.add_theme_font_override("font",UITheme.mono_font())
	return label

func _block_style(active: bool,failed: bool=false,passed: bool=false) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Pal.PANEL_LO.lerp(Pal.RED,.13) if failed else (Pal.PANEL_LO.lerp(Pal.GREEN,.15) if passed else Color(Pal.PANEL_LO,.87))
	style.border_color=Pal.RED if failed else (Pal.GREEN if passed else (Pal.TEAL if active else Color(Pal.TEAL,.25)))
	style.border_width_left=6 if active else 4
	if passed or failed:
		style.border_width_top=1;style.border_width_bottom=1;style.border_width_right=1
	style.corner_radius_top_right=3
	style.corner_radius_bottom_right=3
	style.content_margin_left=10;style.content_margin_right=8
	style.content_margin_top=4;style.content_margin_bottom=4
	return style

func select_mode(next: String,invalidate: bool=true) -> void:
	mode="python" if next=="python" else "blocks"
	_blocks.visible=mode=="blocks" and not _source_button.button_pressed
	editor.visible=mode=="python"
	_source_button.visible=mode=="blocks"
	generated_editor.visible=mode=="blocks" and _source_button.button_pressed
	_blocks_tab.button_pressed=mode=="blocks"
	_python_tab.button_pressed=mode=="python"
	if invalidate:
		playback.clear()
		session.discard_preview()
		demo.clear()
		_clear_results()
		if mode=="python":session.set_source(editor.text)
	_remember()
	_fit_workspace.call_deferred()

func _values() -> Dictionary:
	var keys: Array[String]=[]
	var directions: Array[String]=[]
	var amounts: Array[int]=[]
	for i: int in range(4):
		keys.append(MovementBindings.KEYS[key_fields[i].selected])
		var selected: int=direction_fields[i].selected-1
		directions.append(str(MovementBindings.DIRECTIONS.keys()[selected]) if selected>=0 else "")
		amounts.append(int(amount_fields[i].value))
	return {"keys":keys,"directions":directions,"amounts":amounts}

func _remember() -> void:
	if _loading:return
	var values: Dictionary=_values()
	session.movement_editor={"mode":mode,"keys":values["keys"],"directions":values.directions,"amounts":values.amounts,"python":editor.text}
	session.source_changed.emit()

func _edited(message: String) -> void:
	session.discard_preview()
	playback.clear()
	demo.clear()
	_remember()
	_status_label.text=message
	_demo_label.text="Changed · test again.\nOld results have been cleared."
	_clear_results()
	_fit_workspace.call_deferred()

func _changed() -> void:
	if _loading:return
	_edited("Your blocks changed. Test again before Apply.")
	_update_source()
	_key_buttons(_values()["keys"])

func _key_buttons(keys: Array) -> void:
	for child: Node in _test_keys.get_children():
		_test_keys.remove_child(child)
		child.queue_free()
	for value: Variant in keys:
		var key: String=str(value)
		var button:=UI.button(key,&"",&"ButtonTab",func() -> void:test_key(key))
		button.toggle_mode=true
		button.custom_minimum_size=Vector2(62,30)
		button.add_theme_font_override("font",UITheme.mono_font())
		_test_keys.add_child(button)

func _update_source() -> void:
	var values: Dictionary=_values()
	var compiled: Dictionary=MovementBindings.block_source(values["keys"],values.directions,values.amounts)
	generated_editor.text=str(compiled.get("source",compiled.get("reason","")))

func _toggle_source() -> void:
	generated_editor.visible=_source_button.button_pressed
	_blocks.visible=not _source_button.button_pressed and mode=="blocks"
	_source_button.text="Show blocks" if _source_button.button_pressed else "See Python"
	_work.scroll_vertical=0
	if playback.visible:playback.focus_in(generated_editor if _source_button.button_pressed else null)
	_fit_workspace.call_deferred()

func preview() -> void:
	if session.busy:return
	_remember()
	playback.clear()
	demo.clear()
	if mode=="blocks":
		var values: Dictionary=_values()
		var compiled: Dictionary=MovementBindings.block_source(values["keys"],values.directions,values.amounts)
		if not compiled.ok:
			_status_label.text=str(compiled.reason)
			return
		session.set_source(compiled.source)
	else:session.set_source(editor.text)
	await session.run_preview()

func test_section(index: int) -> void:
	if session.busy:return
	_remember()
	playback.clear()
	demo.clear()
	_clear_results()
	var values: Dictionary=_values()
	var compiled: Dictionary=MovementBindings.block_source(values["keys"],values.directions,values.amounts,index)
	if not compiled.ok:
		_status_label.text=str(compiled.reason)
		return
	_requested_key=values["keys"][index]
	session.set_source(compiled.source)
	await session.run_preview(true)

func _replay_command(index: int) -> void:
	if index>=_run_commands.size():return
	var command: Variant=_run_commands[index]
	if command is Dictionary and command.get("op")=="bind_key":demo.play_key(str(command.get("key","")))

func test_key(key: String) -> void:
	_requested_key=key
	if demo.trials.is_empty():await preview()
	else:
		playback.pause()
		demo.play_key(key)
		_requested_key=""

func _tested(result: Dictionary) -> void:
	if result.get("stale",false):
		playback.clear()
		return
	_run_commands=result.get("commands",[])
	playback.load_run(session.source,result,editor if mode=="python" else (generated_editor if _source_button.button_pressed else null))
	_fit_workspace.call_deferred()
	if mode=="python":
		if result.ok:editor.clear_error()
		else:editor.mark_error(int(result.get("error",{}).get("line",0)))
	var trials: Array[Dictionary]=[]
	for trial: Dictionary in result.get("trials",[]):trials.append(trial)
	if trials.is_empty():
		demo.clear()
		_demo_label.text="No movement to replay.\nCheck the error in your notes."
		return
	demo.load_trials(trials,session.state)
	if mode=="blocks":
		_results.clear()
		for trial: Dictionary in trials:_results[trial.key]=trial
		_paint_results()
		var passed: int=trials.filter(func(trial: Dictionary) -> bool:return trial.ok).size()
		if result.get("section",false):_status_label.text="✓ This event passed. Test code checks all four before Apply."
		if result.ok and passed==4:_status_label.text="✓ All four events passed. Apply to connect your keys."
	var keys: Array=[]
	for trial: Dictionary in trials:keys.append(trial.key)
	_key_buttons(keys)
	var selected: String=_requested_key
	if selected=="":
		selected=trials[0].key
		for trial: Dictionary in trials:
			if not trial.ok:
				selected=trial.key
				break
	_requested_key=""
	if (result.get("trace",[]) as Array).is_empty():demo.play_key(selected)
	else:_demo_label.text="Following the executed Python…\nThe key event plays when its call is reached."

func _show_trial(trial: Dictionary) -> void:
	var count: int=absi(trial.delta.x)+absi(trial.delta.y)
	var outcome: String="✓ One step" if trial.ok else ("No movement · try 1" if count==0 else ("%d cells · target 1" % count))
	if trial.blocked:outcome+=" · blocked"
	_demo_label.text="[%s]  x: 0 → %d   y: 0 → %d\n%s" % [trial.key,trial.delta.x,trial.delta.y,outcome]
	_demo_label.add_theme_color_override("font_color",Pal.GREEN if trial.ok else Pal.RED)
	_paint_results(trial.key)
	for button: FButton in _test_keys.get_children():button.set_pressed_no_signal(button.text==trial.key)

func _clear_results() -> void:
	_results.clear()
	_paint_results()

func _paint_results(active_key: String="") -> void:
	for index: int in range(4):
		var key: String=MovementBindings.KEYS[key_fields[index].selected]
		var tested: Dictionary=_results.get(key,{})
		var passed: bool=not tested.is_empty() and tested.ok
		var failed: bool=not tested.is_empty() and not tested.ok
		_block_panels[index].add_theme_stylebox_override("panel",_block_style(key==active_key,failed,passed))
		_block_results[index].text="✓ Passed" if passed else ("× Blocked" if failed and tested.blocked and tested.valid else ("× Fix" if failed else "· Untested"))
		_block_results[index].add_theme_color_override("font_color",Pal.GREEN if passed else (Pal.RED if failed else Pal.MUTED))

func apply_bindings() -> void:
	if session.apply_preview():
		_status_label.text="Keys connected. Continue to try all four directions.\nPractised: %d / 4." % MovementBindings.tried(session.state)
		applied.emit()

func stop() -> void:
	_remember()
	session.discard_preview()
	demo.clear()
	playback.clear()
	test_window.hide()
	drop_focus()
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _fit_workspace() -> void:
	var source_view: bool=mode=="python" or _source_button.button_pressed
	_work.size_flags_vertical=Control.SIZE_EXPAND_FILL if source_view or not playback.visible else Control.SIZE_FILL
	_work.custom_minimum_size.y=180 if source_view else clampf(_blocks.get_combined_minimum_size().y+4,140,minf(270,get_viewport_rect().size.y*.28))
	playback.size_flags_vertical=Control.SIZE_EXPAND_FILL if mode=="blocks" and not _source_button.button_pressed else Control.SIZE_FILL
	playback.code.custom_minimum_size.y=200 if get_viewport_rect().size.y<850 else 280

func fit_drawer() -> void:
	super.fit_drawer()
	_fit_workspace()
	if test_window.is_inside_tree():test_window.place_beside(get_viewport_rect().size.x-drawer_width-SideDrawer.MARGIN)
