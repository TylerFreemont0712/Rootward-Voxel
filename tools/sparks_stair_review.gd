extends SceneTree
## Agent play-through using the game's real input path and physics clock, without advancing the session manually.
var game: Game
var output: String
var failed: bool = false
func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH","1")
	go.call_deferred()
func go() -> void:
	var args := OS.get_cmdline_user_args()
	output=args[0] if not args.is_empty() else ProjectSettings.globalize_path("res://.cache/stair-playthrough")
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate();root.add_child(game)
	await process_frame
	await game.start_new_game("sparks-and-machines")
	game._pop_all_modals();game.close_notebook(true)
	game.session.state.player=[7,6,0];game.view.sync_player(game.session.state)
	key(KEY_S,true)
	await until(func()->bool:return game.area.id=="workshop-floor")
	key(KEY_S,false)
	await until(func()->bool:return not game._flow_busy)
	await shot("01-real-keyboard-arrival")
	key(KEY_W,true)
	await until(func()->bool:return game.session.player_cell().y==11)
	key(KEY_W,false)
	await until(func()->bool:return not game.session.is_walking())
	await shot("02-real-keyboard-stair-foot")
	await click_walk(Vector2i(2,8))
	game.view.set_zoom(11)
	game.view.focus_on(Vector2(2,8),true)
	await shot("03-trolley-by-drawers")
	game.view.set_zoom(15.5)
	await click_walk(Vector2i(6,11))
	key(KEY_S,true)
	await until(func()->bool:return game.area.id=="workshop-loft")
	key(KEY_S,false)
	await until(func()->bool:return not game._flow_busy)
	await shot("04-real-keyboard-return")
	print("Input play-through: ","FAILED" if failed else "passed", "; keyboard stairs in both directions and mouse route by the drawers.")
	game.queue_free();await process_frame;quit(1 if failed else 0)
func until(predicate: Callable) -> void:
	var deadline: int=Time.get_ticks_msec()+60000
	while not predicate.call() and Time.get_ticks_msec()<deadline:await process_frame
	if not predicate.call():failed=true;printerr("Input play-through timed out in ",game.area.id," at ",game.session.player_cell())
func key(code: Key, pressed: bool) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event)
func click_walk(cell: Vector2i) -> void:
	var viewport_point:=game.view.camera.unproject_position(Vector3(cell.x,WalkingSurface.height(game.area,Vector2(cell),[]),-cell.y))
	var point:=game.surface.global_position + viewport_point * game.surface.size / Vector2(game.world_viewport.size)
	game.surface.grab_focus()
	# This is already in the root viewport's scaled coordinates; push it locally instead of reapplying the OS
	# window transform through Input.parse_input_event. Motion establishes the GUI hover before the button.
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point
	root.push_input(motion,true)
	await process_frame
	print("Click walk to ",cell," at ",point,"; picked ",game.view.pick_cell(viewport_point))
	print("Walkable ",game.session.rules.is_walkable(game.session.state,cell)," plain route ",game.session.rules.find_path(game.session.state,cell)," object ",game._pick_workshop_object(viewport_point))
	for down: bool in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point
		event.global_position=point
		root.push_input(event,true)
		await process_frame
	print("After click: at ",game.session.player_cell()," route ",game.session._route," focus ",DisplayServer.window_is_focused())
	await until(func()->bool:return game.session.player_cell()==cell and not game.session.is_walking())
func shot(name: String) -> void:
	for n: int in range(4):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
