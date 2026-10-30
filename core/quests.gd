class_name Quests
extends RefCounted
## Pure goal evaluation. A quest is data in the area's quest document; its goal is checked against
## plain world state. Completion is sticky: the session records it, and Undo or Reset never revokes it.


static func goal_met(area: AreaDef, state: Dictionary, goal: Dictionary) -> bool:
	var progress: Dictionary = goal_progress(area, state, goal)
	return int(progress.total) > 0 and int(progress.done) >= int(progress.total)


## {done, total}: how far a goal has got, for the objective readout.
static func goal_progress(area: AreaDef, state: Dictionary, goal: Dictionary) -> Dictionary:
	match str(goal.get("type", "")):
		"hotaru_greeted":
			return {"done":1 if state.get("hotaru_greeted",false) else 0,"total":1,"noun":"hello spoken"}
		"movement_ready":
			return {"done": MovementBindings.tried(state), "total": 4, "noun": "directions tried"}
		"inspection_read":
			return {"done": 1 if (state.get("inspections_read", []) as Array).has(str(goal.get("id", ""))) else 0, "total": 1, "noun": "ticket read"}
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
		"all":
			var done: int = 0
			var total: int = 0
			for child: Variant in goal.get("goals", []):
				var part: Dictionary = goal_progress(area, state, child)
				done += int(part.done)
				total += int(part.total)
			return {"done": done, "total": total, "noun": "steps done"}
	return {"done": 0, "total": 0, "noun": ""}


## Quests that are unlocked and not yet complete, in document order.
static func available(area: AreaDef, completed: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest: Dictionary in area.quests:
		if completed.has(quest.id):
			continue
		var unlocked: bool = true
		for required: Variant in quest.requires:
			if not completed.has(required):
				unlocked = false
		if unlocked:
			result.append(quest)
	return result


## Evaluates the unlocked quests and returns the ids that just completed. A quest that unlocks because
## another finished is checked in the same pass, so a player who got ahead is not made to repeat work.
static func newly_completed(area: AreaDef, state: Dictionary, completed: Array) -> Array[String]:
	var finished: Array[String] = []
	var known: Array = completed.duplicate()
	var changed: bool = true
	while changed:
		changed = false
		for quest: Dictionary in available(area, known):
			if goal_met(area, state, quest.goal):
				finished.append(quest.id)
				known.append(quest.id)
				changed = true
	return finished


## The abilities a player's code has earned: everything the quests it has reached unlock (their `unlocks` lists).
## A lesson hands over its ability when it becomes available, not when it is finished, because the lesson's own
## goal needs it. Completion is sticky, so an ability, once earned, stays.
static func capabilities(area: AreaDef, completed: Array) -> Array[String]:
	var result: Array[String] = []
	var reached: Array[Dictionary] = available(area, completed)
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
static func listed(area: AreaDef, completed: Array) -> Array[Dictionary]:
	var reached: Array[Dictionary] = available(area, completed)
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


static func current(area: AreaDef, completed: Array) -> Dictionary:
	var open: Array[Dictionary] = available(area, completed)
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
