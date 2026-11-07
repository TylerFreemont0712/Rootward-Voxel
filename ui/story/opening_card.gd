class_name OpeningCard
extends Modal
## A journey's opening in paper and enamel: a few prose pages, then a handwritten note. Its last button
## (or Escape) finishes the opening; the game decides what follows. Text comes from the journey's story file.

signal finished

var _opening: Dictionary = {}
var _page: int = 0
var _pages: Array = []
var _text: Label
var _note: PanelContainer
var _dots: Label
var _next: FButton
var _done: bool = false
var _prose_only: bool = false


func _init() -> void:
	super()
	theme = PaperTheme.theme()
	_scrim.color = Color(0.06, 0.07, 0.12, 0.55)


func setup(opening: Dictionary, prose_only: bool = false) -> void:
	_opening = opening
	_prose_only = prose_only
	_pages = opening.get("pages", []) as Array
	card.custom_minimum_size = Vector2(640, 0)
	body.add_theme_constant_override("separation", 18)
	body.add_child(UI.caps("First morning"))
	_text = UI.label("", &"", 23)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(580, 120)
	_text.add_theme_constant_override("line_spacing", 4)
	body.add_child(_text)
	_note = _make_note(opening.get("note", {}) as Dictionary)
	_note.visible = false
	body.add_child(_note)
	var row := UI.hbox(12)
	_dots = UI.label("", &"LabelDim", 16)
	_dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_dots)
	_next = UI.button("Continue", &"chevron", &"ButtonPrimary", _advance)
	row.add_child(_next)
	body.add_child(row)
	_show()


static func _make_note(note: Dictionary) -> PanelContainer:
	var card_panel := UI.panel(&"PanelInset")
	card_panel.custom_minimum_size = Vector2(560, 0)
	var column := UI.vbox(10)
	card_panel.add_child(column)
	for line: Variant in [note.get("salutation", "")] + (note.get("lines", []) as Array):
		var label := UI.label(str(line), &"", 21)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_override("font", PaperTheme.slanted_font(500))
		column.add_child(label)
	var signature := UI.label(str(note.get("signature", "")), &"", 22)
	signature.add_theme_font_override("font", PaperTheme.slanted_font(700))
	signature.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(signature)
	if str(note.get("postscript", "")) != "":
		var postscript := UI.label(str(note.postscript), &"LabelDim", 19)
		postscript.add_theme_font_override("font", PaperTheme.slanted_font(500))
		column.add_child(postscript)
	return card_panel


func _show() -> void:
	var on_note: bool = _page >= _pages.size()
	_text.visible = not on_note
	_note.visible = on_note
	if not on_note:
		_text.text = str(_pages[_page])
	var marks: PackedStringArray = []
	for i: int in range(_pages.size() + (0 if _prose_only else 1)):
		marks.append("●" if i == _page else "○")
	_dots.text = " ".join(marks)
	_next.text = "Look around" if _prose_only and _page == _pages.size()-1 else (str(_opening.get("button", "Begin")) if on_note else "Continue")


func _advance() -> void:
	if _page >= _pages.size() or (_prose_only and _page == _pages.size()-1):
		close()
		return
	_page += 1
	_show()


func close() -> void:
	if not _done:
		_done = true
		finished.emit()
	super.close()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		_advance()
		return
	super._unhandled_key_input(event)
