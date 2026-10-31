class_name GhostBox
extends StyleBox
## The frame of a proposal bubble: translucent ice-blue glass, a dashed blue outline whose dashes slowly march, and a
## glow that breathes. The dashes mean it still reads without colour. Speech that has really happened is solid paper
## (`PaperBox`); a Test is this. The owner advances `phase` and redraws.

const DASH: float = 10.0
const GAP: float = 6.0

@export var phase: float = 0.0
@export var radius: float = 9.0


static func make(padding: Vector2 = Vector2(15, 12)) -> GhostBox:
	var box := GhostBox.new()
	box.set_content_margin(SIDE_LEFT, padding.x)
	box.set_content_margin(SIDE_RIGHT, padding.x)
	box.set_content_margin(SIDE_TOP, padding.y)
	box.set_content_margin(SIDE_BOTTOM, padding.y)
	return box


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if rect.size.x < 8.0 or rect.size.y < 8.0:
		return
	var body: Rect2 = rect.grow(-2.0)
	var ring: PackedVector2Array = _rounded(body, minf(radius, minf(body.size.x, body.size.y) * 0.5))
	RenderingServer.canvas_item_add_polygon(to_canvas_item, ring, PackedColorArray([Color(PaperPal.GHOST_FILL, 0.88)]))
	var breath: float = 0.6 + 0.4 * sin(phase * 2.4)
	var closed: PackedVector2Array = ring.duplicate()
	closed.append(ring[0])
	for glow: Array in [[9.0, 0.05], [6.0, 0.09], [3.5, 0.15]]:
		RenderingServer.canvas_item_add_polyline(to_canvas_item, closed, PackedColorArray([Color(PaperPal.GHOST, float(glow[1]) * breath)]), float(glow[0]), true)
	var samples: PackedVector2Array = _resample(closed, 2.0)
	var offset: float = phase * 14.0
	var run := PackedVector2Array()
	for index: int in range(samples.size()):
		var on: bool = fposmod(float(index) * 2.0 + offset, DASH + GAP) < DASH
		if on:
			run.append(samples[index])
		elif run.size() > 1:
			RenderingServer.canvas_item_add_polyline(to_canvas_item, run, PackedColorArray([PaperPal.GHOST]), 2.0, true)
			run = PackedVector2Array()
		else:
			run = PackedVector2Array()
	if run.size() > 1:
		RenderingServer.canvas_item_add_polyline(to_canvas_item, run, PackedColorArray([PaperPal.GHOST]), 2.0, true)


func _rounded(rect: Rect2, r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var centres: Array[Vector2] = [
		rect.position + Vector2(r, r),
		Vector2(rect.end.x - r, rect.position.y + r),
		rect.end - Vector2(r, r),
		Vector2(rect.position.x + r, rect.end.y - r),
	]
	for corner: int in range(4):
		for step: int in range(7):
			var angle: float = PI + float(corner) * PI * 0.5 + float(step) / 6.0 * PI * 0.5
			points.append(centres[corner] + Vector2(cos(angle), sin(angle)) * r)
	return points


## Points every `spacing` pixels along a polyline, so dashes can be cut by distance.
func _resample(line: PackedVector2Array, spacing: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var next: float = 0.0
	var walked: float = 0.0
	for index: int in range(line.size() - 1):
		var from: Vector2 = line[index]
		var to: Vector2 = line[index + 1]
		var length: float = from.distance_to(to)
		while next <= walked + length:
			out.append(from.lerp(to, (next - walked) / length) if length > 0.0 else from)
			next += spacing
		walked += length
	return out
