class_name ReferenceView
extends VBoxContainer
## The Reference tab: every object the game gives your program, plus short Python reminders.
## Searchable, and each entry can be dropped into the editor with one click.

signal insert_requested(snippet: String)

var _search: LineEdit
var _sections: Array[Dictionary] = []


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_search = LineEdit.new()
	_search.placeholder_text = "Search: lamp, loop, bridge…"
	_search.clear_button_enabled = true
	_search.text_changed.connect(_filter)
	add_child(_search)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var column := UI.vbox(14)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	for type_name: String in ["World", "Zone", "Lamp", "Gate", "Bridge", "Prop", "House", "Doodad", "Tree"]:
		var info: Dictionary = ApiReference.TYPES[type_name]
		var rows: Array[Control] = []
		var box := UI.vbox(8)
		column.add_child(box)
		box.add_child(UI.heading(type_name, 22))
		box.add_child(UI.dim(str(info.summary), 17))
		for member: Dictionary in info.members:
			var row: Control = _member_row(member)
			box.add_child(row)
			rows.append(row)
		_sections.append({"box": box, "rows": rows, "head": type_name, "ability": str(info.get("ability", ""))})
	var python := UI.vbox(8)
	column.add_child(python)
	python.add_child(UI.heading("Python reminders", 22))
	var notes: Array[Control] = []
	for note: Dictionary in ApiReference.PYTHON_NOTES:
		var row: Control = _note_row(note)
		python.add_child(row)
		notes.append(row)
	_sections.append({"box": python, "rows": notes, "head": "Python reminders"})


func _member_row(member: Dictionary) -> Control:
	var panel := UI.panel(&"PanelCard")
	var row := UI.hbox(8)
	panel.add_child(row)
	var column := UI.vbox(2)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	var signature := UI.label(str(member.sig), &"", 17, Pal.TEAL)
	signature.add_theme_font_override("font", UITheme.mono_font())
	column.add_child(signature)
	column.add_child(UI.dim(str(member.doc), 16))
	var insert := UI.icon_button(&"plus", "Add %s to your notebook" % member.sig, func() -> void: insert_requested.emit(str(member.sig)))
	insert.custom_minimum_size = Vector2(36, 36)
	insert.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(insert)
	panel.set_meta("search", ("%s %s %s" % [member.sig, member.doc, member.name]).to_lower())
	panel.set_meta("ability", str(member.get("ability", "")))
	return panel


func _note_row(note: Dictionary) -> Control:
	var panel := UI.panel(&"PanelCard")
	var column := UI.vbox(4)
	panel.add_child(column)
	column.add_child(UI.label(str(note.title), &"", 18, Pal.BRASS_HI))
	var signature := UI.label(str(note.sig), &"", 16, Pal.TEAL)
	signature.add_theme_font_override("font", UITheme.mono_font())
	column.add_child(signature)
	column.add_child(UI.dim(str(note.doc), 16))
	var example := UI.hbox(8)
	column.add_child(example)
	var code := Label.new()
	code.text = str(note.example)
	code.add_theme_font_override("font", UITheme.mono_font())
	code.add_theme_font_size_override("font_size", 16)
	code.add_theme_color_override("font_color", Color("e0cfa3"))
	code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	example.add_child(code)
	var insert := UI.icon_button(&"plus", "Add this example to your notebook", func() -> void: insert_requested.emit(str(note.example)))
	insert.custom_minimum_size = Vector2(36, 36)
	insert.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	example.add_child(insert)
	panel.set_meta("search", ("%s %s %s %s" % [note.title, note.sig, note.doc, note.example]).to_lower())
	return panel


## Dims what the player's code has not learned yet, and says which lesson teaches it. `abilities` is what is earned
## (see Quests.capabilities); `lessons` maps a locked ability to the title of the lesson that unlocks it.
func show_unlocks(abilities: Array, lessons: Dictionary) -> void:
	for section: Dictionary in _sections:
		var ability: String = str(section.get("ability", ""))
		_dim(section.box, ability, abilities, lessons)
		for row: Control in section.rows:
			_dim(row, str(row.get_meta("ability", "")), abilities, lessons)


func _dim(node: Control, ability: String, abilities: Array, lessons: Dictionary) -> void:
	var locked: bool = ability != "" and not abilities.has(ability)
	node.modulate = Color(1, 1, 1, 0.5) if locked else Color.WHITE
	if node is PanelContainer:
		var how: String = ("Reach the lesson \"%s\" to use this." % str(lessons[ability])) if lessons.has(ability) else "No lesson teaches this yet."
		node.tooltip_text = ("Not unlocked yet. " + how) if locked else ""


func _filter(query: String) -> void:
	var needle: String = query.strip_edges().to_lower()
	for section: Dictionary in _sections:
		var any: bool = false
		for row: Control in section.rows:
			var match: bool = needle == "" or str(row.get_meta("search")).contains(needle)
			row.visible = match
			any = any or match
		(section.box as Control).visible = any
