extends SceneTree
## Real quest/editor/save/property flow; optional native captures use the exact same path.
var game: Game
var checks: int=0
var failures: Array[String]=[]
var output: String=""
func _initialize()->void:
	OS.set_environment("VOXEL_LAB_FRESH","1")
	Engine.max_fps=60
	process_frame.connect(func()->void:Engine.max_fps=60)
	_run.call_deferred()
func _run()->void:
	if not OS.get_cmdline_user_args().is_empty():output=OS.get_cmdline_user_args()[0]
	if output!="":DirAccess.make_dir_recursive_absolute(output)
	SaveStore.save_path="user://welcome_review_%d.json" % OS.get_process_id()
	SaveStore.profile_path="user://welcome_profile_%d.json" % OS.get_process_id()
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game()
	game._pop_all_modals()
	game.close_notebook(true)
	game.settings.set_value("dialogue_speed",0)
	_check(DevelopmentMode.jump(game,"welcome-start"),"Chapter 03 fixture starts on the lane")
	for frame:int in range(4):await process_frame
	_check(game.session.accounts.wallet==18,"Earlier completed workshop jobs receive wages once")
	_place(Vector2i(10,25))
	await create_timer(2.0).timeout
	var garden:Node3D=game.view._content.find_child("BraumGardenGate",true,false) as Node3D
	_check(DoorSwing.is_open(garden) and DoorSwing.leaves(game.view.link_doors("shell")).size()==2 and not DoorSwing.is_open(game.view.link_doors("shell")),"The garden opens for Braum independently of the town steps")
	await _shot("00-garden-gate")
	_place(Vector2i(11,17))
	var phases: Dictionary={}
	var timeout:int=Time.get_ticks_msec()+14000
	while Time.get_ticks_msec()<timeout:
		await process_frame
		if not game.welcome.actors.is_empty():
			var actor:SpriteActor=game.welcome.actors.braum.actor
			phases[actor.sprite.frame]=true
			var p:Vector3=game.welcome.actors.braum.node.position
			if Vector2(p.x,-p.z).distance_to(Vector2(11,18))<.05:break
	_check(phases.size()>2,"Braum walks out of the garden using changing gait frames")
	await _shot("01-braum-on-lane")
	game._refresh_interaction()
	_check(game._interaction.get("id")=="braum","Approaching Braum offers a real F conversation")
	game.interact()
	_check(not game._modals.is_empty() and game._modals[-1] is DialogueWindow,"Braum opens the story portrait scene")
	await _shot("02-braum-dialogue")
	await _finish_dialogue()
	_check(game.welcome.seen("braum-welcome"),"The finished introduction is remembered")
	_place(Vector2i(11,8))
	game._refresh_interaction()
	game.interact()
	await _shot("03-iona-commission")
	await _finish_dialogue()
	_check(game.session.state.inspections_read.has("sign-commission"),"Iona's finished conversation accepts the nearby commission")
	_check(game.session.accounts.inventory.get("message-card",0)==1,"Iona issues one reusable inventory card")
	var money:int=int(game.session.accounts.wallet)
	game.open_journal()
	_check(game._modals[-1] is JobLedger,"The sign commission appears in the same job book as the workshop")
	(game._modals[-1] as JobLedger).destination_requested.emit("tram-welcome")
	# Follow the actual planned route through ordinary accepted steps. Native review windows
	# may lose desktop focus while screenshots are saved; focus loss correctly cancels held input.
	var sign_route:Array[Vector2i]=game.session._route.duplicate()
	_check(not sign_route.is_empty(),"The job book plans a real walk to the sign's authored connection")
	game.session._cancel_route()
	for cell:Vector2i in sign_route:
		game.session.request_step(cell-game.session.player_cell())
		game.session.advance_walk(LabWorld.STEP_SECONDS)
	game._process(0)
	_check(game.notebook_open and game.journal is JobsJournal,"The sign's own connection opens its editor")
	if not game.journal is JobsJournal:_finish();return
	var editor:JobsJournal=game.journal
	for frame:int in range(3):await process_frame
	_check(editor._notepad.page(&"job").get_child_count()>4 and editor.context.kind=="display","The shared notepad supplies the sign's job, lesson, names and hints")
	_check(editor.drawer_width>840 and editor._sidebar.size.x<=220 and editor.editor.size.x>350,"The wider slate gives most of its glass to code")
	await _shot("03a-shared-slate")
	var width:float=editor.editor.size.x
	editor._split.split_offset=144
	editor._split.dragged.emit(144)
	for frame:int in range(3):await process_frame
	_check(editor.editor.size.x>width and game.session.slate_sidebar_width==144,"Dragging the sidebar narrower gives the editor more space")
	editor._show_variables({"a_long_variable_name_for_the_message_card":"'Hello'"})
	for frame:int in range(3):await process_frame
	_check(editor._sidebar.size.x<=160,"Long variable names cannot force the narrowed sidebar back open")
	editor._show_variables({})
	editor._sidebar_toggle.pressed.emit()
	for frame:int in range(3):await process_frame
	_check(not editor._sidebar.visible and editor.editor.size.x>width+100,"The sidebar control hides files, devices and variables together")
	await _shot("03b-code-focus")
	editor._sidebar_toggle.pressed.emit()
	editor.editor.grab_focus()
	var shortcut:=InputEventKey.new()
	shortcut.keycode=KEY_B
	shortcut.ctrl_pressed=true
	shortcut.pressed=true
	Input.parse_input_event(shortcut)
	for frame:int in range(3):await process_frame
	_check(not editor._sidebar.visible,"Ctrl+B hides the sidebar while the code editor has focus")
	editor.toggle_sidebar()
	for button:Node in editor._sidebar.find_children("*","Button",true,false):
		if str(button.text).contains("DEVICES"):button.pressed.emit();break
	_check(not editor._devices.visible and editor.editor.editable,"The Devices heading collapses without changing the draft")
	for button:Node in editor._sidebar.find_children("*","Button",true,false):
		if str(button.text).contains("DEVICES"):button.pressed.emit();break
	_check(editor._tablet.keys.visible and editor._apply.visible,"Debug and Apply are visible controls on the slate")
	await editor.preview()
	_check(game.session.has_preview() and not game.session.completed.has("proper-welcome"),"One printed starter page is a proposal, not completion")
	_check(game.session.state.display_cards.is_empty() and game.session.accounts.wallet==money,"Debug neither changes the sign nor pays a wage")
	editor.editor.text='def program(world):\n    messages = [\n        "Welcome to Spindle Lane",\n        "No. 7 stops here",\n        "Tea first. Tram second.",\n    ]\n    for message in messages:\n        print(message)\n'
	await editor.preview()
	_check(game.session.has_preview() and game.session.preview_state().display_cards["tram-welcome"].size()==3,"The real finite loop proposes three messages")
	_check(not editor.playback._events.is_empty() and editor.playback.debugger,"The sign uses the same line debugger and variables as the light job")
	await _shot("04-sign-debug")
	editor.editor.text+='    # edited after Debug\n'
	editor.editor.text_changed.emit()
	_check(not game.session.has_preview(),"Editing discards the old display proposal")
	var draft:String=editor.editor.text
	editor.editor.text='def program(world):\n    print("x" * 33)\n'
	await editor.preview()
	_check(not game.session.has_preview() and editor._apply.disabled and not editor._card_preview.text.contains("GHOST CARD"),"A rejected card clears the old page preview as well as Apply")
	editor.editor.text=draft
	await editor.preview()
	editor.apply_routine()
	_check(game.session.completed.has("proper-welcome") and game.session.accounts.wallet==money+25,"Apply installs the card and pays exactly 25 p")
	var earned:Dictionary=game.session.accounts.duplicate(true)
	editor.editor.text+='    # keep editing a completed job\n'
	editor.editor.text_changed.emit()
	_check(editor._run.visible and editor._apply.visible and not editor._done.visible,"Editing a finished job restores Debug and Apply controls")
	_check(game.session.undo_apply() and game.session.accounts==earned,"Undo restores machine state without refunding or duplicating pay")
	await editor.preview()
	editor.apply_routine()
	_check(game.session.accounts==earned,"Reapplying the completed job cannot farm money")
	editor.close()
	for frame:int in range(1000):
		await process_frame
		if not game._modals.is_empty():break
	await _shot("05a-job-acknowledgement")
	await _finish_dialogue()
	_check(game.welcome.seen("welcome-finished"),"Iona and Braum acknowledge the installed card, then stay available without replaying")
	var reply:Dictionary=StoryScenes.log_line(game._story.scenes,{"scene":"braum-welcome","page":0,"kind":"reply","choice":0})
	_check(reply.get("speaker")=="braum","Braum's replies retain his speaker in the saved story log")
	await _shot("05-working-sign")
	if output!="":
		for sign:MessageSign in game.view._message_signs:sign.set_card(["1234567890ABCDEF1234567890ABCDEF"])
		await _shot("05b-max-width-sign")
		for sign:MessageSign in game.view._message_signs:sign.set_card(game.session.state.display_cards[sign.definition.id])
	game.open_inventory()
	await _shot("06-inventory-and-wages")
	game._pop_all_modals()
	var saved:Dictionary=game.session.to_save()
	game._cache_journey_room()
	var square:Dictionary=AreaStore.read_source("haverlund-square")
	var onward:Dictionary={"state":LabWorld.new(AreaStore.load_area("haverlund-square")).initial_state()}
	game._share_journey_progress(onward)
	game._activate_journey_room(square,onward)
	_check(game.session.accounts==earned,"Wallet and inventory follow the player to the square")
	var bank_note: Dictionary=(game.area.interior.inspections as Array).filter(func(note: Dictionary)->bool:return note.id=="bank")[0]
	_place(Vector2i(int(bank_note.at[0]),int(bank_note.at[1])))
	game._refresh_interaction()
	_check(game._interaction.get("id")=="bank","F offers the bank's actual street counter")
	game.interact()
	_check(not game._modals.is_empty() and game._modals[-1] is PropertyBook,"Haverlund Savings opens at its actual counter")
	if not game._modals.is_empty():
		var bank:PropertyBook=game._modals[-1]
		bank.transfer_requested.emit(20,true)
		_check(game.session.accounts.wallet==23 and game.session.accounts.bank==20,"Deposit moves wages to bank")
		bank.transfer_requested.emit(5,false)
		_check(game.session.accounts.wallet==28 and game.session.accounts.bank==15,"Withdrawal returns spendable coins")
		_check((game.hud as PaperHud)._purse_button.text.contains("28 p"),"The Bag button updates immediately after a bank transfer")
		await _shot("07-haverlund-savings")
	game._pop_all_modals()
	game._cache_journey_room()
	var lane:Dictionary=AreaStore.read_source("haverlund-lane")
	game._share_journey_progress(saved)
	game._activate_journey_room(lane,saved)
	_check(game.session.state.display_cards["tram-welcome"].size()==3 and game.session.accounts.bank==15,"Return preserves custom messages and latest account balance")
	var roundtrip:Dictionary=game.session.to_save()
	game.session.begin(game.area,game.view,JSON.parse_string(JSON.stringify(roundtrip)))
	_check(game.session.accounts.wallet==28 and game.session.accounts.bank==15 and game.session.accounts.inventory["message-card"]==1,"Continue-style restore preserves property and receipts")
	game._settle_wages()
	_check(game.session.accounts.wallet==28,"Loading completed quests does not pay again")
	SaveStore.force_enabled=true
	game.save_now()
	var disk:Dictionary=SaveStore.read(LevelStore.MAIN_LEVEL)
	_check(PlayerAccounts.restore(disk.get("accounts",{}))==game.session.accounts and disk.get("journey_rooms",{}).get("active")=="haverlund-lane","The actual save file carries the latest shared account and active room")
	var property:Dictionary=game.session.accounts.duplicate(true)
	game.session.reset_world()
	game._settle_wages()
	_check(game.session.accounts==property and game.session.completed.has("proper-welcome"),"Reset cannot erase property or farm a completed work payment")
	SaveStore.delete(LevelStore.MAIN_LEVEL)
	SaveStore.development=false
	SaveStore.delete(LevelStore.MAIN_LEVEL)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	game.queue_free()
	await process_frame
	_finish()
func _place(at:Vector2i)->void:
	game.session.prepare_travel()
	game.session.state.player=[at.x,at.y,0]
	var zone: String=game.area.zone_at(at)
	if zone!="" and not game.session.state.zones_seen.has(zone):game.session.state.zones_seen.append(zone)
	game.view.sync_player(game.session.state)
func _finish_dialogue()->void:
	if game._modals.is_empty():return
	var scene:DialogueWindow=game._modals[-1] as DialogueWindow
	if scene==null:return
	for step:int in range(100):
		if not is_instance_valid(scene) or scene.is_queued_for_deletion():break
		if scene._choices.visible and scene._choices.get_child_count()>0:scene._choose(scene._page.choices[0])
		else:scene.advance()
		await process_frame
	# A completed sign scene can start Nell’s evening interlude. Wait for actual travel cover before another action.
	while game._flow_busy:await process_frame
func _shot(name:String)->void:
	if output=="" or DisplayServer.get_name()=="headless":return
	for frame:int in range(24):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func _check(ok:bool,message:String)->void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",message)
	if not ok:failures.append(message)
func _finish()->void:
	for failure:String in failures:printerr("FAIL: ",failure)
	print("Welcome quest and property flow: %d checks, %d failures." % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
