class_name FieldNotepad
extends Control
## Field Notes as a spiral-bound notepad: a wire coil through punched holes down its left edge over a cardboard
## spine, ruled lines and a red margin, a couple of sheets peeking out underneath, and sticky markers standing up from
## its top edge. It is a guide, not a requirement: "Put away" tucks it down so only its stickies show, and any sticky
## brings it back (`put_away_requested`, `page_selected`; the owner moves it). Nell's words, the
## names on the link, the hints and the index of lessons live here; code lives on the slate (`TabletScreen`).
## `add_page` gives each sticky a column to fill; `note` is a pencilled line under every page, and `footer` holds
## small links along the bottom.

signal page_selected(id: StringName)
signal put_away_requested

const BINDING: float = 20.0
const STICKY_OUT: float = 30.0
const MARGIN_X: float = 46.0
const LINE_GAP: float = 27.0
const RULE: Color = Color(0.45, 0.66, 0.8, 0.2)
const MARGIN_RED: Color = Color(0.85, 0.42, 0.36, 0.5)
const BOARD: Color = Color("7c5c3e")
const WIRE_DARK: Color = Color("4a4f54")
const WIRE: Color = Color("bfc5ca")
const WIRE_SHINE: Color = Color("f2f4f5")
const STEEL: Color = Color("3b4148")

var note: Label
var footer: HBoxContainer
## Draw a binder clip on the right edge, gripping whatever the pad is clipped to.
var clipped: bool = false
var put_away: Button
var _scroll: ScrollContainer
var _stack: VBoxContainer
var _pages: Dictionary = {}
var _tabs: Dictionary = {}
var _tints: Dictionary = {}
var _order: Array[StringName] = []
var _current: StringName = &""


func _init() -> void:
	theme = PaperTheme.theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_stack = UI.vbox(0)
	_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_stack)
	note = UI.label("", &"", 16, PaperPal.INK_SOFT)
	note.add_theme_font_override("font", PaperTheme.slanted_font(500))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.clip_text = true
	add_child(note)
	footer = UI.hbox(4)
	add_child(footer)
	put_away = UI.button("Put away", &"chevron_down", &"ButtonQuiet", func() -> void: put_away_requested.emit())
	put_away.tooltip_text = "Tuck the notes away; click a sticky to bring them back"
	add_child(put_away)
	resized.connect(_layout)


## A new sticky marker and the column its page is written in. `tint` is the sticky's paper.
func add_page(id: StringName, label: String, tint: Color) -> VBoxContainer:
	var page := UI.vbox(8)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.visible = false
	_stack.add_child(page)
	_pages[id] = page
	_tints[id] = tint
	_order.append(id)
	var tab := Button.new()
	tab.text = label
	tab.focus_mode = Control.FOCUS_NONE
	tab.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tab.add_theme_font_override("font", PaperTheme.display_font(1))
	tab.add_theme_font_size_override("font_size", 13)
	tab.pressed.connect(select.bind(id))
	add_child(tab)
	_tabs[id] = tab
	_restyle_tabs()
	_layout()
	return page


func page(id: StringName) -> VBoxContainer:
	return _pages.get(id) as VBoxContainer


func select(id: StringName) -> void:
	if not _pages.has(id): return
	_current = id
	for key: StringName in _order:
		(_pages[key] as Control).visible = key == id
	_scroll.scroll_vertical = 0
	_restyle_tabs()
	_layout()
	page_selected.emit(id)


func current() -> StringName:
	return _current


## Empties every page but keeps the stickies, for a new job page.
func clear_pages() -> void:
	for key: StringName in _order:
		for child: Node in (_pages[key] as Control).get_children():
			(_pages[key] as Control).remove_child(child)
			child.queue_free()


func _restyle_tabs() -> void:
	for key: StringName in _order:
		var chosen: bool = key == _current
		var tint: Color = _tints[key]
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var box := StyleBoxFlat.new()
			var paper: Color = tint if chosen else tint.lerp(PaperPal.PAPER_DIM, 0.35)
			box.bg_color = paper.lightened(0.08) if state == "hover" else paper
			box.border_color = tint.darkened(0.3)
			box.border_width_left = 1
			box.border_width_top = 1
			box.border_width_right = 1
			box.corner_radius_top_left = 3
			box.corner_radius_top_right = 3
			box.content_margin_top = 4.0
			box.content_margin_bottom = 8.0
			box.shadow_color = Color(PaperPal.SHADOW, 0.5)
			box.shadow_size = 2
			box.shadow_offset = Vector2(1, 1)
			(_tabs[key] as Button).add_theme_stylebox_override(state, box)
		for color: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			(_tabs[key] as Button).add_theme_color_override(color, PaperPal.INK if chosen else PaperPal.INK_SOFT)


func _page_rect() -> Rect2:
	return Rect2(Vector2(BINDING, STICKY_OUT), Vector2(size.x - BINDING - 4.0, size.y - STICKY_OUT - 10.0))


func _layout() -> void:
	var sheet: Rect2 = _page_rect()
	var left: float = sheet.position.x + MARGIN_X + 12.0
	var width: float = sheet.size.x - MARGIN_X - 12.0 - 22.0
	var footer_height: float = footer.get_combined_minimum_size().y
	footer.position = Vector2(left - 8.0, sheet.end.y - footer_height - 10.0)
	footer.size = Vector2(width + 8.0, footer_height)
	note.position = Vector2(left, footer.position.y - 58.0)
	note.size = Vector2(width, 54.0)
	put_away.reset_size()
	put_away.position = Vector2(sheet.end.x - put_away.size.x - 10.0, sheet.position.y + 6.0)
	_scroll.position = Vector2(left, sheet.position.y + 20.0)
	_scroll.size = Vector2(width, maxf(40.0, note.position.y - 8.0 - _scroll.position.y))
	# Stickies stand up from the top edge, stuck a little way down the page; the open one stands tallest.
	var span: float = minf(96.0, (sheet.size.x - MARGIN_X - 30.0) / maxf(1.0, float(_order.size())))
	for index: int in range(_order.size()):
		var tab: Button = _tabs[_order[index]]
		var chosen: bool = _order[index] == _current
		var height: float = STICKY_OUT + (10.0 if chosen else 4.0)
		tab.position = Vector2(sheet.position.x + MARGIN_X - 18.0 + float(index) * span, sheet.position.y - height + 10.0)
		tab.size = Vector2(span - 6.0, height)
	queue_redraw()


func _draw() -> void:
	var sheet: Rect2 = _page_rect()
	if sheet.size.x < 60.0: return
	# The cardboard spine shows down the left, behind the coil.
	_rounded(Rect2(sheet.position + Vector2(-BINDING + 4.0, 4.0), Vector2(BINDING + 10.0, sheet.size.y - 8.0)), 5.0, BOARD)
	# Shadow and the sheets underneath, slightly out of square.
	_rounded(Rect2(sheet.position + Vector2(4, 7), sheet.size), 4.0, PaperPal.SHADOW)
	_rounded(Rect2(sheet.position + Vector2(5, 5), sheet.size - Vector2(2, 0)), 3.0, PaperPal.EDGE)
	_rounded(Rect2(sheet.position + Vector2(3, 3), sheet.size - Vector2(1, 0)), 3.0, PaperPal.PAPER_DIM)
	_rounded(sheet, 3.0, PaperPal.PAPER_HI)
	draw_rect(sheet, PaperPal.EDGE, false, 1.0)
	var y: float = sheet.position.y + 44.0
	while y < sheet.end.y - 8.0:
		draw_line(Vector2(sheet.position.x + 26.0, y), Vector2(sheet.end.x - 4.0, y), RULE, 1.0)
		y += LINE_GAP
	draw_line(Vector2(sheet.position.x + MARGIN_X, sheet.position.y + 2.0), Vector2(sheet.position.x + MARGIN_X, sheet.end.y - 2.0), MARGIN_RED, 1.4)
	# The coil: each loop leaves its punched hole, wraps over the left edge and goes behind.
	var hole_y: float = sheet.position.y + 18.0
	while hole_y < sheet.end.y - 10.0:
		var hole := Vector2(sheet.position.x + 12.0, hole_y)
		draw_circle(hole, 4.4, Color(0.14, 0.11, 0.08, 0.9))
		draw_circle(hole + Vector2(0.8, 0.6), 3.0, Color(BOARD, 0.9))
		var loop := PackedVector2Array()
		for step: int in range(13):
			var angle: float = -float(step) / 12.0 * PI
			loop.append(Vector2(sheet.position.x + 0.5 + cos(angle) * 12.0, hole_y - 2.5 + sin(angle) * 4.2))
		draw_polyline(loop, WIRE_DARK, 4.2, true)
		draw_polyline(loop, WIRE, 2.4, true)
		var shine := PackedVector2Array()
		for point: Vector2 in loop.slice(3, 9): shine.append(point + Vector2(0, -0.6))
		draw_polyline(shine, WIRE_SHINE, 0.9, true)
		hole_y += 19.0
	if clipped:
		_draw_clip(Vector2(sheet.end.x - 6.0, sheet.position.y + 70.0))


## A binder clip gripping the pad's right edge, its wire handles folded back.
func _draw_clip(at: Vector2) -> void:
	var body := PackedVector2Array([at + Vector2(-14, -22), at + Vector2(14, -22), at + Vector2(18, 22), at + Vector2(-18, 22)])
	draw_colored_polygon(PackedVector2Array([body[0] + Vector2(2, 3), body[1] + Vector2(2, 3), body[2] + Vector2(2, 3), body[3] + Vector2(2, 3)]), PaperPal.SHADOW)
	draw_colored_polygon(body, STEEL)
	draw_line(body[0] + Vector2(2, 2), body[1] + Vector2(-2, 2), Color(1, 1, 1, 0.35), 1.5)
	for side: float in [-1.0, 1.0]:
		var handle := PackedVector2Array([at + Vector2(side * 10.0, -20.0), at + Vector2(side * 9.0, -40.0), at + Vector2(side * 3.0, -46.0)])
		draw_polyline(handle, WIRE_DARK, 3.4, true)
		draw_polyline(handle, WIRE, 1.8, true)
	draw_line(at + Vector2(-9, -46), at + Vector2(9, -46), WIRE, 2.0, true)


func _rounded(rect: Rect2, radius: float, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	draw_style_box(box, rect)
