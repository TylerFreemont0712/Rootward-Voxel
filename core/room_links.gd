class_name RoomLinks
extends RefCounted
## Plain authored room connections, stair boundaries and nearby inspection points.

static func find(area: AreaDef, id: String) -> Dictionary:
	for link: Dictionary in area.interior.get("links", []):
		if str(link.id) == id: return link
	return {}


## The cells a link is crossed from: its `cells` across a wide street or flight, or just `at`.
static func cells(link: Dictionary) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for raw: Variant in link.get("cells", [link.at]):
		found.append(Vector2i(int(raw[0]), int(raw[1])))
	return found


## Where crossing from `from` arrives: the matching entry of `arrivals`, or the link's one `arrival`.
static func arrival(link: Dictionary, from: Vector2i) -> Vector2i:
	var index: int = cells(link).find(from)
	var arrivals: Array = link.get("arrivals", [])
	var raw: Array = arrivals[index] if index >= 0 and index < arrivals.size() else link.arrival
	return Vector2i(int(raw[0]), int(raw[1]))


## The link cell nearest to `from` (by grid distance), for click-to-travel.
static func nearest_cell(link: Dictionary, from: Vector2i) -> Vector2i:
	var best: Vector2i = Vector2i(int(link.at[0]), int(link.at[1]))
	for cell: Vector2i in cells(link):
		if absi(cell.x - from.x) + absi(cell.y - from.y) < absi(best.x - from.x) + absi(best.y - from.y):
			best = cell
	return best


## The link in `area` that leads back to `from_area`, or {}.
static func back_to(area: AreaDef, from_area: String) -> Dictionary:
	for link: Dictionary in area.interior.get("links", []):
		if str(link.to) == from_area: return link
	return {}


static func crossing(area: AreaDef, state: Dictionary, direction: Vector2i) -> Dictionary:
	var player := Vector2i(int(state.player[0]), int(state.player[1]))
	for link: Dictionary in area.interior.get("links", []):
		if cells(link).has(player) and direction == AreaDef.STEPS[link.direction]: return link
	return {}


static func stair_edge(area: AreaDef, from: Vector2i, to: Vector2i) -> bool:
	for flight: Dictionary in area.interior.get("stair_flights", []):
		var r: Array = flight.rect
		var rect := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
		var on_from: bool = rect.has_point(Vector2(from))
		var on_to: bool = rect.has_point(Vector2(to))
		if on_from or on_to:
			var direction: Vector2i = AreaDef.STEPS[flight.up]
			if to - from != direction and to - from != -direction: return false
			# A flight is boarded and left at its foot. Its head is a room link, so walking on past the top, or
			# stepping up onto the top from the floor beyond it, is never a step.
			if on_to and not on_from and to - from != direction: return false
			if on_from and not on_to and to - from != -direction: return false
	return true


static func nearest(area: AreaDef, point: Vector2, field: String, radius: float = 1.6) -> Dictionary:
	var found: Dictionary = {}
	var distance: float = radius
	for item: Dictionary in area.interior.get(field, []):
		var at: Array = item.get("approach", item.at)
		var delta: float = point.distance_to(Vector2(float(at[0]), float(at[1])))
		if delta < distance:
			distance = delta
			found = item
	return found


static func restore(raw: Variant, allowed: Array) -> Dictionary:
	var restored: Dictionary = {}
	if not raw is Dictionary: return restored
	for id: Variant in allowed:
		var saved: Variant = raw.get(id)
		if saved is Dictionary and saved.get("area") == id and saved.get("state") is Dictionary:
			restored[id] = saved.duplicate(true)
			restored[id].erase("journey_rooms")
	return restored
