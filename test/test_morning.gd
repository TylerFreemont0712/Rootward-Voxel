extends SceneTree
## Pure binding boundaries and real new-journey, lesson, travel and save isolation.
var checks: int=0
var failures: Array[String]=[]
var game: Game
var output: String=""
const MANUAL: String="def program(world):\n    x = y = 0\n    x += 1\n    world.controls.bind_move(\"W\", x, y)\n\n    x = y = 0\n    y += 1\n    world.controls.bind_move(\"A\", x, y)\n\n    x = y = 0\n    x -= 1\n    world.controls.bind_move(\"S\", x, y)\n\n    x = y = 0\n    y -= 1\n    world.controls.bind_move(\"D\", x, y)\n\n"

func _initialize() -> void:go.call_deferred()
func go() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():output=args[0]
	_pure()
	SaveStore.save_path="user://test_morning_"+str(OS.get_process_id())+".json"
	SaveStore.profile_path="user://test_morning_profile_"+str(OS.get_process_id())+".json"
	SaveStore.force_enabled=true
	SaveStore.delete();SaveStore.delete("village-morning")
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	if args.size()>1:game.settings.set_value("ui_scale",float(args[1]))
	if args.size()>2 and args[2]=="fullscreen":game.settings.set_value("fullscreen",true)
	if args.size()>2 and args[2]=="fullscreen":
		await create_timer(.2).timeout
		_check(game.get_window().mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN],"The lesson layout runs in actual full-screen mode")
		game.open_settings()
		await shot("00-fullscreen-settings")
		game._modals[-1].close()
	await game.start_new_game("kindle-hollow")
	game.session.state.lamps["landing-lamp"]=true
	game.save_now()
	var legacy: Dictionary=SaveStore.read()
	await game._return_to_title()
	_check(LevelStore.available_entries().size()==1 and LevelStore.entry("village-morning").archived,"Village Morning remains an archived regression fixture")
	game._choose_level("village-morning",false)
	await shot("01-levels")
	_check(game._modals[-1] is CharacterScreen,"Choosing a concept continues through character naming")
	(game._modals[-1] as CharacterScreen).begin_requested.emit()
	while game._flow_busy:await process_frame
	await process_frame
	_check(game.inside_house() and game.area.id=="morning-bedroom","The new journey wakes inside the unique home")
	_check(game.view.villagers==null and game.area.props.size()==7 and game.area.prop("candle").is_empty(),"The first slice uses detailed furniture and adds no residents")
	_check(game.session.state.controls.is_empty(),"The first character has no movement keys yet")
	_check(SaveStore.read()==legacy,"Starting the village concept preserves the Kindle Hollow save byte-for-byte as data")
	_check(game._modals[-1] is VillageConversation,"A first-morning welcome precedes the lesson")
	_check(not game.hud.visible and not game.session.input_enabled,"Hotaru uses the same visual novel HUD/input contract as other speakers")
	_check((game._modals[-1] as VillageConversation).portrait.texture.resource_path.ends_with("hotaru-portrait.png"),"The shared dialogue scene uses Hotaru’s selected full-resolution portrait")
	_check((game._modals[-1] as VillageConversation).text.visible_characters!=-1,"Hotaru’s text reveals progressively like every other character")
	(game._modals[-1] as VillageConversation).reveal()
	await shot("02-waking")
	_finish_guided(game._modals[-1] as VillageConversation)
	var greeting:=game.movement_lesson as GreetingLesson
	_check(greeting!=null and not game.session.state.hotaru_greeted,"The guided chat opens Saying Hello automatically before the player can speak")
	game.view.hotaru._animate(0)
	var wing_angle: float=game.view.hotaru.wings[0].rotation.y
	game.view.hotaru._animate(.02)
	_check(not is_equal_approx(wing_angle,game.view.hotaru.wings[0].rotation.y) and HotaruFairy.ORB_RADIUS<.1,"The tiny light has articulated fluttering wings")
	_check(game.view.hotaru!=null and game.view.hotaru.orb!=null and game.view.hotaru.wings.size()==4,"A cute fairy follows the approved boy")
	greeting.message.text="Hello world"
	await greeting.preview()
	greeting.speak()
	_check(not game.session.state.hotaru_greeted and game.movement_lesson==greeting and game._modals.is_empty(),"An incomplete greeting stays in Saying Hello rather than starting First Steps")
	greeting.message.text="Hello, Hotaru!"
	await greeting.preview()
	_check(game.session.has_preview() and not game.session.state.hotaru_greeted and greeting.playback.visible,"Blocks compile print to real Python and show its execution before changing the room")
	_check(game.session.last_run.trace.any(func(event: Dictionary) -> bool:return event.has("command")),"The sandbox reports the actual print line and its recorded speech command")
	_check(greeting._speak.get_global_rect().end.y<game.size.y,"Greeting Speak stays accessible at gameplay size")
	await create_timer(.9).timeout
	_check(greeting._speech.text.contains("Hello, Hotaru!"),"Execution replay gives the preview a visible player voice")
	await shot("02-hello-test")
	greeting.select_mode("python")
	greeting.editor.text='def program(world):\n    print("Hi, Hotaru!")\n'
	await greeting.preview()
	_check(game.session.has_preview() and greeting.playback.visible and not greeting.playback.code.visible,"Handwritten Python uses the same voice preview with highlighted source")
	greeting.speak()
	_check(game.session.completed.has("say-hello") and not game.notebook_open and game._modals[-1] is VillageConversation,"A committed hello automatically begins Hotaru’s First Steps introduction")
	var first_steps:=game._modals[-1] as VillageConversation
	_check(first_steps.dialogue.is_guided() and first_steps.dialogue.topic=="movement" and first_steps.dialogue.history.all(func(entry: Dictionary) -> bool:return entry.speaker=="Hotaru"),"The next lesson begins without a topic menu or invented reply")
	first_steps.reveal()
	await shot("02-first-steps-chat")
	_check(game.session.undo_apply() and not game.session.state.hotaru_greeted and CompanionLesson.has_voice(game.session.state,game.session.completed),"Undo removes the utterance while keeping the learned ability to speak")
	_finish_guided(first_steps)
	var panel:=game.movement_lesson as MovementLesson
	_check(panel!=null and panel.mode=="blocks","Lesson one opens with four ready-made movement blocks")
	await shot("03-blocks")
	_check(panel.position.x>root.size.x*.5 and game.hud._objective_pill.global_position.x<60,"The global interface keeps code right and the translucent quest tracker left")
	await process_frame
	_check(panel.size.y<=game.size.y-30 and panel._apply.get_global_rect().end.y<game.size.y,"The compact drawer keeps the test bench and Apply on screen")
	_check(panel.test_window.get_parent()==game and not panel.is_ancestor_of(panel.test_window),"The larger preview is a foreground window outside the notebook")
	_check(panel.test_window.get_rect().end.x<panel.position.x and panel.test_window.get_rect().end.y<=game.size.y-20 and panel.demo.size.y>=140,"The separate test scene stays beside the notes and fits below the main play area")
	_check(is_equal_approx(game.view._view_shift_target,(panel.drawer_width+SideDrawer.MARGIN)/game.size.x*.5),"The foreground preview does not reserve additional camera space")
	await panel.test_section(0)
	_check(game.session.last_run.commands.size()==1 and not game.session.has_preview() and panel.demo.trials.size()==1,"The block arrow runs only its own event and cannot Apply a partial program")
	_check(panel.playback.visible and panel.playback.code.text.count("bind_move")==1,"Section testing reveals only the executed section's generated Python")
	for i: int in range(4):
		panel.direction_fields[i].select(i+1)
		panel.amount_fields[i].value=1
	panel._changed()
	await panel.preview()
	_check(game.session.has_preview() and game.session.state.controls.is_empty(),"Block programs preview without installing any keys")
	_check(panel._block_panels.all(func(block: PanelContainer) -> bool:return block.get_theme_stylebox("panel").border_color==Pal.GREEN),"Every successful event turns green after the test")
	await process_frame
	if DisplayServer.get_name()!="headless":
		var line_height: int=panel.playback.code.get_line_height()
		_check(panel.playback.code.size.y>=line_height*12,"The compact lesson shows at least twelve Python lines in the existing drawer")
	await shot("04-preview",95)
	panel._source_button.button_pressed=true
	panel._toggle_source()
	_check(panel.generated_editor.visible and not panel._blocks.visible and panel.generated_editor.text==game.session.source and game.session.has_preview(),"See Python reveals the exact tested source without invalidating its proposal")
	panel._source_button.button_pressed=false
	panel._toggle_source()
	var unchanged: Dictionary=game.session.state.duplicate(true)
	_check(panel.generated_editor.text.contains("y += 1") and game.session.source.contains("bind_move"),"Code-like blocks compile to executable Python arithmetic")
	_check(not game.session.input_enabled and game._modals.is_empty(),"The side notebook has no scrim and isolates keyboard tests from real walking")
	_check(panel.demo.trials.size()==4 and panel.demo.play_key("W"),"Both editors share a replayable 3D movement demonstration")
	_check(game.session.state==unchanged and MovementBindings.tried(game.session.state)==0,"Running the mini-room cannot move or award practice to the real character")
	panel.amount_fields[0].value=3
	panel._changed()
	await panel.preview()
	_check(not game.session.has_preview() and game.session.state==unchanged,"Oversized arithmetic runs in WASI but cannot be installed")
	_check(panel.demo.trials[0].delta==Vector2i(0,3) and not panel.demo.trials[0].ok,"The failed program still produces a bounded three-cell example")
	_check(panel._block_panels[0].get_theme_stylebox("panel").border_color==Pal.RED and panel._block_panels[1].get_theme_stylebox("panel").border_color==Pal.GREEN,"The incorrect block turns red while successful events remain green")
	await shot("04-overshoot",95)
	if DisplayServer.get_name()!="headless":
		root.grab_focus();panel.demo.grab_focus()
		_key(KEY_W,true)
		await create_timer(.08).timeout
		_key(KEY_W,false)
		_check(panel.demo.active_key=="W" and game.session.state==unchanged,"Keyboard events in the mini-room replay code without moving the real player")
	panel.amount_fields[0].value=1
	panel._changed()
	_check(panel.demo.trials.is_empty(),"Editing arithmetic clears stale example replays")
	_check(panel._block_results[0].text=="· Untested","Editing clears the old green/red verdicts")
	await panel.preview()
	panel.direction_fields[0].select(2);panel._changed()
	_check(not game.session.has_preview() and not game.session.apply_preview(),"Editing a block invalidates its old preview")
	panel.direction_fields[0].select(1);panel._changed()
	await panel.preview()
	panel.apply_bindings()
	_check(not panel._continue.disabled,"Applied movement exposes an explicit Continue to the room")
	_check(MovementBindings.mapped(game.session.state)==4 and MovementBindings.tried(game.session.state)==0,"Apply installs the exact four-key plan and awaits real practice")
	panel._undo.pressed.emit()
	_check(game.session.state.controls.is_empty() and not game.session.has_preview(),"Undo removes applied bindings and invalidates their preview")
	await panel.preview();panel.apply_bindings()
	panel.select_mode("python")
	panel.editor.text="def program(world):\n    world.controls.bind(\"F\", \"north\")\n"
	var kept: Dictionary=game.session.state.duplicate(true)
	await panel.preview()
	_check(not game.session.has_preview() and game.session.state==kept,"Invalid Python bindings explain an error without partial changes")
	panel.editor.replace_program("def program(world):\n    y = 0\n    y += 4\n    world.controls.bind_move(\"W\", 0, y)\n")
	await panel.preview()
	_check(not game.session.has_preview() and panel.demo.trials[0].delta==Vector2i(0,4),"Handwritten Python gets the same excessive-movement example as blocks")
	panel.editor.text="def program(world):\n    y += 1\n"
	await panel.preview()
	_check(panel.demo.trials.is_empty() and not game.session.has_preview(),"A real Python error clears the previous demonstration")
	panel.editor.text=MANUAL
	await panel.preview()
	_check(game.session.has_preview() and game.session.state.controls.W=="north","Real Python loops produce a proposal without changing applied keys")
	await shot("05-python")
	panel.demo.grab_focus()
	panel.apply_bindings()
	_check(game.session.state.controls.W=="east","Manual code can install a different legitimate key layout")
	await panel.preview()
	panel._continue.pressed.emit()
	_check(not game.notebook_open,"Continue returns directly to room practice")
	_check(not game.session.has_preview(),"Closing the lesson clears its proposal while preserving applied keys")
	game.session.set_physics_process(false)
	game._refresh_interaction()
	game.interact()
	_check(not game._modals.is_empty() and game._modals[-1] is VillageConversation,"F opens Hotaru’s ordinary visual novel conversation again")
	var chat:=game._modals[-1] as VillageConversation
	chat.reveal();chat.advance();chat.reveal()
	chat.choose("company");chat.reveal()
	chat.show_panel("history")
	_check(chat.dialogue.history.any(func(entry: Dictionary) -> bool:return entry.speaker=="You") and chat.mode=="history","Hotaru’s response choices are recorded in the shared history")
	chat.close()
	_check(game.hud.visible and game.session.input_enabled,"Leaving Hotaru’s dialogue restores the room and its input")
	await shot("06-bedroom")
	_check(not game.session.walk_to(Vector2i(6,1)),"Click walking cannot bypass the first movement lesson")
	for key: String in ["W","A","S","D"]:
		var dir: Vector2i=MovementBindings.direction(game.session.state.controls,key)
		if DisplayServer.get_name()=="headless":
			_check(game.session.request_step(dir,key),"The mapped key starts a validated grid step")
			game.session.advance_walk(LabWorld.STEP_SECONDS)
		else:
			root.grab_focus();game.surface.grab_focus()
			var before: Vector2i=game.session.player_cell()
			game.session.set_physics_process(true)
			await create_timer(.08).timeout
			_key(GameSession.BINDING_CODES[key],true)
			await create_timer(.08).timeout
			_key(GameSession.BINDING_CODES[key],false)
			await create_timer(.30).timeout
			game.session.set_physics_process(false)
			_check(game.session.player_cell()==before+dir,"An actual keyboard event follows the learner's custom mapping")
	_check(game.session.completed.has("first-steps"),"Trying all four mapped movements completes the first quest")
	game.session.reset_world()
	_check(MovementBindings.finished(game.session.state),"Resetting room objects preserves learned movement and practice")
	_check(game._modals.is_empty(),"The first quest completes gently without the old valley epilogue")
	game.session.state.memory={"morning":"my own room"}
	game.save_now()
	await game._return_to_title()
	await game.continue_game("village-morning")
	game.session.set_physics_process(false)
	_check(game.area.id=="morning-bedroom" and game.session.state.controls.W=="east" and game.session.completed.has("first-steps"),"Continue resumes this room, custom controls and its first quest")
	_check(game._dialogue_read.get("hotaru",[]).has("company:0"),"Hotaru’s read pages survive Continue for Skip read")
	_check(game.session.greeting_editor.get("python", "").contains("Hi, Hotaru!") and game.session.state.hotaru_greeted,"The independent greeting draft and voice survive travel and Continue")
	_check(game.session.movement_editor.get("python")==MANUAL,"The learner's Python draft survives mode switching and Continue")
	var restored_amounts: Array=game.session.movement_editor.get("amounts",[])
	_check(restored_amounts.size()==4 and restored_amounts.all(func(value: Variant) -> bool:return (value is int or value is float) and float(value)==1.0),"The independent arithmetic block draft survives the handwritten program and Continue")
	game._open_character("view",{})
	_check(_text(game._modals[-1],"Events & movement"),"The character profile uses this journey's home lesson")
	game._modals[-1].close()
	game.session.state.player=[6,1,0];game.view.sync_player(game.session.state)
	game.session.set_physics_process(true)
	_check(game.session.request_step(Vector2i(0,-1),"D") and game._flow_busy,"The learned key starts walking through the aligned frame")
	await create_timer(.08).timeout
	_check(game.session.player_cell()==Vector2i(6,1) and Vector2(game.view._player.position.x,-game.view._player.position.z).is_equal_approx(Vector2(6,1)),"Leaving fades from the sill without walking into a strip of floor or empty space")
	await shot("07-door-sill",1)
	while game._flow_busy:await process_frame
	_check(not game.inside_house(),"Walking through the frame transitions to the lane")
	game.session.set_physics_process(false)
	_check(game.area.id=="village-morning" and game.area.buildings.size()==3 and game.area.villagers.is_empty(),"The expanded village preserves the starting home and adds its civic landmark")
	_check(game.session.state.controls.W=="east" and MovementBindings.finished(game.session.state),"Custom controls follow the player outdoors")
	await shot("07-lane")
	if game.inside_house():
		_check(false,"Room movement completes before the outside doorway checks")
		game.queue_free();await process_frame
		quit(1)
		return
	var entrance: Vector2i=HouseInstances.door(game.area,"morning-home")
	var outside_corner: Vector2i=entrance+Vector2i(-1,0)
	game.session.prepare_travel()
	game.session.state.player=[outside_corner.x,outside_corner.y,0]
	game.view.sync_player(game.session.state)
	game.view.focus_on(Vector2(outside_corner),true)
	if DisplayServer.get_name()=="headless":
		_check(not game.session.request_step(Vector2i(0,1),"A"),"Walking into the reported front-wall bypass is refused")
	else:
		root.grab_focus();game.surface.grab_focus()
		game.session.set_physics_process(true)
		_key(KEY_A,true)
		await create_timer(.35).timeout
		_key(KEY_A,false)
		await create_timer(.1).timeout
		_check(game.session.player_cell()==outside_corner,"A held keyboard direction cannot walk through the cottage wall")
		game.session.set_physics_process(false)
	await shot("08-house-collision")
	var outward: Vector2i=HouseInstances.OUTWARD[game.area.building("morning-home").facing]
	var outer: Vector2i=entrance+outward
	_check(entrance==Vector2i(7,10),"Leaving the cottage lands one tile outside the old door cell")
	game.session.state.player=[outer.x,outer.y,0];game.view.sync_player(game.session.state)
	game.view.focus_on(Vector2(outer),true)
	for frame: int in range(3):await process_frame
	_check(game.session.request_step(-outward) and not game._flow_busy,"The approach to the landing is an ordinary step")
	game.session.advance_walk(1.0)
	_check(game.session.player_cell()==entrance and not game._flow_busy,"Standing outside the frame does not auto-enter")
	_check(game.session.request_step(-outward) and game._flow_busy,"Attempting to step into the frame opens the door")
	await create_timer(.12).timeout
	for frame: int in range(2):await process_frame
	var hinge:=game.view.building_node("morning-home").find_child("DoorHinge*",true,false) as Node3D
	_check(game.session.player_cell()==entrance and absf(hinge.rotation.y)>.01,"The leaf opens before the player can meet it")
	await shot("09-opening-on-landing",1)
	while game._flow_busy:await process_frame
	_check(game.inside_house() and game.area.id=="morning-bedroom","Returning home uses its bespoke room rather than a catalog cookie-cutter")
	_check(game.session.state.memory.get("morning")=="my own room","The unique home keeps its own state")
	await game._return_to_title()
	game._open_character("view",SaveStore.read("village-morning"))
	_check(_text(game._modals[-1],"Events & movement"),"The title character profile reads the saved journey rather than the background area")
	game._modals[-1].close()
	await game.continue_game("kindle-hollow")
	_check(game.area.id=="kindle-hollow" and game.session.state.lamps["landing-lamp"],"The original level and its previous progress remain available")
	game.queue_free();await process_frame
	SaveStore.delete();SaveStore.delete("village-morning")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	SaveStore.force_enabled=false
	if failures.is_empty():print("Village Morning: %d checks passed (pure boundaries, two editors, real WASI, lesson, rooms and isolated level saves)." % checks)
	else:
		for failure: String in failures:printerr("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)

func _pure() -> void:
	var result: Dictionary=AreaStore.read("morning-bedroom")
	_check(result.ok,"The authored bedroom parses: "+str(result.errors))
	if not result.ok:return
	var area: AreaDef=result.area
	var rules:=LabWorld.new(area)
	var state: Dictionary=rules.initial_state()
	for dir: Vector2i in LabWorld.DIRECTIONS:_check(rules.can_step(state,area.spawn,area.spawn+dir),"All first directions have clear floor beside the bed")
	var valid: Dictionary={"op":"bind_key","target":"player","key":"W","direction":"north"}
	for bad: Dictionary in [{"target":"camera"},{"key":"F"},{"key":1},{"direction":"forward"},{"direction":null},{"node_path":"root"}]:
		var command: Dictionary=valid.duplicate(true);command.merge(bad,true)
		var before: Dictionary=state.duplicate(true)
		_check(not rules.propose(state,[valid,command],{}).ok and state==before,"Malformed binding batches reject atomically")
	var legacy:=LabWorld.new(AreaStore.load_area("kindle-hollow"))
	_check(not legacy.propose(legacy.initial_state(),[valid],{}).ok,"The old level's input behavior cannot be reprogrammed by this new capability")
	var plan: Dictionary=rules.propose(state,[valid],{})
	_check(plan.ok and state.controls.is_empty(),"A valid binding remains a detached proposal")
	var unbound: Dictionary=rules.move(plan.state,Vector2i(0,1))
	_check(unbound.ok and MovementBindings.tried(unbound.state)==0,"Ordinary routes do not earn bound-key practice")
	_check(not rules.move(plan.state,Vector2i(1,0),"W").ok,"A forged key/direction pairing is refused")
	var malformed: Dictionary=plan.state.duplicate(true);malformed.controls={"ESCAPE":"north"}
	_check(rules.normalize_state(malformed).is_empty(),"Saved bindings obey the same bounded key vocabulary")
	_check(not MovementBindings.block_source(["W","W","S","D"],["north","west","south","east"]).ok,"Guided blocks flag duplicate keys before running")
	for delta: Vector2i in LabWorld.DIRECTIONS:
		var command: Dictionary={"op":"bind_key","target":"player","key":"W","delta":[delta.x,delta.y]}
		var proposal: Dictionary=rules.propose(state,[command],{})
		_check(proposal.ok and MovementBindings.direction(proposal.state.controls,"W")==delta,"Unit x/y arithmetic installs the same canonical input map")
	for amount: int in [0,2,3,4]:
		var command: Dictionary={"op":"bind_key","target":"player","key":"W","delta":[0,amount]}
		var trace: Array[Dictionary]=MovementBindings.demonstrations(area,state,[command])
		_check(not rules.propose(state,[valid,command],{}).ok and state.controls.is_empty(),"Zero/excessive movement rejects the whole batch")
		_check(trace.size()==1 and trace[0].delta==Vector2i(0,amount) and not trace[0].ok,"Failed whole amounts retain safe diagnostic traces")
	for bad: Variant in [[true,0],[1.5,0],[1000000,0],[0],["x",1],null]:
		var command: Dictionary={"op":"bind_key","target":"player","key":"W","delta":bad}
		_check(not rules.propose(state,[command],{}).ok and MovementBindings.demonstrations(area,state,[command]).is_empty(),"Malformed or unbounded movement cannot reach either the player or the test viewport")
	var diagonal: Dictionary={"op":"bind_key","target":"player","key":"W","delta":[1,1]}
	_check(not rules.propose(state,[diagonal],{}).ok and MovementBindings.demonstrations(area,state,[diagonal])[0].path.size()==1,"A diagonal example explains the fault without crossing a blocked grid passage")
	var rebound: Array[Dictionary]=MovementBindings.demonstrations(area,state,[valid,{"op":"bind_key","target":"player","key":"W","delta":[1,0]}])
	_check(rebound.size()==1 and rebound[0].delta==Vector2i(1,0),"The demonstration uses the last valid binding for a repeated key")

func _finish_guided(chat: VillageConversation) -> void:
	var pages: int=0
	while not chat.dialogue.closed and pages<20:
		chat.reveal()
		_check(chat.dialogue.current().choices.is_empty() and not chat.choices.visible and not chat.next_button.disabled,"Guided pages offer only Continue, with no spoken choices")
		chat.next_button.pressed.emit()
		pages+=1
	_check(chat.dialogue.closed and game.notebook_open and game._modals.is_empty(),"Finishing the chat automatically opens its Field Notes")

func _buttons(node: Node,text: String) -> Array[Button]:
	var found: Array[Button]=[]
	if node is Button and node.text==text:found.append(node)
	for child: Node in node.get_children():found.append_array(_buttons(child,text))
	return found
func _text(node: Node,value: String) -> bool:
	if node is Label and node.text==value:return true
	for child: Node in node.get_children():
		if _text(child,value):return true
	return false
func _check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
func _key(key: Key,pressed: bool) -> void:
	var event:=InputEventKey.new()
	event.keycode=key;event.physical_keycode=key;event.pressed=pressed
	Input.parse_input_event(event)
func shot(name: String,frames: int=20) -> void:
	if output=="" or DisplayServer.get_name()=="headless":return
	for frame: int in range(frames):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
