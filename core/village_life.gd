class_name VillageLife
extends RefCounted
## Deterministic ambient movement over ordinary passages. Phantoms reserve space against residents/robots,
## while the player can pass through them. Timed passengers share the visible tram's timetable.

const STEP: float = 0.42


static func initial(area: AreaDef) -> Dictionary:
	var result: Dictionary = {}
	for villager: Dictionary in area.villagers:
		var at: Vector2i = villager.at
		var seed: int = absi(str(villager.id).hash())
		result[villager.id] = {"at": at, "from": at, "to": at, "phase": 1.0, "pause": 0.7 + float(seed % 29) / 10.0,
			"goal": seed % maxi(1, villager.route.size()) if villager.get("wander", false) else 0,
			"seed": seed, "path": [] as Array[Vector2i], "clock": 0.0, "cycle": -1,
			"active": not villager.has("arrival"), "player_solid": not villager.has("phantom"),
			"presence": 0.0 if villager.has("arrival") else 1.0, "age": 0.0, "fading": -1.0}
	return result


static func clock(residents: Dictionary) -> float:
	return float(residents.values()[0].clock) if not residents.is_empty() else 0.0


## Leave doorways, their walk-through arrivals, stairs and code access clear. These are map data, not visuals.
static func reserved(area: AreaDef) -> Dictionary:
	var result: Dictionary = {area.spawn: true}
	for link: Dictionary in area.interior.get("links", []):
		var points: Array = link.get("cells", [link.at]).duplicate()
		points.append(link.get("approach", link.at))
		for point: Array in points:
			var at := Vector2i(int(point[0]), int(point[1]))
			result[at] = true
			# A returning traveller walks against the exit direction, on into this area.
			for distance: int in range(1, int(link.get("enter", 1)) + 1):
				result[at - AreaDef.STEPS[str(link.direction)] * distance] = true
	for terminal: Dictionary in area.terminals:
		result[Vector2i(int(terminal.at[0]), int(terminal.at[1]))] = true
	for lamp: Dictionary in area.lamps:
		if lamp.get("stand") is Array:
			result[Vector2i(int(lamp.stand[0]), int(lamp.stand[1]))] = true
	return result


## On entry/Continue, an ambient round may start where the saved player stands. Move that resident to the
## nearest free, connected cell before showing it. Route clocks stay local to the visit; player saves stay intact.
static func clear_arrival(area: AreaDef, rules: LabWorld, world: Dictionary, residents: Dictionary, blocked: Dictionary) -> void:
	var avoid: Dictionary = reserved(area)
	avoid.merge(blocked)
	avoid[Vector2i(int(world.player[0]), int(world.player[1]))] = true
	for id: String in residents:
		var resident: Dictionary = residents[id]
		if not resident.get("player_solid", true) or not resident.get("active", true) or not avoid.has(resident.at): continue
		var occupied_cells: Dictionary = occupied(residents)
		var frontier: Array[Vector2i] = [resident.at]
		var seen: Dictionary = {resident.at: true}
		var cursor: int = 0
		while cursor < frontier.size():
			var at: Vector2i = frontier[cursor]
			cursor += 1
			if not avoid.has(at) and not occupied_cells.has(at):
				resident.at = at
				resident.from = at
				resident.to = at
				break
			for direction: Vector2i in LabWorld.DIRECTIONS:
				var next: Vector2i = at + direction
				if not seen.has(next) and rules.can_step(world, at, next):
					seen[next] = true
					frontier.append(next)


## The cells a resident takes up: where it stands, and while it steps, the cell it is stepping into as well.
static func cells(resident: Dictionary) -> Array[Vector2i]:
	if not resident.get("active", true): return []
	var taken: Array[Vector2i] = [resident.at]
	if float(resident.phase) < 1.0 and resident.to != resident.at:
		taken.append(resident.to)
	return taken


## Every cell some resident takes up, as a set: where the player may not step.
static func occupied(residents: Dictionary, for_player: bool = false) -> Dictionary:
	var taken: Dictionary = {}
	for id: Variant in residents:
		if for_player and not residents[id].get("player_solid", true): continue
		for cell: Vector2i in cells(residents[id]):
			taken[cell] = true
	return taken


## `blocked` adds cells nobody may step into, beyond the player's own: the cells the player is stepping between.
static func advance(area: AreaDef, rules: LabWorld, world: Dictionary, residents: Dictionary, delta: float, blocked: Dictionary = {}) -> void:
	var player := Vector2i(int(world.player[0]), int(world.player[1]))
	var protected: Dictionary = reserved(area)
	var seconds: float = maxf(0.0, delta)
	for definition: Dictionary in area.villagers:
		var resident: Dictionary = residents[definition.id]
		resident.clock = float(resident.clock) + seconds
		if not resident.active:
			_try_arrival(area, definition, resident, residents)
			if not resident.active: continue
		resident.age = float(resident.age) + seconds
		if definition.has("arrival"):
			if float(resident.fading) >= 0.0:
				resident.fading = maxf(0.0, float(resident.fading) - seconds)
				resident.presence = float(resident.fading) / 0.7
				if resident.fading <= 0.0: resident.active = false
				continue
			resident.presence = minf(1.0, float(resident.age) / 0.45)
		if float(resident.phase) < 1.0:
			var duration: float = 1.0 / float(definition.speed) if definition.has("speed") else STEP
			resident.phase = minf(1.0, float(resident.phase) + maxf(0.0, delta) / duration)
			if resident.phase >= 1.0:
				resident.at = resident.to
			else:
				continue
		resident.pause = maxf(0.0, float(resident.pause) - maxf(0.0, delta))
		if resident.pause > 0.0 or definition.route.is_empty():
			continue
		var target: Vector2i = definition.route[int(resident.goal) % definition.route.size()]
		if resident.at == target:
			if definition.has("arrival") and int(resident.goal) == definition.route.size() - 1:
				resident.fading = 0.7
				continue
			resident.seed = (int(resident.seed) * 1664525 + 1013904223) & 0x7fffffff
			var stride: int = 1 + int(resident.seed) % maxi(1, definition.route.size() - 1) if definition.get("wander", false) else 1
			resident.goal = int(resident.goal) + stride
			resident.path.clear()
			resident.pause = float(definition.get("pause", 2.0)) + float(int(resident.seed) % 23) / 10.0
			continue
		var avoid: Dictionary = protected.duplicate()
		if definition.has("arrival"):
			for cell: Vector2i in departure_cells(area, str(definition.arrival.exit)):
				avoid.erase(cell)
		if not definition.has("phantom"):
			avoid.merge(blocked)
			avoid[player] = true
		for other: Variant in residents:
			if other != definition.id:
				for cell: Vector2i in cells(residents[other]):
					avoid[cell] = true
		# Keep a legal path until another body or a changed passage obstructs the next step.
		if resident.path.is_empty() or avoid.has(resident.path[0]) or not rules.can_step(world, resident.at, resident.path[0]):
			resident.path = rules.find_path(world, target, resident.at, avoid)
		if resident.path.is_empty():
			resident.pause = 1.0
			continue
		resident.from = resident.at
		resident.to = resident.path.pop_front()
		resident.phase = 0.0


## Only departing, non-solid passengers may use this link's ordinary reserved arrival corridor.
static func departure_cells(area: AreaDef, id: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for link: Dictionary in area.interior.get("links", []):
		if link.id != id: continue
		for point: Array in link.get("cells", [link.at]):
			var at := Vector2i(int(point[0]), int(point[1]))
			for distance: int in range(int(link.get("enter", 1)) + 1):
				result.append(at - AreaDef.STEPS[str(link.direction)] * distance)
	return result


static func _try_arrival(area: AreaDef, definition: Dictionary, resident: Dictionary, residents: Dictionary) -> void:
	if not definition.has("arrival"): return
	var schedule: Dictionary = TramSchedule.sample(area.interior.life.tram, float(resident.clock))
	var trip: int = int(schedule.cycle)
	var arrival: Dictionary = definition.arrival
	if trip <= int(resident.cycle) or not schedule.docked or float(schedule.at_stop) < float(arrival.delay): return
	if trip % int(arrival.get("every", 1)) != int(arrival.get("offset", 0)): return
	if occupied(residents).has(definition.at): return
	resident.merge({"at":definition.at, "from":definition.at, "to":definition.at, "phase":1.0,
		"active":true, "cycle":trip, "goal":0, "pause":0.15, "presence":0.0, "age":0.0, "fading":-1.0}, true)
	resident.path.clear()


static func position(resident: Dictionary) -> Vector2:
	return Vector2(resident.from).lerp(Vector2(resident.to), float(resident.phase))
