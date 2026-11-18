class_name TerminalApp
extends VBoxContainer
## The tablet's terminal: scrollback, a configurable coloured prompt, command history (Up/Down),
## tab completion and Ctrl+L. Commands run through GitShell; this control only draws and types.

signal exit_requested
signal ran
## A line finished running (lessons listen for the exact command).
signal command_ran(line: String, ok: bool)

## A command a lesson suggests: shown grey in the empty input; Tab accepts it.
var ghost: String = "":
	set(value):
		ghost = value
		if _input != null:
			_input.placeholder_text = value

const MAX_LINES: int = 600

var shell: GitShell
var _screen: RichTextLabel
var _prompt: RichTextLabel
var _input: LineEdit
var _history: PackedStringArray = []
var _history_at: int = -1
var _draft: String = ""


func setup(command_shell: GitShell) -> void:
	shell = command_shell
	add_theme_constant_override("separation", 6)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_screen = RichTextLabel.new()
	_screen.bbcode_enabled = true
	_screen.scroll_following = true
	_screen.selection_enabled = true
	_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen.add_theme_font_override("normal_font", UITheme.mono_font())
	_screen.add_theme_font_override("bold_font", UITheme.mono_font())
	_screen.add_theme_font_override("mono_font", UITheme.mono_font())
	_screen.add_theme_font_size_override("normal_font_size", 15)
	_screen.add_theme_font_size_override("bold_font_size", 15)
	_screen.add_theme_color_override("default_color", CodePalette.TEXT)
	_screen.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_screen)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	add_child(row)
	_prompt = RichTextLabel.new()
	_prompt.bbcode_enabled = true
	_prompt.fit_content = true
	_prompt.scroll_active = false
	_prompt.autowrap_mode = TextServer.AUTOWRAP_OFF
	_prompt.add_theme_font_override("normal_font", UITheme.mono_font())
	_prompt.add_theme_font_size_override("normal_font_size", 15)
	_prompt.add_theme_color_override("default_color", CodePalette.TEXT)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_prompt)
	_input = LineEdit.new()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.add_theme_font_override("font", UITheme.mono_font())
	_input.add_theme_font_size_override("font_size", 15)
	_input.add_theme_color_override("font_color", CodePalette.TEXT)
	_input.add_theme_color_override("caret_color", CodePalette.TEXT)
	_input.caret_blink = true
	var flat := StyleBoxEmpty.new()
	for state: StringName in [&"normal", &"focus", &"read_only"]:
		_input.add_theme_stylebox_override(state, flat)
	_input.text_submitted.connect(_submit)
	_input.gui_input.connect(_on_input)
	row.add_child(_input)
	_screen.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed: focus_input())
	_print("[color=#%s]Rootward field tablet · journey terminal[/color]" % CodePalette.DIM.to_html(false))
	_print("[color=#%s]Nothing is saved until you commit it. Type [/color]help[color=#%s] for the commands.[/color]" % [CodePalette.DIM.to_html(false), CodePalette.DIM.to_html(false)])
	_print("")
	_refresh_prompt()


func focus_input() -> void:
	if _input != null:
		_input.grab_focus()
		_input.caret_column = _input.text.length()


## Runs a line as if typed (tests and scripted lessons).
func run_line(line: String) -> Dictionary:
	_print(shell.prompt() + _escape(line))
	var result: Dictionary = shell.run(line)
	if result.clear:
		_screen.clear()
	elif str(result.output) != "":
		_print(str(result.output))
	if result.exit:
		exit_requested.emit()
	_refresh_prompt()
	ran.emit()
	command_ran.emit(line.strip_edges(), bool(result.ok))
	return result


func _submit(text: String) -> void:
	_input.clear()
	if text.strip_edges() != "":
		if _history.is_empty() or _history[-1] != text:
			_history.append(text)
	_history_at = -1
	_draft = ""
	run_line(text)
	focus_input()


func _on_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var key := event as InputEventKey
	match key.keycode:
		KEY_UP:
			_recall(-1)
			accept_event()
		KEY_DOWN:
			_recall(1)
			accept_event()
		KEY_TAB:
			_complete()
			accept_event()
		KEY_L:
			if key.ctrl_pressed:
				_screen.clear()
				accept_event()
		KEY_C:
			if key.ctrl_pressed and not _input.has_selection():
				_print(shell.prompt() + _escape(_input.text) + "^C")
				_input.clear()
				accept_event()
		KEY_ESCAPE:
			exit_requested.emit()
			accept_event()


func _recall(direction: int) -> void:
	if _history.is_empty():
		return
	if _history_at == -1:
		if direction > 0:
			return
		_draft = _input.text
		_history_at = _history.size() - 1
	else:
		_history_at += direction
	if _history_at >= _history.size():
		_history_at = -1
		_input.text = _draft
	else:
		_history_at = clampi(_history_at, 0, _history.size() - 1)
		_input.text = _history[_history_at]
	_input.caret_column = _input.text.length()


func _complete() -> void:
	if _input.text == "" and ghost != "":
		_input.text = ghost
		_input.caret_column = _input.text.length()
		return
	var line: String = _input.text
	var options: PackedStringArray = shell.complete(line)
	if options.is_empty():
		return
	var words: PackedStringArray = GitShell.tokenize(line)
	var partial: String = "" if line.ends_with(" ") or line == "" else (words[-1] if not words.is_empty() else "")
	if options.size() == 1:
		_input.text = line.substr(0, line.length() - partial.length()) + options[0] + " "
	else:
		var common: String = options[0]
		for option: String in options:
			while not option.begins_with(common):
				common = common.left(common.length() - 1)
		if common.length() > partial.length():
			_input.text = line.substr(0, line.length() - partial.length()) + common
		else:
			_print(shell.prompt() + _escape(line))
			_print("  ".join(options))
	_input.caret_column = _input.text.length()


func _refresh_prompt() -> void:
	_prompt.text = shell.prompt()


func _print(bbcode: String) -> void:
	_screen.append_text(bbcode + "\n")
	if _screen.get_line_count() > MAX_LINES:
		_screen.remove_paragraph(0)


static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")
