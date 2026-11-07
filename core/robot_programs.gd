class_name RobotPrograms
extends RefCounted
## Bounded controls over authored, traversable work rounds, not arbitrary renderer coordinates.
static func definitions(area: AreaDef) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for actor: Dictionary in area.villagers:
		if actor.has("object") and not actor.has("phantom"): result.append(actor)
	return result

static func in_reach(area: AreaDef, state: Dictionary, actor: Dictionary) -> bool:
	if not PlayerItems.has(state,"field-tablet"):return false
	var zone: String = area.zone_at(actor.at)
	if not (state.zones_seen as Array).has(zone):return false
	for terminal: Dictionary in area.terminals:
		if ZoneTerminals.in_reach(area,state,terminal):return true
	for note: Dictionary in area.interior.get("inspections",[]):
		if note.id == actor.object and FieldAccess.near(state,note.at):return true
	return false

static func snapshot(area: AreaDef, state: Dictionary) -> Array:
	var result: Array = []
	for actor: Dictionary in definitions(area):
		if not in_reach(area,state,actor):continue
		var config: Dictionary = state.get("robot_programs",{}).get(actor.id,{})
		var tasks: Array = []
		for task: Dictionary in actor.get("errands",[]): tasks.append(task.target)
		result.append({"id":actor.id,"running":config.get("running",true),"speed":config.get("speed",actor.get("speed",1.5)),"stops":tasks,"route":config.get("route",tasks)})
	return result

static func apply(area: AreaDef, state: Dictionary, command: Dictionary, changes: Array[String]) -> String:
	if command.size()!=4 or not command.get("id") is String or not command.get("field") is String:return "A robot instruction needs id, field and value."
	var found: Dictionary = {}
	for actor: Dictionary in definitions(area):
		if actor.id==command.id:found=actor
	if found.is_empty():return "Unknown robot. Read world.robots for the connected workers."
	if not in_reach(area,state,found):return "Connect at the zone screen or the robot's service point with your field slate."
	var value: Variant = command.get("value")
	match command.field:
		"running":
			if not value is bool:return "Use True or False for running."
		"speed":
			if not (value is float or value is int) or value is bool or not is_finite(float(value)) or float(value)<0.5 or float(value)>3:return "Robot speed must be between 0.5 and 3 cells per second."
		"route":
			if not value is Array or value.is_empty() or value.size()>12:return "Choose 1–12 stops from this robot's stops list."
			for stop: Variant in value:
				if not stop is String or not found.get("errands",[]).any(func(task: Dictionary)->bool:return task.target==stop):return "A route may only use this worker's authored service stops."
		_ :return "Robots expose running, speed and route."
	if not state.robot_programs.has(command.id):state.robot_programs[command.id]={}
	state.robot_programs[command.id][command.field]=value.duplicate() if value is Array else value
	changes.append("%s · %s updated" % [command.id,command.field])
	return ""
