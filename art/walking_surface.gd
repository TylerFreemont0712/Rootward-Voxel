class_name WalkingSurface
extends RefCounted
## Presentation support only. Traversal remains the integer-cell rules in LabWorld.
## Tread heights come from the same geometry recipe as the visible stairs. A short
## lead-in raises the feet before each riser instead of cutting through its corner.

const FOOT_LEAD: float = 0.18
const CLEARANCE: float = 0.055


static func height(area: AreaDef, point: Vector2, entrances: Array[Dictionary]) -> float:
	var cell := Vector2i(floori(point.x + 0.5), floori(point.y + 0.5))
	var result: float = float(area.level_at(cell)) * TerrainBuilder.LEVEL_RISE
	for flight: Dictionary in area.stairs:
		var relative: Vector2 = point - Vector2(flight.at)
		var forward := Vector2(flight.dir)
		var along: float = relative.dot(forward)
		if absf(relative.cross(forward)) > 0.4 or along < -0.5 - FOOT_LEAD or along > 0.5:
			continue
		var base: float = float(flight.level) * TerrainBuilder.LEVEL_RISE
		var depth: float = 1.0 / float(TerrainBuilder.STAIR_STEPS)
		for index: int in range(TerrainBuilder.STAIR_STEPS):
			var edge: float = -0.5 + float(index) * depth
			if along < edge - FOOT_LEAD:
				break
			var rise: float = smoothstep(edge - FOOT_LEAD, edge - 0.005, along)
			result = maxf(result, base + (float(index) + rise) * depth * TerrainBuilder.LEVEL_RISE)
	for entry: Dictionary in entrances:
		var relative: Vector2 = (point - (entry.at as Vector2)).rotated(-deg_to_rad(float(AreaDef.FACINGS[entry.facing]))) / float(entry.scale)
		for tread: Array in entry.steps:
			# [front reach, back reach, width, top], in the asset's +Z/front frame.
			var outward: float = -relative.y
			if absf(relative.x) > float(tread[2]) * 0.5 or outward > float(tread[0]) + FOOT_LEAD or outward < float(tread[1]):
				continue
			var blend: float = 1.0 - smoothstep(float(tread[0]), float(tread[0]) + FOOT_LEAD, outward)
			result = maxf(result, float(entry.base) + float(tread[3]) * float(entry.scale) * blend)
	if not area.socket(cell).is_empty():
		result = maxf(result, float(area.level_at(cell)) * TerrainBuilder.LEVEL_RISE + 0.065)
	if not area.interior.is_empty():
		# The room's floor, rugs and exit mat are above the logical zero plane.
		result = maxf(result, 0.04)
		for item: Dictionary in area.interior.furniture:
			if item.kind == "rug" and Rect2(item.at - item.size * 0.5, item.size).has_point(point):
				result = maxf(result, 0.085)
		if point.distance_to(Vector2(float(area.interior.exit[0]), float(area.interior.exit[1]))) < 0.85:
			result = maxf(result, 0.11)
	return result + CLEARANCE
