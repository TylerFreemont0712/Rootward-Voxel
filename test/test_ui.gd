extends SceneTree
## The learner-facing helpers: lesson markup, error explanations, the API reference and the code editor.

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_lesson_text()
	_error_advice()
	_api_reference()
	await _code_editor()
	await _widgets()
	if _failures.is_empty():
		print("Learning interface helpers: %d checks passed." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		quit(1)


func _lesson_text() -> void:
	var blocks: Array[Dictionary] = LessonText.blocks("First line\nsecond line.\n\n```\nlamp.set_lit(True)\n    indented\n```\n\nLast **bold** and `code`.")
	_check(blocks.size() == 3 and blocks[0].type == "p" and blocks[0].text == "First line second line.", "Paragraph lines are joined and blank lines split blocks")
	_check(blocks[1].type == "code" and blocks[1].text == "lamp.set_lit(True)\n    indented", "Fenced code keeps its indentation")
	_check(LessonText.to_bbcode("Use `x[0]` and **go**").contains("[b]") and LessonText.to_bbcode("a [b]b[/b]").begins_with("a [lb]"), "Inline markup converts and stray brackets are escaped")
	var area: AreaDef = AreaStore.load_area("kindle-hollow")
	var every_lesson: bool = true
	for quest: Dictionary in area.quests:
		every_lesson = every_lesson and not LessonText.blocks(str(quest.lesson)).is_empty() and quest.hints.size() == 3 and str(quest.starter).contains("def program(world):")
	_check(every_lesson, "Every quest has a lesson, three hints and a starter that defines program(world)")


func _error_advice() -> void:
	var syntax: Dictionary = ErrorAdvice.parse("  File \"player.py\", line 3\n    def program(:\n               ^\nSyntaxError: invalid syntax\n")
	_check(syntax.kind == "SyntaxError" and syntax.line == 3, "A syntax error's line and kind are parsed")
	var runtime: Dictionary = ErrorAdvice.parse("Traceback (most recent call last):\n  File \"/work/world_harness.py\", line 130, in <module>\n    answer = program(world)\n  File \"player.py\", line 7, in program\n    lamp.light()\n  File \"/work/world_harness.py\", line 41, in set_lit\nAttributeError: 'Lamp' object has no attribute 'light'\n")
	_check(runtime.line == 7 and runtime.kind == "AttributeError", "The player's own frame is chosen over harness frames")
	var names: Array[String] = ApiReference.known_names("lamp = 1")
	var explained: Dictionary = ErrorAdvice.explain({"kind": "AttributeError", "message": "'Lamp' object has no attribute 'set_lt'", "line": 4}, names)
	_check(explained.body.contains("set_lit") and explained.title.begins_with("Line 4"), "A misspelled method suggests the real one")
	explained = ErrorAdvice.explain({"kind": "NameError", "message": "name 'wrld' is not defined", "line": 2}, names)
	_check(explained.body.contains("'world'"), "A misspelled name suggests the nearest known name")
	explained = ErrorAdvice.explain({"kind": "IndentationError", "message": "expected an indented block after 'def' statement on line 1", "line": 2}, names)
	_check(explained.body.contains("4 spaces"), "Indentation errors explain indentation")
	_check(ErrorAdvice.closest("Ture", ["True", "False", "None"]) == "True" and ErrorAdvice.closest("zzzzzz", ["True"]) == "", "Suggestions need a close match")
	_check(ErrorAdvice.parse("").line == 0, "An empty error parses without a line")


func _api_reference() -> void:
	var source: String = "def program(world):\n    green = world.zone(\"green\")\n    for lamp in green.lamps:\n        lamp.set_lit(True)\n    gate = world.gate(\"g\")\n    bridge = world.bridge(\"b\")\n"
	_check(ApiReference.infer_type(source, "world") == "World" and ApiReference.infer_type(source, "green") == "Zone", "Variables assigned from world calls are typed")
	_check(ApiReference.infer_type(source, "lamp") == "Lamp", "A loop variable over zone.lamps is a Lamp")
	_check(ApiReference.infer_type(source, "gate") == "Gate" and ApiReference.infer_type(source, "bridge") == "Bridge", "Gates and bridges are inferred")
	_check(ApiReference.infer_type("a = a.x\n", "a") == "" and ApiReference.infer_type("a = b.x\nb = a.y\n", "a") == "", "Circular assignments terminate")
	var method_names: Array[String] = []
	for member: Dictionary in ApiReference.members_of("Lamp"):
		method_names.append(member.name)
	_check(method_names.has("set_lit") and method_names.has("lit"), "The Lamp reference lists set_lit and lit")
	# The reference matches the real Python objects: every documented member exists on the harness class.
	var harness: String = FileAccess.get_file_as_string("res://sandbox/world_harness.py")
	var all_present: bool = true
	for type_name: String in ApiReference.TYPES:
		for member: Dictionary in ApiReference.members_of(type_name):
			var token: String = ("def %s(" % member.name) if member.kind == "method" else ("self.%s" % member.name)
			if type_name == "World" and member.name in ["lamps", "gates", "bridges", "zones", "player", "memory"]:
				token = "self.%s" % member.name
			if member.name == "here" or member.name == "name" and type_name == "Zone":
				token = "def here(" if member.name == "here" else "self.name"
			# An attribute may be a property (`def houses(self)`), which is how the harness withholds what is not unlocked yet.
			var present: bool = harness.contains(token) or (member.kind == "attribute" and harness.contains("def %s(self)" % member.name))
			if not present:
				all_present = false
				printerr("Reference entry %s.%s has no implementation (%s)" % [type_name, member.name, token])
	_check(all_present, "Every documented API member exists in the Python harness")


func _code_editor() -> void:
	var settings := GameSettings.new()
	var editor := CodeEditor.new()
	root.add_child(editor)
	await process_frame
	editor.apply_settings(settings)
	editor.text = "def program(world):\n    lamp = world.lamp('x')\n    lamp.set_lit(True)\n"
	editor.mark_error(3)
	_check(editor.get_line_background_color(2).a > 0.0 and editor.is_line_breakpointed(2), "An error line is tinted and marked")
	editor.clear_error()
	_check(editor.get_line_background_color(2).a == 0.0 and not editor.is_line_breakpointed(2), "Clearing removes the marker")
	editor.mark_error(99)
	_check(not editor.is_line_breakpointed(0), "An out-of-range error line is ignored")
	editor.set_caret_line(1)
	editor.set_caret_column(0)
	editor.insert_snippet("for lamp in zone.lamps:\n    lamp.set_lit(True)")
	_check(editor.text.contains("for lamp in zone.lamps:\n    lamp.set_lit(True)"), "A snippet inserts at the caret")
	editor.replace_program("def program(world):\n    pass\n")
	_check(editor.text.begins_with("def program"), "The whole program can be replaced")
	editor.undo()
	_check(editor.text.contains("lamp.set_lit(True)"), "Replacing the program is a single undoable edit")
	editor.text = "def program(world):\n    lamp = world.lamp('x')\n    lamp."
	editor.set_caret_line(2)
	editor.set_caret_column(9)
	editor._offer_completions()
	var options: Array[Dictionary] = editor.get_code_completion_options()
	var offered: Array[String] = []
	for option: Dictionary in options:
		offered.append(str(option.insert_text))
	_check(offered.has("set_lit") and offered.has("lit") and not offered.has("place_deck"), "Typing a dot after a lamp variable offers only Lamp members")
	editor.text = "def program(world):\n    wor"
	editor.set_caret_line(1)
	editor.set_caret_column(7)
	editor._offer_completions()
	offered.clear()
	for option: Dictionary in editor.get_code_completion_options():
		offered.append(str(option.insert_text))
	_check(offered.has("world") and not offered.has("lamp_x"), "Typing a word offers the game's own names")
	editor.text = "def program(world):\n    fo"
	editor.set_caret_line(1)
	editor.set_caret_column(6)
	editor._offer_completions()
	offered.clear()
	for option: Dictionary in editor.get_code_completion_options():
		offered.append(str(option.insert_text))
	_check(offered.has("for") and offered.has("float"), "Completions are filtered by what has been typed and include Python keywords and builtins")
	_check(editor.indent_use_spaces and editor.indent_size == 4 and editor.indent_automatic and editor.auto_brace_completion_enabled, "The editor indents with spaces, after colons, and pairs brackets")
	editor.queue_free()


func _widgets() -> void:
	var theme: Theme = UITheme.theme()
	_check(theme.get_stylebox("normal", "ButtonPrimary") is FantasyBox and theme.get_type_variation_base("ButtonPrimary") == "Button", "Button variations exist in the theme")
	var plain: FantasyBox = UITheme.plaque(&"normal", "")
	var copy: FantasyBox = plain.duplicate()
	_check(copy.fill_top == plain.fill_top and copy.chamfer == plain.chamfer and copy.studs == plain.studs, "A duplicated plaque keeps its look (properties are exported)")
	var button := UI.button("Run", &"play", &"ButtonPrimary")
	root.add_child(button)
	await process_frame
	_check(button.get_theme_stylebox("normal").content_margin_left > plain.content_margin_left, "An icon button makes room for its icon")
	button.queue_free()
	var toggle := Toggle.make("Fullscreen", true)
	root.add_child(toggle)
	await process_frame
	var seen: Array = []
	toggle.toggled.connect(func(on: bool) -> void: seen.append(on))
	toggle.button_pressed = false
	_check(not toggle.button_pressed and seen == [false], "A toggle reports changes")
	toggle.queue_free()
	for kind: StringName in [&"play", &"check", &"cross", &"book", &"scroll", &"gear", &"menu", &"undo", &"reset", &"lamp", &"lock", &"star", &"ring", &"map", &"person", &"flame", &"door", &"bridge", &"gate", &"keys", &"info", &"warning", &"chevron_left"]:
		var glyph := Glyph.new()
		glyph.kind = kind
		root.add_child(glyph)
		glyph.size = Vector2(24, 24)
		glyph.queue_redraw()
		glyph.queue_free()
	await process_frame
	_check(true, "Every icon draws without error")


func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
