class_name CodeHoverCard
extends PanelContainer
## The card a code editor shows over a name: what kind of thing it is and its signature, a line of explanation, what
## it holds (a list's items one per line), and where it is set. Hovering shows it; Ctrl+click on an API name pins it.
## Fed by `CodeLookup.describe`; drawn in VS Code's hover colours.

const TYPE_COLOR: Color = Color("4ec9b0")

var pinned: bool = false
var _kind: Label
var _title: RichTextLabel
var _doc: Label
var _holds: Label
var _items: VBoxContainer
var _hint: Label
var _anchor := Vector2.ZERO


func _init() -> void:
	top_level = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = CodePalette.screen_theme()
	var box := StyleBoxFlat.new()
	box.bg_color = CodePalette.BG_RAISED
	box.border_color = Color("454545")
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.set_content_margin_all(10.0)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 6
	add_theme_stylebox_override("panel", box)
	custom_minimum_size.x = 300
	var body := UI.vbox(5)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	_kind = UI.label("", &"LabelDim", 11)
	body.add_child(_kind)
	_title = RichTextLabel.new()
	_title.bbcode_enabled = true
	_title.fit_content = true
	_title.scroll_active = false
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.custom_minimum_size.x = 280
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_theme_font_size_override("normal_font_size", 14)
	body.add_child(_title)
	_doc = UI.label("", &"", 14, Color("cccccc"))
	_doc.add_theme_font_override("font", UITheme.body_font(500))
	_doc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_doc.custom_minimum_size.x = 280
	body.add_child(_doc)
	_holds = UI.label("", &"LabelCaps", 10)
	body.add_child(_holds)
	_items = UI.vbox(1)
	_items.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_items)
	_hint = UI.label("", &"LabelDim", 11)
	body.add_child(_hint)
	hide()


## Shows what `description` says next to `at` (a global point), above it if there is no room below.
func present(description: Dictionary, at: Vector2, pin: bool = false) -> void:
	pinned = pin
	_anchor = at
	_kind.text = str(description.get("kind", "")).to_upper()
	var title: String = str(description.get("title", ""))
	var type: String = str(description.get("type", ""))
	var shown: String = _escape(title)
	if type != "" and title.ends_with(type):
		shown = _escape(title.substr(0, title.length() - type.length())) + "[color=#%s]%s[/color]" % [TYPE_COLOR.to_html(false), _escape(type)]
	_title.text = "[color=#%s]%s[/color]" % [CodePalette.FUNCTION.to_html(false) if str(description.get("kind", "")) == "method" else CodePalette.VARIABLE.to_html(false), shown] if description.get("kind", "") != "keyword" else "[color=#%s]%s[/color]" % [CodePalette.CONTROL.to_html(false), shown]
	_doc.text = str(description.get("doc", ""))
	for child: Node in _items.get_children():
		_items.remove_child(child)
		child.queue_free()
	var items: Array = description.get("items", [])
	var value: String = str(description.get("value", ""))
	_holds.visible = not items.is_empty() or value != ""
	_holds.text = ("HOLDS %d ITEMS" % items.size()) if not items.is_empty() else "HOLDS"
	if not items.is_empty():
		for index: int in range(items.size()):
			_items.add_child(_line("[%d]  " % index, str(items[index])))
	elif value != "":
		_items.add_child(_line("", value))
	var line: int = int(description.get("line", -1))
	var kind: String = str(description.get("kind", ""))
	if kind == "variable" and line >= 0: _hint.text = "Ctrl+click: go to line %d" % (line + 1)
	elif kind in ["variable", "attribute"] and value == "": _hint.text = "Debug to see what it holds."
	else: _hint.text = ""
	_hint.visible = _hint.text != ""
	show()
	reset_size()
	_place.call_deferred()


func dismiss() -> void:
	pinned = false
	hide()


## True while the pointer is still near where the card was opened.
func near(point: Vector2) -> bool:
	return point.distance_to(_anchor) < 46.0 or get_global_rect().grow(8).has_point(point)


func _place() -> void:
	var screen: Vector2 = get_viewport_rect().size
	reset_size()
	var spot: Vector2 = _anchor + Vector2(12, 20)
	if spot.y + size.y > screen.y - 8.0: spot.y = _anchor.y - size.y - 12.0
	spot.x = clampf(spot.x, 8.0, screen.x - size.x - 8.0)
	global_position = spot


func _line(prefix: String, text: String) -> Control:
	var row := RichTextLabel.new()
	row.bbcode_enabled = true
	row.fit_content = true
	row.scroll_active = false
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.custom_minimum_size.x = 280
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_font_override("normal_font", UITheme.mono_font())
	row.add_theme_font_size_override("normal_font_size", 13)
	row.text = "[color=#%s]%s[/color]%s" % [CodePalette.DIM.to_html(false), _escape(prefix), _escape(text)]
	return row


static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")
