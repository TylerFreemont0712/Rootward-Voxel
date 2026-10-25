extends SceneTree
## Area documents: validation, reachability, and the level's teaching arc played with real Python.
## Every quest's reference solution must complete its goal; every starter must not.

const World := preload("res://core/lab_world.gd")
const Program := preload("res://sandbox/lab_program.gd")
var _checks: int = 0
var _failures: Array[String] = []

## Reference solutions live here, not in the shipped content: the game never shows an answer.
const SOLUTIONS: Dictionary = {
	"first-light": "def program(world):\n    lamp = world.lamp(\"landing-lamp\")\n    lamp.set_lit(True)\n",
	"light-the-green": "def program(world):\n    green = world.zone(\"green\")\n    for lamp in green.lamps:\n        lamp.set_lit(True)\n",
	"mill-bridge": "def program(world):\n    bridge = world.bridge(\"mill-bridge\")\n    deck_count = 4\n    for cell in bridge.cells[:deck_count]:\n        bridge.place_deck(cell)\n",
	"night-gate": "def program(world):\n    gate = world.gate(\"night-gate\")\n    west = world.lamp(\"gate-west\")\n    east = world.lamp(\"gate-east\")\n    west.set_lit(True)\n    east.set_lit(True)\n    if west.lit and east.lit:\n        gate.set_open(True)\n    else:\n        gate.set_open(False)\n",
	"kindle-the-hollow": "def light_all(lamps):\n    for lamp in lamps:\n        lamp.set_lit(True)\n\ndef program(world):\n    for zone in world.zones:\n        light_all(zone.lamps)\n",
	# The optional second chapter (it needs a village to build in, so it is played apart from the five above).
	"face-the-lane": "def program(world):\n    row = world.zone(\"cottage-row\")\n    for house in row.houses:\n        if house.cell[1] < 18:\n            house.face(\"north\")\n",
}
## Where the player must stand so the notebook can see what the solution touches.
const VISITS: Dictionary = {
	"light-the-green": [Vector2i(29, 19)],
	"mill-bridge": [Vector2i(42, 19)],
	"night-gate": [Vector2i(29, 30)],
	"kindle-the-hollow": [Vector2i(30, 41), Vector2i(30, 44), Vector2i(10, 19), Vector2i(53, 20), Vector2i(10, 5)],
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var result: Dictionary = AreaStore.read("kindle-hollow")
	_check(result.ok, "Kindle Hollow validates: %s" % str(result.errors))
	if not result.ok:
		_finish()
		return
	var area: AreaDef = result.area
	_check(area.width == 96 and area.height == 80, "Kindle Hollow is 96x80")
	_check(area.lamps.size() >= 15 and area.zones.size() >= 8 and Quests.main(area).size() == 5, "The level has its lamps, zones and five quests in the main arc")
	_check(area.quests.size() == 6 and area.quest("face-the-lane").optional and str(area.quest("face-the-lane").chapter) != "" and Quests.main(area).all(func(entry: Dictionary) -> bool: return not entry.optional), "...and one optional quest in a second chapter, after them")
	var rules := World.new(area)
	_geometry(area, rules)
	_cabin_footprint()
	if Sandbox.is_available(SandboxJob.PYTHON):
		await _playthrough(area, rules)
	else:
		_check(false, "Python/WASI runtime is available")
	_finish()


func _geometry(area: AreaDef, rules: LabWorld) -> void:
	var start: Dictionary = rules.initial_state()
	_check(rules.is_walkable(start, area.spawn), "The spawn cell is standable")
	var open: Dictionary = start.duplicate(true)
	for gate: Dictionary in area.gates:
		open.gates[gate.id] = true
	for bridge: Dictionary in area.bridges:
		open.bridges[bridge.id] = bridge.sockets.size()
	# With every gate open and bridge built, everything the player needs is reachable.
	for lamp: Dictionary in area.lamps:
		var reachable: bool = false
		for delta: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN, Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
			var cell: Vector2i = lamp.cell + delta
			if rules.is_walkable(open, cell) and (cell == area.spawn or not rules.find_path(open, cell).is_empty()):
				reachable = true
				break
		_check(reachable, "Lamp %s has a reachable approach" % lamp.id)
	for zone: Dictionary in area.zones:
		var rect: Rect2i = zone.rect
		var found: bool = false
		for x: int in range(rect.position.x, rect.end.x):
			for y: int in range(rect.position.y, rect.end.y):
				if not found and rules.is_walkable(open, Vector2i(x, y)) and not rules.find_path(open, Vector2i(x, y)).is_empty():
					found = true
		_check(found, "Zone %s can be reached on foot" % zone.id)
	for building: Dictionary in area.buildings:
		var door: Vector2i = _door_cell(building)
		_check(area.in_bounds(door) and rules.is_walkable(open, door) and not rules.find_path(open, door).is_empty(), "The door of %s can be reached" % building.id)
	# The level's locks really lock: the closed state keeps the player out.
	_check(rules.find_path(start, Vector2i(49, 19)).is_empty(), "The mill yard needs the bridge")
	_check(rules.find_path(start, Vector2i(30, 41)).is_empty(), "The Lamp Road needs the gate open")
	_check(not rules.find_path(start, Vector2i(29, 30)).is_empty(), "The Night Gate is open to explore from the start")
	var bridged: Dictionary = start.duplicate(true)
	bridged.bridges["mill-bridge"] = 4
	_check(not rules.find_path(bridged, Vector2i(49, 19)).is_empty(), "The finished bridge opens the mill yard")
	var only_gate: Dictionary = start.duplicate(true)
	only_gate.gates["night-gate"] = true
	_check(not rules.find_path(only_gate, Vector2i(30, 44)).is_empty(), "An open gate leads to the Old Watch")
	for tree: Dictionary in area.trees:
		var cell := Vector2i(roundi(tree.at.x), roundi(tree.at.y))
		_check(cell != area.spawn, "A tree never stands on the spawn cell")
		break


## The log cabin is a drop-in for the cottage: at a whole-cell placement both block exactly the same cells, so
## changing a placement's asset never changes what the player can reach or what a quest solution needs.
func _cabin_footprint() -> void:
	var catalog: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/world-catalog.json")) as Dictionary).assets
	for facing: String in ["S", "E"]:
		var blocked: Array = []
		for id: String in ["cottage", "log-cabin"]:
			var footprint: Array = catalog[id].logical_footprint
			var size := Vector2(float(footprint[2]), float(footprint[3]))
			if facing == "E":
				size = Vector2(size.y, size.x)
			var rect := Rect2(Vector2(24, 6) - size * 0.5, size).grow(World.PLAYER_RADIUS)
			var cells: Array[Vector2i] = []
			for x: int in range(18, 31):
				for y: int in range(0, 13):
					if rect.has_point(Vector2(x, y)):
						cells.append(Vector2i(x, y))
			blocked.append(cells)
		_check(blocked[0] == blocked[1] and not (blocked[0] as Array).is_empty(), "The log cabin blocks the cottage's cells (facing %s)" % facing)
		# The large house is five cells square: two more each way, and no more.
		var large: Array = catalog["log-cabin-large"].logical_footprint
		var large_size := Vector2(float(large[2]), float(large[3]))
		var large_rect := Rect2(Vector2(24, 6) - large_size * 0.5, large_size).grow(World.PLAYER_RADIUS)
		var large_cells: int = 0
		for x: int in range(18, 31):
			for y: int in range(0, 13):
				if large_rect.has_point(Vector2(x, y)):
					large_cells += 1
		_check(large_cells == 25, "The large house blocks exactly five by five cells (%d)" % large_cells)


## The cell just in front of a building's door, from its footprint and facing.
func _door_cell(building: Dictionary) -> Vector2i:
	var rect: Rect2 = building.rect
	var direction: Vector2i = {"S": Vector2i(0, -1), "E": Vector2i(1, 0), "N": Vector2i(0, 1), "W": Vector2i(-1, 0)}[building.facing]
	var half: float = rect.size.x * 0.5 if direction.x != 0 else rect.size.y * 0.5
	return Vector2i(roundi(building.at.x + direction.x * (half + 0.7)), roundi(building.at.y + direction.y * (half + 0.7)))


func _walk(rules: LabWorld, state: Dictionary, goal: Vector2i) -> Dictionary:
	var route: Array[Vector2i] = rules.find_path(state, goal)
	var current: Dictionary = state
	for cell: Vector2i in route:
		var from := Vector2i(int(current.player[0]), int(current.player[1]))
		var step: Dictionary = rules.move(current, cell - from)
		if not step.ok:
			return current
		current = step.state
	return current


func _playthrough(area: AreaDef, rules: LabWorld) -> void:
	var state: Dictionary = rules.initial_state()
	var completed: Array = []
	var order: Array[String] = []
	for quest: Dictionary in Quests.main(area):
		order.append(quest.id)
	_check(Quests.current(area, completed).id == "first-light", "The first quest is available at the start")
	_check(Quests.available(area, completed).size() == 1, "Later quests stay locked until their prerequisites are done")
	for id: String in order:
		var quest: Dictionary = area.quest(id)
		for cell: Vector2i in VISITS.get(id, []):
			var reached: Dictionary = _walk(rules, state, cell)
			_check(reached.player == [cell.x, cell.y, 0], "The player can walk to %s for quest %s" % [str(cell), id])
			state = reached
		# The starter alone must not finish the quest.
		var starter: Dictionary = Program.run(quest.starter, rules.snapshot(state))
		_check(starter.ok, "The %s starter runs: %s" % [id, starter.reason])
		if starter.ok:
			var attempt: Dictionary = rules.propose(state, starter.commands, starter.memory)
			_check(attempt.ok and not Quests.goal_met(area, attempt.state, quest.goal), "The %s starter does not solve the quest" % id)
		var answer: Dictionary = Program.run(SOLUTIONS[id], rules.snapshot(state))
		_check(answer.ok, "The %s solution runs: %s" % [id, answer.reason])
		if not answer.ok:
			continue
		var proposal: Dictionary = rules.propose(state, answer.commands, answer.memory)
		_check(proposal.ok, "The %s solution is accepted by the world rules: %s" % [id, proposal.reason])
		if not proposal.ok:
			continue
		state = proposal.state
		if id == "mill-bridge":
			state = _walk(rules, state, Vector2i(48, 19))
		var done: Array[String] = Quests.newly_completed(area, state, completed)
		_check(done.has(id), "Running the %s solution completes the quest" % id)
		completed.append_array(done)
	_check(completed.size() == order.size(), "The whole arc completes in order")
	_check(Quests.main_arc_done(area, completed) and Quests.main_arc_done(area, completed.slice(0, 4)) == false, "The main arc is done exactly when its five quests are")
	_check(Quests.current(area, completed).get("id") == "face-the-lane", "After the finale only the optional second chapter remains")
	_check(Quests.goal_met(area, state, {"type": "lamps_lit", "all": true}), "Every lamp in the hollow is lit at the end")
	# A player who skipped ahead is not made to repeat work.
	var ahead: Dictionary = state.duplicate(true)
	var early: Array[String] = Quests.newly_completed(area, ahead, [])
	_check(early.size() == order.size(), "Quests whose goals are already met complete in one pass")
	# Out of order: the unlock chain still holds when nothing is done.
	var fresh: Array[String] = Quests.newly_completed(area, rules.initial_state(), [])
	_check(fresh.is_empty(), "A fresh world completes no quest by itself")
	_second_chapter(area, rules, state, completed)
	# The friendly API does not reveal places the player has not been to.
	var unexplored: Dictionary = Program.run("def program(world):\n    world.zone('watch')\n", rules.snapshot(rules.initial_state()))
	_check(not unexplored.ok and unexplored.error.kind == "WorldError", "An unvisited zone is not in the notebook")


## The optional chapter: "Face the lane" needs the village's own edit layer, so it is played with a BuildLedger. Its
## abilities arrive when the lesson is reached, the starter alone does not solve it, and the reference solution does.
func _second_chapter(area: AreaDef, rules: LabWorld, state: Dictionary, completed: Array) -> void:
	var quest: Dictionary = area.quest("face-the-lane")
	var source: Dictionary = AreaStore.read_source("kindle-hollow")
	var catalog: Dictionary = AreaStore.read_build_catalog()
	var ledger := BuildLedger.new(source.document, source.assets, source.quests, catalog, [], "studio", AreaStore.ground_materials())
	for house_id: Variant in quest.goal.ids:
		_check(not area.building(str(house_id)).is_empty(), "The lesson's goal names a real house: %s" % str(house_id))
	var abilities: Array[String] = Quests.capabilities(area, completed)
	_check(abilities.has("read") and abilities.has("turn"), "Reaching the lesson hands the code its abilities")
	_check(Quests.capabilities(area, completed.slice(0, 4)).is_empty(), "...and not before: it opens only after the five lessons")
	var start: Dictionary = Quests.goal_progress(ledger.area, state, quest.goal)
	_check(int(start.done) == 0 and int(start.total) == 2, "At the start no house faces the lane (0 of 2)")
	var snapshot: Dictionary = rules.snapshot(state)
	snapshot["build"] = CodeBuild.snapshot(ledger, state, abilities)
	var starter: Dictionary = Program.run(quest.starter, snapshot)
	_check(starter.ok and str(starter.stdout).contains("row-south-a"), "The face-the-lane starter runs and prints what each house knows: %s" % str(starter.get("reason", "")))
	if starter.ok:
		var attempt: Dictionary = CodeBuild.propose(ledger, state, starter.commands, abilities)
		_check(attempt.ok and (attempt.edits as Array).is_empty() and not Quests.goal_met(attempt.area, state, quest.goal), "The face-the-lane starter does not solve the quest")
	var answer: Dictionary = Program.run(SOLUTIONS["face-the-lane"], snapshot)
	_check(answer.ok, "The face-the-lane solution runs: %s" % str(answer.get("reason", "")))
	if not answer.ok:
		return
	var proposal: Dictionary = rules.propose(state, answer.commands, answer.memory, CodeBuild.BUILD_OPS)
	var building: Dictionary = CodeBuild.propose(ledger, state, answer.commands, abilities)
	_check(proposal.ok and building.ok, "The face-the-lane solution is accepted by the world rules: %s" % str(building.get("reason", proposal.get("reason", ""))))
	if not building.ok:
		return
	ledger.commit_code(building.edits, building.area, building.rules)
	var finished: Array[String] = Quests.newly_completed(ledger.area, state, completed)
	_check(finished == ["face-the-lane"], "Running the face-the-lane solution completes the quest, and only it")
	_check(Quests.main_arc_done(ledger.area, completed), "The epilogue's condition (the main arc) is unchanged by the optional chapter")
	# A player who takes one of the goal's houses away can still build; the lesson counts the houses that remain.
	var removal := BuildLedger.new(source.document, source.assets, source.quests, catalog, [{"op": "remove", "kind": "building", "id": "row-workshop"}], "studio", AreaStore.ground_materials())
	var left: Dictionary = Quests.goal_progress(removal.area, state, quest.goal)
	_check(removal.problems.is_empty() and int(left.total) == 1, "Taking one of the lesson's houses away does not break the village, and the goal counts the other (%d)" % int(left.total))
	var bad: Dictionary = (source.quests as Dictionary).duplicate(true)
	((bad.quests as Array)[5] as Dictionary)["goal"] = {"type": "houses_facing", "ids": [], "facing": "Q"}
	_check(not AreaDef.parse(source.document, source.assets, bad, AreaStore.ground_materials()).ok, "A houses_facing goal needs house ids and a real facing")
	var tangled: Dictionary = (source.quests as Dictionary).duplicate(true)
	((tangled.quests as Array)[0] as Dictionary)["requires"] = ["face-the-lane"]
	var cycle: Dictionary = AreaDef.parse(source.document, source.assets, tangled, AreaStore.ground_materials())
	_check(not cycle.ok and str(cycle.errors).contains("main arc"), "A main-arc quest cannot depend on an optional one")


func _finish() -> void:
	if _failures.is_empty():
		print("Area documents and the level's teaching arc: %d checks passed." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		printerr("Area documents: %d of %d checks failed." % [_failures.size(), _checks])
		quit(1)


func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
