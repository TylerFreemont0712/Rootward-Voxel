extends SceneTree
## Standalone acceptance tests: no production content, autoloads or gdUnit dependencies.
## Rules run against the extracted Rune Mill area document; Python runs in the real WASI sandbox.

const World = preload("res://core/lab_world.gd")
const Program = preload("res://sandbox/lab_program.gd")
var _checks: int = 0
var _failures: Array[String] = []
var rules: LabWorld


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var area: AreaDef = AreaStore.load_area("rune-mill")
	_check(area != null, "The Rune Mill area document loads and validates")
	if area == null:
		quit(1)
		return
	rules = World.new(area)
	_core_tests()
	_discovery_tests()
	_sandbox_tests()
	if _failures.is_empty():
		print("Voxel lab: %d checks passed (pure world rules and real Python/WASI execution)." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		printerr("Voxel lab: %d of %d checks failed." % [_failures.size(), _checks])
		quit(1)


func _core_tests() -> void:
	var original: Dictionary = rules.initial_state()
	var before: String = JSON.stringify(original)
	var invalid: Dictionary = rules.propose(original, [_lamp(true), {"op": "delete_everything"}], {})
	_check(not invalid.ok and invalid.state == original, "Command batches reject atomically")
	_check(JSON.stringify(original) == before, "Rejected batch leaves input untouched")
	_check(not rules.is_walkable(original, Vector2i(7, 5)), "River blocks traversal before construction")
	_check(not rules.is_walkable(original, Vector2i(12, 5)), "Closed gate blocks its cell")
	var opened: Dictionary = rules.propose(original,
		[{"op": "set_field", "entity_id": "gate", "field": "open", "value": true}], {})
	_check(opened.ok and rules.is_walkable(opened.state, Vector2i(12, 5)), "Opening gate changes traversal")
	_check(not rules.is_walkable(original, Vector2i(2, 9)), "Cottage footprint blocks movement")
	_check(not rules.is_walkable(original, Vector2i(-1, 5)), "Map edge blocks movement")
	_check(not rules.move(original, Vector2i(1, 1)).ok, "Diagonal and long movement reject")
	var invalid_support: Dictionary = rules.propose(original, [_place(8)], {})
	_check(not invalid_support.ok and invalid_support.reason.contains("[7,5,0]"), "Bridge construction requires west-bank support and names the next socket")
	var accepted: Dictionary = rules.propose(original, [_lamp(true), _place(7), _place(8), _place(9)], {"runs": 1})
	_check(accepted.ok and accepted.state.bridges.bridge == 3, "Supported bridge batch succeeds")
	_check(accepted.state.revision == 1 and original.revision == 0, "Proposal revises detached candidate only")
	_check(accepted.state.lamps["lamp-west"] and not original.lamps["lamp-west"], "Fields are detached from source")
	_check(accepted.state.memory == {"runs": 1}, "Program memory persists in candidate")
	var bridge_state: Dictionary = accepted.state
	_check(rules.is_walkable(bridge_state, Vector2i(8, 5)), "Constructed bridge is walkable")
	_check(not rules.is_walkable(bridge_state, Vector2i(8, 4)), "Other river cells remain blocked")
	for step: int in range(6):
		var moved: Dictionary = rules.move(bridge_state, Vector2i.RIGHT)
		_check(moved.ok, "Player crosses bridge step %d" % step)
		if moved.ok:
			bridge_state = moved.state
	_check(bridge_state.player == [10, 5, 0], "Player reaches east bank")
	var closing_state: Dictionary = bridge_state.duplicate(true)
	closing_state.player = [12, 5, 0]
	closing_state.gates.gate = true
	_check(not rules.propose(closing_state, [{"op": "set_field", "entity_id": "gate", "field": "open", "value": false}], {}).ok,
		"Cannot close gate onto player")
	var occupied: Dictionary = accepted.state.duplicate(true)
	occupied.player = [9, 5, 0]
	_check(not rules.propose(occupied, [{"op": "remove", "at": [9, 5, 0]}], {}).ok, "Cannot remove occupied bridge deck")
	_check(not rules.propose(accepted.state, [{"op": "remove", "at": [8, 5, 0]}], {}).ok, "Cannot leave unsupported downstream deck")
	var removed: Dictionary = rules.propose(accepted.state, [{"op": "remove", "at": [9, 5, 0]}], {})
	_check(removed.ok and not rules.is_walkable(removed.state, Vector2i(9, 5)), "Removing deck updates traversal")
	_check(rules.propose(accepted.state, [_place(7)], {}).ok, "Existing placements are idempotent")
	var float_coordinate: Dictionary = {"op": "place", "kind": "bridge_deck", "at": [7.0, 5.0, 0.0]}
	_check(rules.propose(original, [float_coordinate], {}).ok, "Whole-number JSON floats are accepted")
	_check(not rules.propose(original, [{"op": "place", "kind": "bridge_deck", "at": [7.5, 5, 0]}], {}).ok,
		"Fractional coordinates reject")
	_check(not rules.propose(original, [{"op": "place", "kind": "bridge_deck", "at": [true, 5, 0]}], {}).ok,
		"Boolean coordinates reject")
	_check(not rules.propose(original, [{"op": "set_field", "entity_id": "lamp-west", "field": "enabled", "value": 1}], {}).ok,
		"Boolean fields reject numeric truthiness")
	_check(not rules.propose(original, [{"op": "set_field", "entity_id": "lamp-missing", "field": "enabled", "value": true}], {}).ok,
		"Unknown entities reject")
	_check(not rules.propose(original, [{"op": "place", "kind": "bridge_deck", "at": [7, 5, 1]}], {}).ok,
		"Unsupported elevation rejects")
	_check(not rules.propose(original, [{"op": "place", "kind": "bridge_deck", "at": [3, 5, 0]}], {}).ok,
		"A cell that is not a bridge socket rejects")
	var extra_key: Dictionary = _lamp(true)
	extra_key["anything"] = 1
	_check(not rules.propose(original, [extra_key], {}).ok, "Unexpected command fields reject")
	var many: Array = []
	for index: int in range(World.MAX_COMMANDS + 1):
		many.append(_lamp(true))
	_check(not rules.propose(original, many, {}).ok, "Command budget enforced")
	_check(not rules.propose(original, [], {"invalid": Vector2i.ONE}).ok, "Non-JSON memory rejects")
	_check(not rules.propose(original, [], {"invalid": NAN}).ok, "Non-finite JSON memory rejects")
	_check(not rules.propose(original, [], {"deep": {"a": {"b": {"c": {"d": 1}}}}}).ok, "Memory depth bounded")
	var large_memory: Dictionary = {}
	for index: int in range(12):
		large_memory[str(index)] = "x".repeat(200)
	_check(not rules.propose(original, [], large_memory).ok, "Memory byte budget enforced")
	var detached: Dictionary = rules.snapshot(accepted.state)
	detached.player[0] = 99
	detached.lamps[0].lit = false
	detached.bridges[0].cells.clear()
	detached.memory["runs"] = 99
	_check(accepted.state.player[0] == 4 and accepted.state.lamps["lamp-west"] and accepted.state.bridges.bridge == 3
		and accepted.state.memory.runs == 1, "Snapshots cannot alias the authoritative state")
	# Undo changes what a program did, not where the player is.
	var walked: Dictionary = accepted.state
	for _step: int in range(2):
		walked = rules.move(walked, Vector2i.RIGHT).state
	var reverted: Dictionary = rules.revert(walked, original)
	_check(reverted.ok and reverted.state.player == walked.player and reverted.state.bridges.bridge == 0
		and not reverted.state.lamps["lamp-west"] and reverted.state.memory.is_empty(), "Revert undoes the program but keeps the player where they stand")
	var on_deck: Dictionary = accepted.state.duplicate(true)
	on_deck.player = [8, 5, 0]
	_check(not rules.revert(on_deck, original).ok, "Revert cannot remove the deck under the player")


func _discovery_tests() -> void:
	var tiny: Dictionary = {
		"schema": 1, "id": "tiny", "title": "Tiny", "version": 1, "size": [8, 4], "spawn": [1, 1],
		"terrain": ["........", "........", "........", "........"],
		"zones": [{"id": "home", "title": "Home", "rect": [0, 0, 4, 4]}, {"id": "far", "title": "Far Side", "rect": [4, 0, 4, 4]}],
		"lamps": [{"id": "near-lamp", "zone": "home", "at": [1, 2]}, {"id": "far-lamp", "zone": "far", "at": [6, 2]}],
		"gates": [], "bridges": [], "buildings": [], "trees": [], "segments": [], "wheels": [],
	}
	var parsed: Dictionary = AreaDef.parse(tiny, {})
	_check(parsed.ok, "A minimal area document validates: %s" % str(parsed.errors))
	var small := World.new(parsed.area)
	var state: Dictionary = small.initial_state()
	_check(state.zones_seen == ["home"], "Only the spawn zone starts discovered")
	var snapshot: Dictionary = small.snapshot(state)
	_check(snapshot.lamps.size() == 1 and snapshot.zones.size() == 1, "Programs only see places the player has been")
	var far_attempt: Dictionary = small.propose(state, [{"op": "set_field", "entity_id": "far-lamp", "field": "enabled", "value": true}], {})
	_check(not far_attempt.ok and far_attempt.reason.contains("Far Side"), "Commands cannot reach an unexplored zone")
	var cursor: Dictionary = state
	for _step: int in range(4):
		var moved: Dictionary = small.move(cursor, Vector2i.RIGHT)
		cursor = moved.state
	_check(cursor.zones_seen.has("far") and small.snapshot(cursor).lamps.size() == 2, "Walking into a zone discovers it")
	_check(small.propose(cursor, [{"op": "set_field", "entity_id": "far-lamp", "field": "enabled", "value": true}], {}).ok, "A discovered zone's lamp can be lit")
	var bad: Dictionary = tiny.duplicate(true)
	bad.lamps = [{"id": "x", "zone": "nowhere", "at": [1, 1]}]
	_check(not AreaDef.parse(bad, {}).ok, "An area whose lamp names an unknown zone is rejected")
	bad = tiny.duplicate(true)
	bad.terrain = ["........"]
	_check(not AreaDef.parse(bad, {}).ok, "A terrain grid with the wrong number of rows is rejected")
	bad = tiny.duplicate(true)
	bad.spawn = [20, 1]
	_check(not AreaDef.parse(bad, {}).ok, "A spawn outside the map is rejected")


func _sandbox_tests() -> void:
	if not Sandbox.is_available(SandboxJob.PYTHON):
		_check(false, "Python/WASI runtime is available (set ROOTWARD_SANDBOX_RUNTIME to the existing installation)")
		return
	var original: Dictionary = rules.initial_state()
	var snapshot: Dictionary = rules.snapshot(original)
	var starter: Dictionary = Program.run(Program.starter_source(), snapshot)
	_check(starter.ok and starter.commands.is_empty(), "The empty starter runs and changes nothing: %s" % starter.reason)
	var friendly: String = "def program(world):\n    bridge = world.bridge('bridge')\n    for cell in bridge.cells[:2]:\n        bridge.place_deck(cell)\n    world.lamp('lamp-west').set_lit(True)\n    print('Prepared', bridge.built)\n"
	var result: Dictionary = Program.run(friendly, snapshot)
	_check(result.ok, "The friendly API runs in real Python: %s" % result.reason)
	if result.ok:
		var proposal: Dictionary = rules.propose(original, result.commands, result.memory)
		_check(proposal.ok and proposal.state.bridges.bridge == 2 and proposal.state.lamps["lamp-west"], "Method calls become validated commands")
		_check(result.stdout.contains("Prepared 2"), "Objects mirror what the program just did")
	var count_program: String = "def program(world):\n    world['memory']['runs'] = world['memory'].get('runs', 0) + 1\n    return {'commands': [], 'memory': world['memory']}\n"
	var count_result: Dictionary = Program.run(count_program, snapshot)
	_check(count_result.ok and count_result.memory.get("runs") == 1, "Older dictionary-style programs still run")
	var memory_program: String = "def program(world):\n    world.memory['visits'] = 7\n"
	var memory_result: Dictionary = Program.run(memory_program, snapshot)
	_check(memory_result.ok and memory_result.memory.get("visits") == 7, "world.memory persists without returning anything")
	_check(snapshot.memory.is_empty(), "Sandbox input snapshot stays detached")
	var syntax_result: Dictionary = Program.run("def program(:\n    pass\n", snapshot)
	_check(not syntax_result.ok and syntax_result.reason.contains("SyntaxError"), "Syntax errors reach caller")
	_check(syntax_result.error.line == 1 and syntax_result.error.kind == "SyntaxError", "The failing line number is recovered")
	var runtime_result: Dictionary = Program.run("def program(world):\n    x = 1\n    raise ValueError('lab error')\n", snapshot)
	_check(not runtime_result.ok and runtime_result.reason.contains("lab error") and runtime_result.error.line == 3, "Runtime errors carry their message and line")
	var name_result: Dictionary = Program.run("def program(world):\n    lamp = world.lamp('lamp-west')\n    lamps.set_lit(True)\n", snapshot)
	_check(not name_result.ok and name_result.error.kind == "NameError" and name_result.error.line == 3, "NameError points at its line")
	var missing: Dictionary = Program.run("def program(world):\n    world.lamp('nope')\n", snapshot)
	_check(not missing.ok and missing.error.kind == "WorldError" and missing.reason.contains("lamp-west"), "Unknown ids list what is known")
	var wrong_type: Dictionary = Program.run("def program(world):\n    world.lamp('lamp-west').set_lit(1)\n", snapshot)
	_check(not wrong_type.ok and wrong_type.reason.contains("True or False"), "Wrong value types are explained before the world sees them")
	var invalid_result: Dictionary = Program.run("def program(world):\n    return 42\n", snapshot)
	_check(not invalid_result.ok, "Invalid function result rejects")
	var forged: Dictionary = Program._decode("__VOXEL_RESULT__{\"commands\":[{\"op\":\"destroy\"}],\"memory\":{}}", 1)
	_check(forged.ok and not rules.propose(original, forged.commands, forged.memory).ok,
		"Forged framing cannot bypass authoritative validation")
	var raw_commands: Dictionary = Program.run("def program(world):\n    return [{'op': 'set_field', 'entity_id': 'lamp-mill', 'field': 'enabled', 'value': True}]\n", snapshot)
	_check(raw_commands.ok and rules.propose(original, raw_commands.commands, raw_commands.memory).ok, "Raw command lists remain available to advanced players")
	var timed: Dictionary = Program.run("def program(world):\n    while True:\n        pass\n", snapshot)
	_check(not timed.ok and timed.reason.contains("time"), "Endless player program times out")
	var output: Dictionary = Program.run("def program(world):\n    print('x' * 65536)\n    return []\n", snapshot)
	_check(not output.ok and output.reason.contains("printed"), "Output cap rejects excessive printing")
	var memory: Dictionary = Program.run("def program(world):\n    huge = [0] * (10 ** 9)\n    return []\n", snapshot)
	_check(not memory.ok and memory.reason.contains("memory"), "Sandbox memory cap enforced")
	var host_file: Dictionary = Program.run("def program(world):\n    open('/etc/passwd').read()\n    return []\n", snapshot)
	_check(not host_file.ok, "Player code cannot read host files")


func _lamp(value: bool) -> Dictionary:
	return {"op": "set_field", "entity_id": "lamp-west", "field": "enabled", "value": value}


func _place(x: int) -> Dictionary:
	return {"op": "place", "kind": "bridge_deck", "at": [x, 5, 0]}


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
