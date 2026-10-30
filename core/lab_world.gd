class_name LabWorld
extends RefCounted
## Pure rules for one area. Rendering never decides whether a change is legal or a cell is walkable.
##
## A LabWorld is built from a validated AreaDef and answers questions about plain-data states:
## `initial_state()` -> state, then `move`, `propose`, `find_path`... never mutate the state they are given.

const PLAYER_RADIUS: float = 0.18
const STEP_SECONDS: float = 13.0 / 60.0
const TRUNK_RADIUS: float = 0.18
const LAMP_RADIUS: float = 0.16
const BEACON_RADIUS: float = 0.42
const MAX_COMMANDS: int = 64
const MAX_MEMORY_BYTES: int = 2048
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN]

var area: AreaDef
var _rect_index: Dictionary = {}
var _circle_index: Dictionary = {}
var _gate_cells: Dictionary = {}
var _near_dynamic: Dictionary = {}
var _edge_cache: Dictionary = {}


func _init(definition: AreaDef) -> void:
	area = definition
	var rects: Array[Rect2] = []
	for building: Dictionary in area.buildings:
		var solids: Array=building.get("collision_rects",[])
		if solids.is_empty():rects.append(building.rect)
		else:
			for solid: Rect2 in solids:rects.append(solid)
	for prop: Dictionary in area.props:
		if prop.solid:
			rects.append(prop.rect)
	for wheel: Dictionary in area.wheels:
		rects.append(wheel.rect)
	for segment: Dictionary in area.segments:
		rects.append(segment.rect)
	for furniture: Dictionary in area.interior.get("furniture", []):
		if furniture.kind != "rug":
			rects.append(furniture.rect)
	rects.append_array(HouseInstances.frame_posts(area))
	for rect: Rect2 in rects:
		_register(_rect_index, rect.grow(PLAYER_RADIUS), rect)
	for tree: Dictionary in area.trees:
		_register_circle(tree.at, float(tree.get("trunk_radius", TRUNK_RADIUS)))
	for lamp: Dictionary in area.lamps:
		if lamp.style != "fixture": _register_circle(lamp.at, BEACON_RADIUS if lamp.style == "beacon" else LAMP_RADIUS)
	var dynamic: Array[Vector2i] = []
	for gate: Dictionary in area.gates:
		_gate_cells[gate.cell] = gate.id
		dynamic.append(gate.cell)
	for bridge: Dictionary in area.bridges:
		dynamic.append_array(bridge.sockets)
	for cell: Vector2i in dynamic:
		for dx: int in range(-1, 2):
			for dy: int in range(-1, 2):
				_near_dynamic[Vector2i(cell.x + dx, cell.y + dy)] = true


func initial_state() -> Dictionary:
	var lamps: Dictionary = {}
	for lamp: Dictionary in area.lamps:
		lamps[lamp.id] = false
	var gates: Dictionary = {}
	for gate: Dictionary in area.gates:
		gates[gate.id] = false
	var bridges: Dictionary = {}
	for bridge: Dictionary in area.bridges:
		bridges[bridge.id] = 0
	var seen: Array = []
	var home: String = area.zone_at(area.spawn)
	if home != "":
		seen.append(home)
	return {
		"revision": 0,
		"player": [area.spawn.x, area.spawn.y, 0],
		"lamps": lamps,
		"gates": gates,
		"bridges": bridges,
		"zones_seen": seen,
		"memory": {},
		"props": {},
		"controls": {},
		"movement_used": [],
		"spoken": "",
		"hotaru_greeted": false,
		"inspections_read": [],
		"terminal_links": [],
		"items": [],
	}


## A state read back from a save file, or {} if it does not fit this area. JSON turns every number
## into a float, so whole numbers are converted back to integers here.
func normalize_state(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	for key: String in ["revision", "player", "lamps", "gates", "bridges", "zones_seen", "memory"]:
		if not (raw as Dictionary).has(key):
			return {}
	var player: Variant = raw.player
	if not player is Array or player.size() != 3:
		return {}
	for part: Variant in player:
		if not _whole_number(part):
			return {}
	var cell := Vector2i(int(player[0]), int(player[1]))
	if not area.in_bounds(cell) or not _whole_number(raw.revision):
		return {}
	var state: Dictionary = initial_state()
	state.revision = int(raw.revision)
	state.player = [cell.x, cell.y, 0]
	for lamp_id: String in state.lamps:
		if not (raw.lamps is Dictionary) or not (raw.lamps as Dictionary).get(lamp_id, false) is bool:
			return {}
		state.lamps[lamp_id] = raw.lamps.get(lamp_id, false)
	for gate_id: String in state.gates:
		if not (raw.gates is Dictionary) or not (raw.gates as Dictionary).get(gate_id, false) is bool:
			return {}
		state.gates[gate_id] = raw.gates.get(gate_id, false)
	for bridge: Dictionary in area.bridges:
		var built: Variant = (raw.bridges as Dictionary).get(bridge.id, 0) if raw.bridges is Dictionary else null
		if not _whole_number(built) or int(built) < 0 or int(built) > (bridge.sockets as Array).size():
			return {}
		state.bridges[bridge.id] = int(built)
	state.zones_seen = []
	for zone_id: Variant in raw.zones_seen if raw.zones_seen is Array else []:
		if zone_id is String and not area.zone(zone_id).is_empty() and not (state.zones_seen as Array).has(zone_id):
			(state.zones_seen as Array).append(zone_id)
	if not raw.memory is Dictionary or not _json_value(raw.memory, 0):
		return {}
	state.memory = (raw.memory as Dictionary).duplicate(true)
	var prop_states: Variant = raw.get("props", {})
	if not prop_states is Dictionary:
		return {}
	for id: Variant in prop_states:
		if not id is String or not AreaDef._id(id) or not prop_states[id] is bool:
			return {}
	state.props = prop_states.duplicate(true)
	if not MovementBindings.valid(raw.get("controls", {})) or not raw.get("movement_used", []) is Array:
		return {}
	state.controls = raw.get("controls", {}).duplicate(true)
	for direction: Variant in raw.get("movement_used", []):
		if not direction is String or not MovementBindings.DIRECTIONS.has(direction):return {}
		if not state.movement_used.has(direction):state.movement_used.append(direction)
	if not raw.get("spoken", "") is String or str(raw.get("spoken", "")).length()>160 or not raw.get("hotaru_greeted", false) is bool:return {}
	state.spoken=raw.get("spoken", "")
	state.hotaru_greeted=raw.get("hotaru_greeted", false)
	var read: Variant = raw.get("inspections_read", [])
	if not read is Array or read.size() > 24: return {}
	for id: Variant in read:
		if not id is String: return {}
		if (area.interior.get("inspections", []) as Array).any(func(item: Dictionary) -> bool: return item.id == id) and not state.inspections_read.has(id): state.inspections_read.append(id)
	var links: Variant = raw.get("terminal_links", [])
	if not links is Array or links.size() > 24: return {}
	for id: Variant in links:
		if not id is String: return {}
		if not ZoneTerminals.find(area, id).is_empty() and not state.terminal_links.has(id): state.terminal_links.append(id)
	var carried: Variant = raw.get("items", [])
	if not carried is Array or carried.size() > 16: return {}
	state.items = PlayerItems.restore(carried)
	if not is_walkable(state, cell):
		if not _cell_open(state,cell):return {}
		# Recover the two formerly walkable doorway-edge cases introduced before
		# the room boundary / cottage hull fix. Keep the rest of the saved world.
		var recovered:=Vector2i(-1,-1)
		if not area.interior.is_empty() and cell.y<=int(area.interior.exit[1]):
			recovered=Vector2i(cell.x,int(area.interior.exit[1]))
			if cell.y==int(area.interior.exit[1]):recovered.y+=1
			if not is_walkable(state,recovered):recovered=Vector2i(int(area.interior.exit[0]),int(area.interior.exit[1]))
		else:
			for building: Dictionary in area.buildings:
				if (building.get("collision_rects",[]) as Array).is_empty() or _circle_intersects_rect(Vector2(cell),building.rect):continue
				for solid: Rect2 in building.collision_rects:
					if _circle_intersects_rect(Vector2(cell),solid):recovered=HouseInstances.door(area,building.id)
		if recovered.x<0 and area.id in ["morning-bedroom", "workshop-loft", "workshop-floor"]:
			# These rooms gained/rearranged furniture in version 2. Preserve the
			# saved program memory and lessons; move only an obstructed player.
			recovered=area.spawn
		if recovered.x<0 or not is_walkable(state,recovered):return {}
		state.player=[recovered.x,recovered.y,0]
	return state


## Reading a nearby room object is a discovery, independent of Python and Undo.
func read_inspection(state: Dictionary, id: String) -> Dictionary:
	for item: Dictionary in area.interior.get("inspections", []):
		if item.id != id: continue
		var point := Vector2(float(item.at[0]), float(item.at[1]))
		if Vector2(int(state.player[0]), int(state.player[1])).distance_to(point) >= 1.6: return _reject(state, "Walk closer to read it.")
		var candidate: Dictionary = state.duplicate(true)
		if not candidate.inspections_read.has(id):
			candidate.inspections_read.append(id)
			candidate.revision = int(state.revision) + 1
		return {"ok": true, "state": candidate, "changes": [], "reason": ""}
	return _reject(state, "That object isn't in this room.")


## What a program is allowed to know: only places the player has actually been to.
func snapshot(state: Dictionary) -> Dictionary:
	var zones: Array = []
	for zone: Dictionary in area.zones:
		if _seen(state, zone.id):
			var r: Rect2i = zone.rect
			zones.append({"id": zone.id, "title": zone.title, "rect": [r.position.x, r.position.y, r.size.x, r.size.y]})
	var lamps: Array = []
	for lamp: Dictionary in area.lamps:
		if _lamp_seen(state, lamp):
			lamps.append({"id": lamp.id, "zone": lamp.zone, "cell": [lamp.cell.x, lamp.cell.y, 0], "lit": state.lamps[lamp.id]})
	var gates: Array = []
	for gate: Dictionary in area.gates:
		if _seen(state, gate.zone):
			gates.append({"id": gate.id, "zone": gate.zone, "cell": [gate.cell.x, gate.cell.y, 0], "open": state.gates[gate.id]})
	var bridges: Array = []
	for bridge: Dictionary in area.bridges:
		if _seen(state, bridge.zone):
			var cells: Array = []
			for cell: Vector2i in bridge.sockets:
				cells.append([cell.x, cell.y, 0])
			bridges.append({"id": bridge.id, "zone": bridge.zone, "cells": cells, "built": state.bridges[bridge.id]})
	var props: Array = []
	for prop: Dictionary in area.props:
		if not (prop.interaction as Dictionary).is_empty() and PropInteractions.known(state, prop) and ZoneTerminals.connected(area, state, prop.zone):
			props.append({"id": prop.id, "asset": prop.asset, "name": prop.title, "zone": prop.zone,
				"cell": [roundi(prop.at.x), roundi(prop.at.y), 0], "active": bool((state.get("props", {}) as Dictionary).get(prop.id, false))})
	return {
		"revision": int(state.revision),
		"area": {"id": area.id, "title": area.title, "width": area.width, "height": area.height},
		"player": state.player.duplicate(true),
		"player_cell": player_cell(state),
		"zone": area.zone_at(Vector2i(int(state.player[0]), int(state.player[1]))),
		"zones": zones,
		"lamps": lamps,
		"gates": gates,
		"bridges": bridges,
		"props": props,
		"memory": state.memory.duplicate(true),
		"companion": {"enabled": area.movement_lesson or area.voice_lesson},
		"controls": {"enabled": area.movement_lesson, "bindings": state.get("controls", {}).duplicate(true)},
	}


## Commands run against a detached candidate. A rejected final command discards every earlier change.
## `external` lists operations another rule set owns (CodeBuild's building commands): they are counted but not
## applied here. Left empty, any operation this class does not know is refused.
func propose(state: Dictionary, commands: Variant, memory: Variant, external: Array[String] = []) -> Dictionary:
	if not commands is Array:
		return _reject(state, "Return a list of commands.")
	if commands.size() > MAX_COMMANDS:
		return _reject(state, "Use at most %d commands in one run." % MAX_COMMANDS)
	if not memory is Dictionary or not _json_value(memory, 0):
		return _reject(state, "Memory must be a small JSON dictionary, at most four levels deep.")
	if JSON.stringify(memory).to_utf8_buffer().size() > MAX_MEMORY_BYTES:
		return _reject(state, "Memory exceeds the %d byte limit." % MAX_MEMORY_BYTES)
	var candidate: Dictionary = state.duplicate(true)
	var changes: Array[String] = []
	for index: int in range(commands.size()):
		var command: Variant = commands[index]
		if not command is Dictionary or not command.get("op") is String:
			return _reject(state, "Command %d needs an op string." % (index + 1))
		if external.has(command.op):
			continue
		var reason: String = _apply(candidate, command, changes)
		if reason != "":
			return _reject(state, "Command %d: %s" % [index + 1, reason])
	candidate.memory = memory.duplicate(true)
	candidate.revision = int(state.revision) + 1
	return {"ok": true, "reason": "", "state": candidate, "changes": changes}


## Undo a program's effects without teleporting the player: lamps, gates, bridges and memory return to
## `before`, while position and discovered places stay as they are. Refused if that would pull the
## ground from under the player.
func revert(current: Dictionary, before: Dictionary) -> Dictionary:
	var candidate: Dictionary = current.duplicate(true)
	candidate.lamps = (before.lamps as Dictionary).duplicate(true)
	candidate.gates = (before.gates as Dictionary).duplicate(true)
	candidate.bridges = (before.bridges as Dictionary).duplicate(true)
	candidate.props = (before.get("props", {}) as Dictionary).duplicate(true)
	candidate.memory = (before.memory as Dictionary).duplicate(true)
	candidate.controls = before.get("controls", {}).duplicate(true)
	candidate.movement_used = before.get("movement_used", []).duplicate()
	candidate.spoken=before.get("spoken", "")
	candidate.hotaru_greeted=before.get("hotaru_greeted", false)
	if not is_walkable(candidate, Vector2i(int(current.player[0]), int(current.player[1]))):
		return _reject(current, "Walk off the bridge or gate first: undoing would remove the ground you are standing on.")
	candidate.revision = int(current.revision) + 1
	return {"ok": true, "reason": "", "state": candidate, "changes": []}


## One authoritative cardinal cell step. The renderer animates the accepted transition.
func move(state: Dictionary, delta: Vector2i, key: String = "") -> Dictionary:
	if absi(delta.x) + absi(delta.y) != 1:
		return _reject(state, "Choose one neighboring cell on the x or y axis.")
	var from := Vector2i(int(state.player[0]), int(state.player[1]))
	if not can_step(state, from, from + delta):
		return _reject(state, "That passage is blocked. Build a bridge, open a gate or choose another route.")
	if key != "" and (not area.movement_lesson or MovementBindings.direction(state.controls, key) != delta):
		return _reject(state, "That key is not connected to this movement. Preview and Apply your bindings first.")
	var candidate: Dictionary = state.duplicate(true)
	if key != "" and not candidate.movement_used.has(str(candidate.controls[key])):
		candidate.movement_used.append(str(candidate.controls[key]))
	var arrived: Vector2i = from + delta
	candidate.player = [arrived.x, arrived.y, 0]
	candidate.revision = int(state.revision) + 1
	var changes: Array[String] = []
	var zone_id: String = area.zone_at(arrived)
	if zone_id != "" and not (candidate.zones_seen as Array).has(zone_id):
		(candidate.zones_seen as Array).append(zone_id)
		changes.append("Discovered %s" % area.zone(zone_id).title)
	return {"ok": true, "reason": "", "state": candidate, "changes": changes}


func can_step(state: Dictionary, from: Vector2i, to: Vector2i) -> bool:
	if absi(to.x - from.x) + absi(to.y - from.y) != 1 or not area.in_bounds(from) or not area.in_bounds(to):
		return false
	if not _static_edge(from, to):
		return false
	if not _near_dynamic.has(from) and not _near_dynamic.has(to):
		return true
	if not is_walkable(state, from) or not is_walkable(state, to):
		return false
	# Props can stand between cell centers. Validate the short passage as well as its destination.
	for index: int in range(1, 9):
		if not can_stand(state, Vector2(from).lerp(Vector2(to), float(index) / 8.0)):
			return false
	return true


## The shortest route of cardinal steps to `goal`, or none. `avoid` is a set of cells to route round as well (people
## standing about); a route whose goal is one of them is none.
func find_path(state: Dictionary, goal: Vector2i, from: Vector2i = Vector2i(-1, -1), avoid: Dictionary = {}) -> Array[Vector2i]:
	var start: Vector2i = from if from.x >= 0 else Vector2i(int(state.player[0]), int(state.player[1]))
	var empty: Array[Vector2i] = []
	if start == goal or not is_walkable(state, goal) or avoid.has(goal):
		return empty
	var frontier: Array[Vector2i] = [start]
	var parents: Dictionary = {}
	parents[start] = start
	var cursor: int = 0
	while cursor < frontier.size():
		var current: Vector2i = frontier[cursor]
		cursor += 1
		for delta: Vector2i in DIRECTIONS:
			var next: Vector2i = current + delta
			if parents.has(next) or avoid.has(next) or not can_step(state, current, next):
				continue
			parents[next] = current
			if next == goal:
				var path: Array[Vector2i] = []
				var at: Vector2i = goal
				while at != start:
					path.push_front(at)
					at = parents[at]
				return path
			frontier.append(next)
	return empty


func player_position(state: Dictionary) -> Vector2:
	return Vector2(float(state.player[0]), float(state.player[1]))


func player_cell(state: Dictionary) -> Array:
	var at: Vector2 = player_position(state)
	return [floori(at.x + 0.5), floori(at.y + 0.5), 0]


func is_walkable(state: Dictionary, cell: Vector2i) -> bool:
	return can_stand(state, Vector2(cell))


func can_stand(state: Dictionary, at: Vector2) -> bool:
	return _can_stand(state, at, false)


## Could anyone ever stand here, whatever the gates and bridges? Terrain, buildings, props, walls and trunks decide.
func can_ever_stand(at: Vector2) -> bool:
	return _can_stand({}, at, true)


func deck_built(state: Dictionary, cell: Vector2i) -> bool:
	var info: Dictionary = area.socket(cell)
	return not info.is_empty() and int(state.bridges[info.bridge]) > int(info.order)


func _can_stand(state: Dictionary, at: Vector2, static_only: bool) -> bool:
	if not at.is_finite():
		return false
	# The south cutaway is a room boundary, not extra floor behind the exit.
	# The one outward step from this line is handled by HouseInstances.crossing.
	if not area.interior.is_empty() and at.y<float(area.interior.get("walk_front", area.interior.exit[1]))-.0001:return false
	if at.x < -0.5 + PLAYER_RADIUS or at.y < -0.5 + PLAYER_RADIUS or at.x > float(area.width) - 0.5 - PLAYER_RADIUS or at.y > float(area.height) - 0.5 - PLAYER_RADIUS:
		return false
	for x: int in range(floori(at.x - PLAYER_RADIUS + 0.5), floori(at.x + PLAYER_RADIUS + 0.5) + 1):
		for y: int in range(floori(at.y - PLAYER_RADIUS + 0.5), floori(at.y + PLAYER_RADIUS + 0.5) + 1):
			var open: bool = _cell_open_static(Vector2i(x, y)) if static_only else _cell_open(state, Vector2i(x, y))
			if not open and _circle_intersects_rect(at, Rect2(Vector2(x - 0.5, y - 0.5), Vector2.ONE)):
				return false
	var key: Vector2i = Vector2i(floori(at.x + 0.5), floori(at.y + 0.5))
	for rect: Rect2 in _rect_index.get(key, []):
		if _circle_intersects_rect(at, rect):
			return false
	for solid: Vector3 in _circle_index.get(key, []):
		if at.distance_squared_to(Vector2(solid.x, solid.y)) < pow(PLAYER_RADIUS + solid.z, 2.0):
			return false
	return true


## Terrain that never changes is decided once per edge. Only edges near a gate or bridge socket are re-evaluated.
func _static_edge(from: Vector2i, to: Vector2i) -> bool:
	var key: Vector3i = Vector3i(from.x, from.y, (to.x - from.x) + 2 * (to.y - from.y))
	if _edge_cache.has(key):
		return _edge_cache[key]
	var ok: bool = level_step(from, to) and _can_stand({}, Vector2(from), true) and _can_stand({}, Vector2(to), true)
	if ok:
		for index: int in range(1, 9):
			if not _can_stand({}, Vector2(from).lerp(Vector2(to), float(index) / 8.0), true):
				ok = false
				break
	_edge_cache[key] = ok
	return ok


## May a step cross between these neighbouring cells' levels? Level ground joins level ground; a cliff never lets
## anyone by. Stairs are walked only along their own line: up onto the cell above them, or down off their foot.
func level_step(from: Vector2i, to: Vector2i) -> bool:
	if not RoomLinks.stair_edge(area, from, to): return false
	var delta: Vector2i = to - from
	for flight: Dictionary in [area.stair_at(from), area.stair_at(to)]:
		if not flight.is_empty():
			return delta == flight.dir or delta == -(flight.dir as Vector2i)
	return area.level_at(from) == area.level_at(to)


## Bridge sockets and gates count as open for the static pass; the dynamic pass decides them.
func _cell_open_static(cell: Vector2i) -> bool:
	match area.terrain_at(cell):
		-1, AreaDef.Terrain.ROCK:
			return false
		AreaDef.Terrain.WATER:
			return not area.socket(cell).is_empty()
	return true


func _cell_open(state: Dictionary, cell: Vector2i) -> bool:
	match area.terrain_at(cell):
		-1, AreaDef.Terrain.ROCK:
			return false
		AreaDef.Terrain.WATER:
			return deck_built(state, cell)
	if _gate_cells.has(cell):
		return bool(state.gates[_gate_cells[cell]])
	return true


func _register(index: Dictionary, inflated: Rect2, value: Variant) -> void:
	for x: int in range(floori(inflated.position.x + 0.5), floori(inflated.end.x + 0.5) + 1):
		for y: int in range(floori(inflated.position.y + 0.5), floori(inflated.end.y + 0.5) + 1):
			var key := Vector2i(x, y)
			if not index.has(key):
				index[key] = []
			(index[key] as Array).append(value)


func _register_circle(at: Vector2, radius: float) -> void:
	_register(_circle_index, Rect2(at, Vector2.ZERO).grow(radius + PLAYER_RADIUS), Vector3(at.x, at.y, radius))


## A zone's fittings are in reach once visited and, where the zone has a terminal, while standing at it.
func _seen(state: Dictionary, zone_id: String) -> bool:
	return (state.zones_seen as Array).has(zone_id) and ZoneTerminals.connected(area, state, zone_id) and FieldAccess.zone_in_reach(area, state, zone_id)


## A lamp answers to code through its zone's screen or from the place it names to stand.
func _lamp_seen(state: Dictionary, lamp: Dictionary) -> bool:
	return (state.zones_seen as Array).has(lamp.zone) and FieldAccess.lamp_in_reach(area, state, lamp)


func _circle_intersects_rect(at: Vector2, rect: Rect2) -> bool:
	var nearest: Vector2 = at.clamp(rect.position, rect.end)
	return at.distance_squared_to(nearest) < PLAYER_RADIUS * PLAYER_RADIUS - 0.000001


func _player_overlaps_cell(state: Dictionary, cell: Vector2i) -> bool:
	return _circle_intersects_rect(player_position(state), Rect2(Vector2(cell.x - 0.5, cell.y - 0.5), Vector2.ONE))


func _apply(candidate: Dictionary, command: Dictionary, changes: Array[String]) -> String:
	match command.op:
		"say":
			return CompanionLesson.apply(area, candidate, command, changes)
		"bind_key":
			return MovementBindings.apply(area, candidate, command, changes)
		"set_field":
			return _set_field(candidate, command, changes)
		"place", "remove":
			return _bridge(candidate, command, changes)
		_:
			return "Unknown operation '%s'. Use set_field, place or remove." % command.op


func _set_field(candidate: Dictionary, command: Dictionary, changes: Array[String]) -> String:
	if not _keys_match(command, ["op", "entity_id", "field", "value"]):
		return "set_field needs only op, entity_id, field and value."
	if not command.entity_id is String or not command.field is String or not command.value is bool:
		return "entity_id and field must be strings; value must be True or False."
	var entity_id: String = command.entity_id
	var value: bool = command.value
	if command.field == "active":
		var prop: Dictionary = area.prop(entity_id)
		if prop.is_empty() or (prop.interaction as Dictionary).is_empty():
			return "Unknown interactive object '%s'. Read world.props for the working objects." % entity_id
		if not ZoneTerminals.connected(area, candidate, prop.zone): return _unexplored(prop.zone)
		if not PropInteractions.known(candidate, prop):
			return "You have not visited this object's place yet. Walk there before using it in code."
		if not candidate.has("props"):
			candidate.props = {}
		if bool(candidate.props.get(entity_id, false)) != value:
			candidate.props[entity_id] = value
			changes.append(PropInteractions.label(prop, not value))
		return ""
	var lamp: Dictionary = area.lamp(entity_id)
	if not lamp.is_empty() and command.field == "enabled":
		if not _lamp_seen(candidate, lamp):
			return FieldAccess.lamp_reason(area, lamp)
		if candidate.lamps[entity_id] != value:
			candidate.lamps[entity_id] = value
			changes.append("%s %s" % [entity_id, "lit" if value else "extinguished"])
		return ""
	var gate: Dictionary = area.gate(entity_id)
	if not gate.is_empty() and command.field == "open":
		if not _seen(candidate, gate.zone):
			return _unexplored(gate.zone)
		if not value and _player_overlaps_cell(candidate, gate.cell):
			return "Walk off the gate cell before closing it."
		if candidate.gates[entity_id] != value:
			candidate.gates[entity_id] = value
			changes.append("%s %s" % [entity_id, "opened" if value else "closed"])
		return ""
	if lamp.is_empty() and gate.is_empty():
		return "Unknown entity '%s'. Look it up in the World tab: lamps, gates and bridges all have ids." % entity_id
	return "Lamps expose enabled; gates expose open."


func _bridge(candidate: Dictionary, command: Dictionary, changes: Array[String]) -> String:
	var placing: bool = command.op == "place"
	var keys: Array[String] = ["op", "at"]
	if placing:
		keys.insert(1, "kind")
	if not _keys_match(command, keys):
		return "Use place(kind='bridge_deck', at=[x,y,0]) or remove(at=[x,y,0])."
	if placing and command.kind != "bridge_deck":
		return "This prototype can place bridge_deck modules only."
	var at: Variant = command.at
	if not at is Array or at.size() != 3:
		return "at must be a three-number cell [x,y,z]."
	for coordinate: Variant in at:
		if not _whole_number(coordinate):
			return "Cell coordinates must be whole numbers."
	var cell := Vector2i(int(at[0]), int(at[1]))
	var info: Dictionary = area.socket(cell)
	if info.is_empty() or int(at[2]) != 0:
		return "[%d,%d,%d] is not a bridge socket. Read bridge.cells for the real ones." % [cell.x, cell.y, int(at[2])]
	var bridge: Dictionary = area.bridge(info.bridge)
	if not _seen(candidate, bridge.zone):
		return _unexplored(bridge.zone)
	var built: int = int(candidate.bridges[info.bridge])
	var order: int = int(info.order)
	var sockets: Array[Vector2i] = bridge.sockets
	if placing:
		if order < built:
			return ""
		if order > built:
			var next: Vector2i = sockets[built]
			return "Build %s in order: the next socket is [%d,%d,0]." % [bridge.id, next.x, next.y]
		candidate.bridges[info.bridge] = built + 1
		changes.append("Bridge deck placed at [%d,%d,0]" % [cell.x, cell.y])
	else:
		if order >= built:
			return ""
		if _player_overlaps_cell(candidate, cell):
			return "Walk off a bridge deck before removing it."
		if order < built - 1:
			var end: Vector2i = sockets[built - 1]
			return "Remove from the far end first, so every remaining deck stays supported: [%d,%d,0]." % [end.x, end.y]
		candidate.bridges[info.bridge] = built - 1
		changes.append("Bridge deck removed at [%d,%d,0]" % [cell.x, cell.y])
	return ""


func _unexplored(zone_id: String) -> String:
	return FieldAccess.zone_reason(area, zone_id)


static func _keys_match(value: Dictionary, expected: Array[String]) -> bool:
	if value.size() != expected.size():
		return false
	for key: String in expected:
		if not value.has(key):
			return false
	return true


static func _whole_number(value: Variant) -> bool:
	if value is int:
		return value >= -1000000 and value <= 1000000
	if value is float:
		return is_finite(value) and absf(value) <= 1000000.0 and value == floorf(value)
	return false


static func _json_value(value: Variant, depth: int) -> bool:
	if depth > 4:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL:
			return true
		TYPE_INT:
			return value >= -1000000 and value <= 1000000
		TYPE_FLOAT:
			return is_finite(value) and absf(value) <= 1000000.0
		TYPE_STRING:
			return value.to_utf8_buffer().size() <= 256
		TYPE_ARRAY:
			if value.size() > 64:
				return false
			for item: Variant in value:
				if not _json_value(item, depth + 1):
					return false
			return true
		TYPE_DICTIONARY:
			if value.size() > 64:
				return false
			for key: Variant in value:
				if not key is String or key.to_utf8_buffer().size() > 64 or not _json_value(value[key], depth + 1):
					return false
			return true
	return false


static func _reject(state: Dictionary, reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "state": state.duplicate(true), "changes": []}
