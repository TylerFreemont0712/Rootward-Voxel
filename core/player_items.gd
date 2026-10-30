class_name PlayerItems
extends RefCounted
## Things the traveller carries from room to room. Only an authored pickup adds one, only the app asks, and a
## program never can. Plain data in and out: no nodes, files or presentation.
## Every item a journey can hand over, and the name a refusal quotes.
const KNOWN: Dictionary = {"field-tablet": "Nell’s field tablet"}
## Saves from before items existed: a traveller who had already been handed the old hand console keeps the tablet.
const AFTER_GREETING: Array = ["field-tablet"]


static func title(item: String) -> String:
	return str(KNOWN.get(item, item))


static func has(state: Dictionary, item: String) -> bool:
	return (state.get("items", []) as Array).has(item)


static func find(area: AreaDef, id: String) -> Dictionary:
	for pickup: Dictionary in area.pickups:
		if pickup.id == id: return pickup
	return {}


## The pickup this area offers that the traveller is close enough to take, or {}.
static func nearest(area: AreaDef, state: Dictionary, at: Vector2) -> Dictionary:
	var found: Dictionary = {}
	var distance: float = FieldAccess.RANGE
	for pickup: Dictionary in area.pickups:
		if has(state, str(pickup.item)): continue
		var delta: float = at.distance_to(Vector2(pickup.at[0], pickup.at[1]))
		if delta < distance:
			distance = delta
			found = pickup
	return found


## Saved items that this game knows, once each. A malformed list restores as empty.
static func restore(raw: Variant) -> Array:
	var items: Array = []
	if not raw is Array: return items
	for item: Variant in raw:
		if item is String and KNOWN.has(item) and not items.has(item): items.append(item)
	return items


static func merge(first: Variant, second: Variant) -> Array:
	return restore((first as Array if first is Array else []) + (second as Array if second is Array else []))


static func take(area: AreaDef, state: Dictionary, id: String) -> Dictionary:
	var pickup: Dictionary = find(area, id)
	if pickup.is_empty(): return {"ok": false, "state": state, "reason": "There is nothing like that to take here."}
	if has(state, str(pickup.item)): return {"ok": false, "state": state, "reason": "You already have " + title(str(pickup.item)) + "."}
	var at := Vector2(int(state.player[0]), int(state.player[1]))
	if at.distance_to(Vector2(pickup.at[0], pickup.at[1])) >= FieldAccess.RANGE:
		return {"ok": false, "state": state, "reason": "Walk closer to take " + title(str(pickup.item)) + "."}
	var candidate: Dictionary = state.duplicate(true)
	if not candidate.has("items"): candidate["items"] = []
	candidate.items.append(str(pickup.item))
	candidate.revision = int(state.revision) + 1
	return {"ok": true, "state": candidate, "reason": ""}
