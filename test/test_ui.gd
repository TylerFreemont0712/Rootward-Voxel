extends SceneTree
## The learner-facing helpers: lesson markup, error explanations, the API reference and the code editor.

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_display_preferences()
	_lesson_text()
	_error_advice()
	_api_reference()
	await _code_editor()
	await _widgets()
	await _gear_veil()
	if _failures.is_empty():
		print("Learning interface helpers: %d checks passed." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		quit(1)


func _display_preferences() -> void:
	_check(GameSettings.DEFAULTS.fullscreen and GameSettings.DEFAULTS.font_size==15,"The desktop profile starts full screen with compact code text")
	var preferences:=GameSettings.new()
	var screen:=SettingsPanel.new()
	screen.setup(preferences)
	var scales: Array[Node]=screen.find_children("*","HSlider",true,false)
	_check(scales.any(func(node: Node) -> bool:return is_equal_approx((node as HSlider).min_value,.6)),"Interface scale can go below the former 80% limit")
	_check(scales.any(func(node: Node) -> bool:return is_equal_approx((node as HSlider).min_value,10)),"Code text can use a compact ten-pixel minimum independently of the interface")
	screen.free()

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
	await _tablet()


## The field slate's glass: VS Code colours, names coloured as variables, file tabs, a status line and the blue ghost.
func _tablet() -> void:
	_lookups()
	var program: String = 'def program(world):\n    lamps = world.zone("workshop").lamps\n    for lamp in lamps:\n        lamp.set_lit(True)\n'
	var names: Array[String] = CodePalette.names_in(program)
	_check(names.has("world") and names.has("lamps") and names.has("lamp") and not names.has("print") and not names.has("for"), "Names a program makes up are found, keywords and builtins are not: %s" % str(names))
	_check(CodePalette.names_in('print("a = b")\nx = 1\nx += 2\nif x == 3:\n    pass').has("x") and CodePalette.names_in('if x == 3:\n    pass').is_empty(), "An assignment names a variable, a comparison does not")
	var code := CodeEdit.new()
	code.text = program
	CodePalette.style(code)
	var syntax := code.syntax_highlighter as CodeHighlighter
	_check(syntax.keyword_colors.get("for") == CodePalette.CONTROL and syntax.keyword_colors.get("def") == CodePalette.KEYWORD and syntax.keyword_colors.get("lamp") == CodePalette.VARIABLE, "The editor uses Dark+ colours for control flow, definitions and variables")
	code.free()
	var picked: Array[int] = []
	var tablet := TabletScreen.new(TabletScreen.Look.SLATE)
	root.add_child(tablet)
	tablet.set_tabs(["message.blocks", "hello_hotaru.py"], 0, func(index: int) -> void: picked.append(index))
	await process_frame
	_check(tablet._tabs.get_child_count() == 2 and (tablet._tabs.get_child(0) as FButton).button_pressed and not (tablet._tabs.get_child(1) as FButton).button_pressed, "The slate shows its file tabs with the first chosen")
	(tablet._tabs.get_child(1) as FButton).pressed.emit()
	_check(picked == [1] and (tablet._tabs.get_child(1) as FButton).button_pressed and not (tablet._tabs.get_child(0) as FButton).button_pressed, "Choosing a tab reports it and moves the highlight")
	tablet.set_output("Hello, Hotaru!")
	tablet.set_state(&"ghost")
	_check(tablet.output.text == "Hello, Hotaru!" and tablet._status_right.text == "Test ready", "The output strip and status bar show a Test")
	var painted: Dictionary = TabletScreen.painted_frame()
	_check(not painted.is_empty() and tablet.framed() and tablet._title_bar != null and tablet._title_bar.get_parent() == tablet._glass, "The slate is drawn from the selected painted frame, its link words in a title bar on the glass")
	tablet.size = Vector2(760, 1000)
	await process_frame
	await process_frame
	var window := Rect2(float(painted.window[0]), float(painted.window[1]), tablet.size.x - float(painted.size[0]) + float(painted.window[2]), tablet.size.y - TabletScreen.SHADOW - float(painted.size[1]) + float(painted.window[3]))
	var glass := Rect2(tablet._column.position + tablet._glass.position, tablet._glass.size)
	_check(window.grow(0.5).encloses(glass), "The glass sits inside the painted window however far the frame stretches")
	var jack := Vector2(float(painted.jack[0]), float(painted.jack[1]))
	var lamp := Vector2(float(painted.lamp[0]), float(painted.lamp[1]))
	_check(jack.x + float(painted.jack[2]) <= float(painted.slice[0]) and lamp.x + float(painted.lamp[2]) <= float(painted.slice[0]) and lamp.y + float(painted.lamp[2]) <= float(painted.slice[1]), "The painted jack and lamp sit in the frame's fixed corner, so stretching never moves them")
	tablet.size = Vector2(540, 400)
	tablet.skin = TabletScreen.Look.TERMINAL
	await process_frame
	_check(tablet.get_theme_stylebox("panel").get_margin(SIDE_BOTTOM) > TabletScreen.SHADOW + 14.0, "The desk terminal leaves room below the glass for its keys")
	tablet.queue_free()
	await process_frame
	var ghost := GhostBox.make()
	var ring: PackedVector2Array = ghost._resample(ghost._rounded(Rect2(0, 0, 100, 40), 8.0), 2.0)
	_check(ring.size() > 40 and ghost.get_margin(SIDE_LEFT) > 0.0, "The ghost frame samples its outline into dashes and keeps room for its words")


## What the editor says a name is: the expression under the pointer, where a name is set, its type, its value and
## the items of a list, from the program text and a picture of the link alone.
func _lookups() -> void:
	var program: String = '# round.py\ndef program(world):\n    workshop = world.zone("workshop")\n    lamps = workshop.lamps    # three\n    for lamp in lamps:\n        lamp.set_lit(True)\n    lamps[0].set_lit(False)\n'
	var link: Dictionary = {"zones": {"workshop": ["landing-lamp", "repair-light", "assembly-light"]}, "lamps": {"landing-lamp": {"title": "Stair lantern", "lit": true}, "repair-light": {"title": "Repair light", "lit": false}, "assembly-light": {"title": "Assembly light", "lit": false}}, "values": {}}
	var line: String = '    lamps = workshop.lamps    # three'
	_check(CodeLookup.expression_at(line, line.find("lamps", 10) + 2) == "workshop.lamps" and CodeLookup.expression_at(line, 5) == "lamps" and CodeLookup.expression_at(line, line.find("three")) == "", "The pointer finds the dotted name under it, and nothing inside a comment")
	_check(CodeLookup.expression_at('    world.zone("workshop").lamps', 30) == 'world.zone("workshop").lamps' and CodeLookup.expression_at('    lamps[0].set_lit(False)', 15) == "lamps[0].set_lit", "Chains through calls and indexes are followed back to their start")
	var where: Dictionary = CodeLookup.definition(program, "lamps")
	_check(int(where.get("line", -1)) == 3 and int(where.column) == 4 and str(where.value) == "workshop.lamps", "A variable's definition is the line that first sets it, without its comment")
	_check(int(CodeLookup.definition(program, "lamp").get("line", -1)) == 4 and CodeLookup.definition(program, "world").has("parameter"), "Loop names and parameters are definitions too")
	var lamps: Dictionary = CodeLookup.describe(program, "lamps", link)
	_check(lamps.kind == "variable" and lamps.type == "list[Lamp]" and (lamps.items as Array).size() == 3 and str(lamps.items[0]).contains("landing-lamp") and int(lamps.line) == 3, "A list variable says its type, where it is set and its items from the link")
	var member: Dictionary = CodeLookup.describe(program, "workshop.lamps", link)
	_check(member.kind == "attribute" and str(member.title).begins_with("zone.lamps") and str(member.doc) != "" and (member.items as Array).size() == 3, "An API member shows its signature, its explanation and what it holds here")
	_check(CodeLookup.describe(program, "lamps[0].set_lit", link).kind == "method" and CodeLookup.describe(program, "for", link).kind == "keyword" and CodeLookup.describe(program, "nowhere", link).is_empty(), "Methods through an index, keywords, and unknown names")
	_check(CodeLookup.describe(program, "lamp", link).type == "Lamp" and CodeLookup.resolve(program, "lamps[0]", link).value == "Lamp('landing-lamp', lit=True)", "A loop name is one item; an index picks the item")
	link.values = {"lamps": "[Lamp('a'), Lamp('b')]"}
	_check((CodeLookup.describe(program, "lamps", link).items as Array).size() == 2, "Values a debug run saw win over what the link suggests")
	_check(CodeLookup.list_items("[Lamp('a, b'), (1, 2), 'x']") == ["Lamp('a, b')", "(1, 2)", "'x'"] and CodeLookup.list_items("World").is_empty(), "List items are split at the top level only")


func _gear_veil() -> void:
	var veil := GearVeil.new()
	root.add_child(veil)
	veil.size = Vector2(1600, 900)
	await process_frame
	_check(not veil.covering() and veil.mouse_filter == Control.MOUSE_FILTER_IGNORE, "The clockwork veil starts out of the way")
	var told: Array[float] = []
	await veil.close(Vector2(0.4, 0.6), 0.05, func(fraction: float) -> void: told.append(fraction))
	_check(veil.covering() and veil.mouse_filter == Control.MOUSE_FILTER_STOP, "Closed, the veil covers the screen and stops the mouse")
	_check(is_equal_approx(float((veil.material as ShaderMaterial).get_shader_parameter("front")), 1.0), "The veil is opaque at the end of its closing sweep")
	_check(not told.is_empty() and is_equal_approx(told[-1], 1.0), "A walk carried on under the veil is told when the sweep ends")
	_check((veil.material as ShaderMaterial).get_shader_parameter("origin") == Vector2(0.4, 0.6), "The veil grows out of the point it was given")
	# While a scene is being built the veil draws itself between pieces, with its gears turned to the clock.
	BuildPump.tick = veil.keep_turning
	await create_timer(0.06).timeout
	BuildPump.pump()
	_check(veil.pumped >= 1, "A builder's pump makes the veil redraw while the main thread is busy")
	var spin_before: Variant = (veil.material as ShaderMaterial).get_shader_parameter("spin")
	await create_timer(0.06).timeout
	BuildPump.pump()
	_check(float((veil.material as ShaderMaterial).get_shader_parameter("spin")) > float(spin_before), "The gears keep turning from one pump to the next")
	BuildPump.tick = Callable()
	await veil.open(Vector2(0.3, 0.7), 0.05)
	_check(not veil.covering() and veil.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Opened, the veil leaves the screen and the mouse alone")
	_check(veil.material.shader.code.contains("meshed("), "The gears of the veil mesh with one another instead of turning on their own")
	veil.queue_free()


func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
