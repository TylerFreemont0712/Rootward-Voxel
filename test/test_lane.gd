extends SceneTree
## Spindle Lane, outside Nell's workshop: the journey's first outdoor scene. Its document, Blender set and painted
## distance, the street doors in both directions, saving there, and the small motions of the street. The workshop,
## Nell's house and Bram's cottage stand in a row on its west side; the tram runs to the end of the halt.
var checks: int = 0
var failures: Array[String] = []
var game: Game
var output: String = ""
const WorldAssets := preload("res://art/world_assets.gd")
const PROPS: Array[String] = ["haverlund-lane-set", "lane-workshop", "lane-nell-house", "lane-cottage", "lane-lamp", "lane-post-box", "lane-notice-board", "lane-bench", "lane-telescope", "lane-tree", "lane-cypress", "lane-bicycle", "lane-crates", "lane-planter", "lane-handcart", "lane-laundry", "lane-pump", "lane-shed", "lane-tram-shelter", "lane-tram"]


func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	go.call_deferred()


func go() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): output = args[0]
	_rules()
	_refusals()
	_art()
	await _play()
	if failures.is_empty(): print("Spindle Lane: %d checks passed." % checks)
	else:
		for failure: String in failures: printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)


func _rules() -> void:
	var source: Dictionary = AreaStore.read_source("haverlund-lane")
	_check(source.ok, "The lane document and its art references parse: " + str(source.get("errors", [])))
	if not source.ok: return
	var parsed: Dictionary = AreaDef.parse(source.document, source.assets, source.quests, AreaStore.ground_materials())
	_check(parsed.ok, "The lane's collision, links and outdoor data validate: " + str(parsed.get("errors", [])))
	if not parsed.ok: return
	var area: AreaDef = parsed.area
	var rules := LabWorld.new(area)
	var state: Dictionary = rules.initial_state()
	_check(area.width == 24 and area.height == 28 and area.interior.style == "workshop-lane" and area.interior.shell == "haverlund-lane-set", "The lane is a 24 by 28 outdoor scene drawn from its own Blender set")
	_check(area.voice_lesson and not area.movement_lesson and area.quests.is_empty(), "The lane shares the journey's notebook and has no job of its own yet")
	var spec: Dictionary = LevelStore.entry("sparks-and-machines")
	_check((spec.room_areas as Array) == ["workshop-loft", "workshop-floor", "haverlund-lane", "haverlund-square"], "The journey opens the lane third and the square fourth, after the two floors")
	var start := Vector2i(10, 12)
	_check(rules.is_walkable(state, start) and area.spawn == start, "The traveller arrives on the step outside the green doors")
	var targets: Array = [Vector2i(14, 26), Vector2i(12, 26), Vector2i(19, 25), Vector2i(21, 26), Vector2i(17, 6), Vector2i(16, 10), Vector2i(22, 12), Vector2i(1, 5), Vector2i(8, 7),
		Vector2i(13, 4), Vector2i(1, 2), Vector2i(23, 2), Vector2i(19, 2), Vector2i(7, 4), Vector2i(10, 25), Vector2i(10, 19), Vector2i(9, 21), Vector2i(22, 20), Vector2i(17, 26)]
	for item: Dictionary in area.interior.inspections:
		targets.append(Vector2i(int(item.at[0]), int(item.at[1])))
	for target: Vector2i in targets:
		_check(rules.is_walkable(state, target) and not rules.find_path(state, target, start).is_empty(), "The lane reaches " + str(target) + " from the doors")
	for zone: Dictionary in area.zones:
		var rect: Rect2i = zone.rect
		var reached: bool = false
		for x: int in range(rect.position.x, rect.end.x):
			for y: int in range(rect.position.y, rect.end.y):
				if not reached and rules.is_walkable(state, Vector2i(x, y)) and not rules.find_path(state, Vector2i(x, y), start).is_empty(): reached = true
		_check(reached, "Someone can walk into the zone " + str(zone.id))
	for blocked: Vector2i in [Vector2i(5, 0), Vector2i(12, 1), Vector2i(3, 12), Vector2i(9, 14), Vector2i(2, 20), Vector2i(2, 23), Vector2i(7, 25), Vector2i(0, 15), Vector2i(12, 27), Vector2i(23, 10), Vector2i(19, 14), Vector2i(19, 4)]:
		_check(not rules.is_walkable(state, blocked), "Solid ground stays solid at " + str(blocked))
	_check(area.ground_level(Vector2(5, 3)) == 0.0 and area.ground_level(Vector2(5, 8)) == 1.0, "The halt is a level below the lane")
	state.player = [13, 5, 0]
	_check(not rules.move(state, Vector2i.LEFT).ok and rules.move(state, Vector2i(0, 1)).ok and rules.move(state, Vector2i(0, -1)).ok, "The halt steps are climbed along their line, never stepped off sideways")
	var previous: float = -INF
	var smooth: bool = true
	for n: int in range(101):
		var height: float = WalkingSurface.height(area, Vector2(13, 4.0 + n * .02), [])
		smooth = smooth and height >= previous - .0001 and (previous == -INF or height - previous < .08)
		previous = height
	_check(smooth and previous > 1.0, "The feet rise smoothly from the platform to the lane")
	var floor_area: AreaDef = AreaStore.load_area("workshop-floor")
	_check(RoomLinks.find(area, "workshop-door").to == "workshop-floor" and RoomLinks.find(floor_area, "street").to == area.id, "The street doors connect both ways")
	var floor_rules := LabWorld.new(floor_area)
	_check(floor_rules.is_walkable(floor_rules.initial_state(), Vector2i(12, 4)), "Coming back in lands on the workshop floor inside the doors")
	# The town steps are a way down along their whole width: either stair cell crosses, each arriving on its own side of
	# the square's street, and the apprentice walks on through the change.
	var steps: Dictionary = RoomLinks.find(area, "town-steps")
	_check(RoomLinks.cells(steps) == [Vector2i(12, 26), Vector2i(13, 26)] and RoomLinks.arrival(steps, Vector2i(12, 26)) != RoomLinks.arrival(steps, Vector2i(13, 26))
		and bool(steps.get("walk_through", false)) and int(steps.get("enter", 0)) == 2, "Both stair cells lead down, each to its own side of the street")
	var edge: Dictionary = rules.initial_state()
	edge.player = [13, 26, 0]
	_check(RoomLinks.crossing(area, edge, AreaDef.STEPS[steps.direction]).get("id", "") == "town-steps" and RoomLinks.crossing(area, edge, Vector2i.LEFT).is_empty(), "A step down from the second stair cell crosses too, a step sideways does not")
	for bad: Dictionary in [{"cells": [[12, 26], [40, 26]]}, {"cells": [[12, 26], [13, 26]], "arrivals": [[1, 7]]}, {"enter": 9}, {"doors": 4}]:
		var links: Array = (area.interior.links as Array).duplicate(true)
		var link: Dictionary = links[1].duplicate(true)
		link.merge(bad, true)
		links[1] = link
		var lane_source: Dictionary = AreaStore.read_source("haverlund-lane")
		lane_source.document.interior.links = links
		_check(not AreaDef.parse(lane_source.document, lane_source.assets, lane_source.quests, AreaStore.ground_materials()).ok, "A malformed wide link is refused: " + str(bad))
	var inside: Dictionary = floor_rules.initial_state()
	inside.player = [13, 4, 0]
	_check(RoomLinks.crossing(floor_area, inside, Vector2i.RIGHT).get("to") == "haverlund-lane", "Stepping through the open doors goes out to the lane")
	_check(not floor_area.interior.inspections.any(func(item: Dictionary) -> bool: return item.id == "shop-doors"), "The doors no longer say they are latched")
	# The gate lamp answers to code only from beside it, with the slate in hand.
	var lamp: Dictionary = area.lamp("gate-lamp")
	state = rules.initial_state()
	state.zones_seen = ["spindle-lane"]
	state.items = ["field-tablet"]
	_check(not FieldAccess.lamp_in_reach(area, state, lamp), "From the doors the gate lamp is out of reach")
	state.player = [14, 26, 0]
	_check(FieldAccess.lamp_in_reach(area, state, lamp), "Beside the gate with the slate, its lamp answers")
	state.items = []
	_check(not FieldAccess.lamp_in_reach(area, state, lamp), "Without the slate the lamp does not answer even from beside it")
	_check(FieldAccess.lamp_reason(area, lamp).contains("gate lamp"), "The notebook names where to stand for it")
	var hollow: AreaDef = AreaStore.load_area("kindle-hollow")
	var valley: Dictionary = LabWorld.new(hollow).initial_state()
	_check(FieldAccess.lamp_in_reach(hollow, valley, hollow.lamps[0]), "Kindle Hollow's lamps keep their older reach")


func _refusals() -> void:
	var source: Dictionary = AreaStore.read_source("haverlund-lane")
	if not source.ok: return
	var cases: Dictionary = {
		"a haze that is not a colour": func(doc: Dictionary) -> void: doc.interior.outdoor.haze = "sky",
		"a sun with two angles": func(doc: Dictionary) -> void: doc.interior.outdoor.sun.rotation = [1, 2],
		"a backdrop outside the assets": func(doc: Dictionary) -> void: doc.interior.outdoor.backdrop = "res://../secret.png",
		"a tram that is not placed": func(doc: Dictionary) -> void: doc.interior.life.tram.asset = "omnibus",
		"cloth that is not placed": func(doc: Dictionary) -> void: doc.interior.life.sway = ["flag"],
		"a tram with no wait between trips": func(doc: Dictionary) -> void: doc.interior.life.tram.period = 5,
		"a tram whose trip outlasts its period": func(doc: Dictionary) -> void: doc.interior.life.tram.travel = 40,
		"twenty gulls": func(doc: Dictionary) -> void: doc.interior.life.gulls.count = 20,
	}
	for name: String in cases:
		var bad: Dictionary = source.document.duplicate(true)
		(cases[name] as Callable).call(bad)
		_check(not AreaDef.parse(bad, source.assets, source.quests).ok, "The parser refuses " + name)
	var plain: Dictionary = source.document.duplicate(true)
	plain.interior.erase("outdoor")
	plain.interior.erase("life")
	_check(not AreaDef.parse(plain, source.assets, source.quests).ok, "Passenger service cannot silently lose its tram")
	plain.villagers = (plain.villagers as Array).filter(func(person: Dictionary) -> bool: return not person.has("arrival"))
	_check(AreaDef.parse(plain, source.assets, source.quests).ok, "Outdoor light and street life are optional when no passengers depend on the tram")


func _art() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/world-catalog.json"))
	for id: String in PROPS:
		var entry: Dictionary = catalog.assets.get(id, {})
		_check(entry.get("authority") == "blender" and FileAccess.file_exists("res://" + str(entry.get("runtime", ""))) and FileAccess.file_exists("res://" + str(entry.get("source", ""))), "The lane's %s is an adopted, exported Blender model" % id)
	var lamp: Node3D = WorldAssets.instantiate("lane-lamp")
	_check(lamp != null and MechanismBuilder._find_glass(lamp) != null, "The street lamp keeps a separate lamp_glass the game can light")
	if lamp != null: lamp.free()
	var line: Node3D = WorldAssets.instantiate("lane-laundry")
	_check(line != null and line.find_children("cloth*", "Node3D", true, false).size() == 5, "Each of the five cloths on the line is its own node")
	if line != null: line.free()
	# Glass is set into real openings in the house walls and carries its own picture, so it never flickers against
	# the plaster and the illustrated edges leave it clear.
	for id: String in ["lane-workshop", "lane-nell-house", "lane-cottage"]:
		var house: Node3D = WorldAssets.instantiate(id)
		var panes: Array = []
		if house != null:
			for mesh: Node in house.find_children("*", "MeshInstance3D", true, false):
				var material := (mesh as MeshInstance3D).get_active_material(0) as StandardMaterial3D
				if material != null and material.resource_name.contains("window_") and material.albedo_texture != null:
					IllustratedEdges.apply(mesh as MeshInstance3D)
					panes.append(mesh)
			_check(not panes.is_empty() and panes.all(func(mesh: Node) -> bool: return not mesh.has_node("IllustratedOutline")), id + " has painted glass with no outline over it")
			house.free()
	var set: Node3D = WorldAssets.instantiate("haverlund-lane-set")
	var grass: bool = false
	if set != null:
		for mesh: Node in set.find_children("*", "MeshInstance3D", true, false):
			var material := (mesh as MeshInstance3D).get_active_material(0) as StandardMaterial3D
			grass = grass or (material != null and material.albedo_texture != null and material.albedo_texture.resource_path.contains("grass-lush"))
		set.free()
	_check(grass, "The green is the project's lush grass, not a flat colour")
	var painting := load("res://assets/world/backdrops/haverlund-harbour.png") as Texture2D
	_check(painting != null and painting.get_width() >= 1536 and painting.get_height() >= 864, "The painted harbour backdrop is a runtime picture")


func _play() -> void:
	SaveStore.save_path = "user://test_lane_" + str(OS.get_process_id()) + ".json"
	SaveStore.profile_path = "user://test_lane_profile_" + str(OS.get_process_id()) + ".json"
	SaveStore.force_enabled = true
	for id: String in ["kindle-hollow", "village-morning", "sparks-and-machines"]: SaveStore.delete(id)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game("sparks-and-machines")
	game._pop_all_modals()
	game.close_notebook(true)
	# A traveller who has woken Hotaru and carries the slate, as after the loft's first scene.
	game.session.state.hotaru_greeted = true
	game.session.state.spoken = "Hello, Hotaru!"
	game.session.completed.append("say-hello")
	game.session.state.items = ["field-tablet"]
	game._dialogue_read["loft-waking"] = ["introduced"]
	game._dialogue_read["workshop-scenes"] = ["waiting-ticket", "tablet-taken", "workshop-arrival"]
	game.session.state.player = [7, 5, 0]
	game.view.sync_player(game.session.state)
	_check(await game.travel_room_link("downstairs") and game.area.id == "workshop-floor", "The stairs still lead down to the workshop")
	var inside_doors: Node3D = game.view.link_doors("shop-doors")
	_check(inside_doors != null and inside_doors.find_child("doorway_beyond", true, false) == null, "The workshop's street doors open on nothing hung beyond them, not on a picture")
	game._pop_all_modals()
	game.session.state.player = [13, 4, 0]
	game.view.sync_player(game.session.state)
	game.session.state.memory = {"floor_only": "kept"}
	_check(game.session.request_step(Vector2i.RIGHT), "A step through the open street doors starts")
	while game._flow_busy: await process_frame
	await process_frame
	await _settle()
	_check(game.area.id == "haverlund-lane" and game.session.player_cell() == Vector2i(11, 12), "The step carries on through the doors and a pace out onto the lane")
	if game.area.id != "haverlund-lane":
		game.queue_free()
		await process_frame
		return
	_check(not game.session.state.memory.has("floor_only") and PlayerItems.has(game.session.state, "field-tablet") and game.session.state.hotaru_greeted, "The lane keeps its own program memory but shares the slate and the greeting")
	_check(not game._veil.covering() and not game._flow_busy, "The clockwork veil has opened and given the lane back once the apprentice is through")
	var dark_quad := (game.view.link_doors("workshop-front").find_child("doorway_beyond", true, false)) as MeshInstance3D
	var dark_paint := dark_quad.get_active_material(0) as StandardMaterial3D if dark_quad != null else null
	_check(dark_paint != null and dark_paint.albedo_texture == null and dark_paint.albedo_color.get_luminance() < 0.05, "The inside of the lane's workshop doors is flat black")
	_check(is_equal_approx(game.view.zoom(), 16.0), "The lane uses its own wider view")
	_check(game.view.stage is WorkshopLaneStage and game.view.companion_present(), "An awake Hotaru waits by the shop door")
	var backdrop := game.view.camera.get_node_or_null("PaintedDistance") as OutdoorBackdrop
	_check(backdrop != null and backdrop.material_override is ShaderMaterial, "The painted harbour hangs behind the lane")
	_check(game.view._environment.background_color.is_equal_approx(Color("c4d6da")) and is_equal_approx(game.view._sun.light_energy, .88), "The lane has its own daylight and sea haze")
	var stage := game.view.stage as WorkshopLaneStage
	_check(stage.find_children("ChimneySmoke*", "CPUParticles3D", true, false).size() == 3, "The workshop's, Nell's and Bram's chimneys smoke")
	_check(game.view.building_node("nell-house") != null and game.view.building_node("workshop-front") != null and game.view.building_node("bram-cottage") != null, "Nell's house stands between her workshop and Bram's cottage")
	_check(stage._cloths.size() == 5 and stage._gulls.size() == 3, "The washing sways and three gulls wheel over the harbour")
	var tram := game.view.building_node("hill-tram")
	var shelter := game.view.building_node("tram-shelter")
	stage._place_tram(1.0 - 14.0)
	var arriving: float = tram.position.x
	stage._place_tram(20.0 - 14.0)
	_check(arriving < tram.position.x and is_equal_approx(tram.position.x, 19.45) and tram.visible, "The tram comes up out of the cutting and waits at the halt")
	_check(absf(tram.position.x - shelter.position.x) < 1.0 and tram.position.x + 3.4 < float(game.area.width) - .5, "It stops along the shelter, short of the buffer at the end of the line")
	stage._place_tram(60.0 - 14.0)
	_check(not tram.visible, "Between trips the tram is down the hill, out of sight")
	game._refresh_interaction()
	var scene := game._modals[-1] as WorkshopScene if not game._modals.is_empty() else null
	_check(scene != null and scene.pages.size() == 4, "The first time out, Hotaru has something to say about the street")
	if scene != null:
		_check(scene._speaker.text == "Spindle Lane" and scene._finish_label == "Back to the lane", "The lane's scene is narrated as the lane and ends back on it")
		await shot("01b-arrival-scene")
		for step: int in range(12):
			if not is_instance_valid(scene) or not scene.is_inside_tree(): break
			scene._clock = 1000
			scene._text.visible_characters = -1
			if not scene._replying and not (scene._page.get("choices", []) as Array).is_empty():
				scene._choose(scene._page.choices[2])
			else:
				scene.advance()
			await process_frame
	_check(game._modals.is_empty() and (game._dialogue_read.get("workshop-scenes", []) as Array).has("lane-arrival"), "The scene is read once and remembered")
	game._refresh_interaction()
	_check(game._modals.is_empty(), "It does not play again on the next look round")
	_check(game._interaction.get("kind") == "room-link" and game._interaction.get("id") == "workshop-door", "F at the doors offers to go back in")
	game.session.state.player = [11, 11, 0]
	game.view.sync_player(game.session.state)
	game._refresh_interaction()
	_check(game._interaction.get("kind") == "talk" and game._interaction.get("id") == "hotaru", "Beside her by the door, F talks to Hotaru")
	game.interact()
	var remarks: Array = game._story.banter["haverlund-lane"]
	_check(remarks.has(stage.speech_text), "Outside she talks about the street: " + stage.speech_text)
	await shot("01c-hotaru-remark", 40)
	stage.clear_speech()
	game.session.state.player = [10, 12, 0]
	game.view.sync_player(game.session.state)
	var place: String = (game.hud as PaperHud)._location.text
	_check(place.begins_with("Haverlund"), "The location plate names the town: " + place)
	(game.hud as PaperHud)._refresh()
	_check((game.hud as PaperHud).ticket.title.text == "Out on the lane", "The pinned note is the lane's own, not a pointer downstairs")
	await shot("01-arrival")
	game.session.state.player = [14, 26, 0]
	game.view.sync_player(game.session.state)
	game._refresh_interaction()
	_check(game._interaction.get("kind") == "device" and game._interaction.get("id") == "gate-lamp", "Beside the gate, F opens the gate lamp's code")
	game.interact()
	_check(game.workshop_speech._inspection.get("id") == "gate-lamp" and not game.notebook_open, "With no ticket for it yet, the lamp only says nothing has been asked of it")
	game._pop_all_modals()
	var lantern: Node3D = game.view._lamps.get("gate-lamp")
	_check(lantern != null and lantern.has_meta("glass"), "The gate lamp is bound to the lantern on its pedestal")
	if lantern != null and lantern.has_meta("glass"):
		var lit: Dictionary = game.session.state.duplicate(true)
		lit.lamps["gate-lamp"] = true
		game.view.apply_state(lit)
		_check((lantern.get_meta("glass") as MeshInstance3D).material_override == lantern.get_meta("lit") and (lantern.get_node("FixtureLight") as Light3D).visible, "Lit, its glass glows and throws light")
		game.view.apply_state(game.session.state)
	await shot("02-gate")
	for id: String in ["lane-notices", "grey-cat", "town-gate", "tram-halt", "nell-door", "street-sign", "shop-window"]:
		var item: Dictionary = {}
		for candidate: Dictionary in game.area.interior.inspections:
			if candidate.id == id: item = candidate
		game.session.state.player = [int(item.at[0]), int(item.at[1]), 0]
		game.view.sync_player(game.session.state)
		game._refresh_interaction()
		_check(game._interaction.get("kind") == "inspection" and game._interaction.get("id") == id, "F reads " + id + " from where it is authored")
	for spec: Array in [["04-houses", Vector2i(11, 19)], ["05-cutting", Vector2i(4, 3)]]:
		game.session.state.player = [spec[1].x, spec[1].y, 0]
		game.view.sync_player(game.session.state)
		stage._place_tram(20.0 - 14.0)
		await shot(spec[0])
	game.session.state.player = [13, 6, 0]
	game.view.sync_player(game.session.state)
	for direction: Vector2i in [Vector2i(0, -1), Vector2i(0, -1)]:
		_check(game.session.request_step(direction), "A real step goes down the halt steps")
		game.session.advance_walk(LabWorld.STEP_SECONDS)
	_check(game.session.player_cell() == Vector2i(13, 4) and game.view.player_node().position.y < .3 and (game.session.state.zones_seen as Array).has("tram-halt"), "The traveller reaches the platform and finds the tram halt")
	stage._place_tram(20.0 - 14.0)
	await shot("03-halt")
	game.save_now()
	var saved: Dictionary = SaveStore.read("sparks-and-machines")
	_check(saved.area == "workshop-loft" and saved.journey_rooms.active == "haverlund-lane", "The journey's save records the lane as where the traveller is")
	await game._return_to_title()
	await game.continue_game("sparks-and-machines")
	_check(game.area.id == "haverlund-lane" and game.session.player_cell() == Vector2i(13, 4) and PlayerItems.has(game.session.state, "field-tablet"), "Continue puts the traveller back on the lane, slate in hand")
	var painted: Array = game.view.camera.get_children().filter(func(node: Node) -> bool: return node is OutdoorBackdrop)
	_check(painted.size() == 1 and painted[0].name == &"PaintedDistance", "Setting the lane up again leaves exactly one painted distance")
	game.session.state.player = [10, 12, 0]
	game.view.sync_player(game.session.state)
	_check(game.session.request_step(Vector2i.LEFT), "A step back through the doors starts")
	while game._flow_busy: await process_frame
	await _settle()
	_check(game.area.id == "workshop-floor" and game.session.player_cell() == Vector2i(11, 4) and game.session.state.memory.get("floor_only") == "kept", "Going in lands inside the doors with the workshop's own memory")
	_check(game.view.camera.get_node_or_null("PaintedDistance") == null and game.view._outdoor.is_empty(), "Indoors there is no painted distance or daylight left behind")
	game.queue_free()
	await process_frame


## Lets a walk that carries on through a scene change finish.
func _settle() -> void:
	var steps: int = 0
	while (not game.session._route.is_empty() or game.session.is_walking()) and steps < 60:
		game.session.advance_walk(LabWorld.STEP_SECONDS)
		steps += 1
		await process_frame


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)


func shot(name: String, frames: int = 30) -> void:
	if output == "" or DisplayServer.get_name() == "headless": return
	for frame: int in range(frames): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))
