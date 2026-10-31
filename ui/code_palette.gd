class_name CodePalette
extends RefCounted
## The code surface of the Sparks & Machines journey: VS Code's Dark+ colours on the field slate's glass, so what the
## player types looks like what programmers see every day. Colours live here, never inline. `style()` dresses a
## CodeEdit; `screen_theme()` is the dark theme for everything else that sits on the glass (inputs, small buttons,
## labels). Only that journey uses it; CodeEditor keeps its own palette for the others.

const BG: Color = Color("1e1e1e")
const BG_RAISED: Color = Color("252526")
const BG_INPUT: Color = Color("333337")
const TAB_IDLE: Color = Color("2d2d2d")
const TAB_HOVER: Color = Color("37373d")
const RULE: Color = Color("3c3c3c")
const TEXT: Color = Color("d4d4d4")
const DIM: Color = Color("858585")
const CURRENT_LINE: Color = Color("2a2d2e")
const SELECTION: Color = Color("264f78")
const KEYWORD: Color = Color("569cd6")
const CONTROL: Color = Color("c586c0")
const FUNCTION: Color = Color("dcdcaa")
const VARIABLE: Color = Color("9cdcfe")
const STRING: Color = Color("ce9178")
const NUMBER: Color = Color("b5cea8")
const COMMENT: Color = Color("6a9955")
const OK: Color = Color("89d185")
const LIT: Color = Color("4fd06a")
const TODO: Color = Color(1.0, 0.78, 0.25)
const ERROR: Color = Color("f48771")
const ACCENT: Color = Color("7fc8c3")
const EXEC_LINE: Color = Color(1.0, 1.0, 0.0, 0.16)
const EXEC_ARROW: Color = Color("ffcc00")
const STATUS_BAR: Color = Color("1f5f63")
const DEBUG_BAR: Color = Color("cc6633")
const DONE_BAR: Color = Color("2e7d4f")
const CONTROL_WORDS: Array[String] = ["if", "elif", "else", "for", "while", "return", "break", "continue", "pass", "import", "from", "try", "except", "with", "raise"]

static var _theme: Theme
static var _arrow: ImageTexture


## Dresses a CodeEdit as the screen's editor: Dark+ colours, flat glass, an executing-line arrow and names the
## program makes up (`lamp`, `lamps`, `world`) coloured as variables.
static func style(code: CodeEdit) -> void:
	code.add_theme_color_override("font_color", TEXT)
	code.add_theme_color_override("font_readonly_color", TEXT)
	code.add_theme_color_override("caret_color", Color("aeafad"))
	code.add_theme_color_override("line_number_color", DIM)
	code.add_theme_color_override("current_line_color", CURRENT_LINE)
	code.add_theme_color_override("selection_color", SELECTION)
	code.add_theme_color_override("word_highlighted_color", Color(1, 1, 1, 0.07))
	code.add_theme_color_override("brace_mismatch_color", ERROR)
	code.add_theme_color_override("completion_background_color", BG_RAISED)
	code.add_theme_color_override("completion_selected_color", SELECTION)
	code.add_theme_color_override("completion_existing_color", Color(1, 1, 1, 0.08))
	code.add_theme_color_override("completion_scroll_color", RULE)
	code.add_theme_color_override("completion_scroll_hovered_color", DIM)
	code.add_theme_color_override("executing_line_color", EXEC_ARROW)
	code.add_theme_icon_override("executing_line", _arrow_icon())
	code.add_theme_constant_override("line_spacing", 5)
	code.add_theme_font_override("font", UITheme.mono_font())
	for state: String in ["normal", "focus", "read_only"]:
		code.add_theme_stylebox_override(state, glass())
	code.gutters_draw_executing_lines = true
	code.syntax_highlighter = _highlighter([])
	if not code.has_meta("code_palette"):
		code.set_meta("code_palette", true)
		code.text_changed.connect(refresh_names.bind(code))
		code.draw.connect(_draw_todos.bind(code))
	refresh_names(code)


## A short read-only example, with the same colours as the editor and no gutter.
static func snippet(text: String, font_size: int = 16) -> CodeEdit:
	var code := CodeEdit.new()
	code.text = text
	code.editable = false
	code.selecting_enabled = false
	code.context_menu_enabled = false
	code.shortcut_keys_enabled = false
	code.focus_mode = Control.FOCUS_NONE
	code.mouse_filter = Control.MOUSE_FILTER_IGNORE
	code.scroll_fit_content_height = true
	code.highlight_current_line = false
	code.gutters_draw_line_numbers = false
	code.add_theme_font_size_override("font_size", font_size)
	style(code)
	return code


## Colours the names a program assigns, loops over or takes as parameters, as VS Code does for variables.
static func refresh_names(code: CodeEdit) -> void:
	var found: Array[String] = names_in(code.text)
	var key: String = ",".join(found)
	if code.has_meta("code_names") and str(code.get_meta("code_names")) == key:
		return
	code.set_meta("code_names", key)
	code.syntax_highlighter = _highlighter(found)


## Where the program says what still needs doing: a `# TODO` comment marks itself and the lines under it, up to the
## next blank line, as the area to fix. Lines are numbered from 0.
static func todo_lines(source: String) -> Array[int]:
	var marked: Array[int] = []
	var lines: PackedStringArray = source.split("\n")
	var open: bool = false
	for index: int in range(lines.size()):
		var line: String = lines[index].strip_edges()
		if line.begins_with("#") and line.contains("TODO"):
			open = true
		elif line == "":
			open = false
		if open: marked.append(index)
	return marked


## A soft amber band behind the area to fix, with a bar in the gutter, as editors mark a TODO.
static func _draw_todos(code: CodeEdit) -> void:
	for line: int in todo_lines(code.text):
		if line >= code.get_line_count(): continue
		var at: Rect2i = code.get_rect_at_line_column(line, 0)
		if at.position.y < 0: continue
		var band := Rect2(float(at.position.x) - 4.0, float(at.position.y), code.size.x - float(at.position.x) - 8.0, float(at.size.y))
		code.draw_rect(band, Color(TODO, 0.08))
		code.draw_rect(Rect2(band.position.x - 4.0, band.position.y, 3.0, band.size.y), Color(TODO, 0.85))


static func names_in(source: String) -> Array[String]:
	var names: Array[String] = []
	var patterns: Array[String] = [
		"(?m)^[ \\t]*([A-Za-z_][A-Za-z0-9_]*)[ \\t]*(?:[-+*/]|//)?=(?!=)",
		"\\bfor[ \\t]+([A-Za-z_][A-Za-z0-9_]*)[ \\t]+in\\b",
	]
	for pattern: String in patterns:
		var rx := RegEx.new()
		rx.compile(pattern)
		for hit: RegExMatch in rx.search_all(source):
			_remember(names, hit.get_string(1))
	var def_rx := RegEx.new()
	def_rx.compile("\\bdef[ \\t]+[A-Za-z_][A-Za-z0-9_]*\\(([^)]*)\\)")
	var word_rx := RegEx.new()
	word_rx.compile("^[A-Za-z_][A-Za-z0-9_]*")
	for hit: RegExMatch in def_rx.search_all(source):
		for parameter: String in hit.get_string(1).split(","):
			var word: RegExMatch = word_rx.search(parameter.strip_edges())
			if word != null:
				_remember(names, word.get_string())
	return names


static func _remember(names: Array[String], word: String) -> void:
	if not names.has(word) and not ApiReference.KEYWORDS.has(word) and not ApiReference.BUILTINS.has(word):
		names.append(word)


static func _highlighter(names: Array[String]) -> CodeHighlighter:
	var syntax := CodeHighlighter.new()
	syntax.number_color = NUMBER
	syntax.symbol_color = TEXT
	syntax.function_color = FUNCTION
	syntax.member_variable_color = VARIABLE
	for word: String in names:
		syntax.add_keyword_color(word, VARIABLE)
	for word: String in ApiReference.KEYWORDS:
		syntax.add_keyword_color(word, CONTROL if CONTROL_WORDS.has(word) else KEYWORD)
	for word: String in ApiReference.BUILTINS:
		syntax.add_keyword_color(word, FUNCTION)
	syntax.add_color_region("#", "", COMMENT, true)
	syntax.add_color_region("\"", "\"", STRING)
	syntax.add_color_region("'", "'", STRING)
	return syntax


## Flat glass behind code and inputs: no rim, a little room at the edges.
static func glass(color: Color = BG) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_content_margin_all(0.0)
	box.content_margin_left = 8.0
	box.content_margin_right = 8.0
	box.content_margin_top = 6.0
	box.content_margin_bottom = 6.0
	return box


static func _arrow_icon() -> ImageTexture:
	if _arrow == null:
		var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for y: int in range(16):
			for x: int in range(16):
				# A right-pointing triangle, soft at the edge.
				var half: float = 6.0 - absf(float(y) - 7.5) * 0.9
				var inside: float = half - float(x) + 3.0
				if x >= 3 and x <= 13 and inside > 0.0:
					image.set_pixel(x, y, Color(EXEC_ARROW, clampf(inside, 0.0, 1.0)))
		_arrow = ImageTexture.create_from_image(image)
	return _arrow


## The dark theme for everything that sits on the glass: it overrides only what the paper theme draws in ink.
static func screen_theme() -> Theme:
	if _theme == null:
		_theme = _build_theme()
	return _theme


static func _build_theme() -> Theme:
	var t := Theme.new()
	t.set_color("font_color", "Label", TEXT)
	t.set_type_variation("LabelDim", "Label")
	t.set_color("font_color", "LabelDim", DIM)
	t.set_type_variation("LabelCaps", "Label")
	t.set_font("font", "LabelCaps", PaperTheme.display_font(2))
	t.set_color("font_color", "LabelCaps", ACCENT)
	t.set_font_size("font_size", "LabelCaps", 12)
	var field: StyleBoxFlat = glass(BG_INPUT)
	field.set_corner_radius_all(3)
	field.set_border_width_all(1)
	field.border_color = RULE
	var focused: StyleBoxFlat = field.duplicate() as StyleBoxFlat
	focused.border_color = PaperPal.TEAL_HI
	t.set_stylebox("normal", "LineEdit", field)
	t.set_stylebox("focus", "LineEdit", focused)
	t.set_stylebox("read_only", "LineEdit", field)
	t.set_color("font_color", "LineEdit", STRING)
	t.set_color("font_placeholder_color", "LineEdit", DIM)
	t.set_color("caret_color", "LineEdit", Color("aeafad"))
	t.set_color("selection_color", "LineEdit", SELECTION)
	t.set_font("font", "LineEdit", UITheme.mono_font())
	t.set_font_size("font_size", "LineEdit", 18)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font("normal_font", "RichTextLabel", UITheme.mono_font())
	t.set_font_size("normal_font_size", "RichTextLabel", 15)
	for variation: String in ["Quiet", "Tab", "Icon"]:
		var type_name: String = "Button" + variation
		t.set_type_variation(type_name, "Button")
		t.set_font("font", type_name, UITheme.mono_font())
		t.set_font_size("font_size", type_name, 13)
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
			t.set_stylebox(state, type_name, _button_box(variation, state))
		t.set_color("font_color", type_name, DIM if variation == "Tab" else TEXT)
		t.set_color("font_hover_color", type_name, TEXT)
		t.set_color("font_pressed_color", type_name, TEXT)
		t.set_color("font_focus_color", type_name, TEXT)
		t.set_color("font_disabled_color", type_name, Color(DIM, 0.5))
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color(1, 1, 1, 0.04)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(1, 1, 1, 0.16)
	grabber.set_corner_radius_all(3)
	var grabber_hot := grabber.duplicate() as StyleBoxFlat
	grabber_hot.bg_color = Color(1, 1, 1, 0.3)
	for bar: String in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", bar, groove)
		t.set_stylebox("grabber", bar, grabber)
		t.set_stylebox("grabber_highlight", bar, grabber_hot)
		t.set_stylebox("grabber_pressed", bar, grabber_hot)
	return t


static func _button_box(variation: String, state: StringName) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(3)
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	if variation == "Tab":
		box.set_corner_radius_all(0)
		box.bg_color = TAB_IDLE
		box.border_width_top = 2
		box.border_color = Color(0, 0, 0, 0)
		if state == &"hover":
			box.bg_color = TAB_HOVER
		elif state == &"pressed":
			box.bg_color = BG
			box.border_color = PaperPal.TEAL_HI
		return box
	box.bg_color = Color(0, 0, 0, 0)
	if state == &"hover":
		box.bg_color = Color(1, 1, 1, 0.08)
	elif state == &"pressed":
		box.bg_color = Color(1, 1, 1, 0.14)
	elif state == &"focus":
		box.set_border_width_all(1)
		box.border_color = PaperPal.TEAL_HI
	if variation == "Icon":
		box.content_margin_left = 6.0
		box.content_margin_right = 6.0
	return box
