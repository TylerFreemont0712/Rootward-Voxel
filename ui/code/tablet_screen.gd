class_name TabletScreen
extends PanelContainer
## The code surface as an object. Instructions stay on paper beside it; code is on glass. Two looks share one
## screen: Nell's field slate (dark enamel bezel) for job pages, and the loft desk terminal (cream casing, a row of
## keys) for the first greeting. The bezel carries real controls: a link lamp and its words along the top with room
## for buttons at the right end (`header_end`), and keys along the bottom (`keys`). Between them is the glass: file
## tabs, `content`, an OUTPUT strip and a status bar, in VS Code's colours (`CodePalette`).
##
## The slate reaches the world two ways. At a zone's screen it is plugged in, and its cord hangs from its edge
## (`Link.WIRED`). Beside a single fitting it pairs over the air, and its lamp sends out signal arcs
## (`Link.WIRELESS`).
##
## When the selected painted frame is built (`assets/ui/nells-field-slate`, from `pipeline/art-catalog.json`), the
## slate is that painting, stretched as a nine-slice: the glass sits in its painted window, the link words and close
## button become a title bar at the top of the glass, its painted lamp lights up, the cord plugs into its painted
## jack, and the keys sit on its lower ledge. Without it the slate falls back to the drawn enamel bezel.

enum Look { SLATE, TERMINAL }
enum Link { NONE, WIRED, WIRELESS }

const SHADOW: float = 4.0
const BEZEL: float = 14.0
const SLATE_FRAME: String = "res://assets/ui/nells-field-slate/manifest.json"
## Where the keys stand on the painted ledge: this far down it, and in from the corner guards.
const LEDGE_KEYS_AT: float = 0.28
const LEDGE_KEYS_INDENT: float = 24.0

static var _painted: Dictionary = {}
static var _painted_read: bool = false

var content: VBoxContainer
var output: RichTextLabel
var header_end: HBoxContainer
var keys: HBoxContainer
var skin: int = Look.SLATE:
	set(value):
		skin = value
		_arrange()
		_set_margins()
		_restyle_header()
		queue_redraw()
var link: String = "":
	set(value):
		link = value
		if _link_label != null: _link_label.text = value.to_upper()
var link_kind: int = Link.NONE:
	set(value):
		link_kind = value
		queue_redraw()
var linked: bool = true:
	set(value):
		linked = value
		queue_redraw()
var _column: VBoxContainer
var _glass: VBoxContainer
var _header: HBoxContainer
var _title_bar: PanelContainer
var _key_gap: Control
var _key_indent: Control
var _frame_box: StyleBoxTexture
var _lamp: Control
var _link_label: Label
var _tabs: HBoxContainer
var _status_left: Label
var _status_right: Label
var _status_box: StyleBoxFlat
var _on_tab: Callable
var _pulse: float = 0.0


func _init(tablet_skin: int = Look.SLATE) -> void:
	theme = CodePalette.screen_theme()
	mouse_filter = Control.MOUSE_FILTER_PASS
	_column = UI.vbox(8)
	add_child(_column)
	var header := UI.hbox(8)
	_header = header
	header.custom_minimum_size.y = 24
	_lamp = Control.new()
	_lamp.custom_minimum_size = Vector2(34, 22)
	_lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lamp.draw.connect(_draw_lamp)
	header.add_child(_lamp)
	_link_label = UI.label("", &"LabelCaps", 12)
	_link_label.clip_text = true
	_link_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_link_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_link_label)
	header_end = UI.hbox(6)
	header.add_child(header_end)
	_column.add_child(header)
	_glass = UI.vbox(0)
	_glass.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_column.add_child(_glass)
	var tab_bar := PanelContainer.new()
	var tab_box: StyleBoxFlat = CodePalette.glass(CodePalette.BG_RAISED)
	tab_box.set_content_margin_all(0.0)
	tab_bar.add_theme_stylebox_override("panel", tab_box)
	_tabs = UI.hbox(1)
	tab_bar.add_child(_tabs)
	_glass.add_child(tab_bar)
	content = UI.vbox(4)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_glass.add_child(content)
	var strip := PanelContainer.new()
	var strip_box: StyleBoxFlat = CodePalette.glass(CodePalette.BG)
	strip_box.border_width_top = 1
	strip_box.border_color = CodePalette.RULE
	strip.add_theme_stylebox_override("panel", strip_box)
	var strip_body := UI.vbox(2)
	strip.add_child(strip_body)
	strip_body.add_child(UI.label("OUTPUT", &"LabelCaps", 11))
	output = RichTextLabel.new()
	output.fit_content = true
	output.scroll_active = false
	output.custom_minimum_size.y = 44
	output.add_theme_font_size_override("normal_font_size", 16)
	output.text = "No output yet."
	strip_body.add_child(output)
	_glass.add_child(strip)
	var status := PanelContainer.new()
	var status_box: StyleBoxFlat = CodePalette.glass(CodePalette.STATUS_BAR)
	_status_box = status_box
	status_box.content_margin_top = 2.0
	status_box.content_margin_bottom = 2.0
	status.add_theme_stylebox_override("panel", status_box)
	var status_row := UI.hbox(8)
	status.add_child(status_row)
	_status_left = UI.label("Python  ·  4 spaces", &"", 12, Color(1, 1, 1, 0.78))
	status_row.add_child(UI.fill(_status_left))
	_status_right = UI.label("Ready", &"", 12, Color(1, 1, 1, 0.9))
	status_row.add_child(_status_right)
	_glass.add_child(status)
	_key_gap = Control.new()
	_key_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(_key_gap)
	keys = UI.hbox(10)
	keys.visible = false
	_key_indent = Control.new()
	_key_indent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keys.add_child(_key_indent)
	_column.add_child(keys)
	# Key height is only known once the theme reaches the keys, so the ledge is measured again then.
	keys.minimum_size_changed.connect(_set_margins)
	# The glass is drawn from the layout, so it is redrawn whenever the layout moves.
	resized.connect(queue_redraw)
	_glass.item_rect_changed.connect(queue_redraw)
	skin = tablet_skin


func _ready() -> void:
	_set_margins()


## File tabs across the top of the glass. `on_select` receives the chosen index; a single tab is just a file name.
func set_tabs(names: Array[String], selected: int = 0, on_select: Callable = Callable()) -> void:
	_on_tab = on_select
	for child: Node in _tabs.get_children():
		_tabs.remove_child(child)
		child.queue_free()
	for index: int in range(names.size()):
		var tab: FButton = FButton.make(names[index], &"", &"ButtonTab")
		tab.toggle_mode = true
		tab.button_pressed = index == selected
		tab.focus_mode = Control.FOCUS_NONE
		tab.pressed.connect(_pick.bind(index))
		_tabs.add_child(tab)


func select_tab(index: int) -> void:
	for child_index: int in range(_tabs.get_child_count()):
		(_tabs.get_child(child_index) as FButton).button_pressed = child_index == index


## A key on the lower bezel. Keys keep the journey's own enamel look, as physical buttons on the casing.
func add_key(button: Control) -> void:
	keys.add_child(button)
	keys.visible = true
	_set_margins()


func _pick(index: int) -> void:
	select_tab(index)
	if _on_tab.is_valid():
		_on_tab.call(index)


## What the OUTPUT strip shows; `kind` is `&""` for plain output, `&"error"` or `&"ok"`.
func set_output(text: String, kind: StringName = &"") -> void:
	output.text = text
	var color: Color = CodePalette.ERROR if kind == &"error" else (CodePalette.OK if kind == &"ok" else CodePalette.TEXT)
	output.add_theme_color_override("default_color", color)


## The right end of the status bar: `ready`, `ghost` (a Test is waiting), `debug` (a debug run is showing, and the bar
## turns orange as a code editor's does while debugging), `ok` (applied), `done`, `sent`, `error` or `edited`.
func set_state(kind: StringName) -> void:
	_status_right.text = {&"ghost": "Test ready", &"debug": "Debugging  ·  ghost in the room", &"ok": "Applied", &"done": "Job done",
		&"sent": "Sent", &"error": "Error", &"edited": "Edited"}.get(kind, "Ready")
	_status_box.bg_color = CodePalette.DEBUG_BAR if kind == &"debug" else (CodePalette.DONE_BAR if kind == &"done" else CodePalette.STATUS_BAR)


## The selected painted slate frame: its manifest (slice margins, window, jack and lamp in its own pixels) and its
## texture, or {} when it has not been built.
static func painted_frame() -> Dictionary:
	if not _painted_read:
		_painted_read = true
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(SLATE_FRAME)) if FileAccess.file_exists(SLATE_FRAME) else null
		if raw is Dictionary and ResourceLoader.exists(str(raw.get("runtime", ""))):
			var texture := load(str(raw.runtime)) as Texture2D
			if texture != null:
				_painted = (raw as Dictionary).duplicate(true)
				_painted["texture"] = texture
	return _painted


## Whether this slate is drawn from the painted frame.
func framed() -> bool:
	return skin == Look.SLATE and not painted_frame().is_empty()


## The link words and close button sit on the bezel, or in a title bar at the top of the painted frame's glass.
func _arrange() -> void:
	if _header == null: return
	var holder: Node = _header.get_parent()
	if framed():
		if _title_bar == null:
			_title_bar = PanelContainer.new()
			var bar: StyleBoxFlat = CodePalette.glass(Color("323233"))
			bar.content_margin_top = 3.0
			bar.content_margin_bottom = 3.0
			bar.content_margin_left = 12.0
			_title_bar.add_theme_stylebox_override("panel", bar)
		if holder != _title_bar:
			if holder != null: holder.remove_child(_header)
			_title_bar.add_child(_header)
		if _title_bar.get_parent() != _glass:
			_glass.add_child(_title_bar)
			_glass.move_child(_title_bar, 0)
		_lamp.visible = false
	else:
		if holder != _column:
			if holder != null: holder.remove_child(_header)
			_column.add_child(_header)
			_column.move_child(_header, 0)
		if _title_bar != null:
			if _title_bar.get_parent() != null: _title_bar.get_parent().remove_child(_title_bar)
			_title_bar.queue_free()
			_title_bar = null
		_lamp.visible = true


func _set_margins() -> void:
	var box := StyleBoxEmpty.new()
	if framed():
		# The glass fills the painted window; the keys stand on the ledge below it.
		var painted: Dictionary = painted_frame()
		var window := Rect2(float(painted.window[0]), float(painted.window[1]), float(painted.window[2]), float(painted.window[3]))
		var ledge: float = float(painted.size[1]) - window.end.y
		var separation: float = float(_column.get_theme_constant("separation"))
		box.content_margin_left = window.position.x + 2.0
		box.content_margin_top = window.position.y + 2.0
		box.content_margin_right = float(painted.size[0]) - window.end.x + 2.0
		if keys.visible:
			var key_height: float = keys.get_combined_minimum_size().y
			_key_gap.custom_minimum_size.y = maxf(0.0, ledge * LEDGE_KEYS_AT - separation * 2.0)
			box.content_margin_bottom = maxf(4.0, ledge - ledge * LEDGE_KEYS_AT - key_height) + SHADOW
		else:
			_key_gap.custom_minimum_size.y = 0.0
			box.content_margin_bottom = ledge + SHADOW
		_key_gap.visible = keys.visible
		_key_indent.custom_minimum_size.x = LEDGE_KEYS_INDENT
	else:
		box.content_margin_left = BEZEL
		box.content_margin_right = BEZEL
		box.content_margin_top = 8.0
		box.content_margin_bottom = (30.0 if skin == Look.TERMINAL else 12.0) + SHADOW
		_key_gap.visible = false
		_key_indent.custom_minimum_size.x = 0.0
	add_theme_stylebox_override("panel", box)


func _restyle_header() -> void:
	if _link_label == null: return
	var ink: Color = PaperPal.TEAL_DEEP
	if framed(): ink = Color(CodePalette.TEXT, 0.85)
	elif skin == Look.SLATE: ink = Color(PaperPal.CREAM, 0.92)
	_link_label.add_theme_color_override("font_color", ink)


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_pulse += delta
		_lamp.queue_redraw()
		if link_kind == Link.WIRED or (framed() and linked and link_kind != Link.NONE): queue_redraw()


func _draw_lamp() -> void:
	var at := Vector2(9.0, _lamp.size.y * 0.5)
	if not linked or link_kind == Link.NONE:
		_lamp.draw_circle(at, 4.0, Color(PaperPal.BRASS, 0.7))
		return
	var glow: float = 0.5 + 0.5 * sin(_pulse * 2.2)
	_lamp.draw_circle(at, 6.5 + glow * 2.0, Color(PaperPal.TEAL_HI, 0.18))
	_lamp.draw_circle(at, 4.0, PaperPal.TEAL_HI)
	_lamp.draw_arc(at, 4.0, 0.0, TAU, 14, Color(0, 0, 0, 0.35), 1.0)
	if link_kind == Link.WIRELESS:
		# Paired over the air: arcs leave the lamp, one after another, and fade as they go.
		for ring: int in range(3):
			var phase: float = fposmod(_pulse * 0.9 + float(ring) / 3.0, 1.0)
			_lamp.draw_arc(at, 7.0 + phase * 16.0, -0.7, 0.7, 10, Color(PaperPal.TEAL_HI, 0.9 * (1.0 - phase)), 1.6, true)


func _draw() -> void:
	if framed():
		_draw_painted()
		return
	var slate: bool = skin == Look.SLATE
	var frame := Rect2(Vector2.ZERO, size - Vector2(0, SHADOW))
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = PaperPal.SHADOW
	shadow.set_corner_radius_all(18)
	draw_style_box(shadow, Rect2(frame.position + Vector2(2, SHADOW), frame.size))
	if slate and link_kind == Link.WIRED and linked:
		_draw_cord()
	var bezel := StyleBoxFlat.new()
	bezel.bg_color = Color("34454a") if slate else PaperPal.CREAM
	bezel.border_color = PaperPal.TEAL_DEEP if slate else PaperPal.EDGE
	bezel.set_border_width_all(2)
	bezel.set_corner_radius_all(18)
	draw_style_box(bezel, frame)
	if slate:
		# A lighter band along the top edge reads as the enamel catching the light.
		var sheen := StyleBoxFlat.new()
		sheen.bg_color = Color(1, 1, 1, 0.05)
		sheen.set_corner_radius_all(16)
		draw_style_box(sheen, Rect2(frame.position + Vector2(3, 3), Vector2(frame.size.x - 6, 18)))
	if _column != null and _glass != null:
		var screen := Rect2(_column.position + _glass.position, _glass.size)
		var glass := StyleBoxFlat.new()
		glass.bg_color = CodePalette.BG
		glass.border_color = Color("0b0b0b")
		glass.set_border_width_all(2)
		glass.set_corner_radius_all(5)
		draw_style_box(glass, screen.grow(3.0))
		if not slate and not keys.visible:
			# The desk terminal's keys along the lower casing.
			var x: float = BEZEL + 4.0
			while x < frame.size.x - BEZEL - 14.0:
				var key := StyleBoxFlat.new()
				key.bg_color = PaperPal.CREAM_HI
				key.border_color = PaperPal.EDGE
				key.set_border_width_all(1)
				key.set_corner_radius_all(2)
				draw_style_box(key, Rect2(x, frame.size.y - 22.0, 15.0, 11.0))
				x += 19.0
	for corner: Vector2 in [Vector2(9, 9), Vector2(frame.size.x - 9, 9), Vector2(9, frame.size.y - 9), Vector2(frame.size.x - 9, frame.size.y - 9)]:
		draw_circle(corner, 2.6, PaperPal.BRASS_LO)
		draw_circle(corner, 1.8, PaperPal.BRASS)


## Plugged in: a brass jack seated in the slate's left edge and its cord hanging away into the room.
func _draw_cord() -> void:
	var y: float = 28.0
	var sway: float = sin(_pulse * 0.8) * 3.0
	var cord := PackedVector2Array()
	for step: int in range(25):
		var t: float = float(step) / 24.0
		var a := Vector2(-46.0, y)
		var b := Vector2(-70.0 + sway, y + 40.0)
		var c := Vector2(-34.0 - sway, size.y * 0.55)
		var d := Vector2(-58.0, size.y + 40.0)
		var u: float = 1.0 - t
		cord.append(a * u * u * u + b * 3.0 * u * u * t + c * 3.0 * u * t * t + d * t * t * t)
	draw_polyline(cord, Color(0, 0, 0, 0.25), 6.0, true)
	draw_polyline(cord, Color("6f6c66"), 4.0, true)
	draw_polyline(cord, Color("9b978e"), 1.5, true)
	# Rubber strain relief, the brass barrel, a knurled collar and the socket ring on the bezel.
	draw_rect(Rect2(-50.0, y - 6.0, 22.0, 12.0), Color("5d5a55"))
	draw_rect(Rect2(-50.0, y - 6.0, 22.0, 3.0), Color("77736c"))
	draw_rect(Rect2(-30.0, y - 10.0, 30.0, 20.0), PaperPal.BRASS_LO)
	draw_rect(Rect2(-29.0, y - 9.0, 28.0, 18.0), PaperPal.BRASS)
	draw_rect(Rect2(-29.0, y - 9.0, 28.0, 5.0), PaperPal.BRASS_HI)
	for groove: int in range(4):
		draw_line(Vector2(-25.0 + groove * 6.0, y - 9.0), Vector2(-25.0 + groove * 6.0, y + 9.0), Color(PaperPal.BRASS_LO, 0.8), 1.0)
	draw_circle(Vector2(2.0, y), 12.0, PaperPal.BRASS_LO)
	draw_circle(Vector2(2.0, y), 10.0, PaperPal.BRASS)
	draw_circle(Vector2(1.0, y - 1.5), 6.0, PaperPal.BRASS_HI)
	draw_circle(Vector2(2.0, y), 4.0, Color("2b2118"))


## The painted slate: its shadow, the nine-slice frame, the glass in its window, its lamp lit when linked and, when
## plugged in, the cord seated in its painted jack.
func _draw_painted() -> void:
	var painted: Dictionary = painted_frame()
	var frame := Rect2(Vector2.ZERO, size - Vector2(0, SHADOW))
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = PaperPal.SHADOW
	shadow.set_corner_radius_all(22)
	draw_style_box(shadow, Rect2(frame.position + Vector2(3, SHADOW + 2), frame.size))
	if link_kind == Link.WIRED and linked:
		_draw_jack_cord(Vector2(float(painted.jack[0]), float(painted.jack[1])), float(painted.jack[2]), false)
	if _frame_box == null:
		_frame_box = StyleBoxTexture.new()
		_frame_box.texture = painted.texture
		_frame_box.texture_margin_left = float(painted.slice[0])
		_frame_box.texture_margin_top = float(painted.slice[1])
		_frame_box.texture_margin_right = float(painted.slice[2])
		_frame_box.texture_margin_bottom = float(painted.slice[3])
	draw_style_box(_frame_box, frame)
	if _column != null and _glass != null:
		var glass := StyleBoxFlat.new()
		glass.bg_color = CodePalette.BG
		glass.set_corner_radius_all(4)
		draw_style_box(glass, Rect2(_column.position + _glass.position, _glass.size).grow(1.0))
	var lamp := Vector2(float(painted.lamp[0]), float(painted.lamp[1]))
	var radius: float = float(painted.lamp[2])
	if linked and link_kind != Link.NONE:
		var glow: float = 0.5 + 0.5 * sin(_pulse * 2.2)
		draw_circle(lamp, radius * (1.9 + glow * 0.4), Color(PaperPal.TEAL_HI, 0.22))
		draw_circle(lamp, radius * 0.8, PaperPal.TEAL_HI)
		draw_circle(lamp + Vector2(-radius * 0.25, -radius * 0.3), radius * 0.28, Color(1, 1, 1, 0.7))
		if link_kind == Link.WIRELESS:
			for ring: int in range(3):
				var phase: float = fposmod(_pulse * 0.9 + float(ring) / 3.0, 1.0)
				draw_arc(lamp, radius + 3.0 + phase * 18.0, -0.7, 0.7, 10, Color(PaperPal.TEAL_HI, 0.9 * (1.0 - phase)), 1.8, true)
	if link_kind == Link.WIRED and linked:
		_draw_jack_cord(Vector2(float(painted.jack[0]), float(painted.jack[1])), float(painted.jack[2]), true)


## A jack plugged straight into the painted socket, seen end-on, and its cord leaving over the slate's top-left
## corner to hang down into the room. Drawn in two passes: the cord under the frame, the plug over it.
func _draw_jack_cord(jack: Vector2, radius: float, plug: bool) -> void:
	if not plug:
		var sway: float = sin(_pulse * 0.8) * 3.0
		var first := _bezier(jack, jack + Vector2(-18.0, -36.0), Vector2(-24.0, -14.0), Vector2(-34.0, 46.0))
		var second := _bezier(Vector2(-34.0, 46.0), Vector2(-46.0 + sway, 120.0), Vector2(-26.0 - sway, size.y * 0.55), Vector2(-56.0, size.y + 40.0))
		var cord: PackedVector2Array = first + second
		draw_polyline(cord, Color(0, 0, 0, 0.25), 7.0, true)
		draw_polyline(cord, Color("6f6c66"), 5.0, true)
		draw_polyline(cord, Color("9b978e"), 1.8, true)
		return
	# Rubber boot leaving the plug, then the knurled brass cap seated over the socket.
	draw_line(jack, jack + Vector2(-9.0, -14.0), Color("5d5a55"), 8.0, true)
	draw_circle(jack, radius + 6.0, Color(0, 0, 0, 0.25))
	draw_circle(jack, radius + 5.0, PaperPal.BRASS_LO)
	draw_circle(jack, radius + 3.5, PaperPal.BRASS)
	for notch: int in range(16):
		var angle: float = TAU * float(notch) / 16.0
		draw_line(jack + Vector2(cos(angle), sin(angle)) * (radius + 1.5), jack + Vector2(cos(angle), sin(angle)) * (radius + 4.5), Color(PaperPal.BRASS_LO, 0.9), 1.0)
	draw_circle(jack + Vector2(-radius * 0.3, -radius * 0.35), radius * 0.55, PaperPal.BRASS_HI)
	draw_circle(jack, radius * 0.4, Color("2b2118"))


static func _bezier(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step: int in range(17):
		var t: float = float(step) / 16.0
		var u: float = 1.0 - t
		points.append(a * u * u * u + b * 3.0 * u * u * t + c * 3.0 * u * t * t + d * t * t * t)
	return points
