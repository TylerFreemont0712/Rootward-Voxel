class_name BuildHud
extends Control
## Build mode's interface, in the same dark wood and brass as the rest of the game. A rail of round tools runs down
## the left (Move and Delete, then the two build menus, Objects and Land, then Undo, Redo and Done). A tray along the
## whole bottom of the screen holds the catalog for Objects or the ground paints for Land. A details panel slides
## out on the right for whatever is chosen (see BuildDetails). A line of key hints, a bubble at the pointer that says
## why a spot is refused, and quiet toasts complete it. It only shows state and sends signals; BuildMode decides.

signal tool_chosen(tool_index: int)
signal item_chosen(item_id: String)
signal category_changed
signal paint_chosen(material_id: String)
## A land-shaping tool from Terrain or Water: raise, lower, stairs, water or land (fill in).
signal shape_chosen(tool_id: String)
signal brush_chosen(sub_tiles: int)
signal eyedropper_pressed
signal undo_pressed
signal redo_pressed
signal done_pressed

## Tool indices are BuildMode.Tool's values (PLACE 0, MOVE 1, DELETE 2, PAINT 3); the rail lists them in this order.
const TOOLS: Array[Dictionary] = [
	{"tool": 1, "name": "Move", "icon": &"move", "key": "1", "tip": "Move: click something to choose it, drag it to move it (1)"},
	{"tool": 2, "name": "Delete", "icon": &"trash", "key": "2", "tip": "Delete: click something to take it away (2)"},
	{"tool": 0, "name": "Objects", "icon": &"cube", "key": "3", "tip": "Objects: houses, trees and doodads to place (3)"},
	{"tool": 3, "name": "Land", "icon": &"land", "key": "4", "tip": "Land: paint the ground, raise and lower it, build stairs, dig water (4)"},
]
const HINTS: Dictionary = {
	0: "Click to place  ·  R turn  ·  Right-click puts it away  ·  Tab hides the tray",
	1: "Click to choose  ·  drag to move  ·  R turns it  ·  Delete removes it",
	2: "Click a house, tree or doodad to remove it  ·  Ctrl+Z brings it back",
	3: "Drag to paint  ·  [ ] brush size  ·  Alt / I pick  ·  Right-click cancels",
}
## The Land hint for each kind of land tool (see set_land_mode).
const LAND_HINTS: Dictionary = {
	"paint": "Drag to paint  ·  [ ] brush size  ·  Alt / I pick  ·  Right-click cancels",
	"shape": "Drag over the land  ·  [ ] brush size  ·  Release to finish  ·  Right-click cancels",
	"stairs": "Click at the foot of a cliff  ·  R picks the way up  ·  Delete (2) takes stairs away",
}
const NAV_HINT: String = "   ·   WASD or middle-drag to pan  ·  wheel to zoom"
## The Land menu's groups: the ground paints, then shaping the land (content/build/land-tools.json).
const LAND_GROUPS: Array[String] = ["Grass", "Dirt", "Stone", "Soil", "Floors", "Terrain", "Water"]
const SHAPE_GROUPS: Array[String] = ["Terrain", "Water"]
## Brush sizes, in sub-tiles for painting; the land tools use whole cells instead.
const BRUSH_LABELS: Dictionary = {"paint": {1: "1/2", 2: "1", 4: "2"}, "shape": {1: "1", 2: "2", 4: "3"}}
const CATEGORY_ICONS: Dictionary = {"houses": &"house", "trees": &"tree", "doodads": &"sparkle", "furniture": &"house", "workshop": &"hammer", "market": &"cube", "garden": &"tree", "village-magic": &"sparkle"}
const CARD_SIZE := Vector2(112, 134)
const TRAY_HEIGHT: float = 228.0
const MARGIN: float = 16.0

var _catalog: Dictionary = {}
var _items: Array[Dictionary] = []
var _describe: Callable
var _rail: PanelContainer
var _bubbles: Dictionary = {}
var _undo: BuildBubble
var _redo: BuildBubble
var _tray: PanelContainer
var _tray_mark: Glyph
var _tray_title: Label
var _tabs: HBoxContainer
var _category_scroll: ScrollContainer
var _header_spacer: Control
var _tab_buttons: Dictionary = {}
var search: LineEdit
var _land_header: HBoxContainer
var _land_tools: HBoxContainer
var _scroll: ScrollContainer
var _cards_row: HBoxContainer
var _paint_scroll: ScrollContainer
var _swatches: HBoxContainer
var _page_left: FButton
var _page_right: FButton
var _paint_tabs: Dictionary = {}
var _paint_cards: Dictionary = {}
var _paint_family: String = "Grass"
var _paint_material: String = "dirt"
var _brush_buttons: Dictionary = {}
var _brush_label: Label
var _pick_button: FButton
var _land_mode: String = "paint"
## The land-shaping tools with their sample land: AreaStore.read_land_tools().
var land_tools: Array[Dictionary] = []
var _picture_cache: Dictionary = {}
var _cards: Dictionary = {}
var details: BuildDetails
var _hint_label: Label
var _hint_pill: PanelContainer
var _hint_text: String = ""
var _bubble: PanelContainer
var _bubble_label: Label
var _bubble_icon: Glyph
var _toasts: VBoxContainer
var _allowance: PanelContainer
var _allowance_label: Label
var _frame: Control
var _category: String = ""
var _tool: int = 0
var _item: String = ""
var _tray_open: bool = true
var _tray_reveal: float = 0.0
var _tray_tween: Tween
var _details_open: bool = false
var _details_reveal: float = 0.0
var _details_tween: Tween
var _page_tween: Tween


## `describe` is Callable(entry) -> {chip: String, spec: String}: the size line on a card's tooltip.
func setup(catalog: Dictionary, entries: Array[Dictionary], describe: Callable) -> void:
	_catalog = catalog
	_items = entries
	_describe = describe
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	resized.connect(_layout)
	_layout.call_deferred()
	_category = str(entries[0].category) if not entries.is_empty() else ""
	_fill_cards()
	set_tool(0)


# --------------------------------------------------------------------- state
func set_tool(tool_index: int) -> void:
	_tool = tool_index
	for tool: int in _bubbles:
		(_bubbles[tool] as BuildBubble).selected = tool == tool_index
	_hint_text = LAND_HINTS[_land_mode] if tool_index == 3 else HINTS[tool_index]
	var objects: bool = tool_index == 0
	var land: bool = tool_index == 3
	_tray_mark.kind = &"land" if land else &"cube"
	_tray_title.text = "LAND" if land else "OBJECTS"
	_tabs.visible = objects
	_category_scroll.visible = objects
	_header_spacer.visible = land
	search.visible = objects
	_scroll.visible = objects
	_land_header.visible = land
	_land_tools.visible = land
	_paint_scroll.visible = land
	_show_tray(objects or land)
	if land:
		set_paint(_paint_material)
	else:
		set_item(_item)
	if tool_index != 0:
		hide_bubble()
	_layout()
	_update_pages.call_deferred()


## Marks the chosen card and brings its category forward. The details panel is BuildMode's to fill.
func set_item(item_id: String) -> void:
	_item = item_id
	for id: String in _cards:
		(_cards[id] as BuildCard).selected = id == item_id
	var entry: Dictionary = _entry(item_id)
	if not entry.is_empty() and str(entry.category) != _category:
		_choose_category(str(entry.category))


func set_history(can_undo: bool, can_redo: bool) -> void:
	_undo.disabled = not can_undo
	_redo.disabled = not can_redo


func set_allowance(text: String) -> void:
	_allowance.visible = text != ""
	_allowance_label.text = text


## Puts a card's picture in once it has been drawn.
func set_picture(item_id: String, texture: Texture2D) -> void:
	_picture_cache[item_id] = texture
	if _cards.has(item_id):
		(_cards[item_id] as BuildCard).set_picture(texture)


## Slides the details panel out with `subject` (see BuildDetails), or swaps what it shows.
func show_details(subject: Dictionary) -> void:
	details.show_subject(subject)
	_show_details(true)


func hide_details() -> void:
	_show_details(false)


func details_visible() -> bool:
	return _details_open


func set_details_facing(facing: String) -> void:
	details.set_facing(facing)


## The bubble at the pointer: a tick and the item's name where it may go, a warning and the reason where it may not.
func set_bubble(text: String, ok: bool, screen_position: Vector2) -> void:
	_bubble.visible = true
	_bubble_label.text = text
	_bubble_icon.kind = &"check" if ok else &"warning"
	_bubble_icon.color = Pal.GREEN if ok else Pal.RED
	(_bubble.get_theme_stylebox("panel") as FantasyBox).border = Color(Pal.GREEN, 0.9) if ok else Color(Pal.RED, 0.95)
	_bubble.reset_size()
	var spot: Vector2 = screen_position + Vector2(24, 26)
	spot.x = minf(spot.x, size.x - _bubble.size.x - 12.0)
	spot.y = minf(spot.y, size.y - _bubble.size.y - 12.0)
	_bubble.position = spot


func hide_bubble() -> void:
	_bubble.visible = false


func toast(text: String) -> void:
	var pill := UI.panel(&"PanelPill")
	pill.add_child(UI.label(text, &"", 19, Pal.PARCHMENT))
	pill.modulate.a = 0.0
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.add_child(pill)
	var tween := create_tween()
	tween.tween_property(pill, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.2)
	tween.tween_property(pill, "modulate:a", 0.0, 0.5)
	tween.tween_callback(pill.queue_free)


## True if the pointer is over a panel of this interface (so the world should not react to it).
func covers(point: Vector2) -> bool:
	if Rect2(_rail.global_position, _rail.size * _rail.scale).has_point(point):
		return true
	for panel: Control in [_tray if _tray.visible else null, details if details.visible else null, _hint_pill, _allowance if _allowance.visible else null]:
		if panel != null and panel.get_global_rect().has_point(point):
			return true
	return false


func open_tray(open: bool) -> void:
	_show_tray(open)


func tray_visible() -> bool:
	return _tray_open and _tool in [0, 3]


func focus_search() -> void:
	if _tool != 0:
		tool_chosen.emit(0)
	open_tray(true)
	search.grab_focus()
	search.select_all()


func clear_search() -> bool:
	if search.text != "" or search.has_focus():
		search.text = ""
		search.release_focus()
		_filter_cards()
		return true
	return false


func visible_items() -> Array[Dictionary]:
	return _items.filter(func(entry: Dictionary) -> bool: return _cards.has(str(entry.id)) and (_cards[str(entry.id)] as Control).visible)


func set_paint(material_id: String) -> void:
	_paint_material = material_id
	if material_id != "":
		_choose_paint_family(family_for(material_id))
	for id: String in _paint_cards:
		(_paint_cards[id] as BuildCard).selected = id == material_id


func set_brush(side: int) -> void:
	for n: int in _brush_buttons:
		(_brush_buttons[n] as FButton).set_pressed_no_signal(n == side)


## Where everything goes for the window's size and how far the tray and the details panel have slid out.
func _layout() -> void:
	if _tray == null:
		return
	var tray_top: float = size.y - TRAY_HEIGHT * _tray_reveal
	_tray.position = Vector2(-6.0, tray_top)
	_tray.size = Vector2(size.x + 12.0, TRAY_HEIGHT + 8.0)
	_tray.visible = _tray_reveal > 0.005
	var floor_y: float = lerpf(size.y - MARGIN, size.y - TRAY_HEIGHT - 12.0, _tray_reveal)
	var room: float = floor_y - MARGIN
	# The rail stays where it is whichever tool is chosen: it is centred in the space the open tray leaves.
	var rail_room: float = size.y - TRAY_HEIGHT - 12.0 - MARGIN * 2.0
	var rail_size: Vector2 = _rail.get_combined_minimum_size()
	var fit: float = minf(1.0, rail_room / maxf(1.0, rail_size.y))
	_rail.scale = Vector2(fit, fit)
	_rail.size = rail_size
	_rail.position = Vector2(MARGIN, MARGIN + (rail_room - rail_size.y * fit) * 0.5)
	var width: float = maxf(clampf(size.x * 0.18, 250.0, 360.0), details.get_combined_minimum_size().x)
	details.size = Vector2(width, clampf(details.content_height(), 120.0, maxf(120.0, room)))
	details.position = Vector2(size.x - MARGIN - width + (width + 40.0) * (1.0 - _details_reveal), MARGIN)
	details.modulate.a = _details_reveal
	details.visible = _details_reveal > 0.005
	# The hint, the allowance and the toasts sit centred in the free space between the rail and the details panel,
	# and the hint drops its camera reminder when there is no room for it.
	var left: float = MARGIN + rail_size.x * fit + 12.0
	var right: float = (details.position.x if _details_open else size.x - MARGIN) - 12.0
	_hint_label.text = _hint_text + NAV_HINT
	_hint_pill.reset_size()
	if _hint_pill.size.x > right - left:
		_hint_label.text = _hint_text
		_hint_pill.reset_size()
	var middle: float = (left + right) * 0.5
	_hint_pill.position = Vector2(middle - _hint_pill.size.x * 0.5, MARGIN)
	_allowance.reset_size()
	_allowance.position = Vector2(middle - _allowance.size.x * 0.5, MARGIN + _hint_pill.size.y + 8.0)
	_toasts.position = Vector2(middle - _toasts.size.x * 0.5, MARGIN + _hint_pill.size.y + (_allowance.size.y + 16.0 if _allowance.visible else 10.0))


# --------------------------------------------------------------------- build
func _build() -> void:
	_frame = _Frame.new()
	UI.full_rect(_frame)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_build_tray()
	_build_rail()
	details = BuildDetails.new()
	details.visible = false
	details.content_changed.connect(_layout.call_deferred)
	add_child(details)
	# Key hints.
	_hint_pill = UI.panel(&"PanelPill")
	_hint_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label = UI.label("", &"LabelDim", 15)
	_hint_pill.add_child(_hint_label)
	add_child(_hint_pill)
	# The allowance a player has left.
	_allowance = UI.panel(&"PanelPill")
	_allowance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_allowance_label = UI.label("", &"", 16, Pal.PARCHMENT)
	_allowance.add_child(_allowance_label)
	_allowance.visible = false
	add_child(_allowance)
	# Where the cursor bubble and the toasts live.
	_bubble = UI.panel(&"PanelPill")
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_theme_stylebox_override("panel", FantasyBox.make({"fill_top": Color(0.08, 0.06, 0.04, 0.95), "fill_bottom": Color(0.06, 0.045, 0.03, 0.96), "border": Pal.GREEN, "border_width": 1.8, "chamfer": 9.0, "inner_line": Color(0, 0, 0, 0), "shadow": 3.0, "bevel": 0.0}, Vector2(13, 7)))
	var bubble_row := UI.hbox(8)
	_bubble_icon = Glyph.new()
	_bubble_icon.custom_minimum_size = Vector2(20, 20)
	bubble_row.add_child(_bubble_icon)
	_bubble_label = UI.label("", &"", 18, Pal.PARCHMENT)
	bubble_row.add_child(_bubble_label)
	_bubble.add_child(bubble_row)
	_bubble.visible = false
	add_child(_bubble)
	_toasts = UI.vbox(6)
	_toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.resized.connect(_layout)
	add_child(_toasts)


## The rail: a tall plaque of round tools down the left edge.
func _build_rail() -> void:
	_rail = UI.panel()
	_rail.add_theme_stylebox_override("panel", FantasyBox.make({"fill_top": Color(0.1, 0.075, 0.05, 0.95), "fill_bottom": Color(0.07, 0.05, 0.035, 0.96), "border": Pal.BRASS, "border_width": 2.0, "chamfer": 16.0, "inner_line": Color(0.95, 0.8, 0.45, 0.2), "studs": true, "shadow": 5.0, "bevel": 0.1}, Vector2(10, 14)))
	add_child(_rail)
	var column := UI.vbox(4)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_rail.add_child(column)
	var mark := Glyph.new()
	mark.kind = &"hammer"
	mark.color = Pal.BRASS_HI
	mark.custom_minimum_size = Vector2(24, 24)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(mark)
	var title := UI.label("BUILD", &"LabelHeading", 15)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	for index: int in range(TOOLS.size()):
		if index == 0 or index == 2:
			column.add_child(_rule())
		var spec: Dictionary = TOOLS[index]
		var bubble := BuildBubble.make(str(spec.name), spec.icon, str(spec.key), 54.0, str(spec.tip))
		var tool: int = int(spec.tool)
		bubble.pressed.connect(func() -> void: _on_tool_bubble(tool))
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_bubbles[tool] = bubble
		column.add_child(bubble)
	column.add_child(_rule())
	var history := UI.hbox(2)
	history.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(history)
	_undo = BuildBubble.make("", &"undo", "", 34.0, "Undo (Ctrl+Z)")
	_undo.pressed.connect(func() -> void: undo_pressed.emit())
	_redo = BuildBubble.make("", &"redo", "", 34.0, "Redo (Ctrl+Y)")
	_redo.pressed.connect(func() -> void: redo_pressed.emit())
	history.add_child(_undo)
	history.add_child(_redo)
	var done := BuildBubble.make("Done", &"check", "", 44.0, "Back to the hollow (B or Esc)")
	done.primary = true
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(func() -> void: done_pressed.emit())
	column.add_child(done)


## The tray: the whole width of the bottom of the screen, with a header of tabs and one scrolling row of cards.
func _build_tray() -> void:
	_tray = UI.panel()
	_tray.add_theme_stylebox_override("panel", FantasyBox.make({"fill_top": Color(0.1, 0.075, 0.05, 0.97), "fill_bottom": Color(0.06, 0.045, 0.03, 0.98), "border": Pal.BRASS, "border_width": 2.0, "chamfer": 0.0, "inner_line": Color(0.95, 0.8, 0.45, 0.2), "shadow": 0.0, "bevel": 0.12}, Vector2(28, 12)))
	add_child(_tray)
	var column := UI.vbox(8)
	_tray.add_child(column)
	var header := UI.hbox(10)
	column.add_child(header)
	_tray_mark = Glyph.new()
	_tray_mark.kind = &"cube"
	_tray_mark.color = Pal.BRASS_HI
	_tray_mark.custom_minimum_size = Vector2(24, 24)
	_tray_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_tray_mark)
	_tray_title = UI.label("OBJECTS", &"LabelHeading", 17)
	_tray_title.custom_minimum_size.x = 92
	header.add_child(_tray_title)
	header.add_child(_divider())
	_category_scroll = ScrollContainer.new()
	_category_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_category_scroll.custom_minimum_size = Vector2(100, 54)
	_category_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_category_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_category_scroll.tooltip_text = "Scroll across object categories"
	header.add_child(_category_scroll)
	_tabs = UI.hbox(6)
	_category_scroll.add_child(_tabs)
	for category: Variant in _catalog.get("categories", []):
		var category_id: String = str((category as Dictionary).id)
		var count: int = _items.filter(func(entry: Dictionary) -> bool: return entry.category == category_id).size()
		if count == 0:
			continue
		var tab := UI.button(str((category as Dictionary).title), CATEGORY_ICONS.get(category_id, &"cube"), &"ButtonTab")
		tab.toggle_mode = true
		tab.focus_mode = Control.FOCUS_NONE
		tab.custom_minimum_size.y = 38
		tab.add_theme_font_size_override("font_size", 14)
		tab.tooltip_text = "%s  ·  %d" % [str((category as Dictionary).get("blurb", "")), count]
		tab.pressed.connect(func() -> void: _choose_category(category_id))
		_tab_buttons[category_id] = tab
		_tabs.add_child(tab)
	_land_header = UI.hbox(6)
	header.add_child(_land_header)
	for family: String in LAND_GROUPS:
		var tab := UI.button(family, &"", &"ButtonTab")
		tab.add_theme_font_size_override("font_size", 14)
		tab.custom_minimum_size.y = 38
		tab.focus_mode = Control.FOCUS_NONE
		tab.toggle_mode = true
		tab.pressed.connect(func() -> void: _choose_paint_family(family))
		_paint_tabs[family] = tab
		_land_header.add_child(tab)
	_header_spacer = UI.spacer(0, true)
	header.add_child(_header_spacer)
	search = LineEdit.new()
	search.placeholder_text = "Search objects  ·  Ctrl+F"
	search.custom_minimum_size = Vector2(230, 0)
	search.clear_button_enabled = true
	search.add_theme_font_size_override("font_size", 14)
	search.text_changed.connect(func(_text: String) -> void: _filter_cards())
	search.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			clear_search()
			search.accept_event())
	header.add_child(search)
	_land_tools = UI.hbox(5)
	header.add_child(_land_tools)
	_brush_label = UI.label("Brush", &"LabelDim", 14)
	_brush_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_land_tools.add_child(_brush_label)
	for n: int in [1, 2, 4]:
		var brush := UI.button("1/2" if n == 1 else ("1" if n == 2 else "2"), &"", &"ButtonTab")
		brush.tooltip_text = "%d × %d sub-tiles ([ and ])" % [n, n]
		brush.toggle_mode = true
		brush.focus_mode = Control.FOCUS_NONE
		brush.custom_minimum_size.y = 38
		brush.add_theme_font_size_override("font_size", 14)
		brush.pressed.connect(func() -> void: brush_chosen.emit(n))
		_land_tools.add_child(brush)
		_brush_buttons[n] = brush
	_pick_button = UI.button("Pick", &"", &"ButtonTab", func() -> void: eyedropper_pressed.emit())
	_pick_button.tooltip_text = "Pick the ground under the pointer (Alt or I)"
	_pick_button.focus_mode = Control.FOCUS_NONE
	_pick_button.custom_minimum_size.y = 38
	_pick_button.add_theme_font_size_override("font_size", 14)
	_land_tools.add_child(_pick_button)
	set_brush(1)
	var close_tray := UI.icon_button(&"chevron_down", "Hide the tray (Tab)", func() -> void: _show_tray(false))
	close_tray.focus_mode = Control.FOCUS_NONE
	close_tray.custom_minimum_size = Vector2(38, 38)
	header.add_child(close_tray)
	var body := UI.hbox(6)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	_page_left = UI.icon_button(&"chevron_left", "Scroll back (wheel)", func() -> void: _page(-1))
	_page_right = UI.icon_button(&"chevron", "Scroll on (wheel)", func() -> void: _page(1))
	for button: FButton in [_page_left, _page_right]:
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(34, 0)
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_page_left)
	_scroll = _strip()
	body.add_child(_scroll)
	_cards_row = UI.hbox(10)
	_scroll.add_child(_cards_row)
	_paint_scroll = _strip()
	body.add_child(_paint_scroll)
	_swatches = UI.hbox(10)
	_paint_scroll.add_child(_swatches)
	body.add_child(_page_right)
	_build_swatches()


## One scrolling row: the wheel moves it sideways, and the page buttons follow where it is.
func _strip() -> ScrollContainer:
	var strip := ScrollContainer.new()
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	strip.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
			var back: bool = event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT]
			strip.scroll_horizontal += (-1 if back else 1) * int(CARD_SIZE.x + 10.0)
			strip.accept_event())
	strip.get_h_scroll_bar().changed.connect(_update_pages)
	strip.get_h_scroll_bar().value_changed.connect(func(_value: float) -> void: _update_pages())
	strip.resized.connect(_update_pages)
	return strip


func _active_strip() -> ScrollContainer:
	return _paint_scroll if _tool == 3 else _scroll


func _page(direction: int) -> void:
	var strip: ScrollContainer = _active_strip()
	if _page_tween != null:
		_page_tween.kill()
	var goal: int = strip.scroll_horizontal + direction * int(maxf(CARD_SIZE.x, strip.size.x * 0.8))
	_page_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_page_tween.tween_property(strip, "scroll_horizontal", clampi(goal, 0, int(_scroll_end(strip))), 0.3)


func _scroll_end(strip: ScrollContainer) -> float:
	var bar: HScrollBar = strip.get_h_scroll_bar()
	return maxf(0.0, bar.max_value - bar.page)


func _update_pages() -> void:
	if _page_left == null:
		return
	var strip: ScrollContainer = _active_strip()
	var end: float = _scroll_end(strip)
	_page_left.disabled = strip.scroll_horizontal <= 0
	_page_right.disabled = float(strip.scroll_horizontal) >= end - 1.0
	_page_left.queue_redraw()
	_page_right.queue_redraw()


func _on_tool_bubble(tool: int) -> void:
	if tool == _tool and tool in [0, 3]:
		_show_tray(not _tray_open)
	else:
		tool_chosen.emit(tool)


func _fill_cards() -> void:
	for child: Node in _cards_row.get_children():
		_cards_row.remove_child(child)
		child.queue_free()
	_cards.clear()
	for entry: Dictionary in _items:
		var facts: Dictionary = _describe.call(entry)
		var card := BuildCard.make(entry, str(facts.get("chip", "")), CARD_SIZE)
		card.chosen.connect(func(id: String) -> void: item_chosen.emit(id))
		card.visible = str(entry.category) == _category
		_cards[str(entry.id)] = card
		_cards_row.add_child(card)
		if _picture_cache.has(str(entry.id)):
			card.set_picture(_picture_cache[str(entry.id)])
	for id: String in _tab_buttons:
		(_tab_buttons[id] as FButton).set_pressed_no_signal(id == _category)


func _choose_category(category_id: String) -> void:
	_category = category_id
	_filter_cards()
	if _tab_buttons.has(category_id):
		_category_scroll.ensure_control_visible.call_deferred(_tab_buttons[category_id])


func _filter_cards() -> void:
	var query: String = search.text.strip_edges().to_lower()
	for entry: Dictionary in _items:
		var matches: bool = query == "" or (str(entry.title) + " " + str(entry.get("blurb", "")) + " " + str(entry.category)).to_lower().contains(query)
		(_cards[str(entry.id)] as BuildCard).visible = matches and (query != "" or str(entry.category) == _category)
	for id: String in _tab_buttons:
		(_tab_buttons[id] as FButton).set_pressed_no_signal(query == "" and id == _category)
	_scroll.scroll_horizontal = 0
	category_changed.emit()
	_update_pages.call_deferred()


func _build_swatches() -> void:
	var materials: Array = [""]
	materials.append_array(AreaStore.ground_materials())
	for id: String in materials:
		var entry: Dictionary = {"id": id, "title": "Eraser" if id == "" else id.replace("_", " ").capitalize(), "blurb": "Restore natural ground" if id == "" else "Paint " + id, "kind": "paint"}
		var card := BuildCard.make(entry, "Half-cell ground paint", CARD_SIZE)
		card.chosen.connect(func(material_id: String) -> void: paint_chosen.emit(material_id))
		_swatches.add_child(card)
		_paint_cards[id] = card
		if id != "":
			var recipe: Dictionary = WorldTextures.entry(id)
			card.set_picture(WorldTextures.texture(str(recipe.texture)))
			var tint: float = float(recipe.tint)
			card._picture.self_modulate = Color(tint, tint, tint)
			card._picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The land-shaping tools share the strip; their pictures are drawn from their sample land (set_land_picture).
	land_tools = AreaStore.read_land_tools()
	for tool: Dictionary in land_tools:
		var key: String = "shape:" + str(tool.id)
		var card := BuildCard.make({"id": key, "title": tool.title, "blurb": tool.blurb, "kind": "shape", "icon": tool.icon}, str(tool.family), CARD_SIZE)
		var tool_id: String = str(tool.id)
		card.chosen.connect(func(_key: String) -> void: shape_chosen.emit(tool_id))
		_swatches.add_child(card)
		_paint_cards[key] = card
	_choose_paint_family("Grass")


## A land tool's card picture, once it has been drawn from its sample land.
func set_land_picture(tool_id: String, texture: Texture2D) -> void:
	if _paint_cards.has("shape:" + tool_id):
		(_paint_cards["shape:" + tool_id] as BuildCard).set_picture(texture)


## Shows the Land tray's tools for what is chosen: "paint" (brush sizes in sub-tiles and Pick), "shape" (brush sizes
## in whole cells) or "stairs" (no brush at all), with the key hint that goes with it.
func set_land_mode(mode: String) -> void:
	_land_mode = mode if LAND_HINTS.has(mode) else "paint"
	var labels: Dictionary = BRUSH_LABELS.get(_land_mode, {})
	_brush_label.visible = _land_mode != "stairs"
	for n: int in _brush_buttons:
		var brush: FButton = _brush_buttons[n]
		brush.visible = _land_mode != "stairs"
		if labels.has(n):
			brush.text = str(labels[n])
			brush.tooltip_text = ("%d × %d sub-tiles ([ and ])" % [n, n]) if _land_mode == "paint" else ("%s × %s cells ([ and ])" % [labels[n], labels[n]])
	_pick_button.visible = _land_mode == "paint"
	if _tool == 3:
		_hint_text = LAND_HINTS[_land_mode]
		_layout()


func _choose_paint_family(family: String) -> void:
	_paint_family = family
	for id: String in _paint_tabs:
		(_paint_tabs[id] as FButton).set_pressed_no_signal(id == family)
	for id: String in _paint_cards:
		(_paint_cards[id] as BuildCard).visible = (id == "" and not family in SHAPE_GROUPS) or family_for(id) == family
	if _paint_scroll != null:
		_paint_scroll.scroll_horizontal = 0
		_update_pages.call_deferred()


func family_for(id: String) -> String:
	if id.begins_with("shape:"):
		for tool: Dictionary in land_tools:
			if "shape:" + str(tool.id) == id:
				return str(tool.family)
		return "Terrain"
	if id in SurfaceFinishes.OPTIONS.floor:
		return "Floors"
	if id.begins_with("grass"):
		return "Grass"
	if id.begins_with("dirt"):
		return "Dirt"
	if id.begins_with("path") or id in ["pebbles", "rock_face"]:
		return "Stone"
	return "Soil"


func _show_tray(open: bool) -> void:
	_tray_open = open
	if _tray_tween != null:
		_tray_tween.kill()
	_tray_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tray_tween.tween_method(func(value: float) -> void:
		_tray_reveal = value
		_layout(), _tray_reveal, 1.0 if open else 0.0, 0.24)


func _show_details(open: bool) -> void:
	if open == _details_open and (_details_reveal == (1.0 if open else 0.0) or _details_tween != null and _details_tween.is_running()):
		return
	_details_open = open
	if _details_tween != null:
		_details_tween.kill()
	_details_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_details_tween.tween_method(func(value: float) -> void:
		_details_reveal = value
		_layout(), _details_reveal, 1.0 if open else 0.0, 0.22)


func _entry(item_id: String) -> Dictionary:
	for entry: Dictionary in _items:
		if entry.id == item_id:
			return entry
	return {}


func _divider() -> Control:
	var line := ColorRect.new()
	line.color = Color(Pal.BRASS_LO, 0.7)
	line.custom_minimum_size = Vector2(2, 30)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _rule() -> Control:
	var line := ColorRect.new()
	line.color = Color(Pal.BRASS_LO, 0.55)
	line.custom_minimum_size = Vector2(46, 1)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


## Brass corner brackets round the screen: the quiet sign that this is a different mode.
class _Frame extends Control:
	func _draw() -> void:
		var margin: float = 10.0
		var arm: float = 46.0
		var tint := Color(Pal.BRASS, 0.5)
		for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
			var anchor: Vector2 = Vector2(margin, margin) + (size - Vector2(margin * 2.0, margin * 2.0)) * corner
			var sx: float = 1.0 - 2.0 * corner.x
			var sy: float = 1.0 - 2.0 * corner.y
			draw_polyline(PackedVector2Array([anchor + Vector2(arm * sx, 0), anchor, anchor + Vector2(0, arm * sy)]), tint, 2.0, true)
			draw_circle(anchor + Vector2(7.0 * sx, 7.0 * sy), 2.4, Color(Pal.BRASS_HI, 0.6))
