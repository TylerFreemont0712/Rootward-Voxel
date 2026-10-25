class_name FantasyBox
extends StyleBox
## A drawn plaque: chamfered corners, a vertical gradient fill, a brass border with an inner hairline,
## optional corner rivets and a soft drop shadow. Vector-drawn, so it is crisp at any UI scale and needs
## no texture files. Content margins make room for the trim.

@export var fill_top: Color = Pal.PANEL_HI
@export var fill_bottom: Color = Pal.PANEL
@export var border: Color = Pal.BRASS_LO
@export var border_width: float = 1.5
@export var inner_line: Color = Color(0.95, 0.8, 0.45, 0.16)
@export var chamfer: float = 9.0
@export var studs: bool = false
@export var stud_color: Color = Pal.BRASS
@export var shadow: float = 0.0
@export var glow: Color = Color(0, 0, 0, 0)
@export var bevel: float = 0.12


static func make(options: Dictionary = {}, padding: Vector2 = Vector2(18, 12)) -> FantasyBox:
	var box := FantasyBox.new()
	for key: String in options:
		box.set(key, options[key])
	box.set_content_margin(SIDE_LEFT, padding.x)
	box.set_content_margin(SIDE_RIGHT, padding.x)
	box.set_content_margin(SIDE_TOP, padding.y)
	box.set_content_margin(SIDE_BOTTOM, padding.y)
	return box


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if rect.size.x < 4.0 or rect.size.y < 4.0:
		return
	var body: Rect2 = Rect2(rect.position, rect.size - Vector2(0, shadow))
	var c: float = minf(chamfer, minf(body.size.x, body.size.y) * 0.5)
	if shadow > 0.0:
		var offset := PackedVector2Array()
		for point: Vector2 in _octagon(Rect2(rect.position + Vector2(1, shadow), body.size), c):
			offset.append(point)
		RenderingServer.canvas_item_add_polygon(to_canvas_item, offset, PackedColorArray([Pal.SHADOW]))
	if glow.a > 0.0:
		var halo := _octagon(body.grow(3.0), c + 2.0)
		RenderingServer.canvas_item_add_polygon(to_canvas_item, halo, PackedColorArray([glow]))
	var outline: PackedVector2Array = _octagon(body.grow(-border_width * 0.5), c)
	var colors := PackedColorArray()
	for point: Vector2 in outline:
		colors.append(fill_top.lerp(fill_bottom, clampf((point.y - body.position.y) / maxf(1.0, body.size.y), 0.0, 1.0)))
	RenderingServer.canvas_item_add_polygon(to_canvas_item, outline, colors)
	if bevel > 0.0:
		var top: float = body.position.y + border_width + 1.0
		RenderingServer.canvas_item_add_line(to_canvas_item, Vector2(body.position.x + c + 2.0, top), Vector2(body.end.x - c - 2.0, top),
			Color(1, 1, 1, bevel), 1.0)
	var closed := outline.duplicate()
	closed.append(outline[0])
	RenderingServer.canvas_item_add_polyline(to_canvas_item, closed, PackedColorArray([border]), border_width, true)
	if inner_line.a > 0.0 and body.size.x > 18.0 and body.size.y > 18.0:
		var gap: float = border_width + 2.5
		var inner: PackedVector2Array = _octagon(body.grow(-gap), maxf(0.0, c - 3.0))
		inner.append(inner[0])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, inner, PackedColorArray([inner_line]), 1.0, true)
	if studs and c >= 5.0:
		for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
			var anchor: Vector2 = body.position + body.size * corner
			var inward := Vector2(1.0 - 2.0 * corner.x, 1.0 - 2.0 * corner.y)
			var center: Vector2 = anchor + inward * c * 0.48
			RenderingServer.canvas_item_add_circle(to_canvas_item, center, 2.6, Color(0, 0, 0, 0.5))
			RenderingServer.canvas_item_add_circle(to_canvas_item, center, 1.9, stud_color)
			RenderingServer.canvas_item_add_circle(to_canvas_item, center + Vector2(-0.4, -0.5), 0.7, Pal.BRASS_HI)


func _octagon(rect: Rect2, c: float) -> PackedVector2Array:
	var x0: float = rect.position.x
	var y0: float = rect.position.y
	var x1: float = rect.end.x
	var y1: float = rect.end.y
	return PackedVector2Array([
		Vector2(x0 + c, y0), Vector2(x1 - c, y0), Vector2(x1, y0 + c), Vector2(x1, y1 - c),
		Vector2(x1 - c, y1), Vector2(x0 + c, y1), Vector2(x0, y1 - c), Vector2(x0, y0 + c),
	])


func _get_draw_rect(rect: Rect2) -> Rect2:
	return rect.grow(4.0).expand(rect.end + Vector2(0, shadow + 2.0))
