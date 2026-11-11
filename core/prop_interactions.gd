class_name PropInteractions
extends RefCounted
## Pure interaction rules. Models advertise a small boolean capability; meshes never decide the result.

const RANGE: float = 2.2
const KINDS: Array[String] = ["light", "hinge", "lever", "spin_x", "spin_y", "bell", "pump"]


static func known(state: Dictionary, prop: Dictionary) -> bool:
	var zone: String = str(prop.get("zone", ""))
	if zone != "":
		return (state.get("zones_seen", []) as Array).has(zone)
	# Objects outside named districts are visible while the player is actually beside them.
	return Vector2(float(state.player[0]), float(state.player[1])).distance_to(prop.at) <= RANGE


static func can_use(rules: LabWorld, state: Dictionary, prop_id: String) -> Dictionary:
	var prop: Dictionary = rules.area.prop(prop_id)
	if prop.is_empty() or (prop.get("interaction", {}) as Dictionary).is_empty():
		return {"ok": false, "reason": "That object has no working interaction."}
	var player := Vector2(float(state.player[0]), float(state.player[1]))
	if player.distance_to(prop.at) > RANGE:
		return {"ok": false, "reason": "Walk closer to use this object."}
	if not known(state, prop):
		return {"ok": false, "reason": "Visit this object's district first."}
	if rules.area.level_at(Vector2i(floori(player.x + 0.5), floori(player.y + 0.5))) != rules.area.level_under(prop.rect):
		return {"ok": false, "reason": "It is on another level. Find the stairs."}
	var rect: Rect2 = (prop.rect as Rect2).grow(LabWorld.PLAYER_RADIUS + 0.04)
	var approach: Vector2 = player.clamp(rect.position, rect.end)
	for index: int in range(1, 9):
		if not rules.can_stand(state, player.lerp(approach, float(index) / 9.0)):
			return {"ok": false, "reason": "A wall or another object is in the way. Walk around it."}
	return {"ok": true, "reason": ""}


static func nearest(rules: LabWorld, state: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var distance: float = INF
	var player := Vector2(float(state.player[0]), float(state.player[1]))
	for prop: Dictionary in rules.area.props:
		if (prop.get("interaction", {}) as Dictionary).is_empty():
			continue
		var apart: float = player.distance_squared_to(prop.at)
		if apart < distance and can_use(rules, state, str(prop.id)).ok:
			best = prop
			distance = apart
	return best


static func label(prop: Dictionary, active: bool) -> String:
	var interaction: Dictionary = prop.interaction
	return "%s %s" % [str(interaction.off if active else interaction.on), str(prop.title)]
