class_name AreaBuild
extends RefCounted
## Pure rules for rearranging an area, the rules behind build mode. No nodes, no files: it reads an
## AreaDef (and a LabWorld built from it) and answers "may this go there?", and it turns a list of edits
## into a new area document. The renderer and the interface only ask; they never decide.
##
## An edit is a plain dictionary, kept in order and saved with the player's game:
##   {op: "add",    kind: "building", id, item, asset, at: [x, y], facing, scale}
##   {op: "add",    kind: "tree",     at: [x, y], size}
##   {op: "remove", kind: "building", id}            {op: "remove", kind: "tree", at: [x, y]}
##   {op: "move",   kind: "building", id, at, facing} {op: "move",   kind: "tree", from: [x, y], at: [x, y]}
##   {op: "add",    kind: "prop",     id, item, asset, at: [x, y], facing, scale}
##   {op: "remove", kind: "prop",     id}            {op: "move",   kind: "prop", id, at, facing}
## The area document stays the source of truth; edits are a layer over it (see BuildLedger).
##
## `ctx` for the checks is {area, rules, state, assets}: the AreaDef, its LabWorld, the live world state
## (where the player stands) and the world catalog's `assets` block (for footprints).

const FACING_ORDER: Array[String] = ["S", "E", "N", "W"]
const TREE_STEP: float = 0.5
const TREE_SPACING: float = 0.9
const HOUSE_GAP: float = 0.25
const MIN_TREE_SIZE: float = 0.5
const MAX_TREE_SIZE: float = 2.0
## Props are small, so they snap to a quarter cell.
const PROP_STEP: float = 0.25


# ------------------------------------------------------------------ catalog
static func item(build_catalog: Dictionary, item_id: String) -> Dictionary:
	for entry: Variant in build_catalog.get("items", []):
		if entry is Dictionary and (entry as Dictionary).get("id") == item_id:
			return entry
	return {}


static func policy(build_catalog: Dictionary, policy_id: String) -> Dictionary:
	return (build_catalog.get("policies", {}) as Dictionary).get(policy_id, {})


## The catalog items this policy may offer, in catalog order, optionally for one category.
static func allowed_items(build_catalog: Dictionary, policy_id: String, category: String = "") -> Array[Dictionary]:
	var audience: Array = policy(build_catalog, policy_id).get("audience", [])
	var result: Array[Dictionary] = []
	for entry: Variant in build_catalog.get("items", []):
		if entry is Dictionary and audience.has((entry as Dictionary).get("audience", "studio")) and (category == "" or (entry as Dictionary).get("category") == category):
			result.append(entry)
	return result


## How many things of this kind the player has placed that still stand. Taking one of your own down gives it
## back; moving something that was already in the valley spends nothing.
static func player_made(edits: Array, kind: String) -> int:
	var made: Dictionary = {}
	for edit: Variant in edits:
		if not edit is Dictionary or (edit as Dictionary).get("kind") != kind:
			continue
		var key: String = str((edit as Dictionary).get("id", "")) if kind != "tree" else tree_key(Vector2(float((edit.at as Array)[0]), float((edit.at as Array)[1])))
		match str((edit as Dictionary).get("op")):
			"add":
				made[key] = true
			"remove":
				made.erase(key)
			"move":
				if kind == "tree":
					var from: String = tree_key(Vector2(float((edit.from as Array)[0]), float((edit.from as Array)[1])))
					if made.has(from):
						made.erase(from)
						made[key] = true
	return made.size()


## The most this policy lets a player place of a kind, or -1 for no limit.
static func limit_for(build_catalog: Dictionary, policy_id: String, kind: String) -> int:
	return int((policy(build_catalog, policy_id).get("limits", {}) as Dictionary).get(kind, -1))


## "" if the policy still has room to add this kind of thing, else the reason it does not.
static func limit_reason(build_catalog: Dictionary, policy_id: String, edits: Array, kind: String) -> String:
	var limit: int = limit_for(build_catalog, policy_id, kind)
	if limit >= 0 and player_made(edits, kind) >= limit:
		return "You can add at most %d %s here." % [limit, {"building": "buildings", "prop": "doodads"}.get(kind, "trees")]
	return ""


# ----------------------------------------------------------------- geometry
## The ground a building blocks, from its world-catalog footprint, facing and scale. The same arithmetic as AreaDef.
static func footprint_rect(assets: Dictionary, asset: String, at: Vector2, facing: String, scale: float) -> Rect2:
	var footprint: Variant = (assets.get(asset, {}) as Dictionary).get("logical_footprint")
	if not footprint is Array or (footprint as Array).size() != 4:
		return Rect2()
	var size := Vector2(float(footprint[2]), float(footprint[3]))
	if facing == "E" or facing == "W":
		size = Vector2(size.y, size.x)
	size *= scale
	return Rect2(at - size * 0.5, size)


## Whole cells the footprint covers (cell squares that its interior overlaps).
static func footprint_cells(rect: Rect2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x: int in range(ceili(rect.position.x - 0.5), floori(rect.end.x + 0.5 - 0.000001) + 1):
		for y: int in range(ceili(rect.position.y - 0.5), floori(rect.end.y + 0.5 - 0.000001) + 1):
			cells.append(Vector2i(x, y))
	return cells


## Snaps a building's centre so its edges sit on the cell grid: whole cells for an odd number of cells, half cells for an even one.
static func snap_building(assets: Dictionary, asset: String, facing: String, scale: float, point: Vector2) -> Vector2:
	var size: Vector2 = footprint_rect(assets, asset, Vector2.ZERO, facing, scale).size
	var snapped := Vector2(_snap_axis(point.x, size.x), _snap_axis(point.y, size.y))
	return snapped


static func _snap_axis(value: float, length: float) -> float:
	var cells: int = maxi(1, ceili(length - 0.2))
	return roundf(value) if cells % 2 == 1 else floorf(value) + 0.5


static func snap_tree(point: Vector2) -> Vector2:
	return Vector2(roundf(point.x / TREE_STEP) * TREE_STEP, roundf(point.y / TREE_STEP) * TREE_STEP)


static func snap_prop(point: Vector2) -> Vector2:
	return Vector2(roundf(point.x / PROP_STEP) * PROP_STEP, roundf(point.y / PROP_STEP) * PROP_STEP)


## Does the world catalog give this asset a footprint? A prop that has one blocks movement; one that has none does not.
static func prop_is_solid(assets: Dictionary, asset: String) -> bool:
	var footprint: Variant = (assets.get(asset, {}) as Dictionary).get("logical_footprint")
	return footprint is Array and (footprint as Array).size() == 4


## The ground a prop covers: its catalog footprint if it has one, else a small square. The same arithmetic as AreaDef.
static func prop_rect(assets: Dictionary, asset: String, at: Vector2, facing: String, scale: float) -> Rect2:
	var size := Vector2(AreaDef.PROP_BODY, AreaDef.PROP_BODY)
	if prop_is_solid(assets, asset):
		var footprint: Array = (assets[asset] as Dictionary).logical_footprint
		size = Vector2(float(footprint[2]), float(footprint[3]))
	if facing == "E" or facing == "W":
		size = Vector2(size.y, size.x)
	size *= scale
	return Rect2(at - size * 0.5, size)


## The former threshold cell can intersect the closed leaf. Keep it for the
## closed-entry barrier and migration; players arrive one cell farther outside.
static func threshold_cell(rect: Rect2, at: Vector2, facing: String) -> Vector2i:
	var direction: Vector2i = {"S": Vector2i(0, -1), "E": Vector2i(1, 0), "N": Vector2i(0, 1), "W": Vector2i(-1, 0)}[facing]
	var half: float = rect.size.x * 0.5 if direction.x != 0 else rect.size.y * 0.5
	return Vector2i(roundi(at.x + float(direction.x) * (half + 0.7)), roundi(at.y + float(direction.y) * (half + 0.7)))


## Shared safe landing used by travel, routing and the builder's access checks.
static func door_cell(rect: Rect2, at: Vector2, facing: String, offset: int = 0) -> Vector2i:
	var outward: Vector2i = {"S": Vector2i(0, -1), "E": Vector2i(1, 0), "N": Vector2i(0, 1), "W": Vector2i(-1, 0)}[facing]
	return threshold_cell(rect, at, facing) + outward * offset


## Rotate the catalog's closed leaf into logical ground coordinates.
static func entrance_rect(at: Vector2, facing: String, scale: float, entrance: Dictionary) -> Rect2:
	if entrance.is_empty():return Rect2()
	var leaf:=Rect2(float(entrance.get("center_x",0))-float(entrance.width)*.5,-float(entrance.plane)-.09,float(entrance.width),.18)
	var angle: float=deg_to_rad(float(AreaDef.FACINGS[facing]))
	var barrier:=Rect2(at+leaf.position.rotated(angle)*scale,Vector2.ZERO)
	for corner: Vector2 in [leaf.position,leaf.end,Vector2(leaf.end.x,leaf.position.y),Vector2(leaf.position.x,leaf.end.y)]:barrier=barrier.expand(at+corner.rotated(angle)*scale)
	return barrier


## Model-authored clearance, with an automatic extra cell when scaling/rounding
## would put the original grid stop inside the closed leaf's foot clearance.
static func door_offset(rect: Rect2, at: Vector2, facing: String, scale: float, entrance: Dictionary) -> int:
	if entrance.is_empty():return 0
	var threshold:=Vector2(threshold_cell(rect,at,facing))
	var leaf:=entrance_rect(at,facing,scale,entrance)
	var closest: Vector2=threshold.clamp(leaf.position,leaf.end)
	var overlaps: bool=threshold.distance_squared_to(closest)<LabWorld.PLAYER_RADIUS*LabWorld.PLAYER_RADIUS
	return maxi(int(entrance.get("approach_cells",0)),1 if overlaps else 0)


static func turned(facing: String, steps: int = 1) -> String:
	return FACING_ORDER[posmod(FACING_ORDER.find(facing) + steps, FACING_ORDER.size())]


static func tree_key(at: Vector2) -> String:
	return "%.2f,%.2f" % [at.x, at.y]


# ------------------------------------------------------------------- lookup
## What stands where: a building whose footprint holds the point, or the tree nearest to it. {} if nothing.
static func object_near(area: AreaDef, point: Vector2) -> Dictionary:
	for building: Dictionary in area.buildings:
		if (building.rect as Rect2).grow(0.05).has_point(point):
			return {"kind": "building", "id": building.id, "locked": building.locked, "at": building.at}
	for prop: Dictionary in area.props:
		if (prop.rect as Rect2).grow(0.1).has_point(point):
			return {"kind": "prop", "id": prop.id, "locked": false, "at": prop.at}
	var best: Dictionary = {}
	var best_distance: float = 0.7
	for tree: Dictionary in area.trees:
		var distance: float = (tree.at as Vector2).distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = {"kind": "tree", "at": tree.at, "size": tree.size, "asset": tree.get("asset", ""), "locked": false}
	return best


# ------------------------------------------------------------------- checks
## May this building stand here? {ok, reason, rect, door}. Cheap: safe to ask every frame while a ghost moves.
static func check_building(ctx: Dictionary, asset: String, at: Vector2, facing: String, scale: float, ignore_id: String = "") -> Dictionary:
	var area: AreaDef = ctx.area
	var rect: Rect2 = footprint_rect(ctx.assets, asset, at, facing, scale)
	var result: Dictionary = {"ok": false, "reason": "", "rect": rect, "door": Vector2i(-1, -1)}
	if rect.size == Vector2.ZERO:
		result.reason = "That building has no footprint."
		return result
	result.door = door_cell(rect, at, facing, door_offset(rect,at,facing,scale,ctx.assets[asset].get("entrance",{})))
	if rect.position.x < 0.0 or rect.position.y < 0.0 or rect.end.x > float(area.width) or rect.end.y > float(area.height):
		result.reason = "Keep it inside the valley."
		return result
	for cell: Vector2i in footprint_cells(rect):
		match area.terrain_at(cell):
			AreaDef.Terrain.WATER:
				result.reason = "Water is in the way."
				return result
			AreaDef.Terrain.ROCK:
				result.reason = "There is rock under it."
				return result
		if not area.socket(cell).is_empty():
			result.reason = "That crossing must stay clear."
			return result
		if cell == area.spawn:
			result.reason = "Keep the starting spot clear."
			return result
		for gate: Dictionary in area.gates:
			if gate.cell == cell:
				result.reason = "The gate needs its doorway."
				return result
	var level_reason: String = _level_reason(area, rect)
	if level_reason != "":
		result.reason = level_reason
		return result
	for other: Dictionary in area.buildings:
		if other.id != ignore_id and rect.grow(HOUSE_GAP).intersects(other.rect):
			result.reason = "Another building is too close."
			return result
	for prop: Dictionary in area.props:
		if rect.grow(0.1).intersects(prop.rect):
			result.reason = "A doodad is in the way."
			return result
	for wheel: Dictionary in area.wheels:
		if rect.grow(0.2).intersects(wheel.rect):
			result.reason = "The mill wheel needs room to turn."
			return result
	for segment: Dictionary in area.segments:
		if rect.grow(0.2).intersects(segment.rect):
			result.reason = "A %s runs through there." % ("wall" if segment.kind == "wall" else "fence")
			return result
	for lamp: Dictionary in area.lamps:
		if rect.grow(0.5).has_point(lamp.at):
			result.reason = "A lamp needs room around it."
			return result
	for tree: Dictionary in area.trees:
		if rect.grow(maxf(0.55, float(tree.get("trunk_radius", 0.18)) + 0.18)).has_point(tree.at):
			result.reason = "A tree stands in the way."
			return result
	for villager: Dictionary in area.villagers:
		var stops: Array = [villager.at]
		stops.append_array(villager.route)
		for stop: Vector2i in stops:
			if rect.grow(0.5).has_point(Vector2(stop)):
				result.reason = "Leave room for %s's walking route." % str(villager.id).capitalize()
				return result
	var player: Vector2 = Vector2(float(ctx.state.player[0]), float(ctx.state.player[1]))
	if rect.grow(0.4).has_point(player):
		result.reason = "You are standing there."
		return result
	var door: Vector2i = result.door
	if not area.in_bounds(door) or area.terrain_at(door) == AreaDef.Terrain.WATER or area.terrain_at(door) == AreaDef.Terrain.ROCK or rect.grow(0.2).has_point(Vector2(door)):
		result.reason = "The door needs open ground in front of it."
		return result
	if area.level_at(door) != area.level_under(rect) or not area.stair_at(door).is_empty():
		result.reason = "The door needs level ground in front of it."
		return result
	for other: Dictionary in area.buildings:
		if other.id != ignore_id and (other.rect as Rect2).grow(0.3).has_point(Vector2(door)):
			result.reason = "The door would open onto another wall."
			return result
	result.ok = true
	return result


## May this prop stand here? {ok, reason, rect}. Props are small, so the rules are lighter than a building's: open
## ground and clear of other things, and, for one that blocks movement, not on the player or a resident's stops.
## It has no door. Whether the valley stays whole is the ledger's cut-off check.
static func check_prop(ctx: Dictionary, asset: String, at: Vector2, facing: String, scale: float, ignore_id: String = "") -> Dictionary:
	var area: AreaDef = ctx.area
	var rect: Rect2 = prop_rect(ctx.assets, asset, at, facing, scale)
	var result: Dictionary = {"ok": false, "reason": "", "rect": rect}
	if not ctx.assets.has(asset):
		result.reason = "That has no model."
		return result
	if rect.position.x < 0.0 or rect.position.y < 0.0 or rect.end.x > float(area.width) or rect.end.y > float(area.height):
		result.reason = "Keep it inside the valley."
		return result
	for cell: Vector2i in footprint_cells(rect):
		match area.terrain_at(cell):
			AreaDef.Terrain.WATER:
				result.reason = "Water is in the way."
				return result
			AreaDef.Terrain.ROCK:
				result.reason = "There is rock under it."
				return result
		if not area.socket(cell).is_empty():
			result.reason = "That crossing must stay clear."
			return result
		if cell == area.spawn:
			result.reason = "Keep the starting spot clear."
			return result
		for gate: Dictionary in area.gates:
			if gate.cell == cell:
				result.reason = "The gate needs its doorway."
				return result
	var level_reason: String = _level_reason(area, rect)
	if level_reason != "":
		result.reason = level_reason
		return result
	for building: Dictionary in area.buildings:
		if rect.grow(0.05).intersects(building.rect):
			result.reason = "A building is in the way."
			return result
	for other: Dictionary in area.props:
		if other.id != ignore_id and rect.intersects(other.rect):
			result.reason = "Another doodad is there."
			return result
	for wheel: Dictionary in area.wheels:
		if rect.grow(0.1).intersects(wheel.rect):
			result.reason = "The mill wheel needs room to turn."
			return result
	for segment: Dictionary in area.segments:
		if rect.grow(0.1).intersects(segment.rect):
			result.reason = "A %s runs through there." % ("wall" if segment.kind == "wall" else "fence")
			return result
	for lamp: Dictionary in area.lamps:
		if rect.grow(0.3).has_point(lamp.at):
			result.reason = "A lamp needs room around it."
			return result
	for tree: Dictionary in area.trees:
		if rect.grow(float(tree.get("trunk_radius", LabWorld.TRUNK_RADIUS)) + 0.1).has_point(tree.at):
			result.reason = "A tree stands in the way."
			return result
	if prop_is_solid(ctx.assets, asset):
		for villager: Dictionary in area.villagers:
			var stops: Array = [villager.at]
			stops.append_array(villager.route)
			for stop: Vector2i in stops:
				if rect.grow(0.5).has_point(Vector2(stop)):
					result.reason = "Leave room for %s's walking route." % str(villager.id).capitalize()
					return result
		var player: Vector2 = Vector2(float(ctx.state.player[0]), float(ctx.state.player[1]))
		if rect.grow(0.4).has_point(player):
			result.reason = "You are standing there."
			return result
	result.ok = true
	return result


## May a tree of this size stand here? {ok, reason}. `ignore_key` is a tree being moved (see tree_key).
static func check_tree(ctx: Dictionary, at: Vector2, size: float, ignore_key: String = "", asset: String = "") -> Dictionary:
	var area: AreaDef = ctx.area
	var result: Dictionary = {"ok": false, "reason": ""}
	var radius: float = LabWorld.TRUNK_RADIUS
	if asset != "":
		var footprint: Variant = (ctx.assets.get(asset, {}) as Dictionary).get("logical_footprint")
		if not footprint is Dictionary or not footprint.has("trunk_radius"):
			return {"ok": false, "reason": "That tree has no trunk footprint."}
		radius = float(footprint.trunk_radius) * size
	if size < MIN_TREE_SIZE or size > MAX_TREE_SIZE:
		result.reason = "That tree is the wrong size."
		return result
	var cell := Vector2i(roundi(at.x), roundi(at.y))
	if at.x < 0.25 or at.y < 0.25 or at.x > float(area.width) - 1.25 or at.y > float(area.height) - 1.25:
		result.reason = "Keep it inside the valley."
		return result
	match area.terrain_at(cell):
		AreaDef.Terrain.WATER:
			result.reason = "Trees do not grow on water."
			return result
		AreaDef.Terrain.ROCK:
			result.reason = "Trees do not grow in rock."
			return result
		AreaDef.Terrain.PATH, AreaDef.Terrain.COBBLE:
			result.reason = "Keep the paths clear."
			return result
	if not area.socket(cell).is_empty() or cell == area.spawn:
		result.reason = "That spot must stay clear."
		return result
	var level_reason: String = _level_reason(area, Rect2(at, Vector2.ZERO).grow(radius))
	if level_reason != "":
		result.reason = "Trees need level ground." if level_reason.begins_with("The ground") else level_reason
		return result
	for gate: Dictionary in area.gates:
		if Vector2(gate.cell).distance_to(at) < 1.0:
			result.reason = "The gate needs its doorway."
			return result
	for other: Dictionary in area.trees:
		if tree_key(other.at) != ignore_key and (other.at as Vector2).distance_to(at) < maxf(TREE_SPACING, radius + float(other.get("trunk_radius", LabWorld.TRUNK_RADIUS)) + 0.2):
			result.reason = "Trees need a little room."
			return result
	for building: Dictionary in area.buildings:
		if (building.rect as Rect2).grow(maxf(0.6, radius + 0.2)).has_point(at):
			result.reason = "Too close to a building."
			return result
	for prop: Dictionary in area.props:
		if (prop.rect as Rect2).grow(maxf(0.35, radius + 0.1)).has_point(at):
			result.reason = "A doodad is in the way."
			return result
	for lamp: Dictionary in area.lamps:
		if (lamp.at as Vector2).distance_to(at) < 1.1:
			result.reason = "Too close to a lamp."
			return result
	for wheel: Dictionary in area.wheels:
		if (wheel.rect as Rect2).grow(0.5).has_point(at):
			result.reason = "The mill wheel needs room."
			return result
	for segment: Dictionary in area.segments:
		if (segment.rect as Rect2).grow(0.4).has_point(at):
			result.reason = "A %s is there." % ("wall" if segment.kind == "wall" else "fence")
			return result
	for villager: Dictionary in area.villagers:
		var stops: Array = [villager.at]
		stops.append_array(villager.route)
		for stop: Vector2i in stops:
			if Vector2(stop).distance_to(at) < radius + LabWorld.PLAYER_RADIUS + 0.3:
				result.reason = "Leave room for %s's walking route." % str(villager.id).capitalize()
				return result
	var player: Vector2 = Vector2(float(ctx.state.player[0]), float(ctx.state.player[1]))
	if player.distance_to(at) < 0.8:
		result.reason = "You are standing there."
		return result
	result.ok = true
	return result


## "" if everything over this rect stands on one level and off any stairs, else why not.
static func _level_reason(area: AreaDef, rect: Rect2) -> String:
	for cell: Vector2i in footprint_cells(rect):
		if not area.stair_at(cell).is_empty():
			return "Stairs are in the way."
	if area.level_under(rect) < 0:
		return "The ground under it is not level."
	return ""


## May this thing be taken away? Locked things belong to the lessons or to another object.
static func check_remove(area: AreaDef, kind: String, reference: Variant) -> Dictionary:
	if kind == "building":
		var building: Dictionary = area.building(str(reference))
		if building.is_empty():
			return {"ok": false, "reason": "There is nothing there."}
		if building.locked:
			return {"ok": false, "reason": "This building is part of the lessons and cannot be moved or removed."}
		return {"ok": true, "reason": ""}
	if kind == "prop":
		if area.prop(str(reference)).is_empty():
			return {"ok": false, "reason": "There is nothing there."}
		return {"ok": true, "reason": ""}
	if kind == "stairs":
		return {"ok": true, "reason": ""} if reference is Vector2i and not area.stair_at(reference).is_empty() else {"ok": false, "reason": "There are no stairs there."}
	for tree: Dictionary in area.trees:
		if tree_key(tree.at) == str(reference):
			return {"ok": true, "reason": ""}
	return {"ok": false, "reason": "There is nothing there."}


# ------------------------------------------------------------------ terrain
## The land tools: `raise` and `lower` move a cell's land one level toward a target level; `water` digs a pond or a
## river (at the cell's own level, so water on a high level that runs on to a lower one falls); `land` fills water in.
const LAND_TOOLS: Array[String] = ["raise", "lower", "water", "land"]


## Why each cell's ground must stay as it is: {Vector2i: reason} for everything that stands on it or needs it as it
## is. Cells under things never move, so nothing ever floats or sinks; take the thing away first.
static func land_blockers(area: AreaDef) -> Dictionary:
	var blocked: Dictionary = {}
	var mark := func(cell: Vector2i, reason: String) -> void:
		if not blocked.has(cell):
			blocked[cell] = reason
	var cover := func(rect: Rect2, reason: String) -> void:
		for cell: Vector2i in footprint_cells(rect):
			mark.call(cell, reason)
	mark.call(area.spawn, "Keep the starting spot as it is.")
	for building: Dictionary in area.buildings:
		cover.call((building.rect as Rect2).grow(0.05), "A building stands there.")
		mark.call(door_cell(building.rect, building.at, building.facing, int(building.get("door_offset",0))), "Keep the ground before a door as it is.")
	for prop: Dictionary in area.props:
		cover.call((prop.rect as Rect2).grow(0.05), "A doodad stands there.")
	for tree: Dictionary in area.trees:
		cover.call(Rect2(tree.at, Vector2.ZERO).grow(float(tree.get("trunk_radius", LabWorld.TRUNK_RADIUS)) + 0.05), "A tree stands there.")
	for lamp: Dictionary in area.lamps:
		cover.call(Rect2(lamp.at, Vector2.ZERO).grow(0.45), "A lamp stands there.")
	for gate: Dictionary in area.gates:
		for step: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			mark.call((gate.cell as Vector2i) + step, "The gate needs its ground as it is.")
	for bridge: Dictionary in area.bridges:
		for socket: Vector2i in bridge.sockets:
			for dx: int in range(-1, 2):
				for dy: int in range(-1, 2):
					mark.call(socket + Vector2i(dx, dy), "The bridge needs its banks as they are.")
	for wheel: Dictionary in area.wheels:
		cover.call((wheel.rect as Rect2).grow(0.5), "The mill wheel needs its race as it is.")
	for segment: Dictionary in area.segments:
		cover.call((segment.rect as Rect2).grow(0.1), "A %s runs there." % ("wall" if segment.kind == "wall" else "fence"))
	for flight: Dictionary in area.stairs:
		for cell: Vector2i in [flight.at, (flight.at as Vector2i) - (flight.dir as Vector2i), (flight.at as Vector2i) + (flight.dir as Vector2i)]:
			mark.call(cell, "Stairs stand there. Take them away first.")
	for villager: Dictionary in area.villagers:
		var stops: Array = [villager.at]
		stops.append_array(villager.route)
		for stop: Vector2i in stops:
			mark.call(stop, "Leave %s's walking route as it is." % str(villager.id).capitalize())
	return blocked


## "" if this land tool may change this cell (raise and lower move it toward `level`), else why not. Cheap: a drag
## asks it for every cell it crosses. `blockers` is land_blockers(area).
static func land_reason(area: AreaDef, blockers: Dictionary, state: Dictionary, tool: String, cell: Vector2i, level: int = 0) -> String:
	if not area.in_bounds(cell):
		return "Keep it inside the valley."
	var terrain: int = area.terrain_at(cell)
	if terrain == AreaDef.Terrain.ROCK:
		return "Rock stays as it is."
	var current: int = area.level_at(cell)
	match tool:
		"raise":
			if level > AreaDef.MAX_LEVEL:
				return "Land rises no higher than level %d." % AreaDef.MAX_LEVEL
			if current >= level:
				return "That ground is up there already."
		"lower":
			if level < 0:
				return "This is the valley floor. Dig water to go lower."
			if current <= level:
				return "That ground is down there already."
		"water":
			if terrain == AreaDef.Terrain.WATER:
				return "That is water already."
		"land":
			if terrain != AreaDef.Terrain.WATER:
				return "That is dry land already."
		_:
			return "Choose a land tool."
	if blockers.has(cell):
		return str(blockers[cell])
	var player := Vector2(float(state.player[0]), float(state.player[1]))
	if Rect2(Vector2(cell) - Vector2(0.5, 0.5), Vector2.ONE).grow(LabWorld.PLAYER_RADIUS).has_point(player):
		return "You are standing there."
	return ""


## Which way stairs on this cell could climb: `preferred` if a neighbour that way is one level up, else the next such
## way turning clockwise, else "".
static func stairs_direction(area: AreaDef, at: Vector2i, preferred: String) -> String:
	var start: int = maxi(0, FACING_ORDER.find(preferred))
	for turn: int in range(FACING_ORDER.size()):
		var up: String = FACING_ORDER[(start + turn) % FACING_ORDER.size()]
		var above: Vector2i = at + (AreaDef.STEPS[up] as Vector2i)
		if area.in_bounds(above) and area.level_at(above) == area.level_at(at) + 1:
			return up
	return ""


## May a flight of stairs stand on `at`, climbing toward `up`? {ok, reason}. Cheap: safe to ask every frame.
static func check_stairs(ctx: Dictionary, at: Vector2i, up: String) -> Dictionary:
	var area: AreaDef = ctx.area
	var refuse := func(reason: String) -> Dictionary: return {"ok": false, "reason": reason}
	if not AreaDef.STEPS.has(up):
		return refuse.call("Stairs climb one level: set them at the foot of a cliff.")
	var dir: Vector2i = AreaDef.STEPS[up]
	for cell: Vector2i in [at - dir, at, at + dir]:
		if not area.in_bounds(cell):
			return refuse.call("Keep them inside the valley.")
		if area.terrain_at(cell) in [AreaDef.Terrain.WATER, AreaDef.Terrain.ROCK]:
			return refuse.call("Stairs need dry ground below, on and above them.")
	if not area.stair_at(at).is_empty():
		return refuse.call("There are stairs here already.")
	if area.level_at(at - dir) != area.level_at(at) or area.level_at(at + dir) != area.level_at(at) + 1:
		return refuse.call("Stairs climb one level: set them at the foot of a cliff, facing up it.")
	if not area.stair_at(at - dir).is_empty() or not area.stair_at(at + dir).is_empty():
		return refuse.call("Stairs cannot lead straight onto more stairs.")
	if not area.socket(at).is_empty() or at == area.spawn:
		return refuse.call("That spot must stay clear.")
	var body := Rect2(Vector2(at) - Vector2(0.5, 0.5), Vector2.ONE)
	for gate: Dictionary in area.gates:
		if gate.cell == at:
			return refuse.call("The gate needs its doorway.")
	for building: Dictionary in area.buildings:
		if body.intersects((building.rect as Rect2).grow(0.05)):
			return refuse.call("A building is in the way.")
		if door_cell(building.rect, building.at, building.facing, int(building.get("door_offset",0))) == at:
			return refuse.call("Keep the ground before a door clear.")
	for prop: Dictionary in area.props:
		if body.intersects(prop.rect):
			return refuse.call("A doodad is in the way.")
	for tree: Dictionary in area.trees:
		if body.grow(float(tree.get("trunk_radius", LabWorld.TRUNK_RADIUS))).has_point(tree.at):
			return refuse.call("A tree stands in the way.")
	for lamp: Dictionary in area.lamps:
		if body.grow(0.2).has_point(lamp.at):
			return refuse.call("A lamp stands in the way.")
	for wheel: Dictionary in area.wheels:
		if body.intersects((wheel.rect as Rect2).grow(0.2)):
			return refuse.call("The mill wheel needs room to turn.")
	for segment: Dictionary in area.segments:
		if body.intersects(segment.rect):
			return refuse.call("A %s runs through there." % ("wall" if segment.kind == "wall" else "fence"))
	if body.has_point(Vector2(float(ctx.state.player[0]), float(ctx.state.player[1]))):
		return refuse.call("You are standing there.")
	# Stairs are walked only along their line, so both ends must be somewhere a person can stand.
	var rules: LabWorld = ctx.rules
	if not rules.can_ever_stand(Vector2(at - dir)):
		return refuse.call("Leave room at the foot of the stairs.")
	if not rules.can_ever_stand(Vector2(at + dir)):
		return refuse.call("Leave room at the top of the stairs.")
	return {"ok": true, "reason": ""}


# --------------------------------------------------------------- reachability
## The open version of a world: every gate open, every bridge built, the player where they stand.
static func open_state(rules: LabWorld, player_cell: Vector2i) -> Dictionary:
	var state: Dictionary = rules.initial_state()
	for gate: Dictionary in rules.area.gates:
		state.gates[gate.id] = true
	for bridge: Dictionary in rules.area.bridges:
		state.bridges[bridge.id] = (bridge.sockets as Array).size()
	state.player = [player_cell.x, player_cell.y, 0]
	return state


static func flood(rules: LabWorld, state: Dictionary, from: Vector2i) -> Dictionary:
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	var cursor: int = 0
	while cursor < queue.size():
		var current: Vector2i = queue[cursor]
		cursor += 1
		for delta: Vector2i in LabWorld.DIRECTIONS:
			var next: Vector2i = current + delta
			if not seen.has(next) and rules.can_step(state, current, next):
				seen[next] = true
				queue.append(next)
	return seen


## The things the player must always be able to reach: {label, cells}. A group is met if any of its cells is reachable.
static func needs(area: AreaDef, skip_building: Variant = "") -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	for lamp: Dictionary in area.lamps:
		var cells: Array = []
		for dx: int in range(-1, 2):
			for dy: int in range(-1, 2):
				cells.append((lamp.cell as Vector2i) + Vector2i(dx, dy))
		groups.append({"label": "the lamp \"%s\"" % lamp.id, "cells": cells})
	for zone: Dictionary in area.zones:
		var rect: Rect2i = zone.rect
		var cells: Array = []
		for x: int in range(rect.position.x, rect.end.x):
			for y: int in range(rect.position.y, rect.end.y):
				cells.append(Vector2i(x, y))
		groups.append({"label": "%s" % zone.title, "cells": cells})
	for building: Dictionary in area.buildings:
		if not _skipped(building.id, skip_building):
			groups.append({"label": "the door of %s" % building.id, "cells": [door_cell(building.rect, building.at, building.facing, int(building.get("door_offset",0)))]})
	for resident: Dictionary in area.villagers:
		var stops: Array = [resident.at]
		stops.append_array(resident.route)
		for index: int in range(stops.size()):
			groups.append({"label": "%s's walking stop %d" % [str(resident.id).capitalize(), index + 1], "cells": [stops[index]]})
	groups.append({"label": "the starting spot", "cells": [area.spawn]})
	return groups


## `skip` is one building id or a list of them: the buildings whose own door need not stay reachable (the ones being moved).
static func _skipped(id: Variant, skip: Variant) -> bool:
	return (skip is Array and (skip as Array).has(id)) or (skip is String and id == skip)


## "" if every group that could be reached before can still be reached after; otherwise the first thing cut off.
static func reach_problem(before: Dictionary, after: Dictionary, player_cell: Vector2i, skip_building: Variant = "") -> String:
	var open_before: Dictionary = open_state(before.rules, player_cell)
	var open_after: Dictionary = open_state(after.rules, player_cell)
	if not (after.rules as LabWorld).is_walkable(open_after, player_cell):
		return "You are standing there."
	var reach_before: Dictionary = flood(before.rules, open_before, player_cell)
	var reach_after: Dictionary = flood(after.rules, open_after, player_cell)
	var after_labels: Dictionary = {}
	for group: Dictionary in needs(after.area, skip_building):
		after_labels[group.label] = group
	for group: Dictionary in needs(before.area, skip_building):
		var met_before: bool = false
		for cell: Vector2i in group.cells:
			if reach_before.has(cell):
				met_before = true
				break
		if not met_before or not after_labels.has(group.label):
			continue
		var met_after: bool = false
		for cell: Vector2i in (after_labels[group.label] as Dictionary).cells:
			if reach_after.has(cell):
				met_after = true
				break
		if not met_after:
			return "That would cut you off from %s." % group.label
	return ""


# ---------------------------------------------------------------------- diff
## What changed between two worlds, for showing a proposal: {added, removed, changed}, each a list of
## {kind: "building"|"prop"|"tree", id (not for trees), asset, at, facing, scale, size (trees), from: {at, facing} (changed)}.
## A tree that moved reads as one removed and one added, since trees have no identity.
static func diff(before: AreaDef, after: AreaDef) -> Dictionary:
	var result: Dictionary = {"added": [], "removed": [], "changed": []}
	for kind: String in ["building", "prop"]:
		var was: Array = before.buildings if kind == "building" else before.props
		var now: Array = after.buildings if kind == "building" else after.props
		var old_by_id: Dictionary = {}
		for thing: Dictionary in was:
			old_by_id[thing.id] = thing
		var seen: Dictionary = {}
		for thing: Dictionary in now:
			seen[thing.id] = true
			var entry: Dictionary = {"kind": kind, "id": thing.id, "asset": thing.asset, "at": thing.at, "facing": thing.facing, "scale": thing.scale}
			if not old_by_id.has(thing.id):
				(result.added as Array).append(entry)
			else:
				var old: Dictionary = old_by_id[thing.id]
				if old.at != thing.at or old.facing != thing.facing:
					entry["from"] = {"at": old.at, "facing": old.facing}
					(result.changed as Array).append(entry)
		for thing: Dictionary in was:
			if not seen.has(thing.id):
				(result.removed as Array).append({"kind": kind, "id": thing.id, "asset": thing.asset, "at": thing.at, "facing": thing.facing, "scale": thing.scale})
	var old_trees: Dictionary = {}
	for tree: Dictionary in before.trees:
		old_trees[tree_key(tree.at)] = tree
	var new_trees: Dictionary = {}
	for tree: Dictionary in after.trees:
		new_trees[tree_key(tree.at)] = tree
		if not old_trees.has(tree_key(tree.at)):
			(result.added as Array).append({"kind": "tree", "asset": tree.get("asset", ""), "at": tree.at, "size": tree.size, "facing": "S", "scale": 1.0})
	for key: String in old_trees:
		if not new_trees.has(key):
			var gone: Dictionary = old_trees[key]
			(result.removed as Array).append({"kind": "tree", "asset": gone.get("asset", ""), "at": gone.at, "size": gone.size, "facing": "S", "scale": 1.0})
	return result


# ----------------------------------------------------------------- applying
## The area document with `edits` applied in order. Returns {document, skipped}: an edit that no longer fits
## (its target is gone, an id is taken) is skipped and reported rather than guessed at.
static func apply(document: Dictionary, edits: Array, paint_materials: Array = GroundPaint.DEFAULT_PALETTE) -> Dictionary:
	var result: Dictionary = document.duplicate(true)
	var skipped: Array = []
	for edit: Variant in edits:
		if not edit is Dictionary or not _apply_one(result, edit, paint_materials):
			skipped.append(edit)
	return {"document": result, "skipped": skipped}


static func next_building_id(document: Dictionary) -> String:
	var highest: int = 0
	for entry: Variant in document.get("buildings", []):
		var id: String = str((entry as Dictionary).get("id", ""))
		if id.begins_with("build-") and id.substr(6).is_valid_int():
			highest = maxi(highest, id.substr(6).to_int())
	return "build-%d" % (highest + 1)


static func next_prop_id(document: Dictionary) -> String:
	var highest: int = 0
	for entry: Variant in document.get("props", []):
		var id: String = str((entry as Dictionary).get("id", ""))
		if id.begins_with("prop-") and id.substr(5).is_valid_int():
			highest = maxi(highest, id.substr(5).to_int())
	return "prop-%d" % (highest + 1)


static func _apply_one(document: Dictionary, edit: Dictionary, paint_materials: Array) -> bool:
	var kind: String = str(edit.get("kind", ""))
	var op: String = str(edit.get("op", ""))
	if op == "paint":
		return _apply_paint(document, edit, paint_materials)
	if op == "level":
		return _apply_level(document, edit)
	if op == "water" or op == "land":
		return _apply_water(document, edit, op == "water")
	if kind == "stairs":
		var flights: Array = document.get("stairs", [])
		var at: Variant = edit.get("at")
		if not _point(at) or float(at[0]) != floorf(float(at[0])) or float(at[1]) != floorf(float(at[1])):
			return false
		var found: int = -1
		for index: int in range(flights.size()):
			var other: Variant = (flights[index] as Dictionary).get("at") if flights[index] is Dictionary else null
			if _point(other) and int(other[0]) == int(at[0]) and int(other[1]) == int(at[1]):
				found = index
		match op:
			"add":
				if found >= 0 or not AreaDef.STEPS.has(str(edit.get("up", ""))):
					return false
				flights.append({"at": [int(at[0]), int(at[1])], "up": str(edit.up)})
				document["stairs"] = flights
				return true
			"remove":
				if found < 0:
					return false
				flights.remove_at(found)
				return true
		return false
	if op == "finish":
		for key: Variant in edit:
			if not key in ["op", "kind", "id", "slot", "material"]:
				return false
		if not edit.get("slot") is String or not edit.get("material") is String:
			return false
		var target: Dictionary
		if kind == "room":
			if not document.get("interior") is Dictionary or edit.get("id", "") != "":
				return false
			target = document.interior
		elif kind in ["building", "prop"]:
			var bodies: Array = document.get("buildings" if kind == "building" else "props", [])
			var index: int = _find_building(bodies, str(edit.get("id", "")))
			if index < 0:
				return false
			target = bodies[index]
		else:
			return false
		var finishes: Dictionary = target.get("finishes", {}).duplicate(true)
		if edit.material == "":
			finishes.erase(edit.slot)
		else:
			finishes[edit.slot] = edit.material
		target["finishes"] = finishes
		return true
	if kind == "building":
		var buildings: Array = document.get("buildings", [])
		var index: int = _find_building(buildings, str(edit.get("id", "")))
		match op:
			"add":
				if index >= 0 or not _point(edit.get("at")) or not edit.get("asset") is String:
					return false
				buildings.append({"id": edit.id, "asset": edit.asset, "at": [float(edit.at[0]), float(edit.at[1])], "facing": str(edit.get("facing", "S")), "scale": float(edit.get("scale", 1.0))})
				return true
			"remove":
				if index < 0:
					return false
				buildings.remove_at(index)
				return true
			"move":
				if index < 0 or not _point(edit.get("at")):
					return false
				(buildings[index] as Dictionary)["at"] = [float(edit.at[0]), float(edit.at[1])]
				if edit.has("facing"):
					(buildings[index] as Dictionary)["facing"] = str(edit.facing)
				return true
		return false
	if kind == "prop":
		var props: Array = document.get("props", [])
		var index: int = _find_building(props, str(edit.get("id", "")))
		match op:
			"add":
				if index >= 0 or not _point(edit.get("at")) or not edit.get("asset") is String:
					return false
				props.append({"id": edit.id, "asset": edit.asset, "at": [float(edit.at[0]), float(edit.at[1])], "facing": str(edit.get("facing", "S")), "scale": float(edit.get("scale", 1.0))})
				document["props"] = props
				return true
			"remove":
				if index < 0:
					return false
				props.remove_at(index)
				return true
			"move":
				if index < 0 or not _point(edit.get("at")):
					return false
				(props[index] as Dictionary)["at"] = [float(edit.at[0]), float(edit.at[1])]
				if edit.has("facing"):
					(props[index] as Dictionary)["facing"] = str(edit.facing)
				return true
		return false
	if kind == "tree":
		var trees: Array = document.get("trees", [])
		match op:
			"add":
				if not _point(edit.get("at")):
					return false
				if edit.get("asset", "") != "":
					trees.append({"at": [float(edit.at[0]), float(edit.at[1])], "size": float(edit.get("size", 1.0)), "asset": str(edit.asset)})
				else:
					trees.append([float(edit.at[0]), float(edit.at[1]), float(edit.get("size", 1.0))])
				return true
			"remove":
				var index: int = _find_tree(trees, edit.get("at"))
				if index < 0:
					return false
				trees.remove_at(index)
				return true
			"move":
				var index: int = _find_tree(trees, edit.get("from"))
				if index < 0 or not _point(edit.get("at")):
					return false
				if trees[index] is Dictionary:
					trees[index].at = [float(edit.at[0]), float(edit.at[1])]
				else:
					var size: float = float((trees[index] as Array)[2]) if (trees[index] as Array).size() > 2 else 1.0
					trees[index] = [float(edit.at[0]), float(edit.at[1]), size]
				return true
		return false
	return false


## Validate a whole stroke before touching its rows. Water/rock entries are ignored; malformed or
## out-of-map coordinates reject the entire edit. A drag stores only unique paintable sub-tiles.
static func _apply_paint(document: Dictionary, edit: Dictionary, paint_materials: Array) -> bool:
	if not edit.get("material") is String or not edit.get("cells") is Array or edit.cells.is_empty():
		return false
	var material: String = edit.material
	if material != "" and not paint_materials.has(material):
		return false
	var width: int = int(document.size[0]) * 2
	var height: int = int(document.size[1]) * 2
	for cell: Variant in edit.cells:
		if not _point(cell) or not is_finite(float(cell[0])) or not is_finite(float(cell[1])) or float(cell[0]) != floorf(float(cell[0])) or float(cell[1]) != floorf(float(cell[1])):
			return false
		if int(cell[0]) < 0 or int(cell[1]) < 0 or int(cell[0]) >= width or int(cell[1]) >= height:
			return false
	var paint: Dictionary = document.get("paint", {}).duplicate(true)
	if paint.is_empty():
		var rows: Array = []
		for row: int in range(height):
			rows.append(".".repeat(width))
		paint = {"version": 1, "palette": GroundPaint.DEFAULT_PALETTE.duplicate(), "roughen": 0.4, "rows": rows}
	var index: int = (paint.palette as Array).find(material)
	if material != "" and index < 0:
		if paint.palette.size() >= 36:
			return false
		index = paint.palette.size()
		paint.palette.append(material)
	var glyph: String = "." if material == "" else GroundPaint.DIGITS[index]
	for cell: Array in edit.cells:
		var row: int = height - 1 - int(cell[1])
		var terrain: String = document.terrain[row / 2][int(cell[0]) / 2]
		if terrain == "~" or terrain == "#":
			continue
		var line: String = paint.rows[row]
		line[int(cell[0])] = glyph
		paint.rows[row] = line
	document["paint"] = paint
	return true


## Sets each listed cell's land to one level. The `levels` rows are made (all valley floor) the first time.
static func _apply_level(document: Dictionary, edit: Dictionary) -> bool:
	var level: Variant = edit.get("level")
	if not (level is int or level is float) or float(level) != floorf(float(level)) or int(level) < 0 or int(level) > AreaDef.MAX_LEVEL:
		return false
	var cells: Array[Vector2i] = _edit_cells(document, edit)
	if cells.is_empty():
		return false
	var width: int = int(document.size[0])
	var height: int = int(document.size[1])
	var rows: Array = (document.get("levels", []) as Array).duplicate()
	if rows.size() != height:
		rows.clear()
		for row: int in range(height):
			rows.append("0".repeat(width))
	for cell: Vector2i in cells:
		var line: String = rows[height - 1 - cell.y]
		line[cell.x] = str(int(level))
		rows[height - 1 - cell.y] = line
	document["levels"] = rows
	return true


## Digs water into dry ground (`fill`), or fills water in with grass. Rock and the other kind are left alone. Dug
## cells lose their ground paint, as water and rock never keep any.
static func _apply_water(document: Dictionary, edit: Dictionary, fill: bool) -> bool:
	var cells: Array[Vector2i] = _edit_cells(document, edit)
	if cells.is_empty():
		return false
	var height: int = int(document.size[1])
	var rows: Array = (document.terrain as Array).duplicate()
	var paint: Dictionary = document.get("paint", {})
	for cell: Vector2i in cells:
		var line: String = rows[height - 1 - cell.y]
		var glyph: String = line[cell.x]
		if fill and glyph in [".", ",", "="]:
			line[cell.x] = "~"
			if not paint.is_empty():
				for sub_y: int in [cell.y * 2, cell.y * 2 + 1]:
					var paint_line: String = paint.rows[height * 2 - 1 - sub_y]
					paint_line[cell.x * 2] = "."
					paint_line[cell.x * 2 + 1] = "."
					paint.rows[height * 2 - 1 - sub_y] = paint_line
		elif not fill and glyph == "~":
			line[cell.x] = "."
		rows[height - 1 - cell.y] = line
	document["terrain"] = rows
	return true


## The whole cells an edit lists, all inside the document, or none if any is malformed.
static func _edit_cells(document: Dictionary, edit: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var listed: Variant = edit.get("cells")
	if not listed is Array or (listed as Array).is_empty():
		return cells
	for raw: Variant in listed:
		if not _point(raw) or not is_finite(float(raw[0])) or not is_finite(float(raw[1])) or float(raw[0]) != floorf(float(raw[0])) or float(raw[1]) != floorf(float(raw[1])):
			cells.clear()
			return cells
		var cell := Vector2i(int(raw[0]), int(raw[1]))
		if cell.x < 0 or cell.y < 0 or cell.x >= int(document.size[0]) or cell.y >= int(document.size[1]):
			cells.clear()
			return cells
		cells.append(cell)
	return cells


static func _find_building(buildings: Array, id: String) -> int:
	for index: int in range(buildings.size()):
		if (buildings[index] as Dictionary).get("id") == id:
			return index
	return -1


static func _find_tree(trees: Array, at: Variant) -> int:
	if not _point(at):
		return -1
	for index: int in range(trees.size()):
		var entry: Array = trees[index].at if trees[index] is Dictionary else trees[index]
		if absf(float(entry[0]) - float(at[0])) < 0.011 and absf(float(entry[1]) - float(at[1])) < 0.011:
			return index
	return -1


static func _point(value: Variant) -> bool:
	return value is Array and (value as Array).size() == 2 and (value[0] is int or value[0] is float) and (value[1] is int or value[1] is float)
