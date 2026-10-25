class_name FButton
extends Button
## A plaque button with an optional vector icon at its left edge. The theme variation decides the look.

var glyph: StringName = &""
var _glyph_space: float = 0.0


static func make(label: String, icon: StringName = &"", variation: StringName = &"") -> FButton:
	var button := FButton.new()
	button.text = label
	button.glyph = icon
	button.theme_type_variation = variation
	button.custom_minimum_size.y = 46
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	if glyph != &"":
		_glyph_space = 34.0 if text != "" else 0.0
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
			var box: StyleBox = get_theme_stylebox(state).duplicate()
			if text != "":
				box.content_margin_left += _glyph_space
				alignment = HORIZONTAL_ALIGNMENT_LEFT
			add_theme_stylebox_override(state, box)
	toggled.connect(func(_on: bool) -> void: queue_redraw())


func _draw() -> void:
	if glyph == &"":
		return
	var tint: Color = get_theme_color("font_color")
	if disabled:
		tint = get_theme_color("font_disabled_color")
	elif button_pressed and toggle_mode:
		tint = get_theme_color("font_pressed_color")
	elif is_hovered():
		tint = get_theme_color("font_hover_color")
	var box: StyleBox = get_theme_stylebox("normal")
	var icon_size: float = clampf(size.y - 24.0, 16.0, 26.0)
	if text == "":
		Glyph.paint(self, glyph, Rect2((size - Vector2(icon_size, icon_size)) * 0.5, Vector2(icon_size, icon_size)), tint)
	else:
		var left: float = box.content_margin_left - _glyph_space + 2.0
		Glyph.paint(self, glyph, Rect2(Vector2(left, (size.y - icon_size) * 0.5), Vector2(icon_size, icon_size)), tint)
