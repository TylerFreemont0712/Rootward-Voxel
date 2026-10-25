class_name MapView
extends Control
## A small isometric chart of the valley, tilted like the real view so what you see here matches the
## screen. Places you have not visited stay dim. The base map is drawn once per change; the markers on
## top animate.

const TILE_X: float = 7.2
const TILE_Y: float = 3.6

var area: AreaDef
var state: Dictionary = {}
var quest_focus: Variant = null
var _markers: Control


func setup(definition: AreaDef) -> void:
	area = definition
	custom_minimum_size = Vector2((float(area.width + area.height) + 2.0) * TILE_X, (float(area.width + area.height) + 2.0) * TILE_Y)
	_markers = _MapMarkers.new()
	_markers.map = self
	UI.full_rect(_markers)
	add_child(_markers)


func refresh(new_state: Dictionary, focus: Variant) -> void:
	state = new_state
	quest_focus = focus
	queue_redraw()


## Screen position of a logical cell center (or fractional position) inside this control. Screen x grows
## with x + y and screen y with x - y, which is how the real camera sees the grid.
func project(at: Vector2) -> Vector2:
	return Vector2(TILE_X * (at.x + at.y + 1.0), TILE_Y * (at.x - at.y + float(area.height)))


func _draw() -> void:
	if area == null or state.is_empty():
		return
	var seen: Dictionary = {}
	for zone_id: Variant in state.zones_seen:
		seen[zone_id] = true
	for y: int in range(area.height):
		for x: int in range(area.width):
			var cell := Vector2i(x, y)
			var known: bool = seen.has(area.zone_at(cell))
			var tint: Color = _terrain_color(area.terrain_at(cell), cell)
			if not known:
				tint = tint.darkened(0.5).lerp(Color("241d16"), 0.45)
			var center: Vector2 = project(Vector2(x, y))
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -TILE_Y), center + Vector2(TILE_X, 0), center + Vector2(0, TILE_Y), center + Vector2(-TILE_X, 0)]), tint)
	for building: Dictionary in area.buildings:
		if seen.has(area.zone_at(Vector2i(roundi(building.at.x), roundi(building.at.y)))):
			var rect: Rect2 = building.rect
			var corners := PackedVector2Array([project(rect.position), project(Vector2(rect.end.x, rect.position.y)), project(rect.end), project(Vector2(rect.position.x, rect.end.y))])
			draw_colored_polygon(corners, Color("7a67b8") if building.asset != "mill-house" else Color("3d8f9a"))
			corners.append(corners[0])
			draw_polyline(corners, Color("efe3c8", 0.8), 1.2, true)
	for zone: Dictionary in area.zones:
		if seen.has(zone.id):
			var r: Rect2i = zone.rect
			var label_at: Vector2 = project(Vector2(r.position) + Vector2(r.size) * 0.5)
			var font: Font = UITheme.display_font(700, 1)
			var text: String = str(zone.title).to_upper()
			var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string(font, label_at + Vector2(-width * 0.5 + 1, 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0, 0, 0, 0.7))
			draw_string(font, label_at + Vector2(-width * 0.5, 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Pal.PARCHMENT)
	_compass()


func _compass() -> void:
	var base := Vector2(size.x - 70, 60)
	var north := Vector2(TILE_X, -TILE_Y).normalized() * 28.0
	draw_line(base - north * 0.4, base + north, Pal.BRASS, 2.0, true)
	draw_colored_polygon(PackedVector2Array([base + north + north.normalized() * 6.0, base + north + north.orthogonal().normalized() * 5.0, base + north - north.orthogonal().normalized() * 5.0]), Pal.BRASS_HI)
	draw_string(UITheme.display_font(700, 1), base + north + Vector2(8, -4), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Pal.BRASS_HI)


func _terrain_color(terrain: int, cell: Vector2i) -> Color:
	match terrain:
		AreaDef.Terrain.WATER:
			return Color("3f9fb0") if (cell.x + cell.y) % 2 == 0 else Color("4aaebd")
		AreaDef.Terrain.PATH:
			return Color("b0824f")
		AreaDef.Terrain.COBBLE:
			return Color("b9b09a")
		AreaDef.Terrain.ROCK:
			return Color("6d6f72")
	return Color("6c9a46") if (cell.x * 7 + cell.y * 3) % 5 != 0 else Color("66923f")


class _MapMarkers extends Control:
	var map: MapView

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if map == null or map.area == null or map.state.is_empty():
			return
		var area: AreaDef = map.area
		var seen: Dictionary = {}
		for zone_id: Variant in map.state.zones_seen:
			seen[zone_id] = true
		var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
		for bridge: Dictionary in area.bridges:
			if seen.has(bridge.zone):
				var built: int = int(map.state.bridges.get(bridge.id, 0))
				for index: int in range((bridge.sockets as Array).size()):
					var at: Vector2 = map.project(Vector2((bridge.sockets as Array)[index]))
					draw_rect(Rect2(at - Vector2(3, 2), Vector2(6, 4)), Color("c79a5d") if index < built else Color(0.85, 0.7, 0.4, 0.28), true)
		for gate: Dictionary in area.gates:
			if seen.has(gate.zone):
				var at: Vector2 = map.project(Vector2(gate.cell))
				var open: bool = map.state.gates.get(gate.id, false) == true
				draw_circle(at, 5.0, Color("97d474") if open else Color("e88a79"))
				draw_arc(at, 5.5, 0.0, TAU, 16, Color(0, 0, 0, 0.6), 1.2, true)
		for lamp: Dictionary in area.lamps:
			if not seen.has(lamp.zone):
				continue
			var at: Vector2 = map.project(lamp.at)
			var lit: bool = map.state.lamps.get(lamp.id, false) == true
			var radius: float = 5.0 if lamp.style == "beacon" else 3.4
			if lit:
				draw_circle(at, radius * 2.4, Color(1.0, 0.8, 0.35, 0.22))
			draw_circle(at, radius, Pal.BRASS_HI if lit else Color("2b2118"))
			draw_arc(at, radius, 0.0, TAU, 14, Pal.BRASS if lit else Color("8c7a5b"), 1.2, true)
		if map.quest_focus is Vector2:
			var focus: Vector2 = map.project(map.quest_focus)
			draw_arc(focus, 9.0 + pulse * 4.0, 0.0, TAU, 28, Color(Pal.GREEN, 0.9), 2.0, true)
			draw_circle(focus, 2.5, Pal.GREEN)
		var player: Vector2 = map.project(Vector2(float(map.state.player[0]), float(map.state.player[1])))
		draw_circle(player, 9.0 + pulse * 3.0, Color(1.0, 0.95, 0.7, 0.2))
		draw_colored_polygon(PackedVector2Array([player + Vector2(0, -8), player + Vector2(6, 0), player + Vector2(0, 8), player + Vector2(-6, 0)]), Color("ff7b4a"))
		draw_polyline(PackedVector2Array([player + Vector2(0, -8), player + Vector2(6, 0), player + Vector2(0, 8), player + Vector2(-6, 0), player + Vector2(0, -8)]), Color("fff3d0"), 1.6, true)
