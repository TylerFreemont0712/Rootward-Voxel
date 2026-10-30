extends SceneTree
## Area documents: validation, reachability, and the level's teaching arc played with real Python.
## Every quest's reference solution must complete its goal; every starter must not.

const World := preload("res://core/lab_world.gd")
const Program := preload("res://sandbox/lab_program.gd")
var _checks: int = 0
var _failures: Array[String] = []

## Reference solutions live here, not in the shipped content: the game never shows an answer.
const SOLUTIONS: Dictionary = {
	"say-hello": CompanionLesson.STARTER,
	"landing-light": "def program(world):\n    world.lamp(\"landing-lamp\").set_lit(True)\n",
	"morning-round": "def program(world):\n    for lamp in world.zone(\"workshop\").lamps:\n        lamp.set_lit(True)\n",
	"first-steps": "def program(world):\n    x = y = 0\n    y += 1\n    world.controls.bind_move(\"W\", x, y)\n    x = y = 0\n    x -= 1\n    world.controls.bind_move(\"A\", x, y)\n    x = y = 0\n    y -= 1\n    world.controls.bind_move(\"S\", x, y)\n    x = y = 0\n    x += 1\n    world.controls.bind_move(\"D\", x, y)\n",
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
		await _morning_quest()
		var workshop: AreaDef = AreaStore.load_area("workshop-floor")
		var workshop_rules := LabWorld.new(workshop)
		var initial: Dictionary = workshop_rules.initial_state()
		var hello: Dictionary = LabProgram.run(SOLUTIONS["say-hello"], workshop_rules.snapshot(initial))
		var voice: Dictionary = workshop_rules.propose(initial, hello.get("commands", []), hello.get("memory", {}))
		_check(hello.ok and voice.ok and not initial.hotaru_greeted and Quests.goal_met(workshop, voice.state, workshop.quest("say-hello").goal), "The workshop greeting has a real WASI reference solution and remains a detached proposal")
		await _workshop_jobs(workshop, workshop_rules)
		await _playthrough(area, rules)
	else:
		_check(false, "Python/WASI runtime is available")
	_finish()


func _workshop_jobs(room: AreaDef, rules: LabWorld) -> void:
	var state: Dictionary = rules.initial_state()
	state.hotaru_greeted = true
	var completed: Array = ["say-hello"]
	state.player = [12,10,0]
	var ticket: Dictionary = rules.read_inspection(state, "job-board")
	_check(ticket.ok and not Quests.goal_met(room,state,room.quest("waiting-ticket").goal), "Reading the nearby ticket is a detached discovery proposal")
	if not ticket.ok: return
	state = ticket.state
	state.player = [1,2,0]
	_check(not ZoneTerminals.connect_at(room, state, "workshop-terminal").ok, "The wall screen's socket needs the tablet the player carries from the loft")
	state.items = ["field-tablet"]
	var connection: Dictionary = ZoneTerminals.connect_at(room, state, "workshop-terminal")
	_check(connection.ok, "The reference playthrough jacks the tablet into the wall screen before programming its zone")
	if not connection.ok: return
	state = connection.state
	completed.append_array(Quests.newly_completed(room,state,completed))
	_check(completed.has("waiting-ticket"), "The ticket's reference interaction unlocks the stair-light job")
	for id: String in ["landing-light", "morning-round"]:
		var quest: Dictionary = room.quest(id)
		var unchanged: Dictionary = LabProgram.run(quest.starter,rules.snapshot(state))
		var attempt: Dictionary = rules.propose(state,unchanged.get("commands",[]),unchanged.get("memory",{}))
		_check(unchanged.ok and attempt.ok and not Quests.goal_met(room,attempt.state,quest.goal), "The workshop starter leaves its actual goal incomplete: "+id)
		var answer: Dictionary = LabProgram.run(SOLUTIONS[id],rules.snapshot(state))
		var proposal: Dictionary = rules.propose(state,answer.get("commands",[]),answer.get("memory",{}))
		_check(answer.ok and proposal.ok and Quests.goal_met(room,proposal.state,quest.goal), "The real WASI reference solution completes the world goal: "+id)
		_check(not Quests.goal_met(room,state,quest.goal), "A test does not commit the workshop goal: "+id)
		if not proposal.ok:return
		state=proposal.state
		completed.append_array(Quests.newly_completed(room,state,completed))
	_check(Quests.main_arc_done(room,completed), "The ticket and both reference routines complete the connected workshop chapter")


func _morning_quest() -> void:
	var loaded: Dictionary=AreaStore.read("morning-bedroom")
	_check(loaded.ok,"The unique starting bedroom and movement quest validate: "+str(loaded.errors))
	if not loaded.ok:return
	var room: AreaDef=loaded.area
	var rules:=LabWorld.new(room)
	var state: Dictionary=rules.initial_state()
	var hello: Dictionary=LabProgram.run(SOLUTIONS["say-hello"],rules.snapshot(state))
	_check(hello.ok and hello.commands.size()==1 and hello.commands[0].op=="say" and hello.stdout=="Hello, Hotaru!","The hello reference solution uses real Python print and a typed speech command")
	var voice: Dictionary=rules.propose(state,hello.get("commands",[]),hello.get("memory",{}))
	_check(voice.ok and not state.hotaru_greeted and Quests.goal_met(room,voice.state,room.quest("say-hello").goal),"Saying hello remains a detached proposal until Apply")
	if not voice.ok:return
	state=voice.state
	_check(Quests.newly_completed(room,state,[])==["say-hello"] and Quests.current(room,["say-hello"]).id=="first-steps","Greeting unlocks movement as lesson two")
	var starter: Dictionary=LabProgram.run(room.quest("first-steps").starter,rules.snapshot(state))
	_check(starter.ok,"The movement starter runs in real Python/WASI")
	if starter.ok:
		var partial: Dictionary=rules.propose(state,starter.commands,starter.memory)
		_check(partial.ok and not Quests.goal_met(room,partial.state,room.quest("first-steps").goal),"The starter does not solve the movement lesson")
	var answer: Dictionary=LabProgram.run(SOLUTIONS["first-steps"],rules.snapshot(state))
	_check(answer.ok,"The first-step reference program runs through Python/WASI")
	if not answer.ok:return
	var proposal: Dictionary=rules.propose(state,answer.commands,answer.memory)
	_check(proposal.ok and not Quests.goal_met(room,proposal.state,room.quest("first-steps").goal),"Connecting keys still requires trying the keys")
	if not proposal.ok:return
	state=proposal.state
	for key: String in ["W","D","S","A"]:
		var step: Dictionary=rules.move(state,MovementBindings.direction(state.controls,key),key)
		_check(step.ok,"The authored bedroom gives the first-step solution clear walking space")
		if step.ok:state=step.state
	_check(Quests.goal_met(room,state,room.quest("first-steps").goal),"The reference solution plus four bound-key steps completes the first quest")


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
	return Vector2i(roundi(building.at.x + direction.x * (half + 0.7 + int(building.get("door_offset",0)))), roundi(building.at.y + direction.y * (half + 0.7 + int(building.get("door_offset",0)))))


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
