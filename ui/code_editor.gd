class_name CodeEditor
extends CodeEdit
## The notebook's Python editor, tuned for people who are learning: readable colors, automatic
## indentation after a colon, bracket and quote pairing, completion that knows the game's own API,
## and a marker on the line where the last run failed.

signal run_requested

const KEYWORD_COLOR: Color = Color("c9a6f0")
const CONSTANT_COLOR: Color = Color("f0a068")
const BUILTIN_COLOR: Color = Color("7fd0c0")
const NUMBER_COLOR: Color = Color("f4d186")
const STRING_COLOR: Color = Color("a8d98a")
const COMMENT_COLOR: Color = Color("7f725c")
const FUNCTION_COLOR: Color = Color("86d6c6")
const MEMBER_COLOR: Color = Color("e0cfa3")
const ERROR_LINE: Color = Color(0.85, 0.3, 0.25, 0.22)

var _error_line: int = -1
var _auto_complete: bool = true
var _completion_pending: bool = false


func _init() -> void:
	name = "Program"
	gutters_draw_line_numbers = true
	gutters_draw_breakpoints_gutter = true
	gutters_zero_pad_line_numbers = 0
	indent_use_spaces = true
	indent_size = 4
	indent_automatic = true
	indent_automatic_prefixes = [":"]
	auto_brace_completion_enabled = true
	auto_brace_completion_highlight_matching = true
	auto_brace_completion_pairs = {"(": ")", "[": "]", "{": "}", "\"": "\"", "'": "'"}
	delimiter_strings = ["' '", "\" \""]
	delimiter_comments = ["#"]
	highlight_current_line = true
	highlight_all_occurrences = false
	caret_blink = true
	scroll_smooth = true
	code_completion_enabled = true
	code_completion_prefixes = ["."]
	minimap_draw = false
	line_folding = false
	draw_tabs = false
	symbol_lookup_on_click = false
	syntax_highlighter = _highlighter()
	_theme_editor()


func _ready() -> void:
	code_completion_requested.connect(_offer_completions)
	text_changed.connect(_on_text_changed)
	gui_input.connect(_on_gui_input)


func apply_settings(settings: GameSettings) -> void:
	add_theme_font_size_override("font_size", int(settings.get_value("font_size")))
	_auto_complete = bool(settings.get_value("completion"))
	auto_brace_completion_enabled = bool(settings.get_value("auto_brackets"))


## Marks the failing line (1-based, as Python reports it) and scrolls it into view.
func mark_error(line_number: int) -> void:
	clear_error()
	if line_number < 1 or line_number > get_line_count():
		return
	_error_line = line_number - 1
	set_line_background_color(_error_line, ERROR_LINE)
	set_line_as_breakpoint(_error_line, true)
	set_caret_line(_error_line)
	center_viewport_to_caret()


func clear_error() -> void:
	if _error_line >= 0 and _error_line < get_line_count():
		set_line_background_color(_error_line, Color(0, 0, 0, 0))
		set_line_as_breakpoint(_error_line, false)
	_error_line = -1


## Inserts code at the caret as one undoable edit. Continuation lines keep the caret line's indentation.
func insert_snippet(snippet: String) -> void:
	var line: String = get_line(get_caret_line())
	var indent: String = line.substr(0, line.length() - line.lstrip(" \t").length()) if line.strip_edges() == "" else ""
	var lines: PackedStringArray = snippet.split("\n")
	for index: int in range(1, lines.size()):
		lines[index] = indent + lines[index] if lines[index] != "" else lines[index]
	begin_complex_operation()
	insert_text_at_caret("\n".join(lines))
	end_complex_operation()
	grab_focus()


## Replaces the whole program as one undoable edit, so Ctrl+Z brings the old code back.
func replace_program(program: String) -> void:
	begin_complex_operation()
	select_all()
	insert_text_at_caret(program)
	deselect()
	end_complex_operation()
	clear_error()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (((event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER) and event.ctrl_pressed) or event.keycode == KEY_F5):
		accept_event()
		run_requested.emit()


func _on_text_changed() -> void:
	clear_error()
	if not _auto_complete or _completion_pending:
		return
	var line: String = get_line(get_caret_line()).substr(0, get_caret_column())
	if line.length() >= 2 and (line[-1] == "_" or line[-1].to_lower() != line[-1].to_upper()) and not line.strip_edges().begins_with("#"):
		_completion_pending = true
		request_code_completion.call_deferred()
		(func() -> void: _completion_pending = false).call_deferred()


func _offer_completions() -> void:
	var line: String = get_line(get_caret_line()).substr(0, get_caret_column())
	if line.strip_edges().begins_with("#") or _inside_string(line):
		return
	var member := RegEx.new()
	member.compile("([A-Za-z_][A-Za-z0-9_]*)\\.([A-Za-z_0-9]*)$")
	var hit: RegExMatch = member.search(line)
	if hit != null:
		var type_name: String = ApiReference.infer_type(text, hit.get_string(1))
		var members: Array[Dictionary] = ApiReference.members_of(type_name)
		if members.is_empty():
			for candidate: String in ApiReference.TYPES:
				if candidate != "World":
					members.append_array(ApiReference.members_of(candidate))
		var seen: Dictionary = {}
		for item: Dictionary in members:
			if seen.has(item.name):
				continue
			seen[item.name] = true
			var is_method: bool = item.kind == "method"
			add_code_completion_option(CodeEdit.KIND_FUNCTION if is_method else CodeEdit.KIND_MEMBER, item.name + ("(" + _arguments(item) + ")" if is_method else ""),
				item.name, FUNCTION_COLOR if is_method else MEMBER_COLOR)
		update_code_completion_options(true)
		return
	var word := RegEx.new()
	word.compile("([A-Za-z_][A-Za-z0-9_]*)$")
	if word.search(line) == null:
		return
	var offered: Dictionary = {}
	for name: String in ApiReference.KEYWORDS:
		offered[name] = true
		add_code_completion_option(CodeEdit.KIND_PLAIN_TEXT, name, name, CONSTANT_COLOR if name in ["True", "False", "None"] else KEYWORD_COLOR)
	for name: String in ApiReference.BUILTINS:
		offered[name] = true
		add_code_completion_option(CodeEdit.KIND_FUNCTION, name, name, BUILTIN_COLOR)
	offered["world"] = true
	add_code_completion_option(CodeEdit.KIND_VARIABLE, "world", "world", MEMBER_COLOR)
	for name: String in ApiReference.known_names(text):
		if not offered.has(name) and name.length() > 2:
			add_code_completion_option(CodeEdit.KIND_VARIABLE, name, name, Color("c9bda0"))
	update_code_completion_options(true)


func _arguments(item: Dictionary) -> String:
	var signature: String = str(item.sig)
	var open: int = signature.find("(")
	return signature.substr(open + 1, signature.length() - open - 2) if open >= 0 else ""


func _inside_string(line: String) -> bool:
	return (line.count("\"") % 2 == 1) or (line.count("'") % 2 == 1)


func _highlighter() -> CodeHighlighter:
	var syntax := CodeHighlighter.new()
	syntax.number_color = NUMBER_COLOR
	syntax.symbol_color = Color("c0b090")
	syntax.function_color = FUNCTION_COLOR
	syntax.member_variable_color = MEMBER_COLOR
	for name: String in ApiReference.KEYWORDS:
		syntax.add_keyword_color(name, CONSTANT_COLOR if name in ["True", "False", "None"] else KEYWORD_COLOR)
	for name: String in ApiReference.BUILTINS:
		syntax.add_keyword_color(name, BUILTIN_COLOR)
	syntax.add_color_region("#", "", COMMENT_COLOR, true)
	syntax.add_color_region("\"", "\"", STRING_COLOR)
	syntax.add_color_region("'", "'", STRING_COLOR)
	return syntax


func _theme_editor() -> void:
	add_theme_font_override("font", UITheme.mono_font())
	add_theme_font_size_override("font_size", 15)
	add_theme_color_override("font_color", Color("ebe0c4"))
	add_theme_color_override("font_readonly_color", Color("ebe0c4"))
	add_theme_color_override("line_number_color", Color("6f624d"))
	add_theme_color_override("caret_color", Pal.BRASS_HI)
	add_theme_color_override("current_line_color", Color(1, 0.9, 0.7, 0.055))
	add_theme_color_override("selection_color", Color(0.84, 0.65, 0.29, 0.32))
	add_theme_color_override("brace_mismatch_color", Pal.RED)
	add_theme_color_override("word_highlighted_color", Color(1, 0.9, 0.7, 0.08))
	add_theme_color_override("completion_background_color", Color("17120d"))
	add_theme_color_override("completion_selected_color", Color(0.84, 0.65, 0.29, 0.28))
	add_theme_color_override("completion_existing_color", Color(1, 1, 1, 0.06))
	add_theme_color_override("completion_scroll_color", Pal.BRASS_LO)
	add_theme_color_override("completion_scroll_hovered_color", Pal.BRASS)
	add_theme_constant_override("completion_lines", 7)
	add_theme_constant_override("completion_max_width", 26)
	add_theme_constant_override("line_spacing", 1)
	add_theme_stylebox_override("normal", UITheme.panel("inset"))
	var focused: FantasyBox = UITheme.panel("inset")
	focused.border = Pal.BRASS_LO
	focused.border_width = 1.5
	add_theme_stylebox_override("focus", focused)
	add_theme_stylebox_override("read_only", UITheme.panel("inset"))
	add_theme_icon_override("breakpoint", _error_icon())
	add_theme_color_override("breakpoint_color", Color("e0584a"))


func _error_icon() -> ImageTexture:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y: int in range(16):
		for x: int in range(16):
			var distance: float = Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(Vector2(8, 8))
			if distance <= 6.0:
				image.set_pixel(x, y, Color("e0584a") if distance > 4.4 else Color("f4b0a4"))
			elif distance <= 7.0:
				image.set_pixel(x, y, Color(0.88, 0.35, 0.29, 7.0 - distance))
	return ImageTexture.create_from_image(image)
