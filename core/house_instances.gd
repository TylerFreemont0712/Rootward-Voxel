class_name HouseInstances
extends RefCounted
## Pure door rules. An instance is identified by exterior area + stable building id, never a node.

const RANGE: float = 1.5
const OUTWARD: Dictionary = {"S": Vector2i(0, -1), "E": Vector2i(1, 0), "N": Vector2i(0, 1), "W": Vector2i(-1, 0)}


## Shared plain-data footprints for the visible jambs at the room boundary.
static func frame_posts(area: AreaDef) -> Array[Rect2]:
	var result: Array[Rect2]=[]
	if area.interior.is_empty():return result
	if area.interior.has("exit_posts"):
		for raw: Array in area.interior.exit_posts:
			result.append(Rect2(float(raw[0]), float(raw[1]), float(raw[2]), float(raw[3])))
		return result
	var exit: Array=area.interior.exit
	for side: float in [-1.0,1.0]:result.append(Rect2(Vector2(float(exit[0])+side*.75-.09,float(exit[1])-.11),Vector2(.18,.22)))
	return result


## A doorway is crossed deliberately along its approach, never by merely standing
## nearby. Returning from a room or loading a save therefore cannot bounce back in.
static func crossing(area: AreaDef, rules: LabWorld, state: Dictionary, direction: Vector2i, catalog: Dictionary) -> Dictionary:
	if direction.length_squared() != 1:
		return {}
	var player := Vector2i(int(state.player[0]), int(state.player[1]))
	if not area.interior.is_empty():
		var exit: Array = area.interior.exit
		if player == Vector2i(int(exit[0]), int(exit[1])) and direction == AreaDef.STEPS[area.interior.get("exit_direction", "S")] and rules.is_walkable(state, player):
			return {"house": "", "kind": "exit"}
		return {}
	for house: Dictionary in area.buildings:
		var landing: Vector2i=door(area,house.id)
		if player == landing and direction == -(OUTWARD[house.facing] as Vector2i) and check_enter(area, rules, state, house.id, catalog).ok:
			return {"house": house.id, "kind": "enter"}
	return {}


static func at_destination(area: AreaDef, point: Vector2i, catalog: Dictionary) -> String:
	for house: Dictionary in area.buildings:
		if (house.rect as Rect2).has_point(Vector2(point)) and template_for(area, house.id, catalog) != "":
			return house.id
	return ""


static func template_for(area: AreaDef, house_id: String, catalog: Dictionary) -> String:
	var house: Dictionary = area.building(house_id)
	if house.is_empty() or not area.interior.is_empty():
		return ""
	return str(catalog.get("houses", {}).get(area.id + "/" + house_id, catalog.get("assets", {}).get(house.asset, "")))


static func door(area: AreaDef, house_id: String) -> Vector2i:
	var house: Dictionary = area.building(house_id)
	return AreaBuild.door_cell(house.rect, house.at, house.facing, int(house.get("door_offset",0))) if not house.is_empty() else Vector2i(-1, -1)


static func check_enter(area: AreaDef, rules: LabWorld, state: Dictionary, house_id: String, catalog: Dictionary) -> Dictionary:
	var template: String = template_for(area, house_id, catalog)
	if template == "" or not catalog.get("templates", {}).has(template):
		return {"ok": false, "reason": "This building has no accessible interior."}
	var cell: Vector2i = door(area, house_id)
	var player := Vector2i(int(state.player[0]), int(state.player[1]))
	if player != cell:
		return {"ok": false, "reason": "Walk to the front door first."}
	if not rules.is_walkable(state, cell):
		return {"ok": false, "reason": "The doorway is blocked."}
	if area.level_at(player) != area.level_at(cell) or not area.stair_at(player).is_empty():
		return {"ok": false, "reason": "Walk to the front door first."}
	if not rules.is_walkable(state,player):
		return {"ok":false,"reason":"The approach to the front door is blocked."}
	return {"ok": true, "reason": "", "instance": area.id + "/" + house_id, "house": house_id, "template": template, "return_cell": [cell.x, cell.y]}


static func can_exit(area: AreaDef, state: Dictionary) -> bool:
	if area.interior.is_empty():
		return false
	var exit: Array = area.interior.exit
	return Vector2(float(state.player[0]), float(state.player[1])).distance_to(Vector2(float(exit[0]), float(exit[1]))) <= RANGE


## A cached room must match the currently selected template; invalid or orphaned entries are ignored.
static func valid_saved_rooms(raw: Variant, exterior: AreaDef, catalog: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	if not raw is Dictionary:
		return result
	for key: String in raw:
		var entry: Variant = raw[key]
		if not entry is Dictionary or not entry.get("house") is String or not entry.get("save") is Dictionary:
			continue
		var template: String = template_for(exterior, entry.house, catalog)
		if key == exterior.id + "/" + str(entry.house) and template != "" and entry.get("template") == template:
			result[key] = entry.duplicate(true)
	return result
