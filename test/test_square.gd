extends SceneTree
## Rootward Square, version 3: the town's hub. The street down from Spindle Lane arrives in the south-west corner,
## three open ways leave it (north-west, north-east, south-east) for later areas, every building, railing and house is
## its own placement on the base ground, robots on their rounds stay clear of everything that blocks, every inspection
## is reachable, and the room/sandbox boundaries and saved return hold.
var checks: int = 0
var failures: Array[String] = []
var game: Game
var output: String = ""
const WorldAssets := preload("res://art/world_assets.gd")
const MODELS: Array[String] = ["haverlund-square-ground", "rootwell-beacon", "rootwell-plaza", "square-guildhall", "haverlund-post-office",
	"haverlund-fruit-market", "haverlund-bank", "haverlund-bakery", "haverlund-greengrocer", "haverlund-bookshop", "haverlund-cafe",
	"square-banner-lamp", "square-flower-stall", "square-fruit-stall", "square-market-stall", "square-timber-store", "square-node",
	"robot-pip", "robot-trowel", "robot-wick", "robot-heron", "robot-tender", "robot-tally", "town-balustrade", "town-balustrade-pier",
	"town-railing", "town-railing-stair", "town-railing-post", "town-garden-wall", "town-garden-pier", "town-garden-gate", "town-power-pillar",
	"town-kiosk", "town-fountain", "town-bollard", "town-bin", "town-parasol-table", "town-lawn", "town-tree-grate", "town-festoon",
	"town-signpost", "town-planter-bench", "town-bollard-light", "town-poster-column", "town-coffee-cart", "town-bike-rack"]
const FACING := {0: Vector2(0, -1), 90: Vector2(1, 0), 180: Vector2(0, 1), 270: Vector2(-1, 0)}

func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	go.call_deferred()

func go() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): output = args[0]
	_rules()
	await _play()
	if failures.is_empty(): print("Rootward Square: %d checks passed." % checks)
	else:
		for failure: String in failures: printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)

func _rules() -> void:
	var parsed: Dictionary = AreaStore.read("haverlund-square")
	_check(parsed.ok, "The complete square document validates: " + str(parsed.get("errors", [])))
	if not parsed.ok: return
	var area: AreaDef = parsed.area
	var rules := LabWorld.new(area)
	var state: Dictionary = rules.initial_state()
	_check(area.quests.is_empty() and area.spawn == Vector2i(1, 8) and area.version == 3 and area.width == 72 and area.height == 64, "The 72 by 64 hub arrives at the top of its south-west street and adds no quest")
	_check(LevelStore.entry("sparks-and-machines").room_areas.has(area.id), "The fourth room belongs only to Sparks")
	_check(not LevelStore.entry("village-morning").get("room_areas", []).has(area.id), "Village Morning has no square-room dependency")
	var lane: AreaDef = AreaStore.load_area("haverlund-lane")
	var outward: Dictionary = RoomLinks.find(lane, "town-steps")
	var back: Dictionary = RoomLinks.find(area, "uphill")
	_check(outward.to == area.id and Vector2i(int(outward.arrival[0]),int(outward.arrival[1])) == area.spawn and outward.facing == "E" and back.to == lane.id and Vector2i(int(back.arrival[0]),int(back.arrival[1])) == Vector2i(12,26), "The walking links are reciprocal; the tram has no link")
	_check((lane.interior.links as Array).size() == 2, "The tram keeps its separate future destination")
	# Downhill continues: the lane's steps lead on to the square's west edge, high up, and the square lies below to the east.
	_check(back.direction == "W" and Vector2i(int(back.at[0]), int(back.at[1])).x == 0 and area.level_at(area.spawn) == 2 and area.level_at(Vector2i(12, 8)) == 0 and area.level_at(Vector2i(42, 24)) == 0,
		"The uphill street leaves by the west edge at the top; the square is two levels below")
	for item: Dictionary in area.interior.inspections:
		var at := Vector2i(int(item.at[0]), int(item.at[1]))
		_check(rules.is_walkable(state, at) and not rules.find_path(state, at, area.spawn).is_empty(), "The traveller can walk to " + str(item.id))
	for terminal: Dictionary in area.terminals:
		_check(not rules.find_path(state, Vector2i(int(terminal.at[0]),int(terminal.at[1])),area.spawn).is_empty(), "The square screen has a reachable approach")
	for lamp: Dictionary in area.lamps:
		_check(not rules.find_path(state, Vector2i(int(lamp.stand[0]),int(lamp.stand[1])),area.spawn).is_empty(), "The fitting " + str(lamp.id) + " is reachable")
	# Enumerate the actual traversable graph rather than relying on a few specially chosen destinations.
	var reached: Dictionary = {area.spawn:true}
	var queue: Array[Vector2i] = [area.spawn]
	var cursor: int = 0
	while cursor < queue.size():
		var at: Vector2i = queue[cursor]
		cursor += 1
		state.player = [at.x,at.y,0]
		for step: Vector2i in AreaDef.STEPS.values():
			var next: Vector2i = at + step
			if not reached.has(next) and rules.move(state, step).ok:
				reached[next] = true
				queue.append(next)
	var isolated: Array[Vector2i] = []
	for x: int in range(area.width):
		for y: int in range(area.height):
			var cell := Vector2i(x,y)
			if rules.is_walkable(state,cell) and not reached.has(cell): isolated.append(cell)
	_check(isolated.is_empty(), "No stranded walkable cells behind shops, railings or the hall: " + str(isolated))
	_check(reached.size() > 2500, "The hub has room to grow: %d walkable cells" % reached.size())
	_check(not reached.has(Vector2i(30, 55)) and not reached.has(Vector2i(5, 30)) and not reached.has(Vector2i(16, 20)), "The yards behind the hall, the hill and the shops stay closed")
	# The three ways out for later areas: Hill Street (north-west), Lantern Row (north-east) and the Harbour Steps
	# (south-east) are open from the square to the area's edge.
	for exit: Array in [[Vector2i(14, 63), "Hill Street reaches the north edge"], [Vector2i(71, 45), "Lantern Row reaches the east edge"], [Vector2i(60, 0), "The Harbour Steps reach the south edge"]]:
		_check(reached.has(exit[0]), exit[1])
	var previous: float = INF
	var descending: bool = true
	for n: int in range(661):
		var height: float = WalkingSurface.height(area,Vector2(1.0+float(n)/60,8.0),[])
		descending = descending and height <= previous+.0001 and (previous==INF or previous-height < .1)
		previous = height
	_check(descending and previous < .1 and WalkingSurface.height(area, Vector2(1, 8), []) > 1.9, "Both flights descend continuously east with a level landing between them")
	# Robots on their rounds never touch anything that blocks, so they read as going round things.
	var robots: Array = area.interior.life.get("robots", [])
	_check(robots.size() == 3, "Three robots go about their rounds")
	for robot: Dictionary in robots:
		var points: Array[Vector2] = []
		for point: Array in robot.path: points.append(Vector2(float(point[0]), float(point[1])))
		if bool(robot.get("loop", false)): points.append(points[0])
		var clear: bool = true
		for index: int in range(points.size() - 1):
			var a: Vector2 = points[index]
			var b: Vector2 = points[index + 1]
			for k: int in range(int(a.distance_to(b) / .1) + 1):
				var p: Vector2 = a.lerp(b, minf(1.0, float(k) * .1 / maxf(.001, a.distance_to(b))))
				for block: Dictionary in area.interior.furniture:
					var rect: Rect2 = block.rect
					var gap := Vector2(maxf(maxf(rect.position.x - p.x, 0.0), p.x - rect.end.x), maxf(maxf(rect.position.y - p.y, 0.0), p.y - rect.end.y))
					if block.kind != "rug" and gap.length() < .3: clear = false
		_check(clear, "Robot " + str(robot.asset) + "'s round keeps clear of every blocking footprint")
	for bad: Dictionary in [{"asset": "nobody", "path": [[1, 1], [2, 2]], "speed": 1}, {"asset": "pip", "path": [[1, 1]], "speed": 1},
			{"asset": "pip", "path": [[1, 1], [2, 2]], "speed": 9}, {"asset": "pip", "path": [[1, 1], [2, 2]], "speed": 1, "pause": 99}]:
		var room: Dictionary = area.interior.duplicate(true)
		room.life.robots = [bad]
		_check(AreaDef._life_error(room) != "", "A malformed robot round is refused: " + str(bad))
	# The square is part of the town: the ground model reaches well past every edge of the walkable square, so no cut
	# edge or empty sky shows below it, and background houses stand on it all round.
	var houses: Array = (area.interior.assets as Array).filter(func(item: Dictionary) -> bool: return str(item.asset).begins_with("seaside-"))
	# Every placement names a catalogued model; the old one-piece west terrace has gone.
	var placed: Array = (area.interior.assets as Array).map(func(item: Dictionary) -> String: return str(item.asset))
	_check(placed.all(func(id: String) -> bool: return not WorldAssets.entry(id).is_empty()) and not placed.has("square-west-terrace"), "Every placement is a catalogued model and the old terrace is replaced by separate shops")
	_check(["haverlund-bakery", "haverlund-greengrocer", "haverlund-bookshop", "haverlund-cafe", "town-kiosk", "town-coffee-cart"].all(func(id: String) -> bool: return placed.has(id)), "Shops, a kiosk and a coffee cart line the square")
	# The Rootwell stands 35 % larger than its model, and every seat round it faces it with a planter at its back.
	var well: Array = (area.interior.assets as Array).filter(func(item: Dictionary) -> bool: return item.asset == "rootwell-beacon")
	_check(well.size() == 1 and float(well[0].get("scale", 1.0)) >= 1.3, "The Rootwell is placed at least 30 % larger")
	var seats: Array = (area.interior.assets as Array).filter(func(item: Dictionary) -> bool: return item.asset == "town-planter-bench")
	var centre := Vector2(float(well[0].at[0]), float(well[0].at[1])) if well.size() == 1 else Vector2.ZERO
	_check(seats.size() == 8 and seats.all(func(item: Dictionary) -> bool:
		var at := Vector2(float(item.at[0]), float(item.at[1]))
		return FACING.has(int(item.turn)) and (FACING[int(item.turn)] as Vector2).dot((centre - at).normalized()) > .85), "Eight sheltered seats face the Rootwell")
	_check(placed.count("town-bollard-light") >= 12 and placed.count("town-festoon") == 2 and placed.has("town-signpost"), "Low path lights, two festoons and a fingerpost light and sign the ways across")
	_check(houses.size() >= 50 and houses.any(func(item: Dictionary) -> bool: return float(item.at[1]) < 0) and houses.any(func(item: Dictionary) -> bool: return float(item.at[0]) > area.width)
		and houses.any(func(item: Dictionary) -> bool: return float(item.at[1]) > area.height) and houses.any(func(item: Dictionary) -> bool: return float(item.at[0]) < 0), "Background houses stand beyond all four edges (%d)" % houses.size())
	var set_model := WorldAssets.instantiate("haverlund-square-ground")
	_check(set_model != null, "The square ground loads")
	if set_model != null:
		var bounds := AABB()
		var first: bool = true
		for mesh: Node in set_model.find_children("*", "MeshInstance3D", true, false):
			var instance := mesh as MeshInstance3D
			var box: AABB = instance.get_aabb()
			var node: Node3D = instance
			var transform := Transform3D.IDENTITY
			while node != null and node != set_model:
				transform = node.transform * transform
				node = node.get_parent() as Node3D
			box = transform * box
			bounds = box if first else bounds.merge(box)
			first = false
		_check(bounds.position.x < -12.0 and bounds.end.x > area.width + 12.0 and -bounds.end.z < -12.0 and -bounds.position.z > area.height + 8.0 and bounds.position.y < -5.0,
			"The town continues past all four edges, with the lower town below the balustrades: " + str(bounds))
		set_model.free()
	# The retaining walls' power pillars glow along their whole width, not in a slit between stone stiles.
	var pillar := WorldAssets.instantiate("town-power-pillar")
	var column: MeshInstance3D = null
	if pillar != null:
		for mesh: Node in pillar.find_children("*", "MeshInstance3D", true, false):
			if WorldAssetMeta.value(mesh, "power_column", false): column = mesh
	_check(column != null and column.get_aabb().size.x >= 1.0 and column.material_override is ShaderMaterial, "The power pillar is one glowing glass column a metre across")
	if pillar != null: pillar.free()
	state = rules.initial_state()
	state.player = [35,17,0]
	state.zones_seen = ["rootward-square"]
	_check(not ZoneTerminals.connect_at(area,state,"square-terminal").ok, "The square screen requires the carried tablet")
	state.items = ["field-tablet"]
	var linked: Dictionary = ZoneTerminals.connect_at(area,state,"square-terminal")
	_check(linked.ok and rules.snapshot(linked.state).lamps.size()==3, "The physical screen reaches its three declared lamps")
	linked.state.player = [60,5,0]
	_check(rules.snapshot(linked.state).lamps.is_empty(), "Walking away from the screen revokes remote scope")
	var batch: Dictionary = rules.propose(linked.state,[{"op":"set_field","entity_id":"well-west","field":"enabled","value":true}],{})
	_check(not batch.ok, "Raw commands cannot bypass the screen's proximity")
	for id: String in MODELS:
		var model := WorldAssets.instantiate(id)
		_check(model!=null, "The selected square model loads: " + id)
		if model!=null:model.free()

func _play() -> void:
	SaveStore.save_path = "user://test_square_" + str(OS.get_process_id()) + ".json"
	SaveStore.profile_path = "user://test_square_profile_" + str(OS.get_process_id()) + ".json"
	SaveStore.force_enabled = true
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game("sparks-and-machines")
	game._pop_all_modals()
	game.close_notebook(true)
	game.session.state.hotaru_greeted = true
	game.session.state.spoken = "Hello, Hotaru!"
	game.session.completed.append("say-hello")
	game.session.state.items = ["field-tablet"]
	game._dialogue_read["loft-waking"] = ["introduced"]
	game._dialogue_read["workshop-scenes"] = ["waiting-ticket","tablet-taken","workshop-arrival","lane-arrival"]
	game.session.state.player = [7,5,0]
	game.view.sync_player(game.session.state)
	_check(await game.travel_room_link("downstairs"), "Travel begins through the existing real loft link")
	game._pop_all_modals()
	game.session.state.player = [13,4,0]
	game.view.sync_player(game.session.state)
	_check(await game.travel_room_link("street"), "The workshop still opens onto Spindle Lane")
	game._pop_all_modals()
	game.session.state.memory = {"lane_only":17}
	await walk(Vector2i(12,25))
	_check(game.session.request_step(Vector2i(0,1)), "A normal step reaches the gate without leaving the lane")
	game.session.advance_walk(LabWorld.STEP_SECONDS)
	await shot("01-open-gate")
	_check(game.session.request_step(Vector2i(0,1)), "The real outward step through the town gate starts travel")
	while game._flow_busy: await process_frame
	await settle()
	_check(game.area.id=="haverlund-square" and game.session.player_cell()==Vector2i(3,7), "The downhill route walks on through the veil and down into the square's south-west street")
	if game.area.id!="haverlund-square":
		game.queue_free();await process_frame;return
	var stage := game.view.stage as WorkshopLaneStage
	_check(stage != null and game.view.companion_present(), "The square has the same robot, speech and outdoor life presenter")
	_check(PlayerItems.has(game.session.state,"field-tablet") and not game.session.state.memory.has("lane_only"), "The tablet travels while area program memory stays local")
	# Story discovery happens in Game._process once travel has released its input gate.
	game._refresh_interaction()
	await shot("02-street-arrival")
	var arrival := game._modals[-1] as WorkshopScene if not game._modals.is_empty() else null
	_check(arrival!=null and arrival.pages.size()==3, "A short arrival scene introduces the square without adding a quest")
	if arrival!=null:
		while is_instance_valid(arrival) and arrival.index < arrival.pages.size(): arrival.advance()
	_check(game._dialogue_read["workshop-scenes"].has("square-arrival"), "Finishing the arrival records it through the normal story flow")
	game._refresh_interaction()
	await shot("02b-street-top")
	# Follow actual steps at real interpolation cadence; collect a frame mid-flight and at the street's foot.
	for n: int in range(9):
		_check(game.session.request_step(Vector2i(1,0)), "A real step descends the street")
		game.session.advance_walk(LabWorld.STEP_SECONDS*.5)
		if n==4: await shot("03-descending-steps")
		if game.session.is_walking():game.session.advance_walk(LabWorld.STEP_SECONDS)
	_check(game.session.player_cell()==Vector2i(12,7) and game.view.player_node().position.y<.2,"The feet reach the square floor from two flights")
	# Robots on their rounds move, turn their wheels, and wait for someone standing in their way.
	if stage != null:
		_check(stage._rounds.size() == 3, "The three rounds are running")
		var pip: Dictionary = stage._rounds[0]
		var robot: Node3D = pip.node
		var start: Vector3 = robot.position
		var wheel: Node3D = (pip.wheels as Array)[0] if not (pip.wheels as Array).is_empty() else null
		var spin: float = wheel.rotation.x if wheel != null else 0.0
		for n: int in range(80): stage._roll(pip, .1)
		_check(robot.position.distance_to(start) > 1.0 and wheel != null and not is_equal_approx(wheel.rotation.x, spin), "Pip rolls away from the post office on turning wheels")
		var heading: Vector3 = ((pip.points as Array)[int(pip.next)] as Vector3) - robot.position
		heading.y = 0.0
		var player: Node3D = game.view.player_node()
		var kept: Vector3 = player.position
		player.position = robot.position + heading.normalized() * .8
		var held: Vector3 = robot.position
		pip.wait = 0.0
		for n: int in range(10): stage._roll(pip, .1)
		_check(robot.position.distance_to(held) < .001, "A robot waits while the apprentice stands in its way")
		player.position = kept
	await walk(Vector2i(47,19))
	game._refresh_interaction()
	_check(game._interaction.get("id")=="beacon-dial", "F inspects the beacon's dial from the plaza")
	game.interact()
	await shot("04-beacon")
	game.workshop_speech.dismiss_inspection()
	if not output.is_empty() and DisplayServer.get_name()!="headless":
		game.view.set_camera_mode(ClearingView.CameraMode.FIXED)
		game.view.focus_on(Vector2(42,24),true)
		game.view.set_zoom(10)
		await shot("04b-beacon-detail")
		game.view.focus_on(Vector2(36,30),true)
		game.view.set_zoom(24)
		await shot("10-overview")
		game.view.set_zoom(16)
		game.view.set_camera_mode(ClearingView.CameraMode.FOLLOW)
	await walk(Vector2i(19,22))
	await shot("05-shops")
	await walk(Vector2i(22,39))
	await shot("06-market")
	await walk(Vector2i(41,48))
	await shot("07-guild-hall")
	await walk(Vector2i(50,6))
	await shot("07b-yard")
	await walk(Vector2i(35,17))
	game._refresh_interaction()
	_check(game._interaction.get("kind")=="terminal", "The service screen by the beacon offers its physical connection")
	game.interact()
	var page := game.movement_lesson as WorkshopJobsJournal
	_check(page!=null and is_instance_valid(page.editor), "With no quest the screen opens a useful connected scratch page")
	if page!=null and is_instance_valid(page.editor):
		page.editor.text='def program(world):\n    for lamp in world.zone("rootward-square").lamps:\n        lamp.set_lit(True)\n    world.memory["square_only"] = 29\n'
		await page.preview()
		_check(game.session.has_preview() and not game.session.state.lamps["well-west"] and game.session.preview_state().lamps["well-west"], "Real WASI previews the square lights without committing")
		await shot("08-screen-preview")
		page.apply_routine()
		_check(game.session.state.lamps["well-west"] and game.session.state.memory.get("square_only")==29 and game.session.completed.is_empty(),"Apply changes this area without inventing a completed quest")
	game.close_notebook(true)
	game.save_now()
	await game._return_to_title()
	await game.continue_game("sparks-and-machines")
	game._pop_all_modals()
	_check(game.area.id=="haverlund-square" and game.session.state.memory.get("square_only")==29 and game.session.state.terminal_links.has("square-terminal"), "Continue keeps the square, its link, its program and its lights")
	_check(str(game.session.workshop_pages.get("scratch-rootward-square", "")).contains("square_only"), "The connected scratch page survives Continue independently of lesson drafts")
	_check(not game._modals.any(func(modal: Modal) -> bool: return modal is WorkshopScene), "The arrival stays read after Continue")
	await shot("09-square-saved")
	await walk(Vector2i(1,8))
	_check(game.session.request_step(Vector2i(-1,0)), "A normal step reaches the street's head without leaving the square")
	game.session.advance_walk(LabWorld.STEP_SECONDS)
	_check(game.session.request_step(Vector2i(-1,0)), "A real uphill departure starts the return")
	while game._flow_busy:await process_frame
	await settle()
	_check(game.area.id=="haverlund-lane" and game.session.player_cell()==Vector2i(12,24) and game.session.state.memory.get("lane_only")==17 and not game.session.state.memory.has("square_only"), "The return reaches the same gate and restores lane memory")
	SaveStore.delete("sparks-and-machines")
	game.queue_free()
	await process_frame
	await process_frame

func walk(target: Vector2i) -> void:
	var route: bool = game.session.walk_to(target)
	_check(route, "Walking route reaches " + str(target))
	if not route:return
	var steps: int = 0
	while (not game.session._route.is_empty() or game.session.is_walking()) and steps<600:
		game.session.advance_walk(LabWorld.STEP_SECONDS)
		steps+=1
		await process_frame
	_check(game.session.player_cell()==target, "The traveller completes the route to " + str(target))

## Lets a walk that carries on through a scene change finish.
func settle() -> void:
	var steps: int = 0
	while (not game.session._route.is_empty() or game.session.is_walking()) and steps < 60:
		game.session.advance_walk(LabWorld.STEP_SECONDS)
		steps += 1
		await process_frame

func shot(name: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	for n: int in range(6):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func _check(ok: bool, description: String) -> void:
	checks+=1
	if not ok:failures.append(description)
