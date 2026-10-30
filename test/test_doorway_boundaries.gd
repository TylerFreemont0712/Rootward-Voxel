extends SceneTree
## Door/frame alignment, real cottage wall edges, and preservation of legacy edge saves.
var checks: int=0
var failures: Array[String]=[]
var drawn: Array[Dictionary]=[]
func _initialize() -> void:go.call_deferred()
func go() -> void:
	var source: Dictionary=AreaStore.read_source("village-morning")
	var catalog: Dictionary=AreaStore.read_interiors()
	for template: String in catalog.templates.values():
		var room: AreaDef=AreaStore.load_area(template)
		var rules:=LabWorld.new(room)
		var state: Dictionary=rules.initial_state()
		var exit:=Vector2i(int(room.interior.exit[0]),int(room.interior.exit[1]))
		_check(rules.is_walkable(state,exit),"The real opening remains reachable: "+template)
		_check(not rules.find_path(state,exit).is_empty(),"Arrival can route to the exit: "+template)
		for x: int in range(room.width):_check(not rules.is_walkable(state,Vector2i(x,0)),"The cutaway boundary prevents walking behind the exit")
		_check(not rules.can_step(state,exit+Vector2i.LEFT,exit),"The left jamb blocks a sideways passage")
		_check(not rules.can_step(state,exit+Vector2i.RIGHT,exit),"The right jamb blocks a sideways passage")
		state.player=[exit.x,exit.y,0]
		_check(HouseInstances.crossing(room,rules,state,Vector2i(0,-1),catalog).get("kind")=="exit","One outward step from the visible frame exits")
		state.player=[exit.x+2,0,0];state.memory={"keep":"my home"}
		var restored: Dictionary=rules.normalize_state(state)
		_check(not restored.is_empty() and restored.player[1]>=exit.y and restored.memory==state.memory,"Old saves on the former front strip keep their progress on reachable floor")
		drawn.clear()
		InteriorBuilder.build(room,_collect)
		if room.id=="morning-bedroom":_room_arrangement(room)
		for box: Dictionary in drawn:
			if box.at.y<=.08 and box.size.x>float(room.width)-1.0 and box.size.z>3.0:
				_check(-box.at.z-box.size.z*.5>=float(exit.y)-.121,"The floor and its base end at the door sill: "+template)
		for post: Rect2 in HouseInstances.frame_posts(room):
			var matching: bool=false
			for box: Dictionary in drawn:
				if Vector2(box.at.x,-box.at.z).is_equal_approx(post.get_center()) and Vector2(box.size.x,box.size.z).is_equal_approx(post.size):matching=true
			_check(matching,"The visible jamb and its pure collision share one footprint")
	for facing: String in AreaDef.FACINGS:
		for scale: float in [.72,1.0,1.4]:
			var doc: Dictionary=source.document.duplicate(true)
			doc.buildings[0].at=[12,12];doc.buildings[0].facing=facing;doc.buildings[0].scale=scale
			var loaded: Dictionary=AreaDef.parse(doc,source.assets,source.quests)
			_check(loaded.ok,"Rotated/scaled cottage fixture validates")
			if not loaded.ok:continue
			var area: AreaDef=loaded.area
			var rules:=LabWorld.new(area)
			var state: Dictionary=rules.initial_state()
			var door: Vector2i=HouseInstances.door(area,"morning-home")
			_check(rules.is_walkable(state,door),"Collision leaves the safe entrance landing clear")
			var outward: Vector2i=HouseInstances.OUTWARD[facing]
			var threshold:=AreaBuild.threshold_cell(area.buildings[0].rect,Vector2(12,12),facing)
			_check(door==threshold+outward,"The return point is one full grid cell outside the old threshold")
			_check(not rules.is_walkable(state,threshold) and rules.find_path(state,threshold).is_empty(),"Closed door and threshold block both walking and routing")
			state.player=[door.x+outward.x,door.y+outward.y,0]
			_check(HouseInstances.crossing(area,rules,state,-outward,catalog).is_empty(),"Approaching the landing does not trigger the door early")
			state.player=[door.x,door.y,0]
			_check(HouseInstances.crossing(area,rules,state,-outward,catalog).get("house")=="morning-home","The inward attempt toward the frame opens the door")
			_check(HouseInstances.crossing(area,rules,state,outward,catalog).is_empty(),"Exiting to the landing does not re-enter while moving away")
			state.player=[threshold.x,threshold.y,0];state.memory={"keep":"my room"}
			var saved: Dictionary=rules.normalize_state(state)
			_check(not saved.is_empty() and saved.player==[door.x,door.y,0] and saved.memory==state.memory,"A saved character inside the closed threshold migrates to the safe landing")
			_check(not rules.is_walkable(state,Vector2i(12,12)) and rules.find_path(state,Vector2i(12,12)).is_empty(),"Walking and routing cannot enter the solid building")
			for local: Vector2 in [Vector2(-1,-2),Vector2(1,-2),Vector2(0,2),Vector2(2,0),Vector2(-2,0)]:
				var point:=Vector2(12,12)+local.rotated(deg_to_rad(AreaDef.FACINGS[facing]))*scale
				_check(not rules.can_stand(state,point),"Visible log wall edges block the foot footprint in every orientation")
	# Every adopted entrance must keep the player footprint clear of its actual
	# leaf after grid rounding, in each view and at the supported building sizes.
	for asset: String in catalog.assets:
		for facing: String in AreaDef.FACINGS:
			for scale: float in [.72,1.0,1.4]:
				var doc: Dictionary=source.document.duplicate(true)
				doc.buildings[0].asset=asset;doc.buildings[0].at=[12,12];doc.buildings[0].facing=facing;doc.buildings[0].scale=scale
				var loaded: Dictionary=AreaDef.parse(doc,source.assets,source.quests)
				_check(loaded.ok,"The entrance fixture validates: "+asset)
				if not loaded.ok:continue
				var land: AreaDef=loaded.area
				var world:=LabWorld.new(land)
				var saved: Dictionary=world.initial_state()
				var door: Vector2i=HouseInstances.door(land,"morning-home")
				_check(world.is_walkable(saved,door) and (land.spawn==door or not world.find_path(saved,door).is_empty()),"The model's safe landing is reachable: "+asset)
				var leaf: Rect2=AreaBuild.entrance_rect(Vector2(12,12),facing,scale,source.assets[asset].entrance)
				var foot:=Vector2(door)
				_check(foot.distance_to(foot.clamp(leaf.position,leaf.end))>=LabWorld.PLAYER_RADIUS-.0001,"The landing footprint does not intersect the rendered closed leaf: "+asset)
				saved.player=[door.x,door.y,0]
				_check(HouseInstances.check_enter(land,world,saved,"morning-home",catalog).ok,"Travel accepts the same clear landing the rules and renderer use")
	var build_catalog: Dictionary=AreaStore.read_build_catalog()
	var ledger:=BuildLedger.new(source.document,source.assets,source.quests,build_catalog,[],"studio",AreaStore.ground_materials())
	var approach: Vector2i=HouseInstances.door(ledger.area,"morning-home")
	_check(not ledger.place("wooden-chair",Vector2(approach),"S",ledger.rules.initial_state()).ok and ledger.edits.is_empty(),"Building protects the new return/entry tile from props")
	for extra: Variant in [-1,2,true,1.5]:
		var malformed: Dictionary=source.assets.duplicate(true)
		malformed["concept-cottage"].entrance.approach_cells=extra
		_check(not AreaDef.parse(source.document,malformed,source.quests).ok,"Landing offsets are a bounded whole-cell catalog rule")
	var area: AreaDef=AreaStore.load_area("village-morning")
	var rules:=LabWorld.new(area)
	var old: Dictionary=rules.initial_state()
	old.player=[6,11,0];old.memory={"keep":"my lane"};old.controls={"W":"north"}
	_check(not rules.is_walkable(old,Vector2i(6,11)),"The reported front-wall bypass is blocked")
	var restored: Dictionary=rules.normalize_state(old)
	_check(not restored.is_empty() and Vector2i(restored.player[0],restored.player[1])==HouseInstances.door(area,"morning-home") and restored.memory==old.memory and restored.controls==old.controls,"A former wall-edge save recovers to the doorstep without discarding controls or memory")
	if failures.is_empty():print("Doorway boundaries: %d checks passed (room frames, model walls, rotation/scale and saved edge recovery)." % checks)
	else:
		for failure: String in failures:printerr("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)
func _room_arrangement(room: AreaDef) -> void:
	var windows: Array[AABB]=[]
	for box: Dictionary in drawn:
		if box.material=="window_warm":windows.append(AABB(box.at-box.size*.5,box.size))
	for id: String in ["bed","desk","wardrobe","books"]:
		var prop: Dictionary=room.prop(id)
		var model: Node3D=preload("res://art/world_assets.gd").instantiate(prop.asset)
		root.add_child(model)
		model.position=Vector3(prop.at.x,0,-prop.at.y)
		model.rotation.y=deg_to_rad(float(AreaDef.FACINGS[prop.facing]))
		model.scale=Vector3.ONE*float(prop.scale)
		var bounds: AABB=BuildOverlay.world_aabb(model)
		for window: AABB in windows:_check(not bounds.intersects(window),"Furniture geometry stays out of the window: "+id)
		model.free()
	_check(absf(room.prop("bed").at.x-5.5)<.1,"The bed is centered between the windows")
	_check(room.prop("desk").facing=="E" and absf(room.prop("desk").at.x-room.prop("washstand").at.x)<.2 and room.prop("desk").at.distance_to(room.prop("washstand").at)<2.5,"The desk and washstand share a practical side-wall arrangement")
	_check(room.prop("armchair").at.distance_to(room.prop("books").at)<2,"The chair sits beside the bookcase as a reading corner")
	var rules:=LabWorld.new(room)
	var saved: Dictionary=rules.initial_state()
	saved.player=[5,8,0];saved.memory={"keep":"my program"};saved.controls={"W":"north"}
	var restored: Dictionary=rules.normalize_state(saved)
	_check(not restored.is_empty() and restored.player==[room.spawn.x,room.spawn.y,0] and restored.memory==saved.memory and restored.controls==saved.controls,"Rearranging furniture preserves an older room save and moves only an obstructed player")

func _collect(at: Vector3,size: Vector3,_material: String,_rotation: Vector3=Vector3.ZERO) -> void:drawn.append({"at":at,"size":size,"material":_material})
func _check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
