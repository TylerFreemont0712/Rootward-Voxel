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
	"after-the-light": "def program(world):\n    for name in [\"shop-door-lamp\", \"shop-sign-lamp\"]:\n        lamp = world.lamp(name)\n        if world.time.is_dark:\n            lamp.set_lit(True)\n        else:\n            lamp.set_lit(False)\n",
	"proper-welcome": 'def program(world):\n    for message in ["Welcome to Spindle Lane", "Mind the step", "Tea first. Tram second."]:\n        print(message)\n',
	"landing-light": "def program(world):\n    world.lamp(\"landing-lamp\").set_lit(True)\n",
	"morning-round": "def program(world):\n    for lamp in world.zone(\"workshop\").lamps:\n        lamp.set_lit(True)\n",
	"band-seats": "def program(world):\n    for thing in world.doodads:\n        if thing.kind == \"lane-bench\":\n            if thing.at[0] > 85:\n                thing.face(\"west\")\n            elif thing.at[1] < 2:\n                thing.face(\"north\")\n",
	"room-on-the-walk": "def program(world):\n    for i in range(4):\n        world.doodad(\"walk-bench-\" + str(i)).move_to(25.9, 21 + 6 * i)\n",
	"two-parks": "def dress(tree, left, right):\n    x = tree.at[0]\n    left.move_to(x - 1.5, 50)\n    right.move_to(x + 1.5, 50)\n\ndef program(world):\n    dress(world.doodad(\"park-1-tree\"), world.doodad(\"delivery-planter-1\"), world.doodad(\"delivery-planter-2\"))\n    dress(world.doodad(\"park-2-tree\"), world.doodad(\"delivery-planter-3\"), world.doodad(\"delivery-planter-4\"))\n",
	"market-day": "def program(world):\n    stalls = []\n    for thing in world.doodads:\n        if \"stall\" in thing.kind and thing.at[0] < 43:\n            stalls.append(thing)\n    for i in range(len(stalls)):\n        stalls[i].move_to(41.9, 33.5 + 4.25 * i)\n",
	"own-corner": "def program(world):\n    pieces = [world.doodad(\"spindle-park-bench\"), world.doodad(\"spindle-park-seat\"), world.doodad(\"spindle-park-shrub\")]\n    for i in range(len(pieces)):\n        pieces[i].move_to(6 + 4 * i, 4)\n",
	"next-batch": "def program(world):\n    hour = 7\n    while hour <= 11:\n        print(\"BATCH AT \" + str(hour))\n        hour = hour + 2\n",
	"todays-prices": "def program(world):\n    prices = {\"APPLES\": 4, \"LEMONS\": 3, \"PLUMS\": 6}\n    prices[\"PLUMS\"] = 5\n    for name in prices:\n        print(name + \" \" + str(prices[name]) + \"P\")\n",
	"ready-for-collection": "def ticket(name):\n    return name.upper() + \" READY\"\n\ndef program(world):\n    for name in [\"braum\", \"iona\", \"mira\"]:\n        print(ticket(name))\n",
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for id: String in LevelStore.entry(LevelStore.MAIN_LEVEL).room_areas:
		var loaded: Dictionary = AreaStore.read(id)
		_check(loaded.ok, "%s validates: %s" % [id, str(loaded.get("errors", []))])
	if Sandbox.is_available(SandboxJob.PYTHON):
		var workshop: AreaDef = AreaStore.load_area("workshop-floor")
		var workshop_rules := LabWorld.new(workshop)
		var initial: Dictionary = workshop_rules.initial_state()
		var hello: Dictionary = LabProgram.run(SOLUTIONS["say-hello"], workshop_rules.snapshot(initial))
		var voice: Dictionary = workshop_rules.propose(initial, hello.get("commands", []), hello.get("memory", {}))
		_check(hello.ok and voice.ok and not initial.hotaru_greeted and Quests.goal_met(workshop, voice.state, workshop.quest("say-hello").goal), "The workshop greeting has a real WASI reference solution and remains a detached proposal")
		await _workshop_jobs(workshop, workshop_rules)
		_welcome_job()
		_evening_job()
		_public_works()
		_market_street()
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

func _welcome_job() -> void:
	var lane: AreaDef=AreaStore.load_area("haverlund-lane")
	var rules:=LabWorld.new(lane)
	var state: Dictionary=rules.initial_state()
	state.player=[9,6,0]
	state.items=["field-tablet"]
	state.zones_seen.append("tram-halt")
	state.inspections_read=["sign-commission"]
	var snapshot: Dictionary=rules.snapshot(state)
	snapshot["display_sink"]={"target":"tram-welcome"}
	var quest: Dictionary=lane.quest("proper-welcome")
	for source: String in [str(quest.starter),str(SOLUTIONS["proper-welcome"])]:
		var run: Dictionary=LabProgram.run(source,snapshot)
		var result: Dictionary=rules.propose(state,run.get("commands",[]),{})
		_check(run.ok and result.ok,"The sign card executes through WASI and core validation")
		_check(Quests.goal_met(lane,result.state,quest.goal)==(source==SOLUTIONS["proper-welcome"]),"The sign reference completes its world goal; unchanged starter does not")
		_check(state.display_cards.is_empty(),"A sign test never installs a card")
	_check(not rules.find_path(state,Vector2i(7,25),Vector2i(11,18)).is_empty(),"Braum's garden route uses actual open passages")
	_check(not rules.find_path(state,Vector2i(11,18),Vector2i(10,6)).is_empty(),"Braum can walk from the lane to the tram landing")


## Chapter 05: Public Works tickets in the square. Each reference solution runs as real Python, its build commands
## pass the builder's own rules, the ledger keeps them, and the job's goal is met; its starter never meets it.
func _public_works() -> void:
	var source: Dictionary = AreaStore.read_source("haverlund-square")
	var ledger := BuildLedger.new(source.document, source.assets, source.quests, AreaStore.read_build_catalog(), [], "player", AreaStore.ground_materials())
	var square: AreaDef = ledger.area
	_check(Quests.available(square, [], []).is_empty() and Quests.current(square, [], ["after-the-light"]).get("id") == "band-seats", "Public Works opens only after the evening job, which is finished in another room")
	_check(Quests.capabilities(square, [], ["after-the-light"]) == ["read", "turn"] and Quests.capabilities(square, ["band-seats"], ["after-the-light"]).has("move"), "The first ticket teaches reading and turning; the second moving")
	var state: Dictionary = ledger.rules.initial_state()
	state.player = [51, 16, 0]
	state.items = ["field-tablet"]
	# Code reaches the places the player has walked through; by the fifth chapter that is the whole square.
	state.zones_seen = square.zones.map(func(zone: Dictionary) -> String: return str(zone.id))
	var abilities: Array[String] = ["read", "turn", "move"]
	var done: Array = []
	for id: String in ["band-seats", "room-on-the-walk", "two-parks", "market-day", "own-corner"]:
		var quest: Dictionary = square.quest(id)
		_check(Quests.current(ledger.area, done, ["after-the-light"]).get("id") == id, "Ticket order reaches " + id)
		for attempt: String in [str(quest.starter), str(SOLUTIONS[id])]:
			var snapshot: Dictionary = ledger.rules.snapshot(state)
			snapshot["build"] = CodeBuild.snapshot(ledger, state, abilities)
			var run: Dictionary = Program.run(attempt, snapshot)
			var building: Dictionary = CodeBuild.propose(ledger, state, run.get("commands", []), abilities) if run.get("ok", false) else {"ok": false, "reason": run.get("reason", "")}
			var solved: bool = building.ok and not (building.edits as Array).is_empty() and Quests.goal_met(building.area, state, quest.goal)
			if attempt == str(SOLUTIONS[id]):
				_check(run.get("ok", false) and building.ok and solved, "The real WASI reference solution meets the Public Works goal: %s %s %s" % [id, str(run.get("reason", "")), str(building.get("reason", ""))])
				if building.ok:
					ledger.commit_code(building.edits, building.area, building.rules)
			else:
				_check(run.get("ok", false) and not solved, "The unchanged starter runs but leaves the job open: " + id)
		_check(Quests.goal_met(ledger.area, state, quest.goal), "The kept edits complete " + id)
		done.append(id)
	_check(Quests.main_arc_done(ledger.area, done), "The five tickets complete the square's chapter")


## Chapter 06: each shop's board job. The reference solution writes exactly the lines the shopkeeper asked for; the
## starter runs and writes a card, but not that one.
func _market_street() -> void:
	for spec: Array in [["shop-bakery", "next-batch", "bake-board"], ["shop-greengrocer", "todays-prices", "price-board"], ["shop-bookshop", "ready-for-collection", "order-board"]]:
		var room: AreaDef = AreaStore.load_area(spec[0])
		var quest: Dictionary = room.quest(spec[1])
		_check(Quests.available(room, [], []).is_empty() and Quests.current(room, [], ["own-corner"]).get("id") == spec[1], "%s opens once Public Works is finished" % spec[1])
		var rules := LabWorld.new(room)
		var display: Dictionary = DisplayCards.find(room, spec[2])
		var state: Dictionary = rules.initial_state()
		state.player = [int(display.at[0]), int(display.at[1]), 0]
		state.items = ["field-tablet"]
		state.inspections_read = [str(display.commission)]
		_check(rules.is_walkable(state, Vector2i(int(display.at[0]), int(display.at[1]))) and DisplayCards.in_reach(room, state, display), "The %s can be written from where its job stands you" % display.title)
		var snapshot: Dictionary = rules.snapshot(state)
		snapshot["display_sink"] = {"target": spec[2]}
		for source: String in [str(quest.starter), str(SOLUTIONS[spec[1]])]:
			var run: Dictionary = Program.run(source, snapshot)
			var result: Dictionary = rules.propose(state, run.get("commands", []), {})
			_check(run.get("ok", false) and result.ok, "%s runs as real Python and installs a card: %s %s" % [spec[1], str(run.get("reason", "")), str(result.get("reason", ""))])
			if result.ok: _check(Quests.goal_met(room, result.state, quest.goal) == (source == str(SOLUTIONS[spec[1]])), "Only the finished %s routine writes the shopkeeper's lines" % spec[1])


func _evening_job() -> void:
	var room: AreaDef = AreaStore.load_area("haverlund-lane")
	var rules := LabWorld.new(room)
	var state: Dictionary=rules.initial_state()
	state.player=[11,13,0]
	state.items=["field-tablet"]
	state.zones_seen=["spindle-lane"]
	state.inspections_read=["nell-evening"]
	var daylight: Dictionary=rules.snapshot(state)
	daylight.companion.enabled=false
	daylight.time.is_dark=false
	var darkness: Dictionary=daylight.duplicate(true)
	darkness.time.is_dark=true
	for source: String in [str(room.quest("after-the-light").starter),str(SOLUTIONS["after-the-light"])]:
		var answer: Dictionary=LampPrograms.compile_trials(Program.run(source,daylight),Program.run(source,darkness))
		var proposal: Dictionary=rules.propose(state,answer.get("commands",[]),{})
		_check(answer.get("ok",false) and proposal.ok,"Closing-round starter and solution both run as real Python")
		if proposal.ok:_check(Quests.goal_met(room,proposal.state,room.quest("after-the-light").goal)==(source==SOLUTIONS["after-the-light"]),"Only the corrected condition passes both clock states")
