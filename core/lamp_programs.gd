class_name LampPrograms
extends RefCounted
## Finite daylight controller: real WASI executions supply both rows; core validates installation.
static func compile_trials(day: Dictionary, night: Dictionary) -> Dictionary:
	for answer: Dictionary in [day,night]:
		if not answer.get("ok",false): return answer
	var rows: Array[Dictionary] = []
	for answer: Dictionary in [day,night]:
		var row: Dictionary = {}
		for command: Variant in answer.get("commands",[]):
			if not command is Dictionary or command.size()!=4 or command.get("op")!="set_field" or command.get("field")!="enabled" or not command.get("value") is bool or not command.get("entity_id") is String:
				return {"ok":false,"reason":"A daylight routine may only switch the connected lamps. Keep other work on its own page."}
			row[command.entity_id] = command.value
		rows.append(row)
	if rows[0].is_empty() or rows[0].keys().any(func(id: String)->bool:return not rows[1].has(id)) or rows[0].size()!=rows[1].size():
		return {"ok":false,"reason":"Give every lamp an instruction for daylight and darkness. Add an else: branch so it knows when to switch off."}
	var commands: Array = []
	for id: String in rows[0]: commands.append({"op":"set_lamp_program","id":id,"day":rows[0][id],"night":rows[1][id]})
	var result: Dictionary = night.duplicate(true)
	result.commands = commands
	result["wall_ms"] = int(day.get("wall_ms",0))+int(night.get("wall_ms",0))
	result["stdout"] = "DAYLIGHT TEST\n"+str(day.get("stdout",""))+"\nDARKNESS TEST\n"+str(night.get("stdout",""))
	return result

static func apply(area: AreaDef, state: Dictionary, command: Dictionary, changes: Array[String]) -> String:
	if command.size()!=4 or not command.get("id") is String or not command.get("day") is bool or not command.get("night") is bool:
		return "A lamp controller needs an id and Boolean daylight/darkness instructions."
	var lamp: Dictionary = area.lamp(command.id)
	if lamp.is_empty(): return "Unknown lamp '%s'." % command.id
	if not (state.zones_seen as Array).has(lamp.zone) or not FieldAccess.lamp_in_reach(area,state,lamp):return FieldAccess.lamp_reason(area,lamp)
	state.lamp_programs[command.id] = {"day":command.day,"night":command.night}
	state.lamps[command.id] = command.night if state.get("time",{}).get("is_dark",false) else command.day
	changes.append("%s · daylight %s · darkness %s" % [command.id,"ON" if command.day else "OFF","ON" if command.night else "OFF"])
	return ""

static func refresh(area: AreaDef, state: Dictionary, dark: bool) -> bool:
	var changed: bool = false
	for lamp: Dictionary in area.lamps:
		var routine: Dictionary = state.get("lamp_programs",{}).get(lamp.id,{})
		# Street fixtures ship with dusk relays. Lesson fittings keep their authored/manual instruction.
		var requested: bool = bool(state.lamps[lamp.id])
		if not routine.is_empty(): requested = bool(routine.night if dark else routine.day)
		elif lamp.get("automatic",false): requested = dark
		if requested != state.lamps[lamp.id]:
			state.lamps[lamp.id] = requested
			changed = true
	return changed
