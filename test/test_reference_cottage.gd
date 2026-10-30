extends SceneTree
## Authored comparison house, rotated/scaled doors, new texture provenance and
## real entry/exit without sharing or replacing the existing home's save.
var checks: int=0
var failures: Array[String]=[]
var game: Game
var output: String=""

func _initialize() -> void:_run.call_deferred()

func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():output=args[0]
	var source: Dictionary=AreaStore.read_source("village-morning")
	var area: AreaDef=AreaStore.load_area("village-morning")
	_check(area.building("morning-home").asset=="concept-cottage" and area.building("morning-home").at==Vector2(7,13),"The existing home keeps its original asset and placement")
	_check(area.building("concept-comparison").asset=="reference-cottage" and area.building("concept-comparison").at.distance_to(area.building("morning-home").at)<9,"The separate study stands beside the current home")
	var old_manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/concept-cottage/manifest.json"))
	_check(FileAccess.get_sha256("res://"+str(old_manifest.source))==old_manifest.source_sha256,"The approved earlier cottage master is untouched")
	var rules:=LabWorld.new(area)
	var state: Dictionary=rules.initial_state()
	var door:=HouseInstances.door(area,"concept-comparison")
	_check(door==Vector2i(10,20) and not rules.find_path(state,door,HouseInstances.door(area,"morning-home")).is_empty(),"The existing home connects to the study's lane-facing landing")
	for cell: Vector2i in [Vector2i(7,20),Vector2i(9,21),Vector2i(10,19),Vector2i(6,18)]:
		_check(not rules.is_walkable(state,cell),"Wall, planter, fenced bed and barrel block their visible ground: "+str(cell))
	# Loading the expanded authored map retains a previous home-lane save.
	state.player=[7,10,0];state.memory={"home":"unchanged"};state.controls={"W":"north"}
	var restored: Dictionary=rules.normalize_state(state)
	_check(restored.player==state.player and restored.memory==state.memory and restored.controls==state.controls,"The comparison building does not discard an older journey")
	var catalog: Dictionary=AreaStore.read_interiors()
	for facing: String in AreaDef.FACINGS:
		for scale: float in [.72,1.0,1.4]:
			var doc: Dictionary=source.document.duplicate(true)
			doc.buildings=[{"id":"concept-comparison","asset":"reference-cottage","at":[12,12],"facing":facing,"scale":scale}]
			doc.trees=[];doc.props=[];doc.lamps=[]
			doc.terrain=[]
			for row: int in range(area.height):doc.terrain.append(".".repeat(area.width))
			var parsed: Dictionary=AreaDef.parse(doc,source.assets,source.quests)
			_check(parsed.ok,"The detailed house validates at "+facing+" / "+str(scale))
			if not parsed.ok:continue
			var land: AreaDef=parsed.area
			var world:=LabWorld.new(land)
			var saved: Dictionary=world.initial_state()
			var landing:=HouseInstances.door(land,"concept-comparison")
			_check(world.is_walkable(saved,landing) and not world.find_path(saved,landing).is_empty(),"Garden and barrel keep the entrance reachable at every facing/scale")
			var leaf: Rect2=AreaBuild.entrance_rect(Vector2(12,12),facing,scale,source.assets["reference-cottage"].entrance)
			var foot:=Vector2(landing)
			_check(foot.distance_to(foot.clamp(leaf.position,leaf.end))>=LabWorld.PLAYER_RADIUS-.0001,"The returned player's feet clear the closed modeled leaf")
			var outward: Vector2i=HouseInstances.OUTWARD[facing]
			saved.player=[landing.x+outward.x,landing.y+outward.y,0]
			_check(HouseInstances.crossing(land,world,saved,-outward,catalog).is_empty(),"An approach step cannot enter a tile early")
			saved.player=[landing.x,landing.y,0]
			_check(HouseInstances.crossing(land,world,saved,-outward,catalog).get("house")=="concept-comparison","The next frame attempt enters the comparison house")
			_check(not world.is_walkable(saved,Vector2i(12,12)),"The detailed building remains solid")
	_textures()
	await _travel()
	if failures.is_empty():print("Reference cottage: %d checks passed (source/texture handoff, twelve door variants and independent saved entry)." % checks)
	else:
		for failure: String in failures:printerr("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)

func _textures() -> void:
	var path: String="res://art/source/world/reference-cottage/v1/textures/"
	var provenance: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path+"generation.json"))
	var outputs: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/textures/reference-cottage-manifest.json"))
	_check(FileAccess.get_sha256(path+"library.json")==provenance.library_sha256 and provenance.materials.size()==3,"The three generated surface prompts and their source record agree")
	for item: Dictionary in provenance.materials:
		_check(FileAccess.get_sha256("res://"+str(item.source))==item.sha256,"Native painting is preserved: "+item.id)
		for style: String in ["lush","solid"]:
			var output_item: Dictionary=outputs.materials[item.id].outputs[style]
			_check(FileAccess.get_sha256(output_item.path)==output_item.sha256,"The single art build owns the selected texture: "+item.id+" / "+style)
			var image:=Image.load_from_file(ProjectSettings.globalize_path(output_item.path))
			var periodic: bool=image.detect_alpha()==Image.ALPHA_NONE
			for i: int in range(image.get_width()):periodic=periodic and image.get_pixel(i,0)==image.get_pixel(i,image.get_height()-1)
			for i: int in range(image.get_height()):periodic=periodic and image.get_pixel(0,i)==image.get_pixel(image.get_width()-1,i)
			_check(periodic,"The packaged material is opaque and periodic: "+item.id)
			var import_settings:=ConfigFile.new()
			_check(import_settings.load(str(output_item.path)+".import")==OK and import_settings.get_value("params","mipmaps/generate",false),"The painted material uses mipmaps at gameplay distance")
	var base: String="res://art/source/world/reference-cottage/v1/"
	_check(FileAccess.file_exists(base+"model.pass-01.blend") and FileAccess.file_exists(base+"model.pass-02.blend"),"Both reviewed earlier masters are preserved")
	var pass3: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base+"pass-03.json"))
	_check(FileAccess.get_sha256(base+"model.blend")==pass3.after_sha256 and int(pass3.ridge_caps_layered)==12,"The selected master is the recorded third review revision")

func _travel() -> void:
	SaveStore.save_path="user://test_reference_cottage_"+str(OS.get_process_id())+".json"
	SaveStore.profile_path="user://test_reference_cottage_profile_"+str(OS.get_process_id())+".json"
	SaveStore.force_enabled=true;SaveStore.delete("village-morning")
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate();root.add_child(game)
	await process_frame
	await game.start_new_game("village-morning")
	if not game._modals.is_empty():game._modals[-1].close()
	game.session.set_physics_process(false)
	game.session.state.controls={"W":"north","A":"west","S":"south","D":"east"}
	game.session.state.movement_used=["north","west","south","east"]
	game.session.state.hotaru_greeted=true
	game.session.state.memory={"bedroom":"my original home"}
	_at(Vector2i(6,1));await game.leave_house()
	game.session.set_physics_process(false)
	game.session.state.memory={"lane":"outside"}
	var door:=HouseInstances.door(game.area,"concept-comparison")
	_at(door)
	var tread_height: float = .12 + WalkingSurface.CLEARANCE
	_check(is_equal_approx(game.view._deck_height(Vector2(door)),tread_height) and is_equal_approx(game.view._player.position.y,tread_height),"The character's feet clear the actual lower tread by the shared walking-surface offset")
	await _shot("at-new-door")
	var position: Vector3=game.view._player.position
	var hinge:=game.view.building_node("concept-comparison").find_child("DoorHinge*",true,false) as Node3D
	game.view.open_door("concept-comparison")
	for frame: int in range(60):
		await process_frame
		if hinge!=null and absf(hinge.rotation.y)>.01:break
	_check(hinge!=null and absf(hinge.rotation.y)>.01,"The selected model's actual leaf opens")
	_check(game.session.request_step(Vector2i.LEFT) and game._flow_busy,"Walking toward the new frame starts its saved-room entry")
	_check(game.view._player.position.is_equal_approx(position),"Entry does not slide the character into the closed wall")
	while game._flow_busy:await process_frame
	_check(game._inside_id=="village-morning/concept-comparison" and not game.session.state.memory.has("bedroom"),"The shared room template has a separate instance for the study")
	_check(MovementBindings.finished(game.session.state),"The comparison home keeps the player's learned keys")
	game.session.state.memory={"study":"comparison visit"}
	_at(Vector2i(6,1));await game.leave_house()
	_check(game.session.player_cell()==door and game.session.state.memory.get("lane")=="outside","Leaving returns to the clear modeled tread with the outdoor state intact")
	game.save_now();await game._return_to_title();await game.continue_game("village-morning")
	game.session.set_physics_process(false)
	await game.enter_house("concept-comparison")
	_check(game.session.state.memory.get("study")=="comparison visit","Continue keeps the comparison room's independent state")
	_at(Vector2i(6,1));await game.leave_house()
	_at(HouseInstances.door(game.area,"morning-home"));await game.enter_house("morning-home")
	_check(game.session.state.memory.get("bedroom")=="my original home" and not game.session.state.memory.has("study"),"The new house never replaces or shares the original bedroom's state")
	game.queue_free();await process_frame;SaveStore.delete("village-morning")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))

func _at(cell: Vector2i) -> void:
	game.session.prepare_travel();game.session.state.player=[cell.x,cell.y,0]
	game.view.sync_player(game.session.state);game.view.focus_on(Vector2(cell),true)

func _shot(name: String) -> void:
	if output=="" or DisplayServer.get_name()=="headless":return
	await create_timer(.5).timeout
	for frame: int in range(6):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func _check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
