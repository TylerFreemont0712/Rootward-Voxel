extends SceneTree
## Terminal scope is authored data and validated before Python can change a zone.
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	go.call_deferred()

func go() -> void:
	var source: Dictionary = AreaStore.read_source("workshop-floor")
	_check(source.ok, "The workshop terminal document validates")
	if not source.ok: quit(1); return
	var area: AreaDef = AreaStore.load_area("workshop-floor")
	var rules := LabWorld.new(area)
	var initial: Dictionary = rules.initial_state()
	_check(rules.snapshot(initial).lamps.is_empty() and rules.snapshot(initial).zones.is_empty(), "Walking into a terminal zone does not connect it automatically")
	_check(not ZoneTerminals.connect_at(area, initial, "workshop-terminal").ok and not ZoneTerminals.connect_at(area, initial, "missing").ok, "Unknown and distant computers cannot grant access")
	var near: Dictionary = initial.duplicate(true)
	near.player = [1,2,0]
	var bare: Dictionary = ZoneTerminals.connect_at(area, near, "workshop-terminal")
	_check(not bare.ok and str(bare.reason).contains("tablet"), "The wall screen refuses a traveller who does not carry the tablet, and says why")
	near.items = ["field-tablet"]
	var linked: Dictionary = ZoneTerminals.connect_at(area, near, "workshop-terminal")
	_check(linked.ok and near.terminal_links.is_empty() and linked.state.terminal_links == ["workshop-terminal"], "A tablet at the wall screen returns a detached saved connection")
	_check(ZoneTerminals.connect_at(area, linked.state, "workshop-terminal").state.revision == linked.state.revision, "Reusing the same connection is idempotent")
	_check(rules.snapshot(linked.state).lamps.size() == 3 and ZoneTerminals.caption(area, linked.state).contains("workshop"), "The linked zone and its three lamps become available together")
	var command: Dictionary = {"op":"set_field", "entity_id":"landing-lamp", "field":"enabled", "value":true}
	_check(not rules.propose(near, [command], {}).ok and rules.propose(near, [command], {}).reason.contains("stair lantern"), "Raw returned commands also need the connection or the place to stand, and say where")
	_check(rules.propose(linked.state, [command], {}).ok, "The same validated command works through its linked zone")
	var forged: Dictionary = near.duplicate(true)
	forged.memory = {"terminal_links":["workshop-terminal"]}
	_check(rules.snapshot(forged).lamps.is_empty(), "Player program memory cannot forge a terminal connection")
	_check(not rules.propose(near, [{"op":"connect_terminal", "id":"workshop-terminal"}], {}).ok, "Player Python cannot issue an unvalidated terminal-connect command")
	var raw: Dictionary = linked.state.duplicate(true)
	raw.terminal_links = ["foreign", "workshop-terminal", "workshop-terminal"]
	_check(rules.normalize_state(raw).terminal_links == ["workshop-terminal"], "Only known unique connections restore")
	raw.terminal_links = "workshop-terminal"
	_check(rules.normalize_state(raw).is_empty(), "A malformed connection list is refused")
	var before: Dictionary = near.duplicate(true)
	_check(rules.revert(linked.state, before).state.terminal_links == ["workshop-terminal"], "Undoing a program keeps the discovered connection")
	for defect: String in ["unknown-zone", "missing-object", "duplicate", "outside", "wrong-model", "far-approach", "unknown-item", "malformed-prompt"]:
		var doc: Dictionary = source.document.duplicate(true)
		match defect:
			"unknown-zone": doc.terminals[0].zone = "missing"
			"missing-object": doc.terminals[0].object = "missing"
			"duplicate": doc.terminals.append(doc.terminals[0].duplicate())
			"outside": doc.terminals[0].at = [99,99]
			"wrong-model": doc.terminals[0].object = "repair-bench"
			"far-approach": doc.terminals[0].at = [6,0]
			"unknown-item": doc.terminals[0].requires = "skeleton-key"
			"malformed-prompt": doc.terminals[0].prompt = 7
		_check(not AreaDef.parse(doc, source.assets, source.quests).ok, "Invalid terminal authoring is refused: " + defect)
	_two_zones(source)
	_items()
	_reach()
	_arm_length()
	for id: String in ["workshop-loft", "workshop-floor"]:
		var room: AreaDef = AreaStore.load_area(id)
		var room_rules := LabWorld.new(room)
		var approaches: Array = []
		for terminal: Dictionary in room.terminals: approaches.append(terminal.at)
		for pickup: Dictionary in room.pickups: approaches.append(pickup.at)
		for approach: Array in approaches:
			var target := Vector2i(int(approach[0]), int(approach[1]))
			var start: Dictionary = room_rules.initial_state()
			_check(room_rules.is_walkable(start, target) and (Vector2i(int(start.player[0]), int(start.player[1])) == target or not room_rules.find_path(start, target).is_empty()), "The authored approach is reachable: %s %s" % [id, target])
	if failures.is_empty(): print("Zone terminals: %d checks passed." % checks)
	else:
		for failure: String in failures: printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)

func _two_zones(source: Dictionary) -> void:
	var doc: Dictionary = source.document.duplicate(true)
	doc.zones = [{"id":"workshop", "title":"Workshop", "rect":[0,0,7,12]}, {"id":"annex", "title":"Annex", "rect":[7,0,7,12]}]
	doc.interior.assets.append({"id":"annex-computer", "asset":"zone-terminal", "at":[9,5], "height":0, "turn":0, "scale":1})
	doc.terminals.append({"id":"annex-terminal", "title":"Annex terminal", "object":"annex-computer", "zone":"annex", "at":[9,5]})
	doc.lamps.append({"id":"annex-light", "at":[10,5], "zone":"annex", "style":"post"})
	var parsed: Dictionary = AreaDef.parse(doc, source.assets, source.quests)
	_check(parsed.ok, "The same computer model can connect two independently authored zones")
	if not parsed.ok: return
	var rules := LabWorld.new(parsed.area)
	var state: Dictionary = rules.initial_state()
	state.zones_seen = ["workshop", "annex"]
	state.player = [1,2,0]
	state.items = ["field-tablet"]
	state = ZoneTerminals.connect_at(parsed.area, state, "workshop-terminal").state
	_check(rules.snapshot(state).lamps.size() == 3, "One connection cannot reveal a second visited but unlinked zone")
	var batch: Array = [{"op":"set_field", "entity_id":"landing-lamp", "field":"enabled", "value":true}, {"op":"set_field", "entity_id":"annex-light", "field":"enabled", "value":true}]
	var rejected: Dictionary = rules.propose(state, batch, {})
	_check(not rejected.ok and not state.lamps["landing-lamp"], "A batch crossing an unlinked zone is rejected atomically")
	state.player = [9,5,0]
	var workshop_state: Dictionary = state.duplicate(true)
	state = ZoneTerminals.connect_at(parsed.area, state, "annex-terminal").state
	_check(rules.snapshot(state).lamps.size() == 1 and rules.snapshot(state).lamps[0].id == "annex-light", "Standing at the second terminal reaches only its own zone")
	_check(rules.propose(state, [batch[1]], {}).ok and not rules.propose(state, batch, {}).ok, "The second physical connection grants its own zone, and the first stays out of reach")
	workshop_state.player = [1,2,0]
	_check(rules.snapshot(workshop_state).lamps.size() == 3 and rules.snapshot(workshop_state).zones.size() == 1, "Walking back to the first screen reaches the first zone again")

## The tablet is picked up in the loft and carried; only an authored pickup in reach can hand it over.
func _items() -> void:
	var source: Dictionary = AreaStore.read_source("workshop-loft")
	_check(source.ok, "The loft pickup document validates")
	if not source.ok: return
	var loft: AreaDef = AreaStore.load_area("workshop-loft")
	var rules := LabWorld.new(loft)
	var state: Dictionary = rules.initial_state()
	_check(state.items.is_empty() and not PlayerItems.has(state, "field-tablet"), "A traveller begins without the tablet")
	state.player = [1,1,0]
	var far: Dictionary = PlayerItems.take(loft, state, "tablet")
	_check(not far.ok and str(far.reason).contains("closer"), "The tablet cannot be taken from across the room")
	_check(PlayerItems.nearest(loft, state, Vector2(1, 1)).is_empty() and not PlayerItems.nearest(loft, state, Vector2(7, 8)).is_empty(), "Only the bed's foot offers the tablet")
	state.player = [7,8,0]
	var taken: Dictionary = PlayerItems.take(loft, state, "tablet")
	_check(taken.ok and state.items.is_empty() and taken.state.items == ["field-tablet"] and int(taken.state.revision) == int(state.revision) + 1, "Taking the tablet returns a detached state that carries it")
	_check(not PlayerItems.take(loft, taken.state, "tablet").ok and PlayerItems.nearest(loft, taken.state, Vector2(7, 8)).is_empty(), "A tablet already carried is not offered again")
	_check(not PlayerItems.take(loft, state, "missing").ok, "An unknown pickup gives nothing")
	var raw: Dictionary = taken.state.duplicate(true)
	raw.items = ["skeleton-key", "field-tablet", "field-tablet", 4]
	_check(rules.normalize_state(raw).items == ["field-tablet"], "Only known items restore, once each")
	raw.items = "field-tablet"
	_check(rules.normalize_state(raw).is_empty(), "A malformed item list is refused")
	raw.erase("items")
	_check(rules.normalize_state(raw).items.is_empty(), "A save from before items restores with none")
	var forged: Dictionary = state.duplicate(true)
	forged.memory = {"items":["field-tablet"]}
	_check(not PlayerItems.has(forged, "field-tablet") and not rules.propose(state, [{"op":"take_item", "id":"tablet"}], {}).ok, "Player code can neither claim nor take an item")
	_check(PlayerItems.merge(["field-tablet"], []) == ["field-tablet"] and PlayerItems.merge([], ["field-tablet", "field-tablet"]) == ["field-tablet"], "Rooms share what the traveller carries without duplicates")
	for defect: String in ["unknown-item", "missing-object", "duplicate-item", "far-approach", "outside"]:
		var doc: Dictionary = source.document.duplicate(true)
		match defect:
			"unknown-item": doc.pickups[0].item = "skeleton-key"
			"missing-object": doc.pickups[0].object = "missing"
			"duplicate-item": doc.pickups.append(doc.pickups[0].duplicate())
			"far-approach": doc.pickups[0].at = [1,1]
			"outside": doc.pickups[0].at = [99,99]
		_check(not AreaDef.parse(doc, source.assets, source.quests).ok, "Invalid pickup authoring is refused: " + defect)

## Code reaches only what the traveller stands beside: a zone through its screen, one lamp from its own place.
func _reach() -> void:
	var area: AreaDef = AreaStore.load_area("workshop-floor")
	var rules := LabWorld.new(area)
	var state: Dictionary = rules.initial_state()
	state.items = ["field-tablet"]
	state.terminal_links = ["workshop-terminal"]
	state.player = [9,3,0]
	_check(rules.snapshot(state).lamps.is_empty() and rules.snapshot(state).zones.is_empty(), "From across the room, a linked and equipped traveller reaches nothing")
	var lantern: Dictionary = {"op":"set_field", "entity_id":"landing-lamp", "field":"enabled", "value":true}
	var refused: Dictionary = rules.propose(state, [lantern], {})
	_check(not refused.ok and str(refused.reason).contains("stair lantern"), "A command for a lamp out of reach is refused and says where to stand")
	state.player = [5,11,0]
	var at_lantern: Dictionary = rules.snapshot(state)
	_check(at_lantern.lamps.size() == 1 and at_lantern.lamps[0].id == "landing-lamp" and at_lantern.zones.is_empty(), "Standing beside the stair lantern reaches that lantern alone, and no zone")
	_check(rules.propose(state, [lantern], {}).ok and not rules.propose(state, [{"op":"set_field", "entity_id":"repair-light", "field":"enabled", "value":true}], {}).ok, "Its code lights it but cannot touch another light")
	var bare: Dictionary = state.duplicate(true)
	bare.items = []
	_check(rules.snapshot(bare).lamps.is_empty() and not rules.propose(bare, [lantern], {}).ok, "Without the tablet, standing beside it reaches nothing")
	state.player = [4,11,0]
	_check(rules.snapshot(state).lamps.size() == 1, "A step beside the place to stand still reaches the lantern")
	state.player = [7,11,0]
	_check(rules.snapshot(state).lamps.is_empty(), "Two cells from the stair lantern reaches nothing")
	state.player = [1,2,0]
	var at_screen: Dictionary = rules.snapshot(state)
	_check(at_screen.lamps.size() == 3 and at_screen.zones.size() == 1, "Standing at the wall screen reaches the whole zone")
	var unlinked: Dictionary = state.duplicate(true)
	unlinked.terminal_links = []
	_check(rules.snapshot(unlinked).lamps.is_empty(), "Standing at a screen that has not been jacked into reaches nothing")
	for lamp: Dictionary in area.lamps:
		var stand := Vector2i(int(lamp.stand[0]), int(lamp.stand[1]))
		_check(rules.is_walkable(rules.initial_state(), stand) and not rules.find_path(rules.initial_state(), stand).is_empty(), "A place to stand beside " + str(lamp.id) + " can be reached")

## F is arm's length: every authored thing to use has a walkable, reachable cell within the shorter reach.
func _arm_length() -> void:
	for id: String in ["workshop-loft", "workshop-floor"]:
		var room: AreaDef = AreaStore.load_area(id)
		var rules := LabWorld.new(room)
		var start: Dictionary = rules.initial_state()
		var points: Array = []
		for item: Dictionary in room.interior.get("inspections", []): points.append([str(item.id), Vector2(float(item.at[0]), float(item.at[1]))])
		for link: Dictionary in room.interior.get("links", []):
			var spot: Array = link.get("approach", link.at)
			points.append([str(link.id), Vector2(float(spot[0]), float(spot[1]))])
		for terminal: Dictionary in room.terminals: points.append([str(terminal.id), Vector2(float(terminal.at[0]), float(terminal.at[1]))])
		for pickup: Dictionary in room.pickups: points.append([str(pickup.id), Vector2(float(pickup.at[0]), float(pickup.at[1]))])
		for lamp: Dictionary in room.lamps:
			if lamp.get("stand") is Array: points.append([str(lamp.id), Vector2(float(lamp.stand[0]), float(lamp.stand[1]))])
		for entry: Array in points:
			var found: bool = false
			for dx: int in range(-1, 2):
				for dy: int in range(-1, 2):
					var cell := Vector2i(roundi(entry[1].x) + dx, roundi(entry[1].y) + dy)
					if Vector2(cell).distance_to(entry[1]) >= FieldAccess.RANGE or not rules.is_walkable(start, cell): continue
					var here := Vector2i(int(start.player[0]), int(start.player[1]))
					if here == cell or not rules.find_path(start, cell).is_empty(): found = true
			_check(found, "Standing within arm's length of %s is possible in %s" % [entry[0], id])
		var hotaru: Dictionary = {}
		for item: Dictionary in room.interior.get("assets", []):
			if str(item.asset) == "loft-hotaru": hotaru = item
		if not hotaru.is_empty():
			var seat := Vector2(float(hotaru.at[0]), float(hotaru.at[1]))
			var close: bool = false
			for x: int in range(roundi(seat.x) - 2, roundi(seat.x) + 3):
				for y: int in range(roundi(seat.y) - 2, roundi(seat.y) + 3):
					close = close or (Vector2(x, y).distance_to(seat) < 1.6 and rules.is_walkable(start, Vector2i(x, y)) and not rules.find_path(start, Vector2i(x, y)).is_empty())
			_check(close, "Somewhere beside Hotaru can be stood on in " + id)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
