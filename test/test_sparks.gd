extends SceneTree
## The Sparks & Machines journey: a separate third journey whose first area is the workshop loft. It must leave
## Kindle Hollow and Village Morning exactly as they were (their catalog entries, HUD, fairy and saves).
var checks: int=0
var failures: Array[String]=[]
var game: Game
var output: String=""

func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	go.call_deferred()
func go() -> void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():output=args[0]
	_catalog()
	_rules()
	await _journey()
	if failures.is_empty():
		print("Sparks & Machines journey: %d checks passed." % checks)
		quit(0)
	else:
		for failure: String in failures:printerr("FAIL: ",failure)
		quit(1)


func _catalog() -> void:
	var entries: Array[Dictionary]=LevelStore.entries()
	_check(entries.map(func(entry: Dictionary) -> String: return str(entry.id))==["kindle-hollow","village-morning","sparks-and-machines"],"The new journey is appended after the two existing ones")
	for entry: Dictionary in entries.slice(0,2):
		_check(entry.archived and entry.keys().all(func(key: String) -> bool: return key in ["id","title","subtitle","description","area","opening_house","archived"]),"An archived journey retains its original definition: "+str(entry.id))
	var spec: Dictionary=LevelStore.entry("sparks-and-machines")
	_check(spec.area=="workshop-loft" and spec.opening_house=="" and spec.look=="paper" and spec.journal=="workshop" and spec.build==false,"The journey starts in its own loft with the paper look and no build mode")
	var source: Dictionary=AreaStore.read_source("workshop-loft")
	_check(source.ok,"The loft document, its quests and catalog references load: "+str(source.get("errors",[])))
	var area: AreaDef=source.get("area") if source.ok else null
	if area==null:return
	_check(area.width==14 and area.height==12 and area.voice_lesson and not area.movement_lesson,"The loft is 14 by 12, over the whole workshop, with the hello lesson but not the movement-key lesson")
	_check(area.interior.style=="workshop-loft" and area.interior.shell=="loft-shell","The loft names its own room style and Blender shell")
	_check(area.quest("say-hello").goal.type=="hotaru_greeted","The loft's first job is waking Hotaru")
	var story: Dictionary=JourneyStory.read(str(spec.story))
	_check((story.opening.pages as Array).size()==3 and (story.opening.note.lines as Array).size()==3 and story.tickets.has("say-hello"),"The story file holds the opening pages, Nell's note and ticket numbers")
	_check(not JSON.stringify(story).to_lower().contains("eleven") and str(story.opening.note.lines[1]).contains("week") and str(story.opening.note.lines[2]).contains("terminal"),"Hotaru has been dozing this week; the terminal rings her bell rather than repairing an ancient failure")
	var shell: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/world-catalog.json")).assets.get("loft-shell",{})
	_check(shell.get("authority")=="blender" and FileAccess.file_exists("res://"+str(shell.get("runtime",""))),"The loft shell is an adopted, exported Blender model")
	_check(HouseInstances.frame_posts(area).size()==2 and is_equal_approx(HouseInstances.frame_posts(area)[0].get_center().x,6.32) and is_equal_approx(HouseInstances.frame_posts(area)[1].get_center().x,7.68),"The stairwell's collision posts stand where the shell's top newel posts are")


func _rules() -> void:
	var loft: AreaDef=AreaStore.load_area("workshop-loft")
	var rules:=LabWorld.new(loft)
	var state: Dictionary=rules.initial_state()
	_check(rules.snapshot(state).companion.enabled and not rules.snapshot(state).controls.enabled,"In the loft, print speaks to Hotaru while the keys work as usual")
	var changes: Array[String]=[]
	_check(CompanionLesson.apply(loft,state,{"op":"say","target":"hotaru","text":"Hello, Hotaru!"},changes)=="" and state.hotaru_greeted,"A greeting with her name is accepted in the loft")
	var hollow: AreaDef=AreaStore.load_area("kindle-hollow")
	var other: Dictionary=LabWorld.new(hollow).initial_state()
	_check(CompanionLesson.apply(hollow,other,{"op":"say","target":"hotaru","text":"Hello, Hotaru!"},changes)=="Hotaru's voice lesson belongs to Village Morning." and not LabWorld.new(hollow).snapshot(other).companion.enabled,"Kindle Hollow still refuses speech with its original message")
	var start: Vector2i=loft.spawn
	_check(rules.is_walkable(state,start) and rules.is_walkable(state,Vector2i(7,5)),"The spawn and the top stair cell are walkable")
	_check(start == Vector2i(6,8) and not rules.find_path(state, Vector2i(1,8), start).is_empty(), "The traveller begins by the bed with a safe route to the desk")
	_check(not rules.read_inspection(state, "nell-note").ok, "Nell’s note cannot be read from across the room")
	var near: Dictionary = state.duplicate(true)
	near.player = [1,10,0]
	var found: Dictionary = rules.read_inspection(near, "nell-note")
	_check(found.ok and found.state.inspections_read.has("nell-note") and not near.inspections_read.has("nell-note"), "Reading the reachable note creates a saved discovery without mutating the old state")
	_check(not rules.find_path(state,Vector2i(7,6),start).is_empty() and not rules.find_path(state,Vector2i(3,9),start).is_empty(),"The furnished loft keeps routes from the spawn to the stairwell and desk approach")
	_check(not rules.can_stand(state,Vector2(6.32,4.0)) and not rules.can_stand(state,Vector2(7.68,4.0)) and not rules.is_walkable(state,Vector2i(7,4)),"The stairwell's railings and its open drop block like the drawn ones")
	var top: Dictionary = state.duplicate(true)
	top.player = [7,5,0]
	_check(not rules.move(top,Vector2i.LEFT).ok and not rules.move(top,Vector2i.RIGHT).ok,"The top tread is left only forward, through the open end of the rail")
	_check(not rules.is_walkable(state,Vector2i(6,10)) and not rules.is_walkable(state,Vector2i(1,9)) and not rules.is_walkable(state,Vector2i(4,10)),"The bed, desk and unpacked case block walking through the visible furniture")
	_check(rules.is_walkable(state,Vector2i(5,7)) and not rules.find_path(state,start,Vector2i(8,9)).is_empty(),"The rug is walkable and the bedside approach stays reachable")
	for item: String in ["window-seat","wardrobe","rocking-chair","floor-plant","corner-plant","street-window-life"]:
		_check((loft.interior.assets as Array).any(func(a: Dictionary) -> bool: return a.id == item),"The loft's new space is furnished: "+item)
	var old_save: Dictionary=state.duplicate(true)
	old_save.player=[6,10,0]
	old_save.memory={"first_page":true}
	old_save.hotaru_greeted=true
	old_save.spoken="Hello, Hotaru!"
	var recovered: Dictionary=rules.normalize_state(old_save)
	_check(not recovered.is_empty() and recovered.player==[start.x,start.y,0] and recovered.memory.first_page and recovered.hotaru_greeted and recovered.spoken==old_save.spoken,"An older empty-loft save inside the new bed recovers its position without losing memory or greeting progress")
	var previous: float = INF
	var smooth_descent: bool = true
	for step: int in range(101):
		var point := Vector2(7, 6.2 - float(step) * 1.3 / 100.0)
		var support: float = WalkingSurface.height(loft,point,[])
		smooth_descent = smooth_descent and support <= previous + .0001 and (previous == INF or previous - support < .04)
		var tread: float = .04 if point.y >= 5.86 else (-.14 if point.y >= 5.53 else (-.29 if point.y >= 5.2 else -.44))
		smooth_descent = smooth_descent and support >= tread + WalkingSurface.CLEARANCE - .0001
		previous = support
	_check(smooth_descent,"The loft stair support descends smoothly along every tread")
	_check(previous < -.3 and WalkingSurface.height(loft,Vector2(9,5),[]) > 0,"Stair feet descend below the floor while the floor around the stairwell stays level")
	var source: Dictionary = AreaStore.read_source("workshop-loft")
	var bad: Dictionary = source.document.duplicate(true)
	bad.interior.stairwell.treads=[-.14,-.44]
	_check(not AreaDef.parse(bad,source.assets,source.quests).ok,"A reversed stair profile is refused by the area parser")


func _journey() -> void:
	SaveStore.save_path="user://test_sparks_"+str(OS.get_process_id())+".json"
	SaveStore.profile_path="user://test_sparks_profile_"+str(OS.get_process_id())+".json"
	SaveStore.force_enabled=true
	for level: String in ["kindle-hollow","village-morning","sparks-and-machines"]:SaveStore.delete(level)
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game("kindle-hollow")
	game.save_now()
	var hollow_bytes: PackedByteArray=FileAccess.get_file_as_bytes(SaveStore.level_path("kindle-hollow"))
	_check(not (game.hud is PaperHud) and is_instance_valid(game.view.hotaru),"Kindle Hollow keeps the default HUD and the fairy")
	await game._return_to_title()
	game._new_game_flow()
	_check(game._modals[-1] is CharacterScreen and LevelStore.available_entries().size()==1,"New game enters the Sparks character flow directly")
	await shot("01-levels")
	var screen:=game._modals[-1] as CharacterScreen
	_check(screen!=null and _text(screen,"LODGER IN NELL'S LOFT"),"The character screen speaks of Nell's loft")
	screen.begin_requested.emit()
	while game._flow_busy:await process_frame
	await process_frame
	_check(game.area.id=="workshop-loft" and not game.inside_house() and game._level_id=="sparks-and-machines","The journey starts in the loft itself, with no outside area")
	_check(game.hud is PaperHud and game.hud.visible and (game.hud as PaperHud).ticket.number.text=="JOB NO. 0","The paper HUD pins JOB No. 0")
	_check(game.view.hotaru==null and game.view.stage is WorkshopLoftStage and game.view.stage.replaces_companion(),"The loft's stage replaces the fairy")
	_check(is_equal_approx(game.view.zoom(),14.5),"The loft uses its own indoor zoom")
	_check(game._modals[-1] is OpeningCard,"The opening card comes first")
	await shot("02-opening")
	var card:=game._modals[-1] as OpeningCard
	for page: int in range(3):card._advance()
	await process_frame
	_check(game._modals.is_empty() and not game.notebook_open and game.session.player_cell()==Vector2i(6,8),"The opening leaves the traveller beside the bed in the live room")
	_zoom()
	_markers()
	_reach()
	_check(game.session.request_step(Vector2i.LEFT), "A step can start beside the bed")
	var tap := InputEventKey.new()
	tap.keycode = KEY_S
	tap.pressed = true
	game.session._input(tap)
	tap.pressed = false
	game.session._input(tap)
	for tick: int in range(12): game.session.advance_walk(1.0/60.0)
	_check(game.session.is_walking(), "The faster step is still interpolating after twelve physics ticks")
	game.session.advance_walk(1.0/60.0)
	_check(not game.session.is_walking(), "The faster step completes on its thirteenth physics tick")
	_check(game.session._take_buffered_step(), "A quick key tap during a step is kept for the next step")
	game.session.advance_walk(LabWorld.STEP_SECONDS)
	_check(game.session.player_cell()==Vector2i(5,7) and not game.session._take_buffered_step(), "The buffered tap moves once and is consumed")
	game.session.state.player = [6,8,0]
	game.view.sync_player(game.session.state)
	var note_object: Node3D = game.view.building_node("nell-note")
	_check(note_object != null and note_object.visible, "Nell’s note is a visible separate object on the desk")
	game.open_notebook()
	_check(not game.notebook_open, "Field Notes waits for the note and terminal during the first introduction")
	await shot("03-loft-before-note")
	var tablet_object: Node3D = game.view.building_node("bed-tablet")
	_check(tablet_object != null and tablet_object.visible and game.session.state.items.is_empty(), "Nell’s tablet is lying on the bed when the journey begins, and the traveller carries nothing")
	game._refresh_interaction()
	_check(game._interaction.get("kind", "") != "pickup" and game._pick_workshop_object(game.view.camera.unproject_position(BuildOverlay.world_aabb(tablet_object).get_center())) != "tablet", "The tablet is part of the room until Hotaru has sent the traveller to it")
	var note_point: Vector2 = game.view.camera.unproject_position(BuildOverlay.world_aabb(note_object).get_center())
	_check(game._pick_workshop_object(note_point)=="nell-note", "The visible note is a clickable world object")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = note_point * game.surface.size / Vector2(game.world_viewport.size)
	game._on_world_input(click)
	_check(game._pending_room_target=="nell-note" and not game.session._route.is_empty(), "Clicking the note plans a route to the desk")
	var cancel_tap := InputEventKey.new()
	cancel_tap.keycode = KEY_W
	cancel_tap.pressed = true
	game._unhandled_key_input(cancel_tap)
	_check(game._pending_room_target=="", "Manual movement cancels the automatic desk interaction")
	game._on_world_input(click)
	var route: Array[Vector2i] = game.session._route.duplicate()
	game.session._cancel_route()
	for cell: Vector2i in route:
		game.session.request_step(cell-game.session.player_cell())
		game.session.advance_walk(LabWorld.STEP_SECONDS)
	game._process(0)
	_check(game._modals.size()==1 and game._modals[0] is NellNote, "Arriving opens Nell’s actual note")
	var note := game._modals[0] as NellNote
	await shot("03-note")
	note.close()
	_check(note_object.visible and not game.session.state.inspections_read.has("nell-note"), "Leaving without reading keeps the note on the desk")
	game.interact()
	note = game._modals[0] as NellNote
	(_buttons(note, "Put the note away")[0] as Button).pressed.emit()
	_check(game.session.state.inspections_read.has("nell-note") and not note_object.visible, "Putting away the read note updates the saved room and removes the paper")
	game.open_notebook()
	_check(not game.notebook_open, "The first lesson still needs the desk terminal")
	var terminal_point: Vector2 = game.view.camera.unproject_position(BuildOverlay.world_aabb(game.view.building_node("tape-reader")).get_center())
	click.position = terminal_point * game.surface.size / Vector2(game.world_viewport.size)
	game._on_world_input(click)
	var console_route: Array[Vector2i] = game.session._route.duplicate()
	game.session._cancel_route()
	for cell: Vector2i in console_route:
		game.session.request_step(cell-game.session.player_cell())
		game.session.advance_walk(LabWorld.STEP_SECONDS)
	game._process(0)
	_check(game.session.player_cell() == Vector2i(1,8), "The traveller walks from the note to the terminal keyboard")
	_check(game.notebook_open and game.movement_lesson is WorkshopJournal and game.session.state.inspections_read.has("desk-terminal"), "Clicking the terminal opens the first working page")
	_check(game.session.state.terminal_links == ["desk-terminal"] and game.view.terminal_display != null, "Using the loft computer creates its saved zone link")
	await _greeting()
	game.close_notebook(true)
	await process_frame
	await shot("08-furnished-loft")
	await _tablet()
	await _stairs()
	game.open_build()
	_check(not game.builder.active,"Build mode stays closed in the loft")
	game._on_doorway_requested("")
	_check(game.area.id=="workshop-loft" and not game.inside_house(),"The stair hatch answers with a line instead of travelling")
	for repeat: int in range(40):
		game._stairs_said=-10.0
		game._on_doorway_requested("")
	var stairs_text: String=game._story.stairs.awake
	var copies: int=0
	for child: Node in game.hud._toast_box.get_children():
		if child.get_meta("feedback_text","")==stairs_text:copies+=1
	_check(copies==1,"Forty repeated refusals keep exactly one stairs message")
	await shot("04-loft")
	game.save_now()
	_check(SaveStore.has_save("sparks-and-machines") and FileAccess.get_file_as_bytes(SaveStore.level_path("kindle-hollow"))==hollow_bytes,"The journey saves to its own file; Kindle Hollow's save is untouched")
	await game._return_to_title()
	_check(game.hud is PaperHud and not game.hud.visible,"The title retains Sparks presentation with the play HUD hidden")
	await game.continue_game("sparks-and-machines")
	_check(game.area.id=="workshop-loft" and game.hud is PaperHud and game._modals.is_empty(),"Continue resumes in the loft without replaying the opening")
	_check((game.view.stage as WorkshopLoftStage).awake,"Continue restores Hotaru's committed awake state")
	var legacy_save: Dictionary = game.session.to_save()
	legacy_save.state.erase("terminal_links")
	legacy_save.state.erase("items")
	legacy_save.area_version = 6
	game.session.begin(game.area, game.view, legacy_save)
	_check(game.session.state.terminal_links.has("desk-terminal"), "A pre-terminal loft save keeps its earned code access and greeting")
	_check(game.session.state.items == ["field-tablet"], "A save from before items, already past the greeting, is handed the tablet")
	var reset_world_state: Dictionary = game.session.state.duplicate(true)
	game.session.reset_world()
	_check(game.session.state.items == reset_world_state.items, "Resetting the room keeps what the traveller carries")
	_check(game.session.state.inspections_read.has("nell-note") and not game.view.building_node("nell-note").visible and game._dialogue_read.get("nell-note", []).has("read"), "Continue keeps the note read and its physical paper put away")
	game.open_workshop_log()
	_check(game._modals[0] is WorkshopLog and _text(game._modals[0], "Lodger"), "The read note is kept in the story log")
	await shot("16-story-log")
	(game._modals[0] as WorkshopLog).close()
	game.open_journal()
	_check(game._modals.size()==1 and game._modals[0] is WorkshopJobLedger, "The pinned job opens the reached jobs book")
	_check(not _text(game._modals[0], "The morning round"), "The job book does not reveal work in an unvisited room")
	await shot("15-job-book")
	(game._modals[0] as WorkshopJobLedger).close()
	await _window_steady()
	game.open_notebook()
	_check(game.movement_lesson is WorkshopJournal and game.movement_lesson.editor.text.contains("Hello, Hotaru!") and not (game.movement_lesson as WorkshopJournal)._in_conversation,"After the waking introduction, Field Notes anywhere opens the plain open page with the saved Python, without replaying the introduction")
	game.close_notebook(true)
	await game._return_to_title()
	await game.start_new_game("village-morning")
	while game._flow_busy:await process_frame
	_check(not (game.hud is PaperHud) and is_instance_valid(game.view.hotaru) and game.view.stage==null,"Village Morning still has the default HUD and the fairy")
	_check(game.view.marker_style == "" and game.view._route_material(false) != null, "Village Morning keeps its original route and job marks")
	game.view.show_route([Vector2i(5,5), Vector2i(6,5)])
	_check(game.view._route_visual.get_child_count() == 2 and (game.view._route_visual.get_child(0) as MeshInstance3D).mesh is BoxMesh, "Its route is still the square gold tiles")
	for level: String in ["kindle-hollow","village-morning","sparks-and-machines"]:SaveStore.delete(level)
	game.queue_free()
	await process_frame
	await process_frame


func _greeting() -> void:
	var notes:=game.movement_lesson as WorkshopJournal
	if notes==null:return
	var stage:=game.view.stage as WorkshopLoftStage
	_check(not stage.awake,"Hotaru begins with a genuinely dark window")
	_check(notes.mode=="blocks" and notes.message.text=="Hello", "The first page starts with an editable message block")
	await shot("09-blocks")
	notes.message.text = "Hello, Mira!"
	await notes.preview()
	_check(game.session.has_preview() and game.session.source.contains('print("Hello, Mira!")') and stage.speech_text=="Hello, Mira!" and not stage.awake, "Blocks run real Python and ghost-print a different name")
	notes.message.text = "Hello, Hotaru!"
	await notes.preview()
	_check(game.session.has_preview() and not stage.awake, "A correct block greeting is still a preview until Speak")
	notes.select_mode("python")
	_check(notes.editor.text.contains('Hello, Hotaru!') and not game.session.has_preview(), "Python reveals the block’s code and switching modes clears the old test")
	await shot("09-first-notes")
	notes.editor.text='def program(world):\n    print("Hello"\n'
	await notes.preview()
	_check(not game.session.has_preview() and notes._speak.disabled and notes._status.text.contains("Line"),"A real Python syntax error names its line and cannot be spoken")
	var draft: String = notes.editor.text
	notes.select_mode("blocks")
	notes.message.text = "Hello, Rowan!"
	notes.select_mode("python")
	_check(notes.editor.text == draft, "A custom Python draft survives a trip through the block view")
	await notes.preview()
	_check(not stage.awake and not game.session.has_preview(),"Repeating an invalid program keeps one current error result")
	await shot("05-code-error")
	# Keep the real speech clock still during screenshot frames; explicitly step it below.
	stage.set_process(false)
	notes.editor.text='def program(world):\n    name = "Mira"\n    print("Hello, " + name + "!")\n    name = "Rowan"\n    print("Good morning, " + name + ".")\n'
	await notes.preview()
	_check(game.session.has_preview() and stage.output_is_preview and not stage.awake,"A successful test shows provisional screen output without waking Hotaru")
	_check((game.view.terminal_display.displays["desk-terminal"].text as Label3D).text.contains("TEST OUTPUT"), "The real test output appears on the computer screen")
	_check(stage.speech_preview and stage.speech_text=="Hello, Mira!" and stage.speech_characters==0,"A wrong name still ghost-types the exact real Python output beside the player")
	stage._process(.105)
	_check(stage.speech_characters>0 and stage.speech_characters<stage.speech_text.length(),"The world bubble types progressively instead of appearing all at once")
	stage.advance_speech()
	await shot("10-ghost-wrong-name")
	stage.advance_speech()
	_check(stage.speech_text=="Good morning, Rowan." and not stage.awake,"Multiple print calls appear in order without waking Hotaru for other names")
	stage.set_process(true)
	notes.playback.replay()
	_check(stage.speech_text=="Hello, Mira!" and stage.speech_characters==0,"Replay restarts the same ghost words using executed output")
	notes.speak()
	_check(not stage.awake and not game.session.completed.has("say-hello"),"A greeting without her name prints but leaves Hotaru asleep")
	_check(not stage.speech_preview and stage.speech_text=="Hello, Mira!","Speak replaces the ghost with the committed words")
	notes.editor.text='def program(world):\n    print("Hello, Hotaru!")\n'
	await notes.preview()
	_check(game.session.has_preview() and not stage.awake,"The correct greeting remains a proposal until Speak")
	notes.editor.text+='    # My first page\n'
	notes.speak()
	_check(not game.session.has_preview() and notes._speak.disabled and not stage.output_is_preview and stage.speech_text=="","Editing invalidates Speak, the provisional screen output and world speech")
	_check(not stage.awake,"A stale greeting cannot wake Hotaru")
	await notes.preview()
	stage.advance_speech()
	await shot("06-test-tape")
	notes.speak()
	_check(game.session.state.hotaru_greeted and game.session.completed.has("say-hello") and stage.awake and not stage.output_is_preview,"Speak commits the tested greeting, wakes Hotaru and completes the job")
	_check(notes._output.text.contains("Hello, Hotaru!") and notes._status.text.contains("Morning"),"The journal keeps the real output and Hotaru's ordinary morning response")
	for frame: int in range(3):await process_frame
	_check(game._modals.size()==1 and game._modals[0] is WorkshopScene,"Waking opens a portrait story conversation outside the code drawer")
	var waking:=game._modals[0] as WorkshopScene
	_check(not game.notebook_open and waking._portrait.texture!=null,"The waking avatar leaves the room visible and the editor closes cleanly")
	waking._layout()
	_check(waking._player_portrait.texture != null and waking._portrait.flip_h and waking._player_portrait.position.x > waking._portrait.position.x, "Hotaru and the traveller have opposing portrait positions")
	for n: int in range(4):waking.advance()
	_check(waking._choices.visible and waking._choices.get_child_count()==3,"Hotaru's greeting keeps all three authored replies")
	await shot("11-waking-choices")
	waking._choose(waking._page.choices[1])
	_check(waking._page.speaker=="player" and waking._text.text==WorkshopJournal.REPLIES[1],"A chosen reply is shown as the player's own line")
	_check(waking._player_portrait.modulate == Color.WHITE and waking._portrait.modulate.r < 1.0, "The speaker’s portrait is highlighted without making the other transparent")
	await shot("12-hotaru-answer")
	var pickup_cue: bool = false
	for n: int in range(48):
		if waking.is_queued_for_deletion():break
		if waking._choices.visible:
			pickup_cue = pickup_cue or str(waking._page.text).contains("something on the quilt")
			waking._choose(waking._page.choices[0])
		else: waking.advance()
	_check(pickup_cue, "Hotaru names what Nell left on the quilt before the conversation ends")
	_check(game._dialogue_read.get("loft-waking",[]).has("introduced"),"The finished waking story is saved separately from program state")
	game._process(0)
	_check(game.view.building_node("hand-terminal") == null and game.view.building_node("bed-tablet").visible and game.session.state.items.is_empty(), "The old hand console is gone and the slate still waits on the bed")
	game._open_workshop_journal(true)
	notes=game.movement_lesson as WorkshopJournal
	_check(not notes._in_conversation and notes._writing.visible and not notes._run.disabled,"The original page stays editable after the story conversation")
	await notes.preview()
	_check(stage.speech_preview and not stage.speech_text.is_empty(),"A repeat test after the introduction still shows a fresh ghost print")
	notes.stop()
	_check(stage.speech_text.is_empty() and not game.session.has_preview(),"Closing the page cancels its speech and proposal")


## F is arm's length: far from Hotaru it offers nothing, beside her it offers to talk.
func _reach() -> void:
	game.session.state.player = [8,2,0]
	game.view.sync_player(game.session.state)
	game._refresh_interaction()
	_check(game.view.companion_present() and game._interaction.get("kind", "") != "talk", "From across the loft F does not offer to talk to Hotaru")
	game.session.state.player = [1,4,0]
	game.view.sync_player(game.session.state)
	game._refresh_interaction()
	_check(game._interaction.get("kind", "") == "talk" and game._interaction.id == "hotaru", "Standing by her shelf F offers to talk to Hotaru")
	game.session.state.player = [6,8,0]
	game.view.sync_player(game.session.state)
	game._refresh_interaction()

## Every story page, in every scene, is drawn in one window of one size and place; choices sit inside it on the right.
func _window_steady() -> void:
	var seen: Dictionary = {}
	var total: int = 0
	for id: String in (game._story.scenes as Dictionary).keys():
		if not game._modals.is_empty(): break
		game._show_workshop_scene(id)
		if game._modals.is_empty(): continue
		var scene := game._modals[-1] as WorkshopScene
		for step: int in range(60):
			if scene.is_queued_for_deletion(): break
			scene.advance()
			scene._layout()
			total += 1
			seen[str([scene.card.position, scene.card.size])] = true
			_check(absf(scene.card.position.x + scene.card.size.x - (scene.size.x - WorkshopScene.EDGE_MARGIN)) < 1.0, "The story window runs to the right margin: " + id)
			_check(scene.card.get_global_rect().encloses(Rect2(scene._text_box.global_position, scene._text_box.size)), "The words sit inside the window: " + id)
			if scene._choices.visible:
				var inside: Rect2 = Rect2(scene._choices.global_position, scene._choices.size)
				_check(scene.card.get_global_rect().encloses(inside) and inside.position.x > scene._text_box.global_position.x + scene._text_box.size.x - 1.0, "Choices are buttons inside the window, to the right of the words: " + id)
				scene._choose(scene._page.choices[0])
				scene._layout()
				seen[str([scene.card.position, scene.card.size])] = true
		if not scene.is_queued_for_deletion(): scene.close()
		await process_frame
		_check(game._modals.is_empty(), "The scene closes cleanly: " + id)
	_check(total > 30 and seen.size() == 1, "All %d story pages are drawn in one window of one size and place (%d found)" % [total, seen.size()])
	_check(game.hud._controls == null, "The Sparks HUD keeps the lower right clear: no controls hint under the story window")

## The paper journey draws its route and destinations with round outlined marks, and its job mark from sparks.
func _markers() -> void:
	_check(game.view.marker_style == "paper", "The Sparks journey asks for the paper marker style")
	game.view.show_route([Vector2i(5,5), Vector2i(6,5), Vector2i(7,5)])
	var route: Node3D = game.view._route_visual
	var dots: Array[MeshInstance3D] = []
	for child: Node in route.get_children(): dots.append(child as MeshInstance3D)
	_check(dots.size() == 3 and dots.all(func(dot: MeshInstance3D) -> bool: return dot.mesh is QuadMesh and dot.material_override is ShaderMaterial), "Each step is a round marker drawn from a distance field, not a square block")
	_check((dots[2].mesh as QuadMesh).size.x > (dots[0].mesh as QuadMesh).size.x * 1.5, "The last cell of a route is a larger ring")
	game.view.show_route([])
	_check(route.get_child_count() == 0, "Clearing the route removes every marker")
	var note: Node3D = game.view.building_node("nell-note")
	game.view.set_target_highlight("nell-note")
	var lit: bool = false
	for mesh: Node in note.find_children("*", "MeshInstance3D", true, false):
		lit = lit or (mesh.name != &"IllustratedOutline" and (mesh as MeshInstance3D).material_overlay != null)
	_check(lit, "The thing the traveller is heading for is lit")
	game.view.set_target_highlight("")
	var still_lit: bool = false
	for mesh: Node in note.find_children("*", "MeshInstance3D", true, false): still_lit = still_lit or (mesh as MeshInstance3D).material_overlay != null
	_check(not still_lit, "The light goes out when the walk is over")
	_check(game.view._quest_marker.get_node_or_null("Dial") != null and game.view._motes.size() == 6 and game.view._quest_marker.get_node_or_null("Beam") == null, "A job is marked by a brass dial and rising sparks rather than a tiled ring and a beam")

## The wheel moves the room's own zoom in even steps from where it already is.
func _zoom() -> void:
	var authored: float = 14.5
	var setting: float = float(game.settings.get_value("zoom"))
	var wheel := InputEventMouseButton.new()
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	game._on_world_input(wheel)
	_check(is_equal_approx(game.view.zoom(), authored / game.ROOM_ZOOM_NOTCH), "The first notch out moves one even step from the room's own zoom instead of jumping to a stored setting")
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	game._on_world_input(wheel)
	_check(is_equal_approx(game.view.zoom(), authored), "A notch in undoes a notch out exactly")
	wheel.factor = .25
	game._on_world_input(wheel)
	var small: float = authored * pow(game.ROOM_ZOOM_NOTCH, .25)
	_check(is_equal_approx(game.view.zoom(), small), "A fine-scrolling wheel reports a fraction of a notch and moves a fraction of the step")
	wheel.factor = 1.0
	for notch: int in range(60): game._on_world_input(wheel)
	_check(is_equal_approx(game._room_zoom_scale, game.ROOM_ZOOM_RANGE.x) and game.view.zoom() >= 7.0 and game.view.zoom() <= authored * game.ROOM_ZOOM_RANGE.y, "Zooming all the way in stops at the closest allowed view")
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	for notch: int in range(120): game._on_world_input(wheel)
	_check(is_equal_approx(game._room_zoom_scale, game.ROOM_ZOOM_RANGE.y) and is_equal_approx(game.view.zoom(), authored * game.ROOM_ZOOM_RANGE.y), "Zooming all the way out stops at the widest allowed view")
	var pinch := InputEventMagnifyGesture.new()
	pinch.factor = 1.5
	var wide: float = game._room_zoom_scale
	game._on_world_input(pinch)
	_check(game._room_zoom_scale < wide, "A pinch outward zooms the room in")
	_check(is_equal_approx(float(game.settings.get_value("zoom")), setting), "Wheeling in a room never rewrites the outdoor Camera zoom setting")
	game._room_zoom_scale = 1.0
	game._apply_room_zoom()
	_check(is_equal_approx(game.view.zoom(), authored), "The room returns to its authored zoom")


## Hotaru has sent the traveller to the bed; the slate is picked up in the world and travels with them.
func _tablet() -> void:
	var tablet: Node3D = game.view.building_node("bed-tablet")
	game.session.state.player = [7,8,0]
	game.view.sync_player(game.session.state)
	game._refresh_interaction()
	_check(game._interaction.get("kind", "") == "pickup" and str(game._interaction.label).contains("tablet"), "After her cue, standing at the foot of the bed offers the tablet")
	var point: Vector2 = game.view.camera.unproject_position(BuildOverlay.world_aabb(tablet).get_center())
	_check(game._pick_workshop_object(point) == "tablet", "The visible tablet becomes a clickable world object")
	await shot("08-tablet-offered")
	game.session.state.player = [7,5,0]
	game.view.sync_player(game.session.state)
	var travelled: bool = await game.travel_room_link("downstairs")
	_check(not travelled and game.area.id == "workshop-loft", "The stairs wait while the slate is still on the bed")
	game.session.state.player = [3,6,0]
	game.view.sync_player(game.session.state)
	# The camera follows across the wider loft; aim at where the tablet is drawn now.
	for frame: int in range(30): await process_frame
	point = game.view.camera.unproject_position(BuildOverlay.world_aabb(tablet).get_center())
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = point * game.surface.size / Vector2(game.world_viewport.size)
	game._on_world_input(click)
	_check(game._pending_room_target == "tablet" and not game.session._route.is_empty(), "Clicking the tablet plans a route to the foot of the bed")
	var route: Array[Vector2i] = game.session._route.duplicate()
	game.session._cancel_route()
	for cell: Vector2i in route:
		game.session.request_step(cell - game.session.player_cell())
		game.session.advance_walk(LabWorld.STEP_SECONDS)
	game._process(0)
	_check(game.session.state.items == ["field-tablet"], "Arriving takes the tablet and records it as carried")
	_check(game._modals.size() == 1 and game._modals[0] is WorkshopScene, "Lifting it opens the short scene about what it is")
	var scene := game._modals[0] as WorkshopScene
	await shot("08b-tablet-scene")
	_check(scene._portrait.texture != null, "Hotaru takes part in the scene")
	var told_where: bool = false
	for n: int in range(48):
		if scene.is_queued_for_deletion(): break
		if scene._choices.visible: scene._choose(scene._page.choices[1])
		else: scene.advance()
		told_where = told_where or str(scene._text.text).contains("isn’t wood")
	_check(game._dialogue_read["workshop-scenes"].has("tablet-taken") and told_where, "Hotaru tells the traveller where the socket is, and the scene is remembered")
	await create_timer(.45).timeout
	_check(not tablet.visible and tablet.position == Vector3(6.75, 1.0, -9.24), "The slate leaves the bed once lifted, and its place in the room is kept")
	game._refresh_interaction()
	_check(game._interaction.get("kind", "") != "pickup", "A tablet already carried is not offered again")
	_check(PlayerItems.has(game.session.state, "field-tablet"), "The item survives in the rules, not only in the picture")


func _drain_speech(stage: WorkshopLoftStage) -> void:
	for step: int in range(32):
		if stage.speech_text=="" or stage.speech_complete:return
		stage.advance_speech()


func _stairs() -> void:
	game.session.state.player=[7,6,0]
	game.view.sync_player(game.session.state)
	var landing: float = game.view.player_node().position.y
	_check(game.session.request_step(Vector2i(0,-1)),"A real session step enters the visible stair flight")
	game.session.advance_walk(LabWorld.STEP_SECONDS * .5)
	_check(game.view.player_node().position.y < landing - .1,"The actual player sprite loses elevation halfway down the stairs")
	await shot("13-stairs-mid-step",0)
	game.session.advance_walk(LabWorld.STEP_SECONDS)
	_check(game.session.player_cell()==Vector2i(7,5) and game.view.player_node().position.y < -.3,"The player stands on the lowest top tread at the exit")
	await shot("14-stairs-bottom")
	var drawn: Array[float] = []
	for node: Node in game.view.find_children("*tread*","MeshInstance3D",true,false):
		drawn.append(BuildOverlay.world_aabb(node as Node3D).end.y)
	drawn.sort()
	var profile: Array = game.area.interior.stairwell.treads
	_check(drawn.size()==10 and range(10).all(func(i: int) -> bool: return is_equal_approx(drawn[i], float(profile[i]))),"The area-owned support profile matches all ten exported shell treads")
	for point: Vector3 in [Vector3(7,-.44,-5.0),Vector3(7,-.29,-5.35),Vector3(7,-.14,-5.7),Vector3(6.5,-.59,-4.7)]:
		var picked: Variant = game.view.pick_point(game.view.camera.unproject_position(point))
		_check(picked is Vector2 and (picked as Vector2).distance_to(Vector2(point.x,-point.z)) < .01,"Clicking a lowered stair tread picks its actual position")
	_check(game.view.pick_cell(game.view.camera.unproject_position(Vector3(9,0,-5.0)))==Vector2i(9,5),"Solid floor beside the stairwell keeps its own click target")
	_check(game.session.request_step(Vector2i(0,1)),"Walking back up the flight is legal")
	game.session.advance_walk(LabWorld.STEP_SECONDS)
	_check(is_equal_approx(game.view.player_node().position.y,landing),"Climbing back up restores the landing elevation")


func _buttons(node: Node,text: String) -> Array[Button]:
	var found: Array[Button]=[]
	if node is Button and (node as Button).text==text:found.append(node)
	for child: Node in node.get_children():found.append_array(_buttons(child,text))
	return found
func _text(node: Node,value: String) -> bool:
	if node is Label and (node as Label).text.contains(value):return true
	if node is Button and (node as Button).text.contains(value):return true
	for child: Node in node.get_children():
		if _text(child,value):return true
	return false
func _check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
func shot(name: String,frames: int=20) -> void:
	if output=="" or DisplayServer.get_name()=="headless":return
	var only: String = OS.get_environment("VOXEL_REVIEW_ONLY")
	if only != "" and only != name: return
	if OS.get_environment("VOXEL_REVIEW_QUICK") == "1": frames = mini(frames, 6)
	for frame: int in range(frames):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
