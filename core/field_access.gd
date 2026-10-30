class_name FieldAccess
extends RefCounted
## Code reaches the world the way a tablet does: from beside what it works on. A zone answers to its screen and a
## single fitting to the traveller standing at it. A skill for working from further away may relax this later; the
## rule lives here so that is one place to change. Plain data in and out: no nodes, files or presentation.

## How near, in cells, the traveller must stand to an authored approach cell for anything to answer.
const RANGE: float = 1.1


static func near(state: Dictionary, at: Array) -> bool:
	var player := Vector2(int(state.player[0]), int(state.player[1]))
	return player.distance_to(Vector2(float(at[0]), float(at[1]))) < RANGE


## True when the traveller can reach the zone's fittings from where they stand. A zone without a terminal keeps the
## older rule (having been there is enough); a zone with one needs the traveller linked, carrying what it requires
## and standing at it.
static func zone_in_reach(area: AreaDef, state: Dictionary, zone_id: String) -> bool:
	var terminals: Array[Dictionary] = ZoneTerminals.for_zone(area, zone_id)
	if terminals.is_empty(): return true
	for terminal: Dictionary in terminals:
		if ZoneTerminals.in_reach(area, state, terminal): return true
	return false


## True when code can see and change this lamp from where the traveller stands: through its zone's screen, or by
## standing beside it (with what it requires) when it names a place to stand. A lamp that names neither, in a zone
## without a screen, keeps the older rule.
static func lamp_in_reach(area: AreaDef, state: Dictionary, lamp: Dictionary) -> bool:
	var stand: Variant = lamp.get("stand")
	var screens: bool = not ZoneTerminals.for_zone(area, lamp.zone).is_empty()
	if not screens and not stand is Array: return true
	if screens and zone_in_reach(area, state, lamp.zone): return true
	if not stand is Array: return false
	if lamp.has("requires") and not PlayerItems.has(state, str(lamp.requires)): return false
	return near(state, stand)


## Why code cannot reach this lamp, in the words a notebook can give.
static func lamp_reason(area: AreaDef, lamp: Dictionary) -> String:
	var name: String = str(lamp.get("title", lamp.id)).to_lower()
	if lamp.get("stand") is Array:
		var carried: String = " with " + PlayerItems.title(str(lamp.requires)) if lamp.has("requires") else ""
		return "Stand beside the %s%s to reach it from code." % [name, carried]
	return zone_reason(area, str(lamp.zone))


static func zone_reason(area: AreaDef, zone_id: String) -> String:
	var terminals: Array[Dictionary] = ZoneTerminals.for_zone(area, zone_id)
	if terminals.is_empty(): return "You have not explored %s yet. Walk there first, then your notebook can reach it." % area.zone(zone_id).title
	return "Stand at the %s with your tablet to reach the %s zone's fittings." % [str(terminals[0].title).to_lower(), zone_id]


## Where a job's code is written: {"kind": "device"|"zone", "title", "target"} with the id to walk to, or {} for a
## job that is not tied to a place.
static func place_for(area: AreaDef, quest: Dictionary) -> Dictionary:
	var access: Variant = quest.get("access")
	if not access is Dictionary: return {}
	if access.kind == "device":
		var lamp: Dictionary = area.lamp(str(access.id))
		if lamp.is_empty(): return {}
		return {"kind": "device", "title": str(lamp.get("title", lamp.id)), "target": str(lamp.id)}
	var terminals: Array[Dictionary] = ZoneTerminals.for_zone(area, str(access.id))
	if terminals.is_empty(): return {}
	return {"kind": "zone", "title": str(terminals[0].title), "target": str(terminals[0].id)}


## A short instruction for the job ticket: where to stand.
static func place_hint(area: AreaDef, quest: Dictionary) -> String:
	var place: Dictionary = place_for(area, quest)
	if place.is_empty(): return ""
	return "Stand %s the %s and press F." % ["beside" if place.kind == "device" else "at", str(place.title).to_lower()]
