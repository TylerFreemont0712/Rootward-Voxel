extends Node2D
## Cached vector drawing: only the complete wheel's transform changes while loading.
var teeth: int = 36
var spokes: int = 6
var copper: bool = false
var _profile: PackedVector2Array

func setup(count: int, arms: int, warm: bool) -> void:
	teeth = count
	spokes = arms
	copper = warm
	_profile = GearGeometry.outline(teeth)
	queue_redraw()

func _draw() -> void:
	if _profile.is_empty(): return
	var radius: float = GearGeometry.pitch(teeth)
	var root: float = radius - GearGeometry.MODULE * 1.25
	var dark := Color("35291d")
	var body := Color("bd844c") if copper else Color("c7a461")
	var light := Color("edbe86") if copper else Color("f8dda0")
	draw_colored_polygon(_profile, body)
	var closed: PackedVector2Array = _profile.duplicate()
	closed.append(closed[0])
	draw_polyline(closed, dark, 2.5, true)
	draw_arc(Vector2.ZERO, root - 3, 0, TAU, 128, light, 2.5, true)
	draw_arc(Vector2.ZERO, root - 10, 0, TAU, 128, Color("7d6036"), 2, true)
	# Rounded web openings between substantial curved spokes.
	for spoke: int in range(spokes):
		var a: float = TAU * spoke / spokes
		var b: float = a + TAU / spokes
		var opening := PackedVector2Array()
		for step: int in range(9):
			opening.append(Vector2.from_angle(lerpf(a+.13,b-.13,step/8.0)) * root * .72)
		for step: int in range(8,-1,-1):
			opening.append(Vector2.from_angle(lerpf(a+.23,b-.23,step/8.0)) * root * .30)
		draw_colored_polygon(opening, Color("111d20"))
		var edge: PackedVector2Array = opening.duplicate()
		edge.append(edge[0])
		draw_polyline(edge, Color("694b30"), 2, true)
		var bolt: Vector2 = Vector2.from_angle(a) * root * .84
		draw_circle(bolt+Vector2(1,2), 3.2, dark)
		draw_circle(bolt, 2.5, light)
		draw_line(bolt-Vector2(1,1),bolt+Vector2(1,1),dark,1,true)
	# A turned shaft and split retaining collar remain readable as the spokes rotate.
	draw_circle(Vector2(2,3), root*.27, Color("58402b"))
	draw_circle(Vector2.ZERO, root*.26, Color("f4cd86"))
	draw_circle(Vector2.ZERO, root*.21, Color("7b5a36"))
	draw_circle(Vector2.ZERO, root*.16, Color("263d3f"))
	draw_arc(Vector2.ZERO,root*.13,-2.8,-.3,32,Color("90b7ae"),2,true)
	for angle: float in [-PI*.5, PI*.5]:
		var at: Vector2 = Vector2.from_angle(angle)*root*.22
		draw_line(at-Vector2(2,0),at+Vector2(2,0),dark,2,true)
