class_name Toggle
extends Button
## A rune switch with a label: used for settings. Behaves like a CheckButton (toggled signal).

static func make(label: String, on: bool = false) -> Toggle:
	var toggle := Toggle.new()
	toggle.text = label
	toggle.toggle_mode = true
	toggle.button_pressed = on
	toggle.theme_type_variation = &"ButtonQuiet"
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggle.focus_mode = Control.FOCUS_ALL
	toggle.custom_minimum_size = Vector2(0, 40)
	return toggle


func _ready() -> void:
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		var box: StyleBox = get_theme_stylebox(state).duplicate()
		box.content_margin_left += 52.0
		add_theme_stylebox_override(state, box)
	toggled.connect(func(_on: bool) -> void: queue_redraw())


func _draw() -> void:
	var track := Rect2(Vector2(6, (size.y - 22.0) * 0.5), Vector2(40, 22))
	var lit: bool = button_pressed
	var fill: Color = Color("6b4f1e") if lit else Color("1a140e")
	draw_rect(track, fill, true)
	draw_rect(track, Pal.BRASS if lit else Pal.BRASS_LO, false, 1.5, true)
	var knob_x: float = track.end.x - 12.0 if lit else track.position.x + 12.0
	var center := Vector2(knob_x, track.position.y + 11.0)
	draw_circle(center, 8.0, Pal.BRASS_HI if lit else Color("8a7a5c"))
	draw_arc(center, 8.0, 0.0, TAU, 20, Color(0, 0, 0, 0.5), 1.2, true)
	if has_focus():
		draw_rect(Rect2(Vector2.ZERO, size).grow(-1.0), Color(Pal.BRASS_HI, 0.5), false, 1.5, true)
