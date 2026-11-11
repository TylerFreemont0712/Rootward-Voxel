class_name BuildBubble
extends Control
## A round button for build mode's left rail: a domed wood-and-brass bubble with an icon, its name under it and
## its key in a small badge. Hovering lifts it a little; the chosen one swells, glows and turns brass. Drawn in
## code like the rest of the kit, so it scales cleanly.

signal pressed

var glyph: StringName = &"dot"
var text: String = ""
var hotkey: String = ""
var diameter: float = 54.0
## The brass-filled look, for Done.
var primary: bool = false
var selected: bool = false:
	set(value):
		if selected == value:
			return
		selected = value
		_settle(true)
var disabled: bool = false:
	set(value):
		disabled = value
		mouse_default_cursor_shape = Control.CURSOR_ARROW if value else Control.CURSOR_POINTING_HAND
		_settle(false)
var _hover: bool = false
## 0 at rest, 0.5 hovered, 1 chosen; animated.
var _swell: float = 0.0
var _tween: Tween


static func make(label: String, icon: StringName, key: String = "", size_px: float = 54.0, tip: String = "") -> BuildBubble:
	var bubble := BuildBubble.new()
	bubble.text = label
	bubble.glyph = icon
	bubble.hotkey = key
	bubble.diameter = size_px
	bubble.tooltip_text = tip
	return bubble


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func() -> void:
		_hover = true
		_settle(false))
	mouse_exited.connect(func() -> void:
		_hover = false
		_settle(false))


func _get_minimum_size() -> Vector2:
	var label_height: float = 17.0 if text != "" else 0.0
	return Vector2(diameter + 14.0, diameter + 8.0 + label_height)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		if not disabled:
			_pop()
			pressed.emit()


func _settle(pop: bool) -> void:
	var target: float = 1.0 if selected else (0.45 if _hover and not disabled else 0.0)
	if not is_inside_tree():
		_set_swell(target)
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_BACK if pop else Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_swell, _swell, target, 0.28 if pop else 0.14)


func _pop() -> void:
	if not is_inside_tree():
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_swell, 1.5, 1.0 if selected else 0.45, 0.3)


func _set_swell(value: float) -> void:
	_swell = value
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, 4.0 + diameter * 0.5)
	var lit: float = clampf(_swell, 0.0, 1.0)
	var radius: float = diameter * 0.5 * (1.0 + 0.06 * _swell)
	var alpha: float = 0.45 if disabled else 1.0
	if selected or primary:
		draw_circle(center, radius + 7.0, Color(Pal.BRASS_HI, 0.1 * lit + (0.06 if primary else 0.0)))
		draw_circle(center, radius + 3.5, Color(Pal.BRASS, 0.22 * lit + (0.1 if primary else 0.0)))
	draw_circle(center + Vector2(0, 3.0), radius, Color(Pal.SHADOW, Pal.SHADOW.a * alpha))
	# A dome: rings from the rim inwards, each a little lighter and a little higher.
	var rim: Color = Pal.PANEL_LO
	var crown: Color = Pal.WOOD_HI.lerp(Color("6a5232"), 0.4 * lit)
	if selected:
		rim = Color("2a1f12")
		crown = Color("8a6a36").lerp(Color("b98d45"), lit)
	if primary:
		rim = Color("a8742a")
		crown = Color("f8d98a") if _hover else Color("f1c767")
	for ring: int in range(7):
		var t: float = float(ring) / 6.0
		draw_circle(center - Vector2(0, radius * 0.16 * t), radius * (1.0 - 0.42 * t), Color(rim.lerp(crown, t), alpha))
	draw_circle(center + Vector2(-radius * 0.3, -radius * 0.42), radius * 0.2, Color(1, 1, 1, 0.07 + 0.05 * lit))
	var ring_color: Color = Pal.BRASS_HI if selected else (Pal.BRASS if _hover or primary else Pal.BRASS_LO)
	draw_arc(center, radius - 0.8, 0.0, TAU, 56, Color(ring_color, alpha), 2.0 + 0.8 * lit, true)
	draw_arc(center, radius - 4.6, 0.0, TAU, 56, Color(Pal.BRASS_HI, 0.16 * alpha), 1.0, true)
	var icon: float = diameter * 0.46
	var tint: Color = Pal.PARCHMENT if selected else (Pal.BRASS_HI if _hover else Pal.BRASS)
	if primary:
		tint = Color("2a1d0c")
	Glyph.paint(self, glyph, Rect2(center - Vector2(icon, icon) * 0.5, Vector2(icon, icon)), Color(tint, alpha))
	if hotkey != "":
		var badge: Vector2 = center + Vector2(radius * 0.72, -radius * 0.72)
		draw_circle(badge, 8.5, Color(Pal.INK, 0.92))
		draw_arc(badge, 8.5, 0.0, TAU, 24, Color(Pal.BRASS_HI if selected else Pal.BRASS_LO, alpha), 1.2, true)
		var small: Font = UITheme.display_font(700, 0)
		draw_string(small, badge + Vector2(-8.5, 4.0), hotkey, HORIZONTAL_ALIGNMENT_CENTER, 17.0, 11, Color(Pal.PARCHMENT, alpha))
	if text != "":
		var font: Font = UITheme.display_font(700, 1)
		var colour: Color = Pal.BRASS_HI if selected else (Pal.PARCHMENT if _hover else Pal.PARCH_DIM)
		draw_string(font, Vector2(0.0, diameter + 20.0), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color(colour, alpha))
