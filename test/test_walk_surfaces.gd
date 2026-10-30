extends SceneTree
## Regression: treads, projected sprite depth and deliberate doorway crossings.

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var source: Dictionary = AreaStore.read_source("kindle-hollow")
	var catalog: Dictionary = AreaStore.read_interiors()
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/art-catalog.json"))
	var textures: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(art.building_textures.manifest))
	var paintings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(art.building_textures.provenance))
	_check(FileAccess.get_sha256(art.building_textures.library)==paintings.library_sha256,"The concept cottage preserves the exact imagegen prompts")
	for painting: Dictionary in paintings.materials:
		_check(FileAccess.get_sha256("res://"+str(painting.source))==painting.sha256,"The native generated painting is preserved")
		for style: String in ["lush","solid"]:
			var output: Dictionary = textures.materials[painting.id].outputs[style]
			_check(FileAccess.get_sha256(output.path)==output.sha256,"The cottage's runtime texture matches the art build")
			var image := Image.load_from_file(ProjectSettings.globalize_path(output.path))
			var periodic: bool = true
			for i: int in range(128):periodic = periodic and image.get_pixel(0,i)==image.get_pixel(127,i) and image.get_pixel(i,0)==image.get_pixel(i,127)
			_check(periodic and image.detect_alpha()==Image.ALPHA_NONE,"The cottage texture is opaque with matching repeat edges")
	var area: AreaDef = AreaStore.load_area("kindle-hollow")
	var rules := LabWorld.new(area)
	for room_id: String in catalog.templates.values():
		var room: AreaDef = AreaStore.load_area(room_id)
		var room_rules := LabWorld.new(room)
		var room_state: Dictionary = room_rules.initial_state()
		_check(HouseInstances.crossing(room,room_rules,room_state,Vector2i(0,-1),catalog).is_empty(),"Arriving inside does not immediately leave")
		room_state.player = [room.interior.exit[0],room.interior.exit[1],0]
		_check(HouseInstances.crossing(room,room_rules,room_state,Vector2i(0,-1),catalog).get("kind")=="exit","Walking south through the room doorway exits")
		for direction: Vector2i in [Vector2i(0,1),Vector2i.LEFT,Vector2i.RIGHT]:
			_check(HouseInstances.crossing(room,room_rules,room_state,direction,catalog).is_empty(),"Walking back inside or past the exit stays indoors")
	var state: Dictionary = AreaBuild.open_state(rules, area.spawn)
	for house: Dictionary in area.buildings:
		var door: Vector2i = HouseInstances.door(area, house.id)
		state.player = [door.x, door.y, 0]
		var outward: Vector2i = HouseInstances.OUTWARD[house.facing]
		_check(HouseInstances.crossing(area, rules, state, -outward, catalog).get("house") == house.id, "Inward step enters the correct house: " + house.id)
		for direction: Vector2i in [outward, Vector2i(-outward.y, outward.x)]:
			_check(HouseInstances.crossing(area, rules, state, direction, catalog).is_empty(), "Walking away/alongside does not enter: " + house.id)
		state.player = [door.x + outward.x, door.y + outward.y, 0]
		_check(HouseInstances.crossing(area, rules, state, -outward, catalog).is_empty(), "Walking onto the landing does not enter a cell early: "+house.id)
	# A deliberately blocked approach cannot initiate travel, even if a caller sets the player's cell there.
	var blocked_doc: Dictionary = source.document.duplicate(true)
	var door: Vector2i = HouseInstances.door(area, "home")
	blocked_doc.props = [{"id":"blocked-door", "asset":"wooden-chair", "at":[door.x,door.y], "facing":"S"}]
	var blocked: Dictionary = AreaDef.parse(blocked_doc, source.assets, source.quests)
	_check(blocked.ok, "Blocked-door fixture parses")
	var blocked_rules := LabWorld.new(blocked.area)
	state.player = [door.x, door.y, 0]
	_check(HouseInstances.crossing(blocked.area, blocked_rules, state, Vector2i.LEFT, catalog).is_empty(), "An occupied doorway refuses travel")
	# All four stair orientations, at both supported terrace levels, in either direction.
	for facing: String in ["N","E","S","W"]:
		var dir: Vector2i = -HouseInstances.OUTWARD[facing]
		for level: int in [0,1]:
			var doc: Dictionary = {"schema":1,"id":"stairs-test","title":"Stairs","version":1,"size":[8,8],"spawn":[0,0],"terrain":[],"levels":[],"stairs":[{"at":[3,3],"up": AreaBuild.turned(facing,2)}]}
			for y: int in range(7,-1,-1):
				doc.terrain.append("........")
				var row: String = ""
				for x: int in range(8):
					row += str(level + (1 if Vector2(Vector2i(x,y)-Vector2i(3,3)).dot(Vector2(dir))>0 else 0))
				doc.levels.append(row)
			var parsed: Dictionary = AreaDef.parse(doc,{})
			_check(parsed.ok,"Stair fixture parses: "+facing)
			if not parsed.ok:continue
			var land: AreaDef = parsed.area
			var previous: float = -1.0
			for i: int in range(201):
				var along: float = -.9 + float(i)*.009
				var point: Vector2 = Vector2(3,3)+Vector2(dir)*along
				var actual: float = WalkingSurface.height(land,point,[])-WalkingSurface.CLEARANCE
				var drawn: float = float(level)
				if along>=-.5 and along<.5:
					drawn+=float(mini(3,floori((along+.5)*4))+1)/4.0
				elif along>=.5:drawn+=1.0
				_check(actual>=drawn-.0001,"Feet never sink below the rendered tread")
				if previous>=0:
					_check(actual>=previous-.0001 and actual-previous<.04,"Support rises continuously before every riser (and reverses on descent)")
				previous=actual
	# Rotate and scale the exact same entrance data as its building mesh.
	var spec: Dictionary = source.assets["log-cabin-large"].entrance
	for facing: String in ["N","E","S","W"]:
		for scale: float in [.72,1.0,1.4]:
			var center := Vector2(40,40)
			var outward := Vector2(HouseInstances.OUTWARD[facing])
			var entry: Array[Dictionary] = [{"at":center,"facing":facing,"scale":scale,"base":0.0,"steps":spec.steps}]
			for tread: Array in spec.steps:
				var point: Vector2 = center+outward*float(tread[0])*scale
				_check(WalkingSurface.height(area,point,entry)>=float(tread[3])*scale+WalkingSurface.CLEARANCE-.0001,"House steps track mesh rotation and scale")
	var actor := SpriteAdventurer.new()
	root.add_child(actor)
	await process_frame
	_check(actor.sprite.billboard==BaseMaterial3D.BILLBOARD_FIXED_Y,"The painted actor's depth plane stays vertical above its feet")
	_check(is_equal_approx(actor._upright.scale.y*cos(SpriteAdventurer.CAMERA_ELEVATION),1.0),"Upright correction preserves the approved on-screen proportions")
	actor.queue_free()
	await _apertures(source.assets, catalog)
	if failures.is_empty():print("Walking surfaces and door rules: %d checks passed." % checks)
	else:
		for failure: String in failures:printerr("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok and not failures.has(message):failures.append(message)


## Test the exported geometry too: a leaf rotating is insufficient if an old
## beam or a Boolean closing face still covers the supposed opening.
func _apertures(assets: Dictionary, catalog: Dictionary) -> void:
	for id: String in catalog.assets:
		var entry: Dictionary = assets[id].entrance
		var model: Node3D = preload("res://art/world_assets.gd").instantiate(id)
		root.add_child(model)
		await process_frame
		var bounds: Array = preload("res://pipeline/world_geometry.gd").audit(model).bounds
		_check(float(bounds[5])<float(assets[id].logical_footprint[3])*.5+1.5,"The doorway edit stays inside the house's approach bounds: "+id)
		var hinge := model.find_child("DoorHinge*",true,false) as Node3D
		_check(hinge!=null,"The exported house has a separate hinged leaf: "+id)
		if hinge==null:
			model.free()
			continue
		for part: Node in model.find_children("Entrance *", "MeshInstance3D", true, false):
			if String(part.name).begins_with("Entrance strap hinge") or String(part.name).begins_with("Entrance hinge stud"):
				_check(hinge.is_ancestor_of(part),"Straps and studs move with the leaf: "+id)
		var front: float = float(entry.plane)
		var center: float = float(entry.bottom)+float(entry.height)*.5
		var origin := Vector3(0,center,front+3.0)
		var closed: float = _front_hit(model,origin)
		hinge.rotation.y=1.3
		var opened: float = _front_hit(model,origin)
		_check(absf(closed-front)<.2,"The closed entry shows its actual leaf: "+id)
		_check(opened<front-.45,"The opened leaf reveals a clear passage into the vestibule: "+id)
		model.free()


func _front_hit(node: Node, origin: Vector3) -> float:
	var nearest: float = -100.0
	if node is MeshInstance3D and node.mesh!=null:
		for surface: int in range(node.mesh.get_surface_count()):
			var arrays: Array=node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			for index: int in range(0,indices.size() if not indices.is_empty() else vertices.size(),3):
				var points: Array[Vector3]=[]
				for k: int in range(3):points.append(node.global_transform*vertices[indices[index+k] if not indices.is_empty() else index+k])
				var hit: Variant=Geometry3D.ray_intersects_triangle(origin,Vector3.FORWARD,points[0],points[1],points[2])
				if hit!=null:nearest=maxf(nearest,(hit as Vector3).z)
	for child: Node in node.get_children():nearest=maxf(nearest,_front_hit(child,origin))
	return nearest
