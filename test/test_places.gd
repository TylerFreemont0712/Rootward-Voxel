extends SceneTree
## Pure door, room, resident and expanded-map contracts.

var checks: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var exterior: AreaDef = AreaStore.load_area("kindle-hollow")
	var rules := LabWorld.new(exterior)
	var state: Dictionary = rules.initial_state()
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/interiors/catalog.json"))
	_check(exterior.width == 96 and exterior.height == 80 and exterior.buildings.size() >= 20, "The main area is larger and has new homes")
	_check(exterior.villagers.size() == 5 and not exterior.boundary.is_empty(), "The village has five residents and a finished boundary")
	_check(not HouseInstances.check_enter(exterior, rules, state, "mira-house", catalog).ok, "A distant house cannot be entered")
	_check(not HouseInstances.check_enter(exterior, rules, state, "unknown", catalog).ok, "Unknown houses are refused")
	var entries: Array[Dictionary] = []
	for id: String in ["home", "row-north-a"]:
		var at: Vector2i = HouseInstances.door(exterior, id)
		state.player = [at.x, at.y, 0]
		var entry: Dictionary = HouseInstances.check_enter(exterior, rules, state, id, catalog)
		_check(entry.ok, "A reachable front door can be entered: " + id)
		entries.append(entry)
	_check(entries[0].instance != entries[1].instance and entries[0].template == entries[1].template, "Identical house templates have different instance identities")
	var rooms: Dictionary = {}
	for entry: Dictionary in entries:
		rooms[entry.instance] = {"house": entry.house, "template": entry.template, "save": {"state": {"memory": {"owner": entry.house}}}}
	var saved: Dictionary = JSON.parse_string(JSON.stringify(rooms))
	var restored: Dictionary = HouseInstances.valid_saved_rooms(saved, exterior, catalog)
	_check(restored.size() == 2 and restored[entries[0].instance].save.state.memory.owner != restored[entries[1].instance].save.state.memory.owner, "Room state survives JSON without sharing between houses")
	saved[entries[0].instance].template = "unknown"
	saved["kindle-hollow/missing"] = {"house": "missing", "template": entries[1].template, "save": {}}
	_check(HouseInstances.valid_saved_rooms(saved, exterior, catalog).size() == 1, "Stale templates and missing house saves are ignored")
	for template: String in catalog.templates.values():
		var room: AreaDef = AreaStore.load_area(template)
		var room_rules := LabWorld.new(room)
		var room_state: Dictionary = room_rules.initial_state()
		_check(room_rules.is_walkable(room_state, room.spawn), template + " has a safe arrival")
		var exit := Vector2i(int(room.interior.exit[0]), int(room.interior.exit[1]))
		_check(not room_rules.find_path(room_state, exit).is_empty(), template + " has a reachable way out")
		room_state.player = [exit.x, exit.y, 0]
		_check(HouseInstances.can_exit(room, room_state), template + " permits exit at its doorway")
		room_state.player = [room.width - 2, room.height - 2, 0]
		_check(not HouseInstances.can_exit(room, room_state), template + " does not teleport from across the room")
		for furniture: Dictionary in room.interior.furniture:
			var at := Vector2i(Vector2(furniture.at).round())
			if furniture.kind != "rug":
				_check(not room_rules.is_walkable(room_state, at), template + " blocks furniture footprint: " + str(furniture.kind))
		_check(room.lamp("hearth-lamp").style == "sconce", template + " has its own programmable wall lamp")
		for stop: Array in room.interior.host.route:
			var host_cell := Vector2i(int(stop[0]), int(stop[1]))
			_check(not room_rules.find_path(room_rules.initial_state(), host_cell).is_empty(), template + " keeps its owner's indoor route clear of furniture")
	var people: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/villagers.json")).residents
	var open: Dictionary = AreaBuild.open_state(rules, exterior.spawn)
	var a: Dictionary = VillageLife.initial(exterior)
	var b: Dictionary = VillageLife.initial(exterior)
	for step: int in range(600):
		VillageLife.advance(exterior, rules, open, a, 1.0 / 60.0)
		VillageLife.advance(exterior, rules, open, b, 1.0 / 60.0)
	_check(a == b, "Resident schedules are deterministic")
	for resident: Dictionary in exterior.villagers:
		_check(people.has(resident.id) and not exterior.building(resident.home).is_empty(), "Resident identity and home exist: " + str(resident.id))
		_check(rules.is_walkable(open, resident.at), "Resident starts on open ground: " + str(resident.id))
		for at: Vector2i in resident.route:
			_check(at == resident.at or not rules.find_path(open, at, resident.at).is_empty(), "Resident route is reachable: " + str(resident.id))
	_check(not rules.is_walkable(open, Vector2i(28, -1)) and not rules.can_step(open, Vector2i(28, 0), Vector2i(28, -1)), "The start boundary blocks leaving the map independently of its visuals")
	var yielding: Dictionary = VillageLife.initial(exterior)
	yielding.mira.pause = 0.0
	yielding.mira.goal = 1
	var occupied: Dictionary = open.duplicate(true)
	occupied.player = [30, 8, 0]
	VillageLife.advance(exterior, rules, occupied, yielding, 0.1)
	_check(yielding.mira.to != Vector2i(30, 8), "A resident never steps into the player's cell: it walks round them")
	var boxed: Dictionary = VillageLife.initial(exterior)
	boxed.mira.pause = 0.0
	boxed.mira.goal = 1
	var round_about: Dictionary = {}
	for cell: Vector2i in [Vector2i(29, 7), Vector2i(31, 7), Vector2i(30, 6)]:
		round_about[cell] = true
	VillageLife.advance(exterior, rules, occupied, boxed, 0.1, round_about)
	_check(boxed.mira.phase == 1.0 and boxed.mira.at == Vector2i(30, 7), "With no way round, a resident waits")
	_check(VillageLife.occupied(boxed).has(Vector2i(30, 7)) and VillageLife.occupied(yielding).has(yielding.mira.to), "A resident takes up its cell, and the next one while it steps")
	var source: Dictionary = AreaStore.read_source("kindle-hollow")
	for invalid: Dictionary in [{"boundary": {"apron": 2}}, {"villagers": [{"id": "bad", "at": [30.5, 7]}]}, {"interior": {"exit": [200, 2]}}, {"interior": {"exit": [28, 3], "furniture": [{"kind": "bed", "at": [3, 3], "size": [-2, 3]}]}}, {"interior": {"exit": [28, 3], "host": {"at": [10, 5], "route": [[200, 2]]}}}]:
		var bad: Dictionary = source.document.duplicate(true)
		bad.merge(invalid, true)
		_check(not AreaDef.parse(bad, source.assets, source.quests).ok, "Malformed room, resident or boundary data is refused: " + str(invalid.keys()))
	var ledger := BuildLedger.new(source.document, source.assets, source.quests, AreaStore.read_build_catalog())
	var build_state: Dictionary = ledger.rules.initial_state()
	var placed: Dictionary = ledger.place("house-hollow", Vector2(34, 5), "S", build_state)
	_check(placed.ok, "A player-built home can receive an instance")
	var first_id: String = placed.edit.id
	ledger.remove_building(first_id, build_state)
	var replacement: Dictionary = ledger.place("house-hollow", Vector2(34, 5), "S", build_state)
	_check(replacement.ok and replacement.edit.id != first_id, "Replacing a removed house cannot inherit its cached room")
	var second_id: String = replacement.edit.id
	ledger.undo(build_state)
	var branched: Dictionary = ledger.place("house-hollow", Vector2(34, 5), "S", build_state)
	_check(branched.ok and branched.edit.id != second_id, "A new house after undo also receives a fresh room identity")
	var reloaded := BuildLedger.new(source.document, source.assets, source.quests, AreaStore.read_build_catalog(), JSON.parse_string(JSON.stringify(ledger.edits)))
	reloaded.remove_building(branched.edit.id, build_state)
	var after_load: Dictionary = reloaded.place("house-hollow", Vector2(34, 5), "S", build_state)
	_check(after_load.ok and after_load.edit.id != branched.edit.id, "Stable room identities also survive the saved build history")
	if failures.is_empty():
		print("Places and village: %d checks passed." % checks)
	else:
		for failure: String in failures:
			printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
