class_name Ornament
extends Control
## A thin brass rule with a small diamond at its middle: the interface's section divider.

@export var tint: Color = Pal.BRASS_LO


func _init() -> void:
	custom_minimum_size = Vector2(0, 14)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var middle: Vector2 = size * 0.5
	var gap: float = 11.0
	draw_line(Vector2(2, middle.y), Vector2(middle.x - gap, middle.y), tint, 1.4, true)
	draw_line(Vector2(middle.x + gap, middle.y), Vector2(size.x - 2, middle.y), tint, 1.4, true)
	var diamond := PackedVector2Array([middle + Vector2(0, -5), middle + Vector2(6, 0), middle + Vector2(0, 5), middle + Vector2(-6, 0)])
	draw_colored_polygon(diamond, Pal.BRASS)
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Pal.BRASS_HI, 1.0, true)
	for side: float in [-1.0, 1.0]:
		draw_circle(middle + Vector2(side * (gap - 3.0), 0), 1.6, tint)
