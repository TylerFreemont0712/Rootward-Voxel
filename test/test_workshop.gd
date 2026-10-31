extends SceneTree
## A connected, saved second room; native art, stairs, inspections and real WASI.
var checks: int = 0
var failures: Array[String] = []
var game: Game
var output: String = ""

func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	go.call_deferred()

func go() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): output = args[0]
	_rules()
	_art()
	await _play()
	if failures.is_empty(): print("Downstairs workshop: %d checks passed." % checks)
	else:
		for failure: String in failures: printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)

func _rules() -> void:
	var source: Dictionary = AreaStore.read_source("workshop-floor")
	_check(source.ok, "The workshop area, quest and art references parse: " + str(source.get("errors", [])))
	if not source.ok: return
	var parsed: Dictionary = AreaDef.parse(source.document, source.assets, source.quests, AreaStore.ground_materials())
	_check(parsed.ok, "The workshop's collision and connection data validate: " + str(parsed.errors))
	if not parsed.ok: return
	var area: AreaDef = parsed.area
	var rules := LabWorld.new(area)
	var state: Dictionary = rules.initial_state()
	_check(area.width == 14 and area.height == 12 and area.interior.assets.size() == 29, "The workshop has its authored 14 by 12 layout, 28 furnishings and Tender")
	for target: Vector2i in [Vector2i(6,5),Vector2i(8,5),Vector2i(12,10),Vector2i(13,4),Vector2i(2,7),Vector2i(3,10),Vector2i(6,11)]:
		_check(not rules.find_path(state,target,area.spawn).is_empty(), "The stairs reach the workshop approach " + str(target))
	state.player = [6,9,0]
	_check(not rules.move(state,Vector2i.RIGHT).ok and rules.move(state,Vector2i(0,-1)).ok, "Stair traversal stays along the flight instead of falling through its railing")
	_check(not rules.is_walkable(state,Vector2i(5,4)) and rules.is_walkable(state,Vector2i(9,5)), "The assembly table blocks and the large rug stays walkable")
	state.player = [6,8,0]
	_check(RoomLinks.crossing(area,state,Vector2i(0,-1)).get("to") == "workshop-loft" and RoomLinks.crossing(area,state,Vector2i.RIGHT).is_empty(), "The head of the walkable flight crosses only deliberately up into the loft")
	state.player = [6,7,0]
	_check(not rules.move(state,Vector2i(0,1)).ok, "The high end of the stairs cannot be stepped onto from the floor beneath it")
	_check([Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7)].all(func(cell: Vector2i) -> bool: return rules.is_walkable(state,cell)) and not rules.is_walkable(state,Vector2i(5,8)) and not rules.is_walkable(state,Vector2i(7,8)), "There is headroom to walk under the high end, and the railings block where they come down low")
	state.player = [4,7,0]
	_check(rules.find_path(state,Vector2i(8,7)).size() == 4, "A straight walk passes beneath the stairs")
	state.player = [6,11,0]
	_check(rules.find_path(state,Vector2i(4,9)).size() <= 4 and rules.find_path(state,Vector2i(8,9)).size() <= 4, "Stepping off the foot of the stairs leads into the room on both sides")
	state.player = [6,10,0]
	_check(rules.move(state,Vector2i(0,1)).ok and area.interior.stair_flights[0].up == "S", "The flight climbs from its foot by the north wall toward the middle of the room")
	var loft: AreaDef = AreaStore.load_area("workshop-loft")
	_check(RoomLinks.find(loft,"downstairs").to == area.id and RoomLinks.find(area,"upstairs").to == loft.id, "The stair connection is reciprocal")
	var previous: float = -INF
	var smooth: bool = true
	for n: int in range(168):
		var height: float = WalkingSurface.height(area,Vector2(6,10.8-float(n)*.02),[])
		smooth = smooth and height >= previous - .0001 and (previous == -INF or height-previous < .07)
		previous = height
	_check(smooth and previous > 1.6, "Eight walkable treads raise the feet continuously from the floor to the flight's head")
	_check(WalkingSurface.height(area,Vector2(6,6.5),[]) < .2, "Beneath the high end the feet stay on the floor")
	var bad: Dictionary = source.document.duplicate(true)
	bad.interior.stair_flights[0].treads=[.4,.2]
	_check(not AreaDef.parse(bad,source.assets,source.quests).ok, "An inverted staircase is rejected by the area parser")
	bad=source.document.duplicate(true)
	bad.interior.links[0].to=area.id
	_check(not AreaDef.parse(bad,source.assets,source.quests).ok, "A self-connection is refused")
	var restored: Dictionary = RoomLinks.restore({"workshop-floor":{"area":"workshop-floor","state":{}},"../outside":{"area":"../outside","state":{}}},["workshop-loft","workshop-floor"])
	_check(restored.keys()==["workshop-floor"], "Saved journey rooms cannot select an unauthorised area")
	_check(RoomLinks.nearest(area,Vector2(12,10),"inspections").get("id")=="job-board", "The job-board inspection uses its authored approach")
	state.player=[13,4,0]
	_check(HouseInstances.crossing(area,rules,state,Vector2i.RIGHT,{}).get("kind")=="exit" and HouseInstances.crossing(area,rules,state,Vector2i(0,-1),{}).is_empty(), "The side shop doors use an east-facing approach")
	state.player=[1,8,0]
	state.memory={"kept_recipe":"loaf"}
	state.hotaru_greeted=true
	var migrated: Dictionary=rules.normalize_state(state)
	_check(migrated.player!=state.player and migrated.memory==state.memory and migrated.hotaru_greeted, "A remembered position now occupied by the trolley moves safely without losing progress")
	_check(RoomLinks.nearest(area,Vector2(3,10),"inspections").get("id")=="bread-cupboard", "The note's bread tin can be found and inspected beneath the clock")

func _art() -> void:
	var crock: Node3D=(load("res://assets/world/workshop-umbrella-stand/model.glb") as PackedScene).instantiate()
	root.add_child(crock)
	var bottom: float=_top_hit(crock,Vector3(.10,2,-.12))
	_check(bottom>.05 and bottom<.20, "A ray into the umbrella crock reaches its recessed bottom through the open rim")
	crock.free()
	for id: String in ["workshop-repair-bench","workshop-assembly-table","workshop-parts-crate"]:
		var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/"+id+"/manifest.json"))
		_check(not manifest.audit.material_records.has("workshop_linen"), "The unwanted white machine covering is removed: "+id)

func _top_hit(node: Node, origin: Vector3) -> float:
	var nearest: float=-INF
	if node is MeshInstance3D and node.mesh!=null and node.name!=&"IllustratedOutline":
		for surface: int in range(node.mesh.get_surface_count()):
			var arrays: Array=node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			for index: int in range(0,indices.size() if not indices.is_empty() else vertices.size(),3):
				var points: Array[Vector3]=[]
				for k: int in range(3):points.append(node.global_transform*vertices[indices[index+k] if not indices.is_empty() else index+k])
				var hit: Variant=Geometry3D.ray_intersects_triangle(origin,Vector3.DOWN,points[0],points[1],points[2])
				if hit!=null:nearest=maxf(nearest,(hit as Vector3).y)
	for child: Node in node.get_children():nearest=maxf(nearest,_top_hit(child,origin))
	return nearest

func _play() -> void:
	SaveStore.save_path="user://test_workshop_"+str(OS.get_process_id())+".json"
	SaveStore.profile_path="user://test_workshop_profile_"+str(OS.get_process_id())+".json"
	SaveStore.force_enabled=true
	for id: String in ["kindle-hollow","village-morning","sparks-and-machines"]:SaveStore.delete(id)
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game("kindle-hollow")
	game.save_now()
	var hollow: PackedByteArray=FileAccess.get_file_as_bytes(SaveStore.level_path("kindle-hollow"))
	await game.start_new_game("sparks-and-machines")
	game._pop_all_modals()
	game.close_notebook(true)
	game.session.state.memory={"loft_only":"kept"}
	game.session.state.player=[7,6,0]
	game.view.sync_player(game.session.state)
	_check(game.session.request_step(Vector2i(0,-1)), "Walking reaches the loft's lower tread")
	game.session.advance_walk(LabWorld.STEP_SECONDS)
	_check(game.view.player_node().position.y < -.3, "The upper room's descent still changes real sprite elevation")
	game.session.set_source('def program(world):\n    print("Hello, Mira!")\n')
	await game.session.run_preview()
	_check(game.session.has_preview(), "A real preview exists before the floor change")
	game.session.request_step(Vector2i(0,-1))
	while game._flow_busy: await process_frame
	_check(game.area.id=="workshop-floor" and not game.session.has_preview(), "Crossing descends into the new room and discards the old proposal")
	if game.area.id!="workshop-floor":
		game.queue_free()
		await process_frame
		return
	_check(game.view.stage is WorkshopFloorStage and not game.view.companion_present(), "A sleeping Hotaru stays upstairs until she has heard the greeting")
	_check(game.session.player_cell()==Vector2i(6,8) and game.view.player_node().position.y > 1.4, "The player arrives partway down the stairs, mid-room, ready to descend")
	await shot("01-upper-landing")
	for n: int in range(3):
		_check(game.session.request_step(Vector2i(0,1)), "A real step descends the workshop staircase")
		game.session.advance_walk(LabWorld.STEP_SECONDS)
	_check(game.session.player_cell()==Vector2i(6,11) and game.view.player_node().position.y < .2, "The actual sprite reaches the floor at the foot of the stairs by the north wall")
	# The flight climbs toward the camera, so each tread hides the near part of the one below; aim at what shows.
	for n: int in range(8):
		var point := Vector3(6,.2*(n+1),-(10.2-(n+.2)*.35))
		var picked: Variant=game.view.pick_point(game.view.camera.unproject_position(point))
		_check(picked is Vector2 and (picked as Vector2).distance_to(Vector2(point.x,-point.z)) < .02, "Clicking the workshop's tread selects its elevated surface")
	game.session.set_source('def program(world):\n    world.memory["floor_only"] = "kept"\n    print("Hello, Hotaru!")\n')
	await game.session.run_preview()
	_check(game.session.has_preview() and game.session.apply_preview(), "The downstairs printer runs and commits real WASI Python")
	_check(game.session.state.memory.get("floor_only")=="kept" and not game.session.state.memory.has("loft_only"), "Program memory belongs to the current floor")
	_check((game.view.stage as WorkshopFloorStage).awake and game.view.companion_present(), "An awake Hotaru joins the lodger at the assembly bench")
	await create_timer(5.1).timeout
	_check(game.hud._objective_title.text=="The waiting ticket", "After greeting the pinned hint points to the workshop's next job")
	game.session.state.player=[8,5,0]
	game.view.sync_player(game.session.state)
	await shot("02-workshop")
	var bench := game.view.find_child("repair-bench",true,false) as Node3D
	var assembly := game.view.find_child("assembly",true,false) as Node3D
	_check(bench.scale.is_equal_approx(Vector3.ONE*.85) and assembly.scale.is_equal_approx(Vector3.ONE*.85), "The downstairs worktops are reduced by fifteen percent")
	_check(game.view.player_node().scale.is_equal_approx(Vector3.ONE), "The traveller retains the approved loft scale")
	game.session.state.player=[3,10,0]
	game.view.sync_player(game.session.state)
	await shot("06-bread-cupboard")
	game._refresh_interaction()
	_check(game._interaction.get("id")=="bread-cupboard", "The food cupboard offers its own contextual interaction")
	game.interact()
	_check(game._modals.is_empty() and game.workshop_speech._inspection.get("id")=="bread-cupboard", "The bread tin uses an object bubble without a modal")
	await shot("07-bread-note")
	game._pop_all_modals()
	game.session.state.player=[12,10,0]
	game.view.sync_player(game.session.state)
	game._refresh_interaction()
	_check(game._interaction.get("kind")=="inspection" and game._interaction.get("id")=="job-board", "F offers the nearby job board")
	game.interact()
	_check(game._modals.is_empty() and game.workshop_speech._inspection.get("id")=="job-board", "The unrecruited ticket uses an object bubble")
	await shot("03-job-board")
	game._pop_all_modals()
	game.session.state.player=[13,4,0]
	game.view.sync_player(game.session.state)
	for frame: int in range(3): await process_frame
	_check((game.view.stage as WorkshopFloorStage)._door_faded, "The foreground doors turn translucent near the player instead of hiding the sprite")
	for n: int in range(40):
		game._stairs_said=-10.0
		game._on_doorway_requested("")
	var copies: int=0
	for child: Node in game.hud._toast_box.get_children():
		if child.get_meta("feedback_text", "")==game._story.street_doors:copies+=1
	_check(copies==1 and game.area.id=="workshop-floor", "Forty closed-street-door requests keep one message and the current room")
	await shot("05-street-door-cutaway")
	game.save_now()
	var saved: Dictionary=SaveStore.read("sparks-and-machines")
	_check(saved.area=="workshop-loft" and saved.journey_rooms.active=="workshop-floor", "The journey keeps its canonical save while recording the active lower floor")
	await game._return_to_title()
	await game.continue_game("sparks-and-machines")
	_check(game.area.id=="workshop-floor" and game.session.state.memory.get("floor_only")=="kept" and game.session.state.hotaru_greeted, "Continue restores the lower room, local memory and shared greeting")
	_check(game.session.source.contains('world.memory["floor_only"]'), "The Python page persists between floors and Continue")
	game.session.state.player=[6,5,0]
	game.view.sync_player(game.session.state)
	_check(game.session.walk_to_link("upstairs") and game.session._route_link=="upstairs" and not game.session._route.is_empty() and game.session._route.has(Vector2i(6,11)), "Click/F travel plans the real staircase route, round to its foot")
	game.session._cancel_route()
	game.session.state.player=[6,11,0]
	game.view.sync_player(game.session.state)
	for n: int in range(3):
		_check(game.session.request_step(Vector2i(0,-1)), "A real step climbs the workshop staircase")
		game.session.advance_walk(LabWorld.STEP_SECONDS)
	_check(game.view.player_node().position.y>1.4, "Ascent restores the flight head's elevation")
	await shot("04-stair-ascent")
	game.session.request_step(Vector2i(0,-1))
	while game._flow_busy:await process_frame
	_check(game.area.id=="workshop-loft" and game.session.player_cell()==Vector2i(7,5), "The return arrives on the matching loft stair tread, mid-loft")
	_check(game.session.state.memory.get("loft_only")=="kept" and not game.session.state.memory.has("floor_only") and game.session.state.hotaru_greeted, "The loft retains its own memory and receives shared voice progress")
	_check(FileAccess.get_file_as_bytes(SaveStore.level_path("kindle-hollow"))==hollow, "The second room does not alter another journey's save")
	for id: String in ["kindle-hollow","village-morning","sparks-and-machines"]:SaveStore.delete(id)
	game.queue_free()
	await process_frame
	await process_frame

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)

func shot(name: String) -> void:
	if output=="" or DisplayServer.get_name()=="headless":return
	for frame: int in range(25):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
