extends "res://test/test_square.gd"
## Real Game doorway, saved-room, collision and native appearance review.
func go() -> void:
	var args := OS.get_cmdline_user_args()
	output=args[0] if not args.is_empty() else "res://evidence/square-renewal/shops"
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1600,1000)
	root.content_scale_size=root.size
	Engine.max_fps=60
	SaveStore.save_path="user://square_shop_review_%d.json" % OS.get_process_id()
	SaveStore.profile_path="user://square_shop_profile_%d.json" % OS.get_process_id()
	SaveStore.force_enabled=true
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game("sparks-and-machines")
	_check(DevelopmentMode.jump(game,"square"),"Reach square through the isolated development checkpoint")
	game._pop_all_modals()
	# Save/reload this fixture through its isolated normal test save.
	SaveStore.development=false
	game.close_notebook(true)
	for id: String in ["bakery","greengrocer","tailor"]:
		var link := RoomLinks.find(game.area,id)
		await walk(Vector2i(link.at[0],link.at[1]))
		_check(game.session.request_step(AreaDef.STEPS[link.direction]),id+" accepts normal doorway input")
		while game._flow_busy: await process_frame
		await settle()
		_check(game.area.id=="shop-"+id,id+" crosses into the correct room")
		if game.area.id!="shop-"+id: break
		game._pop_all_modals()
		await walk(Vector2i(5,8))
		game.session.state.memory={"shop":id}
		for lamp: String in game.session.state.lamps:game.session.state.lamps[lamp]=true
		game.view.apply_state(game.session.state)
		game.view.focus_on(Vector2(5.5,6),true)
		await shot(id+"-interior")
		await walk(Vector2i(6,0))
		_check(game.session.request_step(Vector2i(0,-1)),id+" accepts ordinary exit input")
		while game._flow_busy: await process_frame
		await settle()
		_check(game.area.id=="haverlund-square",id+" returns to the square")
		_check(not game.session.state.memory.has("shop"),id+" keeps its memory inside")
	game.save_now()
	await game._return_to_title()
	await game.continue_game("sparks-and-machines")
	game._pop_all_modals()
	for id: String in ["bakery","greengrocer","tailor"]:
		_check(game._journey_rooms.get("shop-"+id,{}).get("state",{}).get("memory",{}).get("shop")==id,id+" retains independent room state after Continue")
	await shot("strip-in-game")
	for issue: String in failures:printerr("FAIL: ",issue)
	print("Square shops: %d checks, %d failures." % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
