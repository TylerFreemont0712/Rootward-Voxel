extends SceneTree
## Grid movement, pathfinding and support rules use one deterministic authority.

const World := preload("res://core/lab_world.gd")
var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var area: AreaDef = AreaStore.load_area("rune-mill")
	if area == null:
		printerr("FAIL: the Rune Mill area document did not load")
		quit(1)
		return
	var rules := World.new(area)
	var initial: Dictionary = rules.initial_state()
	_check(is_equal_approx(World.STEP_SECONDS * 60.0, 13.0), "A faster step takes exactly thirteen 60 Hz physics ticks")
	var moved: Dictionary = rules.move(initial, Vector2i.RIGHT)
	_check(moved.ok and moved.state.player == [5, 5, 0], "A step lands on the neighboring cell center")
	_check(initial.player == [4, 5, 0], "Moving leaves the original state untouched")
	_check(not rules.move(initial, Vector2i.ONE).ok, "Diagonal corner cutting is excluded")
	_check(not rules.move(initial, Vector2i(2, 0)).ok, "A long move must follow a checked route")
	_check(not rules.move(initial, Vector2i.ZERO).ok, "Idle does not create a state transition")
	var shore: Dictionary = initial.duplicate(true)
	shore.player = [6, 5, 0]
	_check(not rules.move(shore, Vector2i.RIGHT).ok, "The broken crossing blocks a step")
	_check(rules.find_path(initial, Vector2i(10, 5)).is_empty(), "Click routing cannot cross an unbuilt bridge")
	var commands: Array = []
	for x: int in [7, 8, 9]:
		commands.append({"op": "place", "kind": "bridge_deck", "at": [x, 5, 0]})
	var full: Dictionary = rules.propose(initial, commands, {}).state
	var route: Array[Vector2i] = rules.find_path(full, Vector2i(10, 5))
	_check(route.size() == 6 and route[-1] == Vector2i(10, 5), "A complete bridge produces a short click-to-walk route")
	var traversed: Dictionary = full
	for cell: Vector2i in route:
		var from := Vector2i(int(traversed.player[0]), int(traversed.player[1]))
		var result: Dictionary = rules.move(traversed, cell - from)
		_check(result.ok, "Every returned route edge is legal")
		if result.ok:
			traversed = result.state
	_check(traversed.player == [10, 5, 0], "Following the route reaches its destination")
	_check(rules.find_path(full, Vector2i(12, 5)).is_empty(), "A closed gate cannot be a destination")
	var opened: Dictionary = rules.propose(full, [{"op": "set_field", "entity_id": "gate", "field": "open", "value": true}], {}).state
	_check(not rules.find_path(opened, Vector2i(12, 5)).is_empty(), "Opening a gate changes routing through the same world rules")
	_check(rules.find_path(initial, Vector2i(-1, 0)).is_empty(), "An outside destination rejects")
	_check(rules.find_path(initial, Vector2i(2, 9)).is_empty(), "A building interior cannot be a destination")
	_check(rules.find_path(initial, Vector2i(4, 5)).is_empty(), "Clicking the current cell needs no steps")
	_check(rules.find_path(full, Vector2i(10, 5)) == route, "Route tie-breaking is deterministic")
	_check(not rules.can_step(initial, Vector2i(5, 4), Vector2i(6, 4)), "A lamp between otherwise usable cell centers blocks that passage")
	var edge: Dictionary = initial.duplicate(true)
	edge.player = [0, 5, 0]
	_check(not rules.move(edge, Vector2i.LEFT).ok, "Boundary steps reject")
	var occupied: Dictionary = full.duplicate(true)
	occupied.player = [9, 5, 0]
	_check(not rules.propose(occupied, [{"op": "remove", "at": [9, 5, 0]}], {}).ok, "An occupied bridge deck cannot be removed")
	_check(rules.player_cell(moved.state) == moved.state.player, "Programs see exact integer cell coordinates")
	_large_area_tests()
	if _failures.is_empty():
		print("Grid movement and routing: %d checks passed." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		quit(1)


## A 64x48 map must route in a blink: static edges are cached and only gates and bridges are re-evaluated.
func _large_area_tests() -> void:
	var rows: Array = []
	for y: int in range(48):
		rows.append(".".repeat(64))
	var document: Dictionary = {
		"schema": 1, "id": "field", "title": "Field", "version": 1, "size": [64, 48], "spawn": [1, 1], "terrain": rows,
		"zones": [{"id": "all", "title": "All", "rect": [0, 0, 64, 48]}], "lamps": [], "gates": [], "bridges": [],
		"buildings": [], "trees": [], "segments": [{"kind": "wall", "from": [10, 24], "to": [50, 24]}], "wheels": [],
	}
	var parsed: Dictionary = AreaDef.parse(document, {})
	var rules := World.new(parsed.area)
	var state: Dictionary = rules.initial_state()
	var started: int = Time.get_ticks_usec()
	var route: Array[Vector2i] = rules.find_path(state, Vector2i(62, 46))
	var elapsed_ms: float = float(Time.get_ticks_usec() - started) / 1000.0
	_check(not route.is_empty() and route[-1] == Vector2i(62, 46), "A long route across the large area is found")
	_check(elapsed_ms < 400.0, "Cold-cache routing across 3072 cells stays fast (%.0f ms)" % elapsed_ms)
	started = Time.get_ticks_usec()
	rules.find_path(state, Vector2i(5, 46))
	elapsed_ms = float(Time.get_ticks_usec() - started) / 1000.0
	_check(elapsed_ms < 100.0, "Warm routing is quick (%.0f ms)" % elapsed_ms)
	var wall_row: Vector2i = Vector2i(30, 24)
	_check(not rules.is_walkable(state, wall_row), "A wall blocks the cells it runs through")
	var around: Array[Vector2i] = rules.find_path(state, Vector2i(30, 26))
	_check(not around.is_empty() and around.size() > 25, "Routes detour around a wall instead of through it")


func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
