class_name HomeKey
extends Button
## The slate's one physical key, under the glass: a quiet round button with a square mark, learned
## rather than labelled, like a phone's home button. Pressing it goes to the home screen.

const DIAMETER: float = 46.0


static func make(action: Callable) -> HomeKey:
	var key := HomeKey.new()
	key.custom_minimum_size = Vector2(DIAMETER, DIAMETER)
	key.focus_mode = Control.FOCUS_ALL
	key.tooltip_text = "Home"
	key.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		key.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	key.pressed.connect(action)
	key.mouse_entered.connect(key.queue_redraw)
	key.mouse_exited.connect(key.queue_redraw)
	key.focus_entered.connect(key.queue_redraw)
	key.focus_exited.connect(key.queue_redraw)
	return key


func _draw() -> void:
	var centre: Vector2 = size * 0.5
	var radius: float = DIAMETER * 0.5
	var hot: bool = is_hovered() or has_focus()
	draw_circle(centre + Vector2(0, 1.5), radius, Color(0, 0, 0, 0.25))
	draw_circle(centre, radius, Color("e9dfc6") if not hot else Color("f3ead5"))
	draw_arc(centre, radius - 0.5, 0.0, TAU, 48, Color("8c6a2c") if hot else Color("b9a98a"), 1.5, true)
	var mark := Rect2(centre - Vector2(9, 9), Vector2(18, 18))
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = Color("8c6a2c") if hot else Color("a89676")
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	draw_style_box(box, mark)
