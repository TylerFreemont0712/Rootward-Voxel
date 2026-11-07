class_name Quests
extends RefCounted
## Pure goal evaluation. A quest is data in the area's quest document; its goal is checked against
## plain world state. Completion is sticky: the session records it, and Undo or Reset never revokes it.


## Doodads the town's code can arrange: placed props and authored scenery, by id. {id, asset, at, facing} or {}.
static func doodad(area: AreaDef, id: String) -> Dictionary:
	var prop: Dictionary = area.prop(id)
	if not prop.is_empty():
		return {"id": id, "asset": str(prop.asset), "at": prop.at, "facing": str(prop.facing)}
	var item: Dictionary = area.scenery_item(id)
	if not item.is_empty():
		return {"id": id, "asset": str(item.asset), "at": item.at, "facing": ["S", "E", "N", "W"][posmod(roundi(float(item.turn) / 90.0), 4)]}
	return {}


## Every arrangeable doodad whose asset is one of `assets`.
static func doodads_of(area: AreaDef, assets: Array) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for prop: Dictionary in area.props:
		if assets.has(str(prop.asset)): found.append(doodad(area, str(prop.id)))
	for item: Dictionary in area.scenery:
		if assets.has(str(item.asset)): found.append(doodad(area, str(item.id)))
	return found


## The compass way from `from` toward `to`, along whichever axis is further.
static func facing_toward(from: Vector2, to: Vector2) -> String:
	var d: Vector2 = to - from
	if absf(d.x) >= absf(d.y):
		return "E" if d.x > 0 else "W"
	return "N" if d.y > 0 else "S"


static func goal_met(area: AreaDef, state: Dictionary, goal: Dictionary) -> bool:
	var progress: Dictionary = goal_progress(area, state, goal)
	return int(progress.total) > 0 and int(progress.done) >= int(progress.total)


## {done, total}: how far a goal has got, for the objective readout.
static func goal_progress(area: AreaDef, state: Dictionary, goal: Dictionary) -> Dictionary:
	match str(goal.get("type", "")):
		"hotaru_greeted":
			return {"done":1 if state.get("hotaru_greeted",false) else 0,"total":1,"noun":"hello spoken"}
		"inspection_read":
			return {"done": 1 if (state.get("inspections_read", []) as Array).has(str(goal.get("id", ""))) else 0, "total": 1, "noun": "ticket read"}
		"display_lines":
			# The installed card shows each of these lines (exactly, ignoring case and outer spaces).
			var shown: Array = (state.get("display_cards", {}).get(str(goal.get("id", "")), []) as Array).map(func(page: Variant) -> String: return str(page).strip_edges().to_upper())
			var found: int = 0
			for line: Variant in goal.get("lines", []):
				if shown.has(str(line).strip_edges().to_upper()): found += 1
			return {"done": found, "total": (goal.get("lines", []) as Array).size(), "noun": str(goal.get("noun", "lines on the board"))}
		"display_messages":
			var count: int=DisplayCards.distinct((state.get("display_cards",{}).get(str(goal.get("id","")),[]) as Array))
			return {"done":mini(count,2),"total":2,"noun":"different messages installed"}
		"lamp_program":
			var routine: Dictionary = state.get("lamp_programs",{}).get(str(goal.get("id","")),{})
			return {"done":1 if routine.get("day") == false and routine.get("night") == true else 0,"total":1,"noun":"daylight routine"}
		"lamps_lit":
			var ids: Array[String] = _lamp_targets(area, goal)
			var lit: int = 0
			for lamp_id: String in ids:
				if state.lamps.get(lamp_id, false) == true:
					lit += 1
			return {"done": lit, "total": ids.size(), "noun": "lamp lit" if ids.size() == 1 else "lamps lit"}
		"bridge_built":
			var bridge: Dictionary = area.bridge(str(goal.get("bridge", "")))
			var total: int = (bridge.get("sockets", []) as Array).size()
			return {"done": int(state.bridges.get(str(goal.get("bridge", "")), 0)), "total": total, "noun": "bridge deck" if total == 1 else "bridge decks"}
		"gate_open":
			return {"done": 1 if state.gates.get(str(goal.get("gate", "")), false) == true else 0, "total": 1, "noun": "gate open"}
		"reach_zone":
			return {"done": 1 if (state.zones_seen as Array).has(str(goal.get("zone", ""))) else 0, "total": 1, "noun": "place reached"}
		"houses_facing":
			# The goal names houses by id and the way each must face. A house the player has since taken away no
			# longer counts, rather than making the lesson impossible.
			var standing: int = 0
			var facing: int = 0
			for house_id: Variant in goal.get("ids", []):
				var house: Dictionary = area.building(str(house_id))
				if not house.is_empty():
					standing += 1
					if str(house.facing) == str(goal.get("facing", "")):
						facing += 1
			return {"done": facing, "total": standing, "noun": str(goal.get("noun", "houses turned"))}
		"doodads_face_point":
			# Each named doodad faces the point (along the axis it is further from it on).
			var turned: int = 0
			var counted: int = 0
			var target := Vector2(float(goal.at[0]), float(goal.at[1]))
			for id: Variant in goal.get("ids", []):
				var thing: Dictionary = doodad(area, str(id))
				if thing.is_empty(): continue
				counted += 1
				if str(thing.facing) == facing_toward(thing.at, target): turned += 1
			return {"done": turned, "total": counted, "noun": str(goal.get("noun", "facing the right way"))}
		"doodads_at":
			# Each target doodad stands within `tolerance` of its spot, facing that way when the target says so.
			var placed: int = 0
			var targets: Array = goal.get("targets", [])
			for target: Variant in targets:
				var thing: Dictionary = doodad(area, str(target.id))
				if thing.is_empty(): continue
				var spot := Vector2(float(target.at[0]), float(target.at[1]))
				if (thing.at as Vector2).distance_to(spot) <= float(goal.get("tolerance", 0.3)) and (not target.has("facing") or str(thing.facing) == str(target.facing)):
					placed += 1
			return {"done": placed, "total": targets.size(), "noun": str(goal.get("noun", "in place"))}
		"doodads_row":
			# Every doodad of these assets shares one coordinate on `axis` (a straight row) with at least `gap`
			# between neighbours. Progress counts the biggest group already in line.
			var things: Array[Dictionary] = doodads_of(area, goal.get("assets", []))
			var axis: int = 0 if str(goal.get("axis", "x")) == "x" else 1
			var best: Array = []
			for thing: Dictionary in things:
				# Within 0.15: code snaps to quarter cells, so a row laid at 41.9 by hand and 42 by code still lines up.
				var line: Array = things.filter(func(other: Dictionary) -> bool: return absf((other.at as Vector2)[axis] - (thing.at as Vector2)[axis]) <= 0.15)
				if line.size() > best.size(): best = line
			var along: Array = best.map(func(other: Dictionary) -> float: return (other.at as Vector2)[1 - axis])
			along.sort()
			var spaced: bool = true
			for index: int in range(1, along.size()):
				if float(along[index]) - float(along[index - 1]) < float(goal.get("gap", 0.0)) - 0.01: spaced = false
			var lined: int = best.size() if spaced or best.size() < 2 else best.size() - 1
			return {"done": lined, "total": things.size(), "noun": str(goal.get("noun", "in one row"))}
		"doodads_in_rect":
			# At least `at_least` doodads of these assets stand inside the rectangle [x, y, w, h].
			var r: Array = goal.rect
			var area_rect := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
			var inside: int = 0
			for thing: Dictionary in doodads_of(area, goal.get("assets", [])):
				if area_rect.has_point(thing.at): inside += 1
			return {"done": mini(inside, int(goal.at_least)), "total": int(goal.at_least), "noun": str(goal.get("noun", "pieces in place"))}
		"all":
			var done: int = 0
			var total: int = 0
			for child: Variant in goal.get("goals", []):
				var part: Dictionary = goal_progress(area, state, child)
				done += int(part.done)
				total += int(part.total)
			return {"done": done, "total": total, "noun": "steps done"}
	return {"done": 0, "total": 0, "noun": ""}


## Quests that are unlocked and not yet complete, in document order. `journey` lists jobs finished in other rooms of
## the journey; a quest's `after` names those it waits for (its `requires` are this room's own).
static func available(area: AreaDef, completed: Array, journey: Array = []) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest: Dictionary in area.quests:
		if completed.has(quest.id):
			continue
		var unlocked: bool = true
		for required: Variant in quest.requires:
			if not completed.has(required):
				unlocked = false
		for earlier: Variant in quest.get("after", []):
			if not completed.has(earlier) and not journey.has(earlier):
				unlocked = false
		if unlocked:
			result.append(quest)
	return result


## Evaluates the unlocked quests and returns the ids that just completed. A quest that unlocks because
## another finished is checked in the same pass, so a player who got ahead is not made to repeat work.
static func newly_completed(area: AreaDef, state: Dictionary, completed: Array, journey: Array = []) -> Array[String]:
	var finished: Array[String] = []
	var known: Array = completed.duplicate()
	var changed: bool = true
	while changed:
		changed = false
		for quest: Dictionary in available(area, known, journey):
			if goal_met(area, state, quest.goal):
				finished.append(quest.id)
				known.append(quest.id)
				changed = true
	return finished


## The abilities a player's code has earned: everything the quests it has reached unlock (their `unlocks` lists).
## A lesson hands over its ability when it becomes available, not when it is finished, because the lesson's own
## goal needs it. Completion is sticky, so an ability, once earned, stays.
static func capabilities(area: AreaDef, completed: Array, journey: Array = []) -> Array[String]:
	var result: Array[String] = []
	var reached: Array[Dictionary] = available(area, completed, journey)
	for entry: Dictionary in area.quests:
		if completed.has(entry.id) or reached.has(entry):
			for capability: Variant in entry.get("unlocks", []):
				if not result.has(str(capability)):
					result.append(str(capability))
	return result


## The quest whose lesson unlocks a capability, or {} if none does here (so a message can say where to learn it).
static func unlocking(area: AreaDef, capability: String) -> Dictionary:
	for entry: Dictionary in area.quests:
		if (entry.get("unlocks", []) as Array).has(capability):
			return entry
	return {}


## The quests of the main arc, in document order. The rest are `optional`: a later chapter that never holds back
## the epilogue.
static func main(area: AreaDef) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in area.quests:
		if not bool(entry.get("optional", false)):
			result.append(entry)
	return result


## The quests worth showing in a list: the main arc always, and an optional quest only once it has been reached
## (finished, or open), so a later chapter does not appear before the player gets there.
static func listed(area: AreaDef, completed: Array, journey: Array = []) -> Array[Dictionary]:
	var reached: Array[Dictionary] = available(area, completed, journey)
	var result: Array[Dictionary] = []
	for entry: Dictionary in area.quests:
		if not bool(entry.get("optional", false)) or completed.has(entry.id) or reached.has(entry):
			result.append(entry)
	return result


## Has the player finished every quest of the main arc (the point where the epilogue is shown)?
static func main_arc_done(area: AreaDef, completed: Array) -> bool:
	for entry: Dictionary in main(area):
		if not completed.has(entry.id):
			return false
	return true


static func current(area: AreaDef, completed: Array, journey: Array = []) -> Dictionary:
	var open: Array[Dictionary] = available(area, completed, journey)
	return open[0] if not open.is_empty() else {}


static func _lamp_targets(area: AreaDef, goal: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	if goal.get("all", false):
		return area.lamp_ids()
	if goal.has("zone"):
		for lamp: Dictionary in area.lamps_in_zone(str(goal.zone)):
			ids.append(lamp.id)
	for lamp_id: Variant in goal.get("ids", []):
		if not ids.has(str(lamp_id)):
			ids.append(str(lamp_id))
	return ids
