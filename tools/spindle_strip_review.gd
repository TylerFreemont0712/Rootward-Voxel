extends "res://test/test_square.gd"
## Native player-scale review of the moved arrival, both stairs, park and cleared rooms.
func go() -> void:
	var args:=OS.get_cmdline_user_args()
	output=args[0] if not args.is_empty() else "res://evidence/spindle-strip/game"
	root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1600,1000);root.content_scale_size=root.size
	SaveStore.save_path="user://spindle_strip_review_%d.json" % OS.get_process_id()
	SaveStore.profile_path="user://spindle_strip_profile_%d.json" % OS.get_process_id()
	SaveStore.force_enabled=true
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate();root.add_child(game)
	await process_frame
	await game.start_new_game("sparks-and-machines")
	_check(DevelopmentMode.jump(game,"square"),"The existing development fixture reaches the revised square")
	SaveStore.development=false
	game._dialogue_read["workshop-scenes"]=game._story.scenes.keys()
	game._workshop_dismissed=game._story.scenes.keys()
	game._pop_all_modals();game.close_notebook(true)
	await walk(Vector2i(13,12))
	_check(game.session.request_step(Vector2i(-1,0)),"Ordinary input reaches the moved return boundary")
	game.session.advance_walk(LabWorld.STEP_SECONDS)
	_check(game.session.request_step(Vector2i(-1,0)),"The relocated boundary walks through to Spindle Lane")
	while game._flow_busy:await process_frame
	await settle()
	_check(game.area.id=="haverlund-lane","Return still reaches the original lane gate")
	await walk(Vector2i(12,26))
	_check(game.session.request_step(Vector2i(0,1)),"The lane gate enters the widened landing")
	while game._flow_busy:await process_frame
	await settle()
	_check(game.area.id=="haverlund-square" and game.session.player_cell()==Vector2i(15,11),"Arrival lands on the new promenade approach")
	game._pop_all_modals()
	game.view.focus_on(Vector2(21,12),true)
	await shot("arrival-in-game")
	await walk(Vector2i(19,2));game.view.focus_on(Vector2(19,4),true)
	await shot("park-in-game")
	await walk(Vector2i(19,30));game.view.focus_on(Vector2(18,30),true)
	await shot("promenade-in-game")
	await walk(Vector2i(19,52));await shot("future-frontages")
	# Real doors for the three retained market buildings open into empty shells.
	for id: String in ["bakery","greengrocer","bookshop"]:
		var link:=RoomLinks.find(game.area,id)
		await walk(Vector2i(link.at[0],link.at[1]))
		game._pop_all_modals();game.close_notebook(true)

		# walk_to a link schedules its ordinary crossing; do not launch a second
		# transition while the first one is already covering the scene.
		if not game._flow_busy and game.area.id=="haverlund-square":game.session.request_step(AreaDef.STEPS[link.direction])
		while game._flow_busy:await process_frame
		await settle()
		var entered: bool=game.area.id=="shop-"+id
		_check(entered,id+" still opens")
		if not entered:
			for issue: String in failures:printerr("FAIL: ",issue)
			quit(1);return
		game._pop_all_modals();await walk(Vector2i(6,6))
		_check(game.area.interior.furniture.is_empty(),id+" contains no furniture")
		game.session.state.memory={"retained":id}
		await shot(id+"-empty")
		await walk(Vector2i(6,0));game._pop_all_modals()
		while game._flow_busy:await process_frame
		await settle()
		_check(game.area.id=="haverlund-square",id+" returns to the square")
		game._pop_all_modals()
	# Simulate Continue already inside the two retired temporary shop shells.
	for id: String in ["clockmaker","apothecary"]:
		game._cache_journey_room()
		var source:=AreaStore.read_source("shop-"+id)
		var saved: Dictionary=game._journey_rooms.get("shop-"+id,{}).duplicate(true)
		game._activate_journey_room(source,saved)
		game._pop_all_modals();await walk(Vector2i(6,6));await shot(id+"-empty")
		await walk(Vector2i(6,0));game._pop_all_modals()
		while game._flow_busy:await process_frame
		await settle()
		_check(game.area.id=="haverlund-square","An old "+id+" save exits safely without its removed exterior")
		game._pop_all_modals()
	game.save_now();await game._return_to_title();await game.continue_game("sparks-and-machines");game._pop_all_modals()
	_check(game.area.id=="haverlund-square","Continue restores the revised strip")
	for id: String in ["bakery","greengrocer","bookshop"]:
		_check(game._journey_rooms.get("shop-"+id,{}).get("state",{}).get("memory",{}).get("retained")==id,"Clearing "+id+" preserves separate room memory")
	for issue: String in failures:printerr("FAIL: ",issue)
	print("Spindle strip review: %d checks, %d failures." % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
