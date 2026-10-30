class_name ProgramPlayback
extends VBoxContainer
## Replays bounded execution evidence returned by CPython/WASI. Never evaluates source.
signal command_reached(index: int)
signal replay_started
var code: CodeEditor
var _caption: Label
var _events: Array[Dictionary]=[]
var _cursor: int=0
var _elapsed: float=0
var _playing: bool=false
var _highlight: int=-1
var _target: CodeEditor
var _error_line: int=0
var _next: FButton
var _replay: FButton
var _pause: FButton

func _init() -> void:
	add_theme_constant_override("separation",4)
	var row:=UI.hbox(6)
	_caption=UI.dim("Executed Python",15)
	row.add_child(UI.fill(_caption))
	_replay=UI.icon_button(&"undo","Replay the executed code",replay)
	_pause=UI.button("Pause",&"",&"ButtonQuiet",func() -> void:
		if _cursor>=_events.size():replay()
		else:
			_playing=not _playing
			_pause.text="Pause" if _playing else "Play")
	_next=UI.button("Next line",&"play",&"ButtonQuiet",func() -> void:
		_playing=false
		_pause.text="Play"
		step())
	row.add_child(_replay);row.add_child(_pause);row.add_child(_next)
	add_child(row)
	code=CodeEditor.new()
	code.editable=false
	code.custom_minimum_size.y=240
	code.size_flags_vertical=Control.SIZE_EXPAND_FILL
	code.add_theme_font_size_override("font_size",15)
	add_child(code)
	clear()

func load_run(source: String, result: Dictionary, manual_editor: CodeEditor=null) -> void:
	clear()
	code.text=source
	code.visible=manual_editor==null
	_target=manual_editor if manual_editor!=null else code
	for event: Dictionary in result.get("trace",[]):_events.append(event)
	_error_line=int(result.get("error",{}).get("line",0))
	visible=true
	_replay.disabled=_events.is_empty()
	_pause.disabled=_events.is_empty()
	_next.disabled=_events.is_empty()
	if _events.is_empty():
		_caption.text="No lines ran. Check the syntax." if _error_line>0 else "No execution steps returned."
		_target.mark_error(_error_line)
	else:replay()

func focus_in(manual_editor: CodeEditor=null) -> void:
	var line: int=_highlight
	_unmark()
	_target=manual_editor if manual_editor!=null else code
	code.visible=manual_editor==null
	_highlight=line
	if line>=0 and line<_target.get_line_count():
		_target.set_line_background_color(line,Color(Pal.TEAL,.22))
		_target.set_caret_line(line)
		_target.center_viewport_to_caret()

func pause() -> void:
	_playing=false
	_pause.text="Play"

func replay() -> void:
	_unmark()
	_cursor=0
	_elapsed=0
	_playing=not _events.is_empty()
	_pause.text="Pause"
	replay_started.emit()
	step()

func step() -> void:
	if _cursor>=_events.size():
		_playing=false
		_pause.text="Play"
		_next.disabled=true
		if _target!=null and _error_line>0:_target.mark_error(_error_line)
		return
	_unmark()
	var event: Dictionary=_events[_cursor]
	_cursor+=1
	_highlight=int(event.line)-1
	if _target!=null and _highlight>=0 and _highlight<_target.get_line_count():
		_target.set_line_background_color(_highlight,Color(Pal.TEAL,.22))
		_target.set_caret_line(_highlight)
		_target.center_viewport_to_caret()
	var values: PackedStringArray=[]
	for key: String in event.get("values",{}):values.append("%s = %s" % [key,str(event.values[key])])
	_caption.text="Line %d · %s" % [int(event.line),"   ".join(values)]
	_caption.tooltip_text="Executed step %d / %d%s" % [_cursor,_events.size()," (first 96 steps)" if _events.size()==96 else ""]
	if event.has("command"):command_reached.emit(int(event.command))
	_next.disabled=false

func clear() -> void:
	_unmark()
	_events.clear()
	_cursor=0
	_playing=false
	_error_line=0
	visible=false

func _unmark() -> void:
	if is_instance_valid(_target) and _highlight>=0 and _highlight<_target.get_line_count():_target.set_line_background_color(_highlight,Color.TRANSPARENT)
	_highlight=-1

func _process(delta: float) -> void:
	if not _playing:return
	_elapsed+=delta
	if _elapsed>=.32:
		_elapsed=0
		step()
