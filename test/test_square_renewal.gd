extends SceneTree
var failures: Array[String] = []
var checks: int = 0
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var area: AreaDef = AreaStore.load_area("haverlund-square")
	if area == null: quit(1); return
	var rules := LabWorld.new(area)
	var state := rules.initial_state()
	for id: String in ["bakery","greengrocer","bookshop"]:
		var link := RoomLinks.find(area,id)
		_check(not link.is_empty(),id+" has an exterior doorway")
		var at := Vector2i(int(link.at[0]),int(link.at[1]))
		_check(not rules.find_path(state,at,area.spawn).is_empty(),id+" door is reachable")
		var inside: AreaDef = AreaStore.load_area(str(link.to))
		_check(inside != null,id+" has a valid saved interior")
		if inside == null: continue
		var indoor := LabWorld.new(inside)
		var back := RoomLinks.find(inside,"square")
		_check(not indoor.find_path(indoor.initial_state(),Vector2i(back.at[0],back.at[1]),inside.spawn).is_empty(),id+" has an unobstructed return")
		var far: Vector2i = Vector2i(5,8) if id in ["clockmaker","apothecary"] else Vector2i(int(inside.displays[0].at[0]), int(inside.displays[0].at[1]))
		_check(not indoor.find_path(indoor.initial_state(),far,inside.spawn).is_empty(),id+" can be crossed from the door to the back of the room")
	# The three market shops are furnished (2026-11-06): their own shell and door, a shopkeeper, a board and notes.
	for id: String in ["bakery","greengrocer","bookshop"]:
		var inside: AreaDef = AreaStore.load_area("shop-"+id)
		var back := RoomLinks.find(inside,"square")
		_check(str(inside.interior.shell).ends_with("-shell") and str(inside.interior.shell) != "town-shop-shell" and back.get("doors") == "shell" and inside.displays.size() == 1 and inside.villagers.size() == 1 and inside.interior.inspections.size() >= 4 and (inside.interior.assets as Array).size() >= 6, id+" is furnished with its own door, board, keeper and notes")
	var apothecary_room: AreaDef = AreaStore.load_area("shop-apothecary")
	_check(apothecary_room.interior.furniture.is_empty() and apothecary_room.interior.inspections.is_empty(), "The apothecary is still an empty shell")
	# Thyme & Tonic (original v2 model) stands beside the clockmaker with a working door both ways.
	var apothecary := RoomLinks.find(area,"apothecary")
	_check(not apothecary.is_empty() and (area.interior.assets as Array).any(func(a: Dictionary) -> bool: return a.id=="apothecary" and a.asset=="haverlund-apothecary"),"The apothecary is placed with its doorway")
	if not apothecary.is_empty():
		_check(not rules.find_path(state,Vector2i(apothecary.at[0],apothecary.at[1]),area.spawn).is_empty(),"The apothecary door is reachable from the arrival")
		var back := RoomLinks.find(AreaStore.load_area("shop-apothecary"),"square")
		_check(Vector2i(back.arrival[0],back.arrival[1])==Vector2i(apothecary.at[0],apothecary.at[1]),"Leaving the apothecary returns to its own door")
	_check(not rules.find_path(state,Vector2i(12,40),area.spawn).is_empty(),"The physic garden is reachable through its opening on the walk")
	for id: String in ["bakery","greengrocer","bookshop"]:
		_check(not rules.is_walkable(state,Vector2i(28,int(RoomLinks.find(area,id).at[1]))),id+" stands against the terrace wall; no path runs behind it")
	_check(not rules.find_path(state,Vector2i(19,3),area.spawn).is_empty(),"The raised park is reachable from the arrival")
	_check(not rules.find_path(state,Vector2i(23,52),area.spawn).is_empty(),"The promenade reaches the future northern frontages")
	_check(area.lamps.size()<75,"Square light count is reduced")
	_check(not (area.interior.assets as Array).any(func(a: Dictionary) -> bool: return a.asset=="town-bollard-light"),"Path-light models are removed")
	for x: int in [45,49,65,69]:
		state.player=[x,48,0]
		_check(not rules.move(state,Vector2i(0,1)).ok,"Hall garden wall blocks passage at "+str(x))
	for x: int in [47,67]:
		state.player=[x,48,0]
		_check(rules.move(state,Vector2i(0,1)).ok,"Hall park opening remains usable")
	state=rules.initial_state();state.player=[45,49,0];state.memory={"kept":17}
	var restored := rules.normalize_state(state)
	_check(not restored.is_empty() and restored.memory.get("kept")==17 and rules.is_walkable(restored,Vector2i(restored.player[0],restored.player[1])),"A save inside a repaired wall keeps progress and relocates only the feet")
	state=rules.initial_state();state.player=[17,1,0];state.memory={"kept":19}
	var moved := rules.normalize_state(state)
	_check(not moved.is_empty() and moved.memory.get("kept")==19 and rules.is_walkable(moved,Vector2i(moved.player[0],moved.player[1])),"Old feet covered by a park tree relocate without losing saved work")
	for id: String in ["clockmaker","apothecary"]:
		var old_room: AreaDef=AreaStore.load_area("shop-"+id)
		var return_link := RoomLinks.find(old_room,"square")
		var arrival_cell := Vector2i(return_link.arrival[0],return_link.arrival[1])
		_check(rules.is_walkable(rules.initial_state(),arrival_cell) and not rules.find_path(rules.initial_state(),arrival_cell,area.spawn).is_empty(),"An old "+id+" interior save has a safe exit onto the new strip")
	# The start-pivot fence occupies [4,6] rather than being centred on cell 4.
	var source := AreaStore.read_source("haverlund-square")
	var doc: Dictionary = source.document.duplicate(true)
	doc.interior.assets.append({"id":"test-barrier","asset":"town-railing","at":[56,40],"solid":true,"turn":90,"scale":1})
	var parsed := AreaDef.parse(doc,source.assets)
	_check(parsed.ok,"Rotated reusable barrier validates")
	if parsed.ok:
		var test_rules := LabWorld.new(parsed.area)
		state=test_rules.initial_state();state.player=[55,41,0]
		_check(not test_rules.move(state,Vector2i(1,0)).ok,"Rotated start-pivot barrier blocks its actual span")
	doc.interior.assets[-1].turn=45
	_check(not AreaDef.parse(doc,source.assets).ok,"Diagonal collision authoring is refused")
	doc.interior.assets[-1].turn=0;doc.interior.assets[-1].scale=-1
	_check(not AreaDef.parse(doc,source.assets).ok,"Negative collision scale is refused")
	var rect := AreaBuild.prop_rect(source.assets,"town-railing",Vector2(26,10),"N",1)
	_check(rect.get_center().is_equal_approx(Vector2(25,10)),"Build placement preserves a barrier's start pivot after rotation")
	for issue: String in failures: printerr("FAIL: ",issue)
	print("Square renewal: %d checks, %d failures." % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
