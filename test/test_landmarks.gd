extends SceneTree
## Village reachability, root collision, adopted art and independent civic-room travel.
var checks: int=0
var failures: Array[String]=[]
var game: Game
var output: String=""

func _initialize() -> void:_run.call_deferred()

func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():output=args[0]
	var area: AreaDef=AreaStore.load_area("village-morning")
	_check(area!=null,"The expanded village validates")
	if area==null:quit(1);return
	var rules:=LabWorld.new(area)
	var state: Dictionary=rules.initial_state()
	var catalog: Dictionary=AreaStore.read_interiors()
	_check(area.width==64 and area.height==72 and area.buildings.size()==3,"The retained home and new hall inhabit the expanded village")
	_check(area.villagers.is_empty() and area.quests.is_empty(),"This slice adds places without new residents or tutorial requirements")
	for house: Dictionary in area.buildings:
		var door: Vector2i=HouseInstances.door(area,house.id)
		_check(rules.is_walkable(state,door) and not rules.find_path(state,door).is_empty(),"A safe path reaches "+house.id)
		_check(not rules.is_walkable(state,Vector2i(house.at)),"The walls remain solid: "+house.id)
		state.player=[door.x,door.y,0]
		var inward: Vector2i=-HouseInstances.OUTWARD[house.facing]
		_check(HouseInstances.crossing(area,rules,state,inward,catalog).get("house")==house.id,"An inward frame attempt enters the correct room: "+house.id)
		state.player=[door.x-inward.x,door.y-inward.y,0]
		_check(HouseInstances.crossing(area,rules,state,inward,catalog).is_empty(),"The approach never activates a tile early: "+house.id)
	state=rules.initial_state()
	for point: Vector2i in [Vector2i(32,22),Vector2i(19,36),Vector2i(45,36),Vector2i(32,50),Vector2i(32,55)]:
		_check(not rules.find_path(state,point).is_empty(),"All sides of the square and hall forecourt are reachable: "+str(point))
	for point: Vector2i in [Vector2i(32,36),Vector2i(38,36),Vector2i(32,42),Vector2i(26,36),Vector2i(32,30),Vector2i(32,44),Vector2i(40,36)]:
		_check(not rules.is_walkable(state,point) and rules.find_path(state,point).is_empty(),"Root and trunk occupancy blocks walking/routing: "+str(point))
	for lamp: Dictionary in area.lamps:
		var reachable: bool=false
		for delta: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			reachable=reachable or not rules.find_path(state,lamp.cell+delta).is_empty()
		_check(reachable,"Square furnishings leave a reachable lamp approach: "+lamp.id)
	# Old lane saves keep the same addressed home, player position, code memory and controls.
	state.player=[7,10,0];state.memory={"keep":"my village"};state.controls={"W":"north"}
	var restored: Dictionary=rules.normalize_state(state)
	_check(restored.player==state.player and restored.memory==state.memory and restored.controls==state.controls,"Expanding the authored map preserves an existing home-lane save")
	var room: AreaDef=AreaStore.load_area("morning-town-hall-room")
	var room_rules:=LabWorld.new(room)
	var room_state: Dictionary=room_rules.initial_state()
	_check(not room_rules.find_path(room_state,Vector2i(8,1)).is_empty() and not room_rules.find_path(room_state,Vector2i(8,8)).is_empty(),"The council room has an open entrance and central aisle")
	for prop: Dictionary in room.props:
		var reachable: bool=false
		for offset: Vector2i in [Vector2i.LEFT*2,Vector2i.RIGHT*2,Vector2i.UP*2,Vector2i.DOWN*2]:
			var cell:=Vector2i(roundi(prop.at.x),roundi(prop.at.y))+offset
			reachable=reachable or cell==room.spawn or not room_rules.find_path(room_state,cell).is_empty()
		_check(reachable,"A visitor can approach "+prop.id)
	await _travel()
	if failures.is_empty():print("Village landmarks and council room: %d checks passed." % checks)
	else:
		for failure: String in failures:printerr("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)

func _travel() -> void:
	SaveStore.save_path="user://test_landmarks_"+str(OS.get_process_id())+".json"
	SaveStore.profile_path="user://test_landmarks_profile_"+str(OS.get_process_id())+".json"
	SaveStore.force_enabled=true
	SaveStore.delete("village-morning")
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game("village-morning")
	if not game._modals.is_empty():game._modals[-1].close()
	game.session.set_physics_process(false)
	game.session.state.controls={"W":"north","A":"west","S":"south","D":"east"}
	game.session.state.movement_used=["north","west","south","east"]
	game.session.state.hotaru_greeted=true
	game.session.state.memory={"room":"bedroom"}
	await _shot("bedroom")
	game.session.state.player=[6,1,0];game.view.sync_player(game.session.state)
	await game.leave_house()
	game.session.set_physics_process(false)
	_check(game.area.id=="village-morning" and game.session.player_cell()==Vector2i(7,10),"The old home still exits to the safe original landing")
	game.session.state.memory={"outside":"village"}
	var tree: Node3D=game.view._asset_tree_nodes["32,36"] if game.view._asset_tree_nodes.has("32,36") else null
	if tree==null:
		for node: Node3D in game.view._asset_tree_nodes.values():
			if node.find_child("RootwardPresence",true,false)!=null:tree=node;break
	_check(tree!=null,"The new tree loads its adopted Blender model")
	if tree!=null:
		var presence:=tree.find_child("RootwardPresence",true,false) as RootwardPresence
		_check(presence!=null and presence._wisps.size()==84 and tree.find_children("RootwardLight_*","Node3D",true,false).size()==30 and presence._lanterns.instance_count>0 and presence._lanterns.instance_count<30,"The complete source keeps its lantern anchors; cutaway lights only illuminate visible lanterns")
		var hidden_crown: int=0
		var crown_parts: int=0
		var visible_roots: int=0
		for mesh: MeshInstance3D in tree.find_children("*","MeshInstance3D",true,false):
			var role: String=str((mesh.get_meta("extras",{}) as Dictionary).get("part",""))
			if role in ["Crown","Boughs"]:
				crown_parts+=1
				hidden_crown+=1 if not mesh.is_visible_in_tree() else 0
			if role=="Buttress roots" and mesh.is_visible_in_tree():visible_roots+=1
		_check(crown_parts>=8 and hidden_crown==crown_parts and visible_roots>=3,"The playable tree retains its roots while the authored crown and boughs cannot cover the town or cast canopy shadows")
		var before: Transform3D=presence._motes.get_instance_transform(0)
		var elapsed: float=presence._time
		var before_state: Dictionary=game.session.state.duplicate(true)
		presence._process(.5)
		_check(presence._time>elapsed and game.session.state==before_state,"Cosmetic animation advances without changing any world state")
		if DisplayServer.get_name()!="headless":
			_check(not before.is_equal_approx(presence._motes.get_instance_transform(0)),"The renderer moves the individual wisps")
	_at(Vector2i(32,45))
	_check(not game.session.request_step(Vector2i(0,-1)) and game.session.player_cell()==Vector2i(32,45),"Real movement stops before the raised ward ring and exposed roots")
	_at(Vector2i(32,25))
	await _shot("rootward-ground")
	# A review-only wide framing shows the complete landmark. Gameplay keeps its normal camera.
	if output!="" and DisplayServer.get_name()!="headless":
		game.view.set_camera_mode(ClearingView.CameraMode.FIXED)
		game.view._zoom_target=40
		game.view.camera.size=40
		game.view._focus=Vector3(32,10,-36)
		game.view._focus_target=game.view._focus
		game.view._place_camera()
		await _shot("rootward-overview")
		game.view._zoom_target=13;game.view.camera.size=13
	var door:=HouseInstances.door(game.area,"town-hall")
	_at(door+Vector2i.RIGHT*3)
	await _shot("town-hall")
	_at(door)
	var left:=game.view.building_node("town-hall").find_child("DoorHinge_L",true,false) as Node3D
	var right:=game.view.building_node("town-hall").find_child("DoorHinge_R",true,false) as Node3D
	# Inspect the animation before beginning travel: on a slow rendered frame the
	# fade can already have swapped/freed the exterior before a timer resumes.
	game.view.open_door("town-hall")
	for frame: int in range(60):
		await process_frame
		if left!=null and right!=null and left.rotation.y>.01 and right.rotation.y<-.01:break
	_check(left!=null and right!=null and left.rotation.y>.01 and right.rotation.y<-.01,"Both oak leaves open away from the center")
	_check(game.session.request_step(Vector2i(0,1)) and game._flow_busy,"The hall uses the same walk-into-frame entrance")
	while game._flow_busy:await process_frame
	_check(game.area.id=="morning-town-hall-room" and game._inside_id=="village-morning/town-hall","The hall opens its own council instance")
	_check(MovementBindings.finished(game.session.state) and game.session.state.hotaru_greeted,"Voice and learned controls carry into the civic room")
	game.session.state.memory={"council":"visited"}
	_at(Vector2i(8,6))
	await _shot("council-room")
	_at(Vector2i(8,1));await game.leave_house()
	_check(game.session.player_cell()==door and game.session.state.memory.get("outside")=="village","Leaving restores the exact exterior snapshot and clear hall landing")
	await game.enter_house("town-hall")
	_check(game.session.state.memory.get("council")=="visited","The town hall remembers its independent saved state")
	_at(Vector2i(8,1));await game.leave_house()
	game.save_now()
	await game._return_to_title()
	await game.continue_game("village-morning")
	game.session.set_physics_process(false)
	await game.enter_house("town-hall")
	_check(game.session.state.memory.get("council")=="visited","Continue restores the civic room and its state")
	_at(Vector2i(8,1));await game.leave_house()
	_at(HouseInstances.door(game.area,"morning-home"));await game.enter_house("morning-home")
	_check(game.session.state.memory.get("room")=="bedroom" and not game.session.state.memory.has("council"),"The hall never replaces the player's bespoke bedroom")
	game.queue_free();await process_frame
	SaveStore.delete("village-morning")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))

func _at(cell: Vector2i) -> void:
	game.session.prepare_travel()
	game.session.state.player=[cell.x,cell.y,0]
	game.view.sync_player(game.session.state)
	game.view.focus_on(Vector2(cell),true)
	game.session.current_zone=game.area.zone_at(cell)
	game.session.state_changed.emit()
	game.session.zone_changed.emit(game.area.zone(game.session.current_zone))

func _shot(name: String) -> void:
	if output=="" or DisplayServer.get_name()=="headless":return
	await create_timer(.55).timeout
	for frame: int in range(6):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func _check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
