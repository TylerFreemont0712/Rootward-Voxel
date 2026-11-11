class_name ZoneTerminals
extends RefCounted
## Authored zone connections. No source execution, file access or renderer decisions.

static func find(area: AreaDef, id: String) -> Dictionary:
	for terminal: Dictionary in area.terminals:
		if terminal.id == id: return terminal
	return {}

static func nearest(area: AreaDef, at: Vector2) -> Dictionary:
	var found: Dictionary = {}
	var distance: float = FieldAccess.RANGE
	for terminal: Dictionary in area.terminals:
		var delta: float = at.distance_to(Vector2(terminal.at[0], terminal.at[1]))
		if delta < distance:
			distance = delta
			found = terminal
	return found

static func for_zone(area: AreaDef, zone: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for terminal: Dictionary in area.terminals:
		if terminal.zone == zone: result.append(terminal)
	return result

static func connected(area: AreaDef, state: Dictionary, zone: String) -> bool:
	var terminals: Array[Dictionary] = for_zone(area, zone)
	if terminals.is_empty(): return true
	for terminal: Dictionary in terminals:
		if (state.get("terminal_links", []) as Array).has(terminal.id): return true
	return false

static func connect_at(area: AreaDef, state: Dictionary, id: String) -> Dictionary:
	var terminal: Dictionary = find(area, id)
	if terminal.is_empty(): return {"ok":false, "state":state, "reason":"That terminal is not in this area."}
	var at := Vector2(int(state.player[0]), int(state.player[1]))
	if at.distance_to(Vector2(terminal.at[0], terminal.at[1])) >= FieldAccess.RANGE:
		return {"ok":false, "state":state, "reason":"Walk closer to use " + str(terminal.title) + "."}
	if terminal.has("requires") and not PlayerItems.has(state, str(terminal.requires)):
		return {"ok":false, "state":state, "reason":"You need " + PlayerItems.title(str(terminal.requires)) + " to use " + str(terminal.title) + "."}
	if not (state.zones_seen as Array).has(terminal.zone):
		return {"ok":false, "state":state, "reason":"Step into " + str(area.zone(terminal.zone).title) + " before connecting."}
	var candidate: Dictionary = state.duplicate(true)
	if not candidate.terminal_links.has(id):
		candidate.terminal_links.append(id)
		candidate.revision = int(state.revision) + 1
	return {"ok":true, "state":candidate, "reason":""}

## Standing at a linked terminal, with what it requires: the only way its zone's fittings answer to code.
static func in_reach(area: AreaDef, state: Dictionary, terminal: Dictionary) -> bool:
	if not (state.get("terminal_links", []) as Array).has(terminal.id): return false
	if terminal.has("requires") and not PlayerItems.has(state, str(terminal.requires)): return false
	return FieldAccess.near(state, terminal.at)

static func caption(area: AreaDef, state: Dictionary) -> String:
	var names := PackedStringArray()
	for zone: Dictionary in area.zones:
		if not for_zone(area, zone.id).is_empty() and connected(area, state, zone.id): names.append(str(zone.id))
	return "CONNECTED · " + ", ".join(names) if not names.is_empty() else "FIELD NOTES · OFFLINE"
