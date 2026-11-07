extends SceneTree
## Regression: treads, projected sprite depth and deliberate doorway crossings.

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	AreaStore.use_fixtures()
	var source: Dictionary = AreaStore.read_source("kindle-hollow")
	var catalog: Dictionary = AreaStore.read_interiors()
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
	var actor := SpriteActor.new()
	root.add_child(actor)
	await process_frame
	_check(actor.sprite.billboard==BaseMaterial3D.BILLBOARD_FIXED_Y,"The painted actor's depth plane stays vertical above its feet")
	_check(is_equal_approx(actor._upright.scale.y*cos(SpriteActor.CAMERA_ELEVATION),1.0),"Upright correction preserves the approved on-screen proportions")
	actor.queue_free()
	if failures.is_empty():print("Walking surfaces and door rules: %d checks passed." % checks)
	else:
		for failure: String in failures:printerr("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok and not failures.has(message):failures.append(message)
