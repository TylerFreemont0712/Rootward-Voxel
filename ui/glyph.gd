class_name Glyph
extends Control
## Small vector icons for buttons and labels, drawn with lines and polygons so they stay crisp and
## match the interface's brass-on-dark look. `paint` can draw onto any CanvasItem.

@export var kind: StringName = &"star":
	set(value):
		kind = value
		queue_redraw()
@export var color: Color = Pal.BRASS:
	set(value):
		color = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(22, 22)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	paint(self, kind, Rect2(Vector2.ZERO, size), color)


static func paint(canvas: CanvasItem, kind_name: StringName, rect: Rect2, tint: Color) -> void:
	var side: float = minf(rect.size.x, rect.size.y)
	var origin: Vector2 = rect.position + (rect.size - Vector2(side, side)) * 0.5
	var stroke: float = maxf(1.4, side * 0.095)
	var p := func(x: float, y: float) -> Vector2: return origin + Vector2(x, y) * side
	var dim: Color = Color(tint, tint.a * 0.35)
	match kind_name:
		&"play":
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.26, 0.16), p.call(0.8, 0.5), p.call(0.26, 0.84)]), tint)
		&"debug":
			# Run and debug: an open play triangle with a small bug at its lower left.
			canvas.draw_polyline(PackedVector2Array([p.call(0.42, 0.12), p.call(0.92, 0.44), p.call(0.42, 0.76), p.call(0.42, 0.12)]), tint, stroke, true)
			canvas.draw_circle(p.call(0.27, 0.69), side * 0.15, tint)
			canvas.draw_circle(p.call(0.27, 0.49), side * 0.07, tint)
			for leg: float in [0.6, 0.7, 0.8]:
				canvas.draw_line(p.call(0.14, leg), p.call(0.04, leg - 0.05 + (leg - 0.7) * 0.6), tint, stroke * 0.7, true)
				canvas.draw_line(p.call(0.40, leg), p.call(0.50, leg - 0.05 + (leg - 0.7) * 0.6), tint, stroke * 0.7, true)
		&"check":
			canvas.draw_polyline(PackedVector2Array([p.call(0.18, 0.54), p.call(0.4, 0.76), p.call(0.82, 0.26)]), tint, stroke * 1.2, true)
		&"cross":
			canvas.draw_line(p.call(0.24, 0.24), p.call(0.76, 0.76), tint, stroke * 1.15, true)
			canvas.draw_line(p.call(0.76, 0.24), p.call(0.24, 0.76), tint, stroke * 1.15, true)
		&"book":
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.08, 0.22), p.call(0.48, 0.3), p.call(0.48, 0.86), p.call(0.08, 0.78)]), dim)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.52, 0.3), p.call(0.92, 0.22), p.call(0.92, 0.78), p.call(0.52, 0.86)]), dim)
			canvas.draw_polyline(PackedVector2Array([p.call(0.08, 0.22), p.call(0.48, 0.3), p.call(0.52, 0.3), p.call(0.92, 0.22), p.call(0.92, 0.78), p.call(0.52, 0.86), p.call(0.48, 0.86), p.call(0.08, 0.78), p.call(0.08, 0.22)]), tint, stroke * 0.85, true)
			canvas.draw_line(p.call(0.5, 0.3), p.call(0.5, 0.86), tint, stroke * 0.8, true)
			canvas.draw_line(p.call(0.16, 0.42), p.call(0.4, 0.47), tint, stroke * 0.6, true)
			canvas.draw_line(p.call(0.16, 0.56), p.call(0.4, 0.61), tint, stroke * 0.6, true)
			canvas.draw_line(p.call(0.6, 0.47), p.call(0.84, 0.42), tint, stroke * 0.6, true)
			canvas.draw_line(p.call(0.6, 0.61), p.call(0.84, 0.56), tint, stroke * 0.6, true)
		&"scroll":
			canvas.draw_rect(Rect2(p.call(0.22, 0.2), Vector2(0.56, 0.6) * side), dim, true)
			canvas.draw_rect(Rect2(p.call(0.22, 0.2), Vector2(0.56, 0.6) * side), tint, false, stroke * 0.85)
			canvas.draw_arc(p.call(0.22, 0.2), side * 0.08, PI * 0.5, PI * 1.5, 8, tint, stroke * 0.85, true)
			canvas.draw_arc(p.call(0.78, 0.8), side * 0.08, -PI * 0.5, PI * 0.5, 8, tint, stroke * 0.85, true)
			for row: int in range(3):
				var y: float = 0.36 + 0.13 * float(row)
				canvas.draw_line(p.call(0.32, y), p.call(0.68 - 0.1 * float(row == 2), y), tint, stroke * 0.6, true)
		&"gear":
			var teeth := PackedVector2Array()
			for index: int in range(24):
				var angle: float = float(index) * TAU / 24.0
				var radius: float = 0.44 if (index / 2) % 2 == 0 else 0.33
				teeth.append(origin + Vector2(0.5, 0.5) * side + Vector2(cos(angle), sin(angle)) * radius * side)
			canvas.draw_colored_polygon(teeth, tint)
			canvas.draw_circle(origin + Vector2(0.5, 0.5) * side, side * 0.15, Pal.PANEL_LO)
		&"menu":
			for row: int in range(3):
				canvas.draw_line(p.call(0.2, 0.28 + 0.22 * float(row)), p.call(0.8, 0.28 + 0.22 * float(row)), tint, stroke * 1.1, true)
		&"undo":
			canvas.draw_arc(p.call(0.5, 0.56), side * 0.28, PI * 1.05, PI * 2.2, 16, tint, stroke * 1.1, true)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.1, 0.5), p.call(0.4, 0.5), p.call(0.25, 0.24)]), tint)
		&"reset":
			canvas.draw_arc(p.call(0.5, 0.5), side * 0.31, -PI * 0.25, PI * 1.45, 18, tint, stroke * 1.1, true)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.62, 0.08), p.call(0.88, 0.3), p.call(0.58, 0.34)]), tint)
		&"lamp":
			canvas.draw_line(p.call(0.5, 0.08), p.call(0.5, 0.2), tint, stroke * 0.8, true)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.3, 0.32), p.call(0.5, 0.18), p.call(0.7, 0.32)]), tint)
			canvas.draw_rect(Rect2(p.call(0.32, 0.34), Vector2(0.36, 0.4) * side), Color(tint, 0.9), true)
			canvas.draw_rect(Rect2(p.call(0.4, 0.42), Vector2(0.2, 0.24) * side), Pal.PANEL_LO, true)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.28, 0.76), p.call(0.72, 0.76), p.call(0.64, 0.86), p.call(0.36, 0.86)]), tint)
		&"lock":
			canvas.draw_arc(p.call(0.5, 0.4), side * 0.19, PI, TAU, 12, tint, stroke, true)
			canvas.draw_line(p.call(0.31, 0.4), p.call(0.31, 0.48), tint, stroke, true)
			canvas.draw_line(p.call(0.69, 0.4), p.call(0.69, 0.48), tint, stroke, true)
			canvas.draw_rect(Rect2(p.call(0.24, 0.46), Vector2(0.52, 0.38) * side), tint, true)
			canvas.draw_circle(p.call(0.5, 0.63), side * 0.05, Pal.PANEL_LO)
		&"star":
			var points := PackedVector2Array()
			for index: int in range(8):
				var angle: float = float(index) * TAU / 8.0 - PI * 0.5
				var radius: float = 0.44 if index % 2 == 0 else 0.15
				points.append(origin + Vector2(0.5, 0.5) * side + Vector2(cos(angle), sin(angle)) * radius * side)
			canvas.draw_colored_polygon(points, tint)
		&"ring":
			canvas.draw_arc(p.call(0.5, 0.5), side * 0.33, 0.0, TAU, 28, tint, stroke, true)
		&"dot":
			canvas.draw_circle(p.call(0.5, 0.5), side * 0.2, tint)
		&"chevron":
			canvas.draw_polyline(PackedVector2Array([p.call(0.36, 0.2), p.call(0.66, 0.5), p.call(0.36, 0.8)]), tint, stroke * 1.15, true)
		&"chevron_left":
			canvas.draw_polyline(PackedVector2Array([p.call(0.64, 0.2), p.call(0.34, 0.5), p.call(0.64, 0.8)]), tint, stroke * 1.15, true)
		&"chevron_down":
			canvas.draw_polyline(PackedVector2Array([p.call(0.2, 0.36), p.call(0.5, 0.66), p.call(0.8, 0.36)]), tint, stroke * 1.15, true)
		&"map":
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.1, 0.24), p.call(0.36, 0.16), p.call(0.36, 0.78), p.call(0.1, 0.86)]), dim)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.64, 0.22), p.call(0.9, 0.14), p.call(0.9, 0.76), p.call(0.64, 0.84)]), dim)
			canvas.draw_polyline(PackedVector2Array([p.call(0.1, 0.24), p.call(0.36, 0.16), p.call(0.64, 0.24), p.call(0.9, 0.14), p.call(0.9, 0.76), p.call(0.64, 0.84), p.call(0.36, 0.76), p.call(0.1, 0.86), p.call(0.1, 0.24)]), tint, stroke * 0.85, true)
			canvas.draw_line(p.call(0.36, 0.16), p.call(0.36, 0.76), tint, stroke * 0.7, true)
			canvas.draw_line(p.call(0.64, 0.24), p.call(0.64, 0.84), tint, stroke * 0.7, true)
		&"person":
			canvas.draw_circle(p.call(0.5, 0.32), side * 0.17, tint)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.18, 0.88), p.call(0.22, 0.62), p.call(0.36, 0.54), p.call(0.64, 0.54), p.call(0.78, 0.62), p.call(0.82, 0.88)]), tint)
		&"flame":
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.06), p.call(0.72, 0.36), p.call(0.78, 0.6), p.call(0.66, 0.84), p.call(0.5, 0.92), p.call(0.34, 0.84), p.call(0.22, 0.6), p.call(0.3, 0.4), p.call(0.42, 0.52), p.call(0.44, 0.3)]), tint)
		&"door":
			canvas.draw_polyline(PackedVector2Array([p.call(0.46, 0.14), p.call(0.16, 0.14), p.call(0.16, 0.86), p.call(0.46, 0.86)]), tint, stroke, true)
			canvas.draw_line(p.call(0.38, 0.5), p.call(0.84, 0.5), tint, stroke, true)
			canvas.draw_polyline(PackedVector2Array([p.call(0.66, 0.32), p.call(0.84, 0.5), p.call(0.66, 0.68)]), tint, stroke, true)
		&"plus":
			canvas.draw_line(p.call(0.5, 0.2), p.call(0.5, 0.8), tint, stroke * 1.15, true)
			canvas.draw_line(p.call(0.2, 0.5), p.call(0.8, 0.5), tint, stroke * 1.15, true)
		&"minus":
			canvas.draw_line(p.call(0.2, 0.5), p.call(0.8, 0.5), tint, stroke * 1.15, true)
		&"info":
			canvas.draw_arc(p.call(0.5, 0.5), side * 0.38, 0.0, TAU, 28, tint, stroke * 0.9, true)
			canvas.draw_circle(p.call(0.5, 0.31), side * 0.055, tint)
			canvas.draw_line(p.call(0.5, 0.45), p.call(0.5, 0.72), tint, stroke * 1.1, true)
		&"warning":
			canvas.draw_polyline(PackedVector2Array([p.call(0.5, 0.12), p.call(0.9, 0.84), p.call(0.1, 0.84), p.call(0.5, 0.12)]), tint, stroke * 0.9, true)
			canvas.draw_line(p.call(0.5, 0.38), p.call(0.5, 0.62), tint, stroke, true)
			canvas.draw_circle(p.call(0.5, 0.73), side * 0.04, tint)
		&"bridge":
			canvas.draw_arc(p.call(0.5, 0.95), side * 0.45, PI * 1.12, PI * 1.88, 16, tint, stroke, true)
			canvas.draw_line(p.call(0.06, 0.52), p.call(0.94, 0.52), tint, stroke, true)
			for post: float in [0.2, 0.5, 0.8]:
				canvas.draw_line(p.call(post, 0.34), p.call(post, 0.52), tint, stroke * 0.8, true)
		&"gate":
			canvas.draw_rect(Rect2(p.call(0.12, 0.2), Vector2(0.14, 0.64) * side), tint, true)
			canvas.draw_rect(Rect2(p.call(0.74, 0.2), Vector2(0.14, 0.64) * side), tint, true)
			for slat: float in [0.36, 0.5, 0.64]:
				canvas.draw_line(p.call(slat, 0.3), p.call(slat, 0.84), tint, stroke * 0.8, true)
			canvas.draw_line(p.call(0.26, 0.42), p.call(0.74, 0.42), tint, stroke * 0.7, true)
		&"sparkle":
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.05), p.call(0.6, 0.4), p.call(0.95, 0.5), p.call(0.6, 0.6), p.call(0.5, 0.95), p.call(0.4, 0.6), p.call(0.05, 0.5), p.call(0.4, 0.4)]), tint)
		&"keys":
			canvas.draw_rect(Rect2(p.call(0.08, 0.28), Vector2(0.84, 0.46) * side), dim, true)
			canvas.draw_rect(Rect2(p.call(0.08, 0.28), Vector2(0.84, 0.46) * side), tint, false, stroke * 0.8)
			for column: int in range(4):
				canvas.draw_rect(Rect2(p.call(0.18 + 0.19 * float(column), 0.38), Vector2(0.11, 0.09) * side), tint, true)
			canvas.draw_rect(Rect2(p.call(0.3, 0.56), Vector2(0.4, 0.09) * side), tint, true)
		&"eraser":
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.12, 0.62), p.call(0.58, 0.16), p.call(0.9, 0.48), p.call(0.54, 0.84), p.call(0.34, 0.84)]), tint)
			canvas.draw_line(p.call(0.34, 0.4), p.call(0.67, 0.72), Pal.PANEL_LO, stroke * 0.7, true)
			canvas.draw_line(p.call(0.14, 0.9), p.call(0.9, 0.9), tint, stroke * 0.65, true)
		&"brush":
			canvas.draw_line(p.call(0.42, 0.56), p.call(0.84, 0.12), tint, stroke * 1.1, true)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.18, 0.6), p.call(0.38, 0.48), p.call(0.55, 0.66), p.call(0.42, 0.84), p.call(0.1, 0.92)]), tint)
			canvas.draw_line(p.call(0.24, 0.64), p.call(0.43, 0.81), dim, stroke * 0.7, true)
		&"hammer":
			canvas.draw_line(p.call(0.22, 0.88), p.call(0.6, 0.44), tint, stroke * 1.5, true)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.4, 0.28), p.call(0.66, 0.08), p.call(0.92, 0.3), p.call(0.66, 0.5)]), tint)
			canvas.draw_line(p.call(0.5, 0.2), p.call(0.8, 0.4), Color(0, 0, 0, 0.35), stroke * 0.5, true)
		&"house":
			canvas.draw_rect(Rect2(p.call(0.22, 0.46), Vector2(0.56, 0.4) * side), dim, true)
			canvas.draw_rect(Rect2(p.call(0.22, 0.46), Vector2(0.56, 0.4) * side), tint, false, stroke * 0.85)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.1, 0.5), p.call(0.5, 0.14), p.call(0.9, 0.5)]), tint)
			canvas.draw_rect(Rect2(p.call(0.43, 0.6), Vector2(0.14, 0.26) * side), Pal.PANEL_LO, true)
			canvas.draw_rect(Rect2(p.call(0.66, 0.16), Vector2(0.09, 0.2) * side), tint, true)
		&"tree":
			canvas.draw_rect(Rect2(p.call(0.44, 0.6), Vector2(0.12, 0.3) * side), tint, true)
			canvas.draw_circle(p.call(0.5, 0.36), side * 0.27, tint)
			canvas.draw_circle(p.call(0.3, 0.5), side * 0.17, tint)
			canvas.draw_circle(p.call(0.7, 0.5), side * 0.17, tint)
			canvas.draw_circle(p.call(0.44, 0.3), side * 0.07, Color(1, 1, 1, 0.22))
		&"move":
			canvas.draw_line(p.call(0.5, 0.16), p.call(0.5, 0.84), tint, stroke, true)
			canvas.draw_line(p.call(0.16, 0.5), p.call(0.84, 0.5), tint, stroke, true)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.04), p.call(0.38, 0.22), p.call(0.62, 0.22)]), tint)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.96), p.call(0.38, 0.78), p.call(0.62, 0.78)]), tint)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.04, 0.5), p.call(0.22, 0.38), p.call(0.22, 0.62)]), tint)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.96, 0.5), p.call(0.78, 0.38), p.call(0.78, 0.62)]), tint)
		&"trash":
			canvas.draw_line(p.call(0.16, 0.26), p.call(0.84, 0.26), tint, stroke * 1.1, true)
			canvas.draw_polyline(PackedVector2Array([p.call(0.38, 0.26), p.call(0.38, 0.14), p.call(0.62, 0.14), p.call(0.62, 0.26)]), tint, stroke * 0.9, true)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.24, 0.32), p.call(0.76, 0.32), p.call(0.7, 0.9), p.call(0.3, 0.9)]), dim)
			canvas.draw_polyline(PackedVector2Array([p.call(0.24, 0.32), p.call(0.76, 0.32), p.call(0.7, 0.9), p.call(0.3, 0.9), p.call(0.24, 0.32)]), tint, stroke * 0.9, true)
			for x: float in [0.42, 0.5, 0.58]:
				canvas.draw_line(p.call(x, 0.44), p.call(x, 0.78), tint, stroke * 0.55, true)
		&"redo":
			canvas.draw_arc(p.call(0.5, 0.56), side * 0.28, -PI * 1.2, -PI * 0.05, 16, tint, stroke * 1.1, true)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.9, 0.5), p.call(0.6, 0.5), p.call(0.75, 0.24)]), tint)
		&"rotate":
			canvas.draw_arc(p.call(0.5, 0.5), side * 0.3, PI * 0.15, PI * 1.55, 18, tint, stroke * 1.1, true)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.1, 0.46), p.call(0.4, 0.5), p.call(0.22, 0.74)]), tint)
			canvas.draw_rect(Rect2(p.call(0.4, 0.4), Vector2(0.2, 0.2) * side), dim, true)
		&"grid":
			for step: float in [0.3, 0.5, 0.7]:
				canvas.draw_line(p.call(step, 0.14), p.call(step, 0.86), tint, stroke * 0.7, true)
				canvas.draw_line(p.call(0.14, step), p.call(0.86, step), tint, stroke * 0.7, true)
		&"cube":
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.1), p.call(0.88, 0.3), p.call(0.5, 0.5), p.call(0.12, 0.3)]), tint)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.12, 0.3), p.call(0.5, 0.5), p.call(0.5, 0.92), p.call(0.12, 0.72)]), dim)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.5), p.call(0.88, 0.3), p.call(0.88, 0.72), p.call(0.5, 0.92)]), Color(tint, tint.a * 0.62))
			canvas.draw_polyline(PackedVector2Array([p.call(0.12, 0.3), p.call(0.12, 0.72), p.call(0.5, 0.92), p.call(0.88, 0.72), p.call(0.88, 0.3)]), tint, stroke * 0.8, true)
		&"land":
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.04, 0.66), p.call(0.3, 0.3), p.call(0.44, 0.46), p.call(0.64, 0.18), p.call(0.96, 0.66)]), tint)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.56, 0.3), p.call(0.64, 0.18), p.call(0.72, 0.3), p.call(0.64, 0.27)]), Color(1, 1, 1, 0.3))
			var wave := PackedVector2Array()
			for step: int in range(13):
				var x: float = 0.08 + 0.84 * float(step) / 12.0
				wave.append(p.call(x, 0.82 + 0.05 * sin(float(step) * PI / 3.0)))
			canvas.draw_polyline(wave, tint, stroke * 0.85, true)
		&"raise", &"lower":
			# A terrace block with an arrow over it: up for raising the land, down for lowering it.
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.12, 0.62), p.call(0.5, 0.46), p.call(0.88, 0.62), p.call(0.5, 0.78)]), tint)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.12, 0.62), p.call(0.5, 0.78), p.call(0.5, 0.94), p.call(0.12, 0.8)]), dim)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.78), p.call(0.88, 0.62), p.call(0.88, 0.8), p.call(0.5, 0.94)]), Color(tint, tint.a * 0.62))
			var tip_y: float = 0.06 if kind_name == &"raise" else 0.42
			var tail_y: float = 0.4 if kind_name == &"raise" else 0.06
			canvas.draw_line(p.call(0.5, tail_y), p.call(0.5, (tip_y + tail_y) * 0.5 + (0.04 if kind_name == &"raise" else -0.04)), tint, stroke * 1.1, true)
			var wing: float = 0.13 if kind_name == &"raise" else -0.13
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.5, tip_y), p.call(0.36, tip_y + wing), p.call(0.64, tip_y + wing)]), tint)
		&"hand":
			# An open hand reaching to use something: four fingers, a thumb and a palm.
			for finger: int in range(4):
				var x: float = 0.3 + float(finger) * 0.12
				var top: float = [0.26, 0.16, 0.18, 0.28][finger]
				canvas.draw_line(p.call(x, top), p.call(x, 0.56), tint, side * 0.1, true)
				canvas.draw_circle(p.call(x, top), side * 0.05, tint)
			canvas.draw_line(p.call(0.2, 0.5), p.call(0.3, 0.68), tint, side * 0.1, true)
			canvas.draw_circle(p.call(0.2, 0.5), side * 0.05, tint)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.25, 0.52), p.call(0.71, 0.52), p.call(0.69, 0.78), p.call(0.55, 0.9), p.call(0.38, 0.9), p.call(0.27, 0.74)]), tint)
		&"stairs":
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.1, 0.88), p.call(0.1, 0.7), p.call(0.3, 0.7), p.call(0.3, 0.52), p.call(0.5, 0.52), p.call(0.5, 0.34), p.call(0.7, 0.34), p.call(0.7, 0.16), p.call(0.9, 0.16), p.call(0.9, 0.88)]), dim)
			canvas.draw_polyline(PackedVector2Array([p.call(0.1, 0.88), p.call(0.1, 0.7), p.call(0.3, 0.7), p.call(0.3, 0.52), p.call(0.5, 0.52), p.call(0.5, 0.34), p.call(0.7, 0.34), p.call(0.7, 0.16), p.call(0.9, 0.16)]), tint, stroke, true)
		&"water":
			var drop := PackedVector2Array([p.call(0.5, 0.08)])
			for step: int in range(13):
				var angle: float = lerpf(-0.15 * PI, 1.15 * PI, float(step) / 12.0)
				drop.append(p.call(0.5 + cos(angle) * 0.26, 0.62 + sin(angle) * 0.26))
			canvas.draw_colored_polygon(drop, tint)
			canvas.draw_arc(p.call(0.5, 0.62), side * 0.15, PI * 0.55, PI * 0.95, 6, Color(1, 1, 1, 0.35), stroke * 0.7, true)
		&"fill":
			var ripple := PackedVector2Array()
			for step: int in range(13):
				var x: float = 0.08 + 0.84 * float(step) / 12.0
				ripple.append(p.call(x, 0.82 + 0.05 * sin(float(step) * PI / 3.0)))
			canvas.draw_polyline(ripple, dim, stroke * 0.85, true)
			canvas.draw_colored_polygon(PackedVector2Array([p.call(0.14, 0.7), p.call(0.3, 0.36), p.call(0.5, 0.26), p.call(0.7, 0.36), p.call(0.86, 0.7)]), tint)
			canvas.draw_line(p.call(0.3, 0.36), p.call(0.5, 0.26), Color(1, 1, 1, 0.3), stroke * 0.6, true)
		&"code":
			canvas.draw_polyline(PackedVector2Array([p.call(0.32, 0.26), p.call(0.1, 0.5), p.call(0.32, 0.74)]), tint, stroke * 1.1, true)
			canvas.draw_polyline(PackedVector2Array([p.call(0.68, 0.26), p.call(0.9, 0.5), p.call(0.68, 0.74)]), tint, stroke * 1.1, true)
			canvas.draw_line(p.call(0.58, 0.18), p.call(0.42, 0.82), tint, stroke * 0.9, true)
		&"turn_left", &"turn_right":
			# A curved arrow round a little floor tile: turn the thing on it.
			var mirror: float = -1.0 if kind_name == &"turn_left" else 1.0
			var q := func(x: float, y: float) -> Vector2: return p.call(0.5 + (x - 0.5) * mirror, y)
			canvas.draw_colored_polygon(PackedVector2Array([q.call(0.5, 0.5), q.call(0.68, 0.59), q.call(0.5, 0.68), q.call(0.32, 0.59)]), dim)
			var arc := PackedVector2Array()
			var last: float = PI * 2.04
			for step: int in range(15):
				var angle: float = lerpf(PI * 0.95, last, float(step) / 14.0)
				arc.append(q.call(0.5 + cos(angle) * 0.34, 0.52 + sin(angle) * 0.3))
			canvas.draw_polyline(arc, tint, stroke * 1.05, true)
			var end := Vector2(0.5 + cos(last) * 0.34, 0.52 + sin(last) * 0.3)
			var along := Vector2(-sin(last) * 0.34, cos(last) * 0.3).normalized()
			var across := Vector2(-along.y, along.x)
			var tip: Vector2 = end + along * 0.17
			var left: Vector2 = end + across * 0.12
			var right: Vector2 = end - across * 0.12
			canvas.draw_colored_polygon(PackedVector2Array([q.call(tip.x, tip.y), q.call(left.x, left.y), q.call(right.x, right.y)]), tint)
		_:
			canvas.draw_circle(p.call(0.5, 0.5), side * 0.2, tint)
