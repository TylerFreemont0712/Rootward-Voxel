class_name VillageLife
extends RefCounted
## Deterministic villagers. Their routes use the same passage rules as the player. Nobody walks through anybody:
## a resident takes up its cell (and the next one while it steps), routes round the player, the cells the player is
## stepping between and the other residents, and waits when there is no way round. Villagers lock no quests.

const STEP: float = 0.42


static func initial(area: AreaDef) -> Dictionary:
	var result: Dictionary = {}
	for villager: Dictionary in area.villagers:
		var at: Vector2i = villager.at
		result[villager.id] = {"at": at, "from": at, "to": at, "phase": 1.0, "pause": 1.0 + float(str(villager.id).hash() % 17) / 10.0, "goal": 0}
	return result


## The cells a resident takes up: where it stands, and while it steps, the cell it is stepping into as well.
static func cells(resident: Dictionary) -> Array[Vector2i]:
	var taken: Array[Vector2i] = [resident.at]
	if float(resident.phase) < 1.0 and resident.to != resident.at:
		taken.append(resident.to)
	return taken


## Every cell some resident takes up, as a set: where the player may not step.
static func occupied(residents: Dictionary) -> Dictionary:
	var taken: Dictionary = {}
	for id: Variant in residents:
		for cell: Vector2i in cells(residents[id]):
			taken[cell] = true
	return taken


## `blocked` adds cells nobody may step into, beyond the player's own: the cells the player is stepping between.
static func advance(area: AreaDef, rules: LabWorld, world: Dictionary, residents: Dictionary, delta: float, blocked: Dictionary = {}) -> void:
	var player := Vector2i(int(world.player[0]), int(world.player[1]))
	for definition: Dictionary in area.villagers:
		var resident: Dictionary = residents[definition.id]
		if float(resident.phase) < 1.0:
			resident.phase = minf(1.0, float(resident.phase) + maxf(0.0, delta) / STEP)
			if resident.phase >= 1.0:
				resident.at = resident.to
			continue
		resident.pause = maxf(0.0, float(resident.pause) - maxf(0.0, delta))
		if resident.pause > 0.0 or definition.route.is_empty():
			continue
		var target: Vector2i = definition.route[int(resident.goal) % definition.route.size()]
		if resident.at == target:
			resident.goal = int(resident.goal) + 1
			resident.pause = 2.0 + float(absi(str(definition.id).hash()) % 19) / 10.0
			continue
		var avoid: Dictionary = blocked.duplicate()
		avoid[player] = true
		for other: Variant in residents:
			if other != definition.id:
				for cell: Vector2i in cells(residents[other]):
					avoid[cell] = true
		var path: Array[Vector2i] = rules.find_path(world, target, resident.at, avoid)
		if path.is_empty():
			resident.pause = 1.0
			continue
		resident.from = resident.at
		resident.to = path[0]
		resident.phase = 0.0


static func position(resident: Dictionary) -> Vector2:
	return Vector2(resident.from).lerp(Vector2(resident.to), float(resident.phase))
