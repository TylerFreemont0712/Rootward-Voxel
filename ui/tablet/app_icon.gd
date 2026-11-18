class_name AppIcon
extends Button
## A home-screen app: a rounded coloured tile with a glyph, and its name beneath. Keyboard-focusable.

var glyph: StringName = &"code"
var tint: Color = Pal.TEAL
var caption: String = ""
var badge: String = ""

const TILE: float = 82.0


static func make(label: String, icon: StringName, color: Color, action: Callable) -> AppIcon:
	var node := AppIcon.new()
	node.caption = label
	node.glyph = icon
	node.tint = color
	node.custom_minimum_size = Vector2(TILE + 36.0, TILE + 34.0)
	node.focus_mode = Control.FOCUS_ALL
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		node.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	node.pressed.connect(action)
	node.mouse_entered.connect(node.queue_redraw)
	node.mouse_exited.connect(node.queue_redraw)
	node.focus_entered.connect(node.queue_redraw)
	node.focus_exited.connect(node.queue_redraw)
	return node


func _draw() -> void:
	var tile := Rect2(Vector2((size.x - TILE) * 0.5, 2.0), Vector2(TILE, TILE))
	var hot: bool = is_hovered() or has_focus()
	var box := StyleBoxFlat.new()
	box.bg_color = tint.lerp(Color.WHITE, 0.12 if hot else 0.0)
	box.set_corner_radius_all(20)
	box.shadow_color = Color(0, 0, 0, 0.45)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 3)
	draw_style_box(box, tile)
	# A glossy upper half, like a pressed enamel key.
	var gloss := StyleBoxFlat.new()
	gloss.bg_color = Color(1, 1, 1, 0.10)
	gloss.set_corner_radius_all(20)
	gloss.corner_radius_bottom_left = 0
	gloss.corner_radius_bottom_right = 0
	draw_style_box(gloss, Rect2(tile.position, Vector2(tile.size.x, tile.size.y * 0.5)))
	if has_focus():
		var ring := StyleBoxFlat.new()
		ring.draw_center = false
		ring.border_color = Pal.PARCHMENT
		ring.set_border_width_all(2)
		ring.set_corner_radius_all(23)
		draw_style_box(ring, tile.grow(3.0))
	var glyph_size: float = 40.0
	Glyph.paint(self, glyph, Rect2(tile.get_center() - Vector2(glyph_size, glyph_size) * 0.5, Vector2(glyph_size, glyph_size)), Color("f6f1e4"))
	if badge != "":
		var font: Font = UITheme.body_font(700)
		var width: float = font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12.0
		var at := Rect2(tile.end.x - width + 8.0, tile.position.y - 6.0, width, 20.0)
		var pill := StyleBoxFlat.new()
		pill.bg_color = Pal.RED
		pill.set_corner_radius_all(10)
		draw_style_box(pill, at)
		draw_string(font, at.position + Vector2(6.0, 14.0), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	var label_font: Font = UITheme.body_font(500)
	var label_width: float = label_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(label_font, Vector2((size.x - label_width) * 0.5, tile.end.y + 20.0), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e8e2d2") if hot else Color("c9c2b2"))
