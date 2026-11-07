extends SceneTree
## Clock, breakers, real Python condition trials, protected robot work and the civic room contract.
var checks: int = 0
var failures: Array[String] = []
const SOLUTION: String = 'def program(world):\n    for name in ["shop-door-lamp", "shop-sign-lamp"]:\n        lamp = world.lamp(name)\n        if world.time.is_dark:\n            lamp.set_lit(True)\n        else:\n            lamp.set_lit(False)\n'

func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH","1")
	_run.call_deferred()

func _run() -> void:
	var clock: Dictionary=CityCycle.fresh()
	_check(CityCycle.time(clock).phase=="Morning" and CityCycle.power(clock).band=="green","The first morning begins with normal 5–6 pressure")
	CityCycle.at_hour(clock,23.99)
	CityCycle.advance(clock,2)
	_check(clock.day==2 and CityCycle.time(clock).phase=="Night","The clock wraps days without resetting rooms")
	for hour: float in [6.0,12.0,18.0,22.0]:
		CityCycle.at_hour(clock,hour)
		_check(CityCycle.time(clock).phase=={6.0:"Morning",12.0:"Day",18.0:"Evening",22.0:"Night"}[hour],"Clock phase %.0f"%hour)
	for p: float in [5.6,8.0,8.9,9.0,10.0,14.9,15.0]:
		CityCycle.set_pressure(clock,p)
		_check(CityCycle.power(clock).band==("green" if p<8 else ("yellow" if p<9 else "red")),"Pressure bands %.1f"%p)
	_check(not CityCycle.power(clock).online,"15 trips the shared breaker")
	CityCycle.set_pressure(clock,5.6)
	_check(not CityCycle.power(clock).online and CityCycle.restore(clock).tripped,"Lowering pressure or reloading does not secretly repair a tripped breaker")
	_check(CityCycle.restore({"minute":"bad","pressure":INF}).pressure==5.6,"Malformed clock data cannot create nonfinite time or supply")
	_check(CityInstruments.describe_pressure(5.6).contains("5.6") and CityInstruments.describe_pressure(8.5).contains("amber"),"Inspecting the physical dial describes its actual reading and band")
	_check(CityInstruments.describe_pressure(15).contains("10") and not CityInstruments.describe_pressure(15).contains("15"),"The physical dial cannot claim a numerical reading beyond its 10-unit scale")
	for id: String in LevelStore.entry("sparks-and-machines").room_areas:
		var loaded: Dictionary=AreaStore.read(id)
		_check(loaded.ok,"Area %s validates: %s"%[id,str(loaded.get("errors",[]))])
		if not loaded.ok:continue
		var area: AreaDef=loaded.area
		var rules:=LabWorld.new(area)
		var state: Dictionary=rules.initial_state()
		if id=="city-hall":
			_check(not rules.can_step(state,Vector2i(23,18),Vector2i(24,18)),"The hall’s visible archive divider blocks crossing its timber partition")
			_check(not rules.find_path(state,Vector2i(26,18)).is_empty(),"The archive remains reachable from the open end of its divider")
		for lamp: Dictionary in area.lamps:
			if lamp.get("stand") is Array:
				var at:=Vector2i(lamp.stand[0],lamp.stand[1])
				_check(rules.is_walkable(state,at) and (at==area.spawn or not rules.find_path(state,at).is_empty()),"%s lamp %s has a reachable service point %s"%[id,lamp.id,str(at)])
		for link: Dictionary in area.interior.get("links",[]):
			var at:=Vector2i(link.at[0],link.at[1])
			_check(rules.is_walkable(state,at) and (at==area.spawn or not rules.find_path(state,at).is_empty()),"%s link %s is reachable"%[id,link.id])
		if id in ["haverlund-lane","haverlund-square"]:
			var mappings: Array=area.interior.lamp_fixtures.map(func(f: Dictionary)->String:return f.asset)
			for item: Dictionary in area.interior.assets:
				if item.asset in ["lane-lamp","square-banner-lamp","town-bollard-light","town-festoon"]:
					_check(mappings.has(item.id),"Every visible street fixture is connected: "+item.id)
	var world_catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/world-catalog.json")).assets
	for id: String in LevelStore.entry("sparks-and-machines").room_areas:
		var area: AreaDef=AreaStore.load_area(id)
		if area==null:continue
		var mapped: Array=area.interior.get("lamp_fixtures",[]).map(func(spec: Dictionary)->String:return spec.asset)
		for item: Dictionary in area.interior.assets:
			var file:=FileAccess.open("res://"+str(world_catalog[item.asset].runtime),FileAccess.READ)
			file.seek(12)
			var length: int=file.get_32()
			file.get_32()
			var glb: Dictionary=JSON.parse_string(file.get_buffer(length).get_string_from_utf8())
			var fitting: bool=(glb.get("materials",[]) as Array).any(func(material: Dictionary)->bool:return str(material.get("name","")).ends_with("lamp_glass") or str(material.get("name","")).ends_with("festoon_glass"))
			if fitting:_check(mapped.has(item.id),"Every placed lamp-glass model is connected: "+id+"/"+item.id)
	_condition()
	_robots()
	await _drafts()
	for failure: String in failures:printerr("FAIL: ",failure)
	print("City cycle: %d checks, %d failures."%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func _condition() -> void:
	var area: AreaDef=AreaStore.load_area("haverlund-lane")
	if area==null:return
	var rules:=LabWorld.new(area)
	var state: Dictionary=rules.initial_state()
	state.items=["field-tablet"]
	state.zones_seen=["spindle-lane"]
	state.player=[11,13,0]
	state.inspections_read=["nell-evening"]
	state.time={"is_dark":true,"hour":19.25,"day":1,"phase":"Evening"}
	var day: Dictionary=rules.snapshot(state)
	day.companion.enabled=false
	day.time={"is_dark":false,"hour":12.0,"day":1,"phase":"Day"}
	var night: Dictionary=day.duplicate(true)
	night.time={"is_dark":true,"hour":20.0,"day":1,"phase":"Evening"}
	var trials: Dictionary=LampPrograms.compile_trials(LabProgram.run(SOLUTION,day),LabProgram.run(SOLUTION,night))
	_check(trials.get("ok",false),"Real WASI runs both branches: "+str(trials))
	var proposed: Dictionary=rules.propose(state,trials.get("commands",[]),{})
	_check(proposed.ok and state.lamp_programs.is_empty(),"Installing the two-phase program remains a detached proposal")
	if not proposed.ok:return
	var after: Dictionary=proposed.state
	_check(Quests.goal_met(area,after,area.quest("after-the-light").goal),"Both real Python lamp routines plus Nell’s ticket complete the new quest")
	var restored: Dictionary=rules.normalize_state(after)
	LampPrograms.refresh(area,restored,false)
	_check(not restored.lamps["shop-door-lamp"] and not restored.lamps["shop-sign-lamp"],"Saved controllers switch both shop lamps off in daylight")
	LampPrograms.refresh(area,restored,true)
	_check(restored.lamps["shop-door-lamp"] and restored.lamps["shop-sign-lamp"],"The same controllers relight at dusk without running a Python loop forever")
	var undo: Dictionary=rules.revert(after,state)
	_check(undo.ok and undo.state.lamp_programs.is_empty(),"Undo removes installed lamp routines")
	var starter: String=str(area.quest("after-the-light").starter)
	var wrong: Dictionary=LampPrograms.compile_trials(LabProgram.run(starter,day),LabProgram.run(starter,night))
	var reversed: Dictionary=rules.propose(state,wrong.get("commands",[]),{})
	_check(reversed.ok and not Quests.goal_met(area,reversed.state,area.quest("after-the-light").goal),"The reversed starter is valid Python but fails the closing-round goal")
	var missing_else: String='def program(world):\n    if world.time.is_dark:\n        world.lamp("shop-door-lamp").set_lit(True)\n'
	_check(not LampPrograms.compile_trials(LabProgram.run(missing_else,day),LabProgram.run(missing_else,night)).ok,"Missing daylight instruction gives a useful failure instead of silently installing a partial card")
	after.player=[23,23,0]
	_check(not rules.propose(after,trials.commands,{}).ok,"Raw controller commands cannot bypass standing beside the connected lamps")

func _robots() -> void:
	var area: AreaDef=AreaStore.load_area("haverlund-square")
	if area==null:return
	var rules:=LabWorld.new(area)
	var state: Dictionary=rules.initial_state()
	state.items=["field-tablet"]
	state.zones_seen=area.zones.map(func(zone: Dictionary)->String:return zone.id)
	state.player=[51,17,0]
	state.terminal_links=["square-terminal"]
	var snapshot: Dictionary=rules.snapshot(state)
	snapshot.companion.enabled=false
	_check(snapshot.robots.size()>=6 and not snapshot.has("city_power"),"The service screen exposes workers; city pressure stays outside the learner API")
	var code: String='def program(world):\n    bot = world.robot("square-wick")\n    bot.set_speed(2.5)\n    bot.set_route([bot.stops[-1], bot.stops[0]])\n    bot.pause()\n'
	var answer: Dictionary=LabProgram.run(code,snapshot)
	var proposal: Dictionary=rules.propose(state,answer.get("commands",[]),{})
	_check(answer.ok and proposal.ok,"Real Python configures a named worker through bounded commands")
	if not proposal.ok:return
	var after: Dictionary=proposal.state
	_check(after.robot_programs["square-wick"].speed==2.5 and after.robot_programs["square-wick"].route.size()==2,"The chosen pace and two-stop round are committed data")
	var life: Dictionary=VillageLife.initial(area)
	var before: Vector2=VillageLife.position(life["square-wick"])
	VillageLife.advance(area,rules,after,life,10)
	_check(VillageLife.position(life["square-wick"])==before,"A paused robot actually stops its work round")
	_check(rules.normalize_state(after).robot_programs==after.robot_programs,"Valid robot instructions survive save/restore")
	var damaged: Dictionary=after.duplicate(true)
	damaged.robot_programs["square-wick"][12]=false
	_check(rules.normalize_state(damaged).robot_programs==after.robot_programs,"Malformed saved worker keys are ignored without losing valid instructions")
	var resume: Dictionary=rules.propose(after,[{"op":"set_robot","id":"square-wick","field":"running","value":true}],{})
	var stops: Array=[]
	for frame: int in range(2000):
		VillageLife.advance(area,rules,resume.state,life,.1)
		var worker: Dictionary=life["square-wick"]
		if worker.target!="" and (stops.is_empty() or stops[-1]!=worker.target):stops.append(worker.target)
		if stops.size()==2:break
	_check(stops==after.robot_programs["square-wick"].route,"A resumed worker physically reaches the two programmed stops in order")
	for command: Dictionary in [{"op":"set_robot","id":"square-wick","field":"speed","value":300},{"op":"set_robot","id":"square-wick","field":"route","value":["unknown"]}]:
		_check(not rules.propose(state,[{"op":"set_robot","id":"square-wick","field":"running","value":false},command],{}).ok and state.robot_programs.is_empty(),"A bad worker command rejects the whole batch")

	# The lane's service clock is read from its first resident, Pip. Pause that actual worker.
	var lane: AreaDef=AreaStore.load_area("haverlund-lane")
	var lane_rules:=LabWorld.new(lane)
	var lane_state: Dictionary=lane_rules.initial_state()
	lane_state.items=["field-tablet"]
	lane_state.player=[11,21,0]
	lane_state.terminal_links=["lane-service-terminal"]
	lane_state.zones_seen=lane.zones.map(func(zone: Dictionary)->String:return zone.id)
	var scheduled: Dictionary=VillageLife.initial(lane)
	var first_worker: String=str(scheduled.keys()[0])
	var clock_pause: Dictionary=lane_rules.propose(lane_state,[{"op":"set_robot","id":first_worker,"field":"running","value":false}],{})
	var service_before: float=VillageLife.clock(scheduled)
	var worker_before: Vector2=VillageLife.position(scheduled[first_worker])
	if clock_pause.ok:VillageLife.advance(lane,lane_rules,clock_pause.state,scheduled,1.0)
	_check(clock_pause.ok and VillageLife.clock(scheduled)>service_before and VillageLife.position(scheduled[first_worker])==worker_before,"Pausing the first worker cannot freeze the district tram/passenger service clock")

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message)

func _drafts() -> void:
	var area: AreaDef=AreaStore.load_area("workshop-loft")
	var view:=ClearingView.new()
	root.add_child(view)
	await process_frame
	view.setup(area)
	var session:=GameSession.new()
	session.input_enabled=false
	root.add_child(session)
	var pages: Dictionary={}
	for index: int in range(32):pages["scratch-light-%d"%index]='def program(world):\n    print("Lamp %d")\n'%index
	session.begin(area,view,{"workshop_pages":pages})
	_check(session.workshop_pages==pages,"Opening many programmable fittings no longer discards every draft after the old 16-page limit")
	var saved: Dictionary=JSON.parse_string(JSON.stringify(session.to_save()))
	session.begin(area,view,saved)
	_check(session.workshop_pages==pages,"All device drafts survive an actual JSON save/restore")
	for index: int in range(GameSession.MAX_WORKSHOP_PAGES+4):pages["scratch-light-%d"%index]="def program(world):\n    pass\n"
	session.begin(area,view,{"workshop_pages":pages})
	_check(session.workshop_pages.size()==GameSession.MAX_WORKSHOP_PAGES and session.workshop_pages.has("scratch-light-0"),"Oversized page collections stay bounded while retaining valid drafts")
	session.queue_free()
	view.queue_free()
	await process_frame
