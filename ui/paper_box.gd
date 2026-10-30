class_name PaperBox
extends StyleBox
## The drawn surfaces of the paper-and-enamel interface, vector-only like FantasyBox:
## card (cream paper, soft blue shadow), ticket (pinned paper with a torn right edge), enamel (a rounded
## sign plate with two rivets, for buttons and plates), graph (paper ruled for code), tape (a ticker strip with
## sprocket holes) and tab (a notebook index tab).

@export var kind: StringName = &"card"
@export var fill: Color = PaperPal.PAPER
@export var rim: Color = PaperPal.EDGE
@export var rim_width: float = 1.0
@export var shadow: float = 3.0
@export var radius: float = 7.0
@export var rivets: bool = false
@export var pin: bool = false
@export var grid: float = 0.0


static func make(options: Dictionary = {}, padding: Vector2 = Vector2(16, 12)) -> PaperBox:
	var box := PaperBox.new()
	for key: String in options:
		box.set(key, options[key])
	box.set_content_margin(SIDE_LEFT, padding.x)
	box.set_content_margin(SIDE_RIGHT, padding.x + (14.0 if box.kind == &"ticket" else 0.0))
	box.set_content_margin(SIDE_TOP, padding.y + (4.0 if box.pin else 0.0))
	box.set_content_margin(SIDE_BOTTOM, padding.y + box.shadow)
	return box


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if rect.size.x < 4.0 or rect.size.y < 4.0:
		return
	var body := Rect2(rect.position, rect.size - Vector2(0, shadow))
	var r: float = minf(radius, minf(body.size.x, body.size.y) * 0.5)
	var outline: PackedVector2Array = _distinct(_torn(body) if kind == &"ticket" else _rounded(body, r))
	if shadow > 0.0:
		var under := PackedVector2Array()
		for point: Vector2 in outline:
			under.append(point + Vector2(1.0, shadow))
		RenderingServer.canvas_item_add_polygon(to_canvas_item, under, PackedColorArray([PaperPal.SHADOW]))
	RenderingServer.canvas_item_add_polygon(to_canvas_item, outline, PackedColorArray([fill]))
	if kind == &"enamel":
		# A lighter upper half reads as a domed enamel sign.
		var top := _distinct(_rounded(Rect2(body.position + Vector2(2, 2), Vector2(body.size.x - 4, body.size.y * 0.45)), minf(maxf(0.0, r - 2.0), body.size.y * 0.2)))
		RenderingServer.canvas_item_add_polygon(to_canvas_item, top, PackedColorArray([Color(1, 1, 1, 0.12)]))
	if grid > 0.0:
		var x: float = body.position.x + grid
		while x < body.end.x - 2.0:
			RenderingServer.canvas_item_add_line(to_canvas_item, Vector2(x, body.position.y + 3), Vector2(x, body.end.y - 3), PaperPal.GRID, 1.0)
			x += grid
		var y: float = body.position.y + grid
		while y < body.end.y - 2.0:
			RenderingServer.canvas_item_add_line(to_canvas_item, Vector2(body.position.x + 3, y), Vector2(body.end.x - 3, y), PaperPal.GRID, 1.0)
			y += grid
	if kind == &"tape":
		var hole_y: float = body.position.y + 5.0
		var step: float = 9.0
		var hx: float = body.position.x + 8.0
		while hx < body.end.x - 6.0:
			RenderingServer.canvas_item_add_circle(to_canvas_item, Vector2(hx, hole_y), 1.6, Color(PaperPal.INK, 0.28))
			hx += step
	if rim_width > 0.0 and rim.a > 0.0:
		var closed := outline.duplicate()
		closed.append(outline[0])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, closed, PackedColorArray([rim]), rim_width, true)
	if rivets and body.size.x > 40.0:
		for side: float in [0.0, 1.0]:
			var centre := Vector2(body.position.x + (r * 0.7 + 4.0 if side == 0.0 else body.size.x - r * 0.7 - 4.0), body.position.y + body.size.y * 0.5)
			RenderingServer.canvas_item_add_circle(to_canvas_item, centre, 3.4, Color(PaperPal.BRASS_LO, 0.9))
			RenderingServer.canvas_item_add_circle(to_canvas_item, centre, 2.5, PaperPal.BRASS)
			RenderingServer.canvas_item_add_circle(to_canvas_item, centre + Vector2(-0.6, -0.7), 0.9, PaperPal.BRASS_HI)
	if pin:
		var head := body.position + Vector2(18, 7)
		RenderingServer.canvas_item_add_circle(to_canvas_item, head + Vector2(1, 2), 6.0, PaperPal.SHADOW)
		RenderingServer.canvas_item_add_circle(to_canvas_item, head, 6.0, PaperPal.BRASS_LO)
		RenderingServer.canvas_item_add_circle(to_canvas_item, head, 4.8, PaperPal.BRASS)
		RenderingServer.canvas_item_add_circle(to_canvas_item, head + Vector2(-1.5, -1.5), 1.6, PaperPal.BRASS_HI)


func _rounded(rect: Rect2, r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if r <= 0.5:
		return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var corners: Array[Vector2] = [Vector2(rect.end.x - r, rect.position.y + r), Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r), Vector2(rect.position.x + r, rect.position.y + r)]
	var start: float = -PI * 0.5
	for i: int in range(4):
		for step: int in range(7):
			var angle: float = start + float(i) * PI * 0.5 + float(step) / 6.0 * PI * 0.5
			points.append(corners[i] + Vector2(cos(angle), sin(angle)) * r)
	return points


## Drops repeated corner points (a pill whose radius is half its height), which the triangulator rejects.
func _distinct(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in points:
		if result.is_empty() or result[-1].distance_squared_to(point) > 0.01:
			result.append(point)
	if result.size() > 2 and result[0].distance_squared_to(result[-1]) <= 0.01:
		result.remove_at(result.size() - 1)
	return result


## A paper ticket: square left side, a gently torn right edge.
func _torn(rect: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array([rect.position, Vector2(rect.end.x - 10.0, rect.position.y)])
	var teeth: int = maxi(3, int(rect.size.y / 9.0))
	for i: int in range(1, teeth):
		var y: float = rect.position.y + rect.size.y * float(i) / float(teeth)
		points.append(Vector2(rect.end.x - (10.0 if i % 2 == 0 else 2.0) - float((i * 7) % 4), y))
	points.append(Vector2(rect.end.x - 10.0, rect.end.y))
	points.append(Vector2(rect.position.x, rect.end.y))
	return points


func _get_draw_rect(rect: Rect2) -> Rect2:
	return rect.grow(3.0).expand(rect.end + Vector2(2.0, shadow + 2.0))
