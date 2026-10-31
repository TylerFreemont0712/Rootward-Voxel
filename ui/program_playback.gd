class_name ProgramPlayback
extends VBoxContainer
## Replays bounded execution evidence returned by CPython/WASI. Never evaluates source.
## `use_screen_look()` gives it the field slate's debugger look: VS Code's executing-line highlight and arrow in the
## gutter, with the line's values written dim at its end. Without it the older journeys keep their teal highlight.
signal command_reached(index: int)
signal replay_started
## The program's own names as they stand at the step shown (a debugger's VARIABLES), and once the replay ends.
signal variables_changed(names: Dictionary)
var code: CodeEditor
var debugger: bool = false
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
var _inline: Label
var _inline_line: int=-1
var _locals: Dictionary={}

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

## The field slate's look: dark glass, the executing line marked as in a debugger, values at the end of the line.
func use_screen_look() -> void:
	debugger=true
	CodePalette.style(code)

func load_run(source: String, result: Dictionary, manual_editor: CodeEditor=null) -> void:
	clear()
	code.text=source
	if debugger:CodePalette.refresh_names(code)
	code.visible=manual_editor==null
	_target=manual_editor if manual_editor!=null else code
	for event: Dictionary in result.get("trace",[]):_events.append(event)
	_error_line=int(result.get("error",{}).get("line",0))
	_locals=result.get("locals",{})
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
		_mark(line)
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
		variables_changed.emit(_locals if not _locals.is_empty() else _names_at(_events.size()))
		return
	_unmark()
	var event: Dictionary=_events[_cursor]
	_cursor+=1
	_highlight=int(event.line)-1
	if _target!=null and _highlight>=0 and _highlight<_target.get_line_count():
		_mark(_highlight)
		_target.set_caret_line(_highlight)
		_target.center_viewport_to_caret()
	var values: PackedStringArray=[]
	for key: String in event.get("values",{}):values.append("%s = %s" % [key,str(event.values[key])])
	_caption.text="Line %d" % int(event.line)+(" · "+"   ".join(values) if not values.is_empty() else "")
	_caption.tooltip_text="Executed step %d / %d%s" % [_cursor,_events.size()," (first 96 steps)" if _events.size()==96 else ""]
	if debugger and _cursor>1:
		# What a line set shows at the end of that line, as a debugger writes it, once the next line is reached.
		var set_here: PackedStringArray=[]
		var names: Dictionary=event.get("vars",{})
		for key: String in names:set_here.append("%s = %s" % [key,str(names[key])])
		var setter: int=int(_events[_cursor-2].line)-1
		if not set_here.is_empty():_show_inline(setter,set_here)
	elif not debugger:_show_inline(_highlight,values)
	variables_changed.emit(_names_at(_cursor))
	if event.has("command"):command_reached.emit(int(event.command))
	_next.disabled=false

## The names as a debugger would show them paused at step `count`: every change recorded up to that step.
func _names_at(count: int) -> Dictionary:
	var names: Dictionary={}
	for index: int in range(mini(count,_events.size())):
		var changed: Dictionary=_events[index].get("vars",{})
		for key: String in changed:names[key]=changed[key]
	return names

func clear() -> void:
	_unmark()
	_locals={}
	_events.clear()
	_cursor=0
	_playing=false
	_error_line=0
	visible=false

func _mark(line: int) -> void:
	if debugger:
		_target.set_line_background_color(line,CodePalette.EXEC_LINE)
		_target.set_line_as_executing(line,true)
	else:_target.set_line_background_color(line,Color(Pal.TEAL,.22))

func _unmark() -> void:
	if is_instance_valid(_target) and _highlight>=0 and _highlight<_target.get_line_count():
		_target.set_line_background_color(_highlight,Color.TRANSPARENT)
		if debugger:_target.set_line_as_executing(_highlight,false)
	_highlight=-1
	_inline_line=-1
	if _inline!=null:_inline.modulate.a=0.0

## The values the line just worked with, dim at its end, as VS Code shows them while debugging.
func _show_inline(line: int, values: PackedStringArray) -> void:
	if not debugger or not is_instance_valid(_target) or values.is_empty():
		_inline_line=-1
		if _inline!=null:_inline.modulate.a=0.0
		return
	if _inline==null:
		_inline=Label.new()
		_inline.mouse_filter=Control.MOUSE_FILTER_IGNORE
		_inline.add_theme_font_override("font",UITheme.mono_font())
		_inline.add_theme_color_override("font_color",Color(CodePalette.TEXT,.55))
		var back:=StyleBoxFlat.new()
		back.bg_color=Color(1,1,1,.07)
		back.set_corner_radius_all(3)
		back.content_margin_left=6
		back.content_margin_right=6
		back.content_margin_top=0
		back.content_margin_bottom=0
		_inline.add_theme_stylebox_override("normal",back)
		_inline.clip_text=true
	if _inline.get_parent()!=_target:
		if _inline.get_parent()!=null:_inline.get_parent().remove_child(_inline)
		_target.add_child(_inline)
	_inline.add_theme_font_size_override("font_size",maxi(11,_target.get_theme_font_size("font_size")-3))
	_inline.text="   ".join(values)
	_inline_line=line
	_place_inline()

func _place_inline() -> void:
	if _inline==null or _inline_line<0 or not is_instance_valid(_target) or _inline_line>=_target.get_line_count():return
	var rect: Rect2i=_target.get_rect_at_line_column(_inline_line,_target.get_line(_inline_line).length())
	var free: float=_target.size.x-float(rect.position.x+rect.size.x)-36.0
	if rect.position.x<0 or rect.position.y<0 or free<64.0:
		_inline.modulate.a=0.0
		return
	var font: Font=_inline.get_theme_font("font")
	var wanted: float=font.get_string_size(_inline.text,HORIZONTAL_ALIGNMENT_LEFT,-1,_inline.get_theme_font_size("font_size")).x+14.0
	_inline.size=Vector2(minf(wanted,free),float(rect.size.y))
	_inline.position=Vector2(float(rect.position.x+rect.size.x)+16.0,float(rect.position.y))
	_inline.modulate.a=1.0

func _process(delta: float) -> void:
	if _inline_line>=0:_place_inline()
	if not _playing:return
	_elapsed+=delta
	if _elapsed>=.32:
		_elapsed=0
		step()
