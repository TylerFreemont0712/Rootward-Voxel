extends "res://test/test_welcome_flow.gd"
## Native review of day/night, saved controllers, supply instruments and the actual civic doorway.
func _run() -> void:
	Engine.max_fps=60
	DisplayServer.window_set_size(Vector2i(1600,1000))
	var args:PackedStringArray=OS.get_cmdline_user_args()
	output=args[0] if args.size()>0 else "res://evidence/city-cycle/1600"
	if args.size()>1:
		root.mode=Window.MODE_WINDOWED
		root.size=Vector2i(int(args[1]),int(args[2]))
		root.content_scale_size=root.size
		DisplayServer.window_set_size(root.size)
	DirAccess.make_dir_recursive_absolute(output)
	SaveStore.save_path="user://city_cycle_review_%d.json" % OS.get_process_id()
	SaveStore.profile_path="user://city_cycle_profile_%d.json" % OS.get_process_id()
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game()
	if args.size()>1:
		root.mode=Window.MODE_WINDOWED
		root.size=Vector2i(int(args[1]),int(args[2]))
		root.content_scale_size=root.size
		DisplayServer.window_set_size(root.size)
	game._pop_all_modals()
	game.close_notebook(true)
	game.settings.set_value("dialogue_speed",0)
	_check(DevelopmentMode.jump(game,"welcome-end"),"The sign’s completed checkpoint precedes Nell’s return")
	game._dialogue_read["workshop-scenes"].append("welcome-finished")
	game._pop_all_modals()
	_place(Vector2i(13,16))
	game._try_evening_return()
	while game._flow_busy:await process_frame
	var gait: Dictionary={}
	var deadline: int=Time.get_ticks_msec()+60000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if game.evening!=null and is_instance_valid(game.evening._actor):
			gait[game.evening._actor.sprite.frame]=true
			var p: Vector3=game.evening._holder.position
			if Vector2(p.x,-p.z).distance_to(Vector2(12,17))<.05:break
	_check(gait.size()>2 and game.session.cycle.evening_started,"Nell walks home with changing gait frames after the evening interlude")
	game._refresh_interaction()
	_check(game._interaction.get("kind")=="nell-evening" and game._resident_marks().get("nell")=="!","Nell’s real arrival offers an F conversation and story marker")
	await _shot("00a-nell-home")
	_check(DevelopmentMode.jump(game,"evening-start"),"Chapter 04 begins in a saved evening")
	for frame: int in range(10):await process_frame
	await _shot("00-evening-shop")
	game._show_workshop_scene("nell-evening","nell-evening")
	await _shot("01-nell-return")
	await _finish_dialogue()
	game._activate_device("shop-door-lamp")
	_check(game.journal is WorkshopJobsJournal and game.notebook_open,"Both shop lamps use the existing field slate")
	var journal:=game.journal as WorkshopJobsJournal
	_check(game.session.daylight_program,"Closing-round page selects the two-phase controller")
	journal.editor.text=TestSolution()
	journal._edited()
	_check(await game.session.run_preview(),"Real controller preview runs day and night on the worker")
	_check(not game.session.state.lamps["shop-door-lamp"] and game.session.preview_state().lamps["shop-door-lamp"],"Night lamps remain a ghost until Apply")
	await _shot("02-condition-slate")
	_check(game.session.apply_preview(),"Apply installs the two tested instructions")
	game.close_notebook(true)
	game._pop_all_modals()
	await _shot("03-shop-lamps-lit")
	_check(game.session.completed.has("after-the-light"),"The evening quest completes through real code")
	var saved_clock: Dictionary=game.session.cycle.duplicate(true)
	_check(DevelopmentMode.jump(game,"square"),"The square is available for instrument review")
	CityCycle.at_hour(game.session.cycle,12)
	game.session.sync_cycle()
	_place(Vector2i(47,19))
	game.view.focus_on(Vector2(43,24),true)
	for frame: int in range(6):await process_frame
	await _shot("04-rootwell-day")
	CityCycle.at_hour(game.session.cycle,22)
	game.session.sync_cycle()
	await _shot("05-rootwell-night")
	var needle: Node3D=game.view.building_node("rootwell").find_child("gauge_needle",true,false) as Node3D
	_check(needle!=null and needle.has_meta("rest_transform"),"The actual adopted gauge has a live calibrated needle")
	var normal: Transform3D=needle.transform if needle!=null else Transform3D.IDENTITY
	CityCycle.set_pressure(game.session.cycle,12)
	game.session.sync_cycle()
	_check(needle==null or not needle.transform.is_equal_approx(normal),"Overpressure moves the physical gauge to its stop")
	await _shot("06-rootwell-overpressure")
	CityCycle.set_pressure(game.session.cycle,15)
	game.session.sync_cycle()
	_check(not game.session.state.city_power.online,"An overload trips the same supply used by lamps and the loading meter")
	await _shot("07-supply-tripped")
	game.session.cycle.tripped=false
	CityCycle.set_pressure(game.session.cycle,5.6)
	CityCycle.at_hour(game.session.cycle,19.25)
	game.session.sync_cycle()
	_place(Vector2i(41,48))
	game.view.focus_on(Vector2(41,50),true)
	var hall_model: Node3D=game.view.building_node("guild-hall")
	var hands: Array=hall_model.get_meta("city_clock_hands",[])
	_check(hands.size()==2,"The adopted hall’s two original hands follow the shared clock")
	await _shot("08-hall-entrance")
	# Follow ordinary accepted steps onto the new entrance stair link.
	_check(game.session.request_step(Vector2i(0,1)),"The new city hall steps accept a normal grid step")
	game.session.advance_walk(LabWorld.STEP_SECONDS)
	_check(game.session.request_step(Vector2i(0,1)),"The hall door threshold is walkable")
	game.session.advance_walk(LabWorld.STEP_SECONDS)
	game.session._cancel_route()
	var pressure: float=game.session.cycle.pressure
	var minute: float=game.session.cycle.minute
	_check(await game.travel_room_link("city-hall"),"The real hinged door enters the new scene")
	_check(game.area.id=="city-hall" and game.session.cycle.pressure==pressure and absf(float(game.session.cycle.minute)-minute)<1.0,"City Hall shares the same saved clock and supply")
	game._pop_all_modals()
	_place(Vector2i(14,11))
	game.view.focus_on(Vector2(13.5,11),true)
	await _shot("09-city-hall-lobby")
	_place(Vector2i(7,15))
	game._refresh_interaction()
	game.interact()
	await _shot("10-help-desk")
	game._pop_all_modals()
	_place(Vector2i(20,15))
	game._refresh_interaction()
	game.interact()
	_check(not game._modals.is_empty() and game._modals[-1] is WorkshopJobLedger,"The public works desk opens the existing job ledger")
	await _shot("11-public-works")
	game._pop_all_modals()
	_place(Vector2i(14,0))
	_check(await game.travel_room_link("square"),"The hall's matching doorway returns to the square")
	_check(game.area.id=="haverlund-square","Return restores the square scene")
	game._veil.set_world_state(game.session.state)
	game._veil.set_status("Following the conduits…")
	await game._veil.close(Vector2(.5,.5),.3)
	await create_timer(.6).timeout
	await _shot("12-loading-pressure")
	await game._veil.open(Vector2(.5,.5),.3)
	game.open_development()
	await _shot("13-development-controls")
	_check(not game._modals.is_empty() and (game._modals[-1] as DevelopmentPanel).card.size.y<root.size.y,"The expanded development controls fit the gameplay window")
	_finish()

func TestSolution() -> String:
	return 'def program(world):\n    lamps = [world.lamp("shop-door-lamp"),\n             world.lamp("shop-sign-lamp")]\n    for lamp in lamps:\n        if world.time.is_dark:\n            lamp.set_lit(True)\n        else:\n            lamp.set_lit(False)\n'
