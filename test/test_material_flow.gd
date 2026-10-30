extends SceneTree
## Real finish selectors, preserved interactive state, undo and per-house Continue.
## Optional -- <directory> captures the same flow in a real window at gameplay scale.

var checks: int = 0
var failures: Array[String] = []
var game: Game
var output: String = ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): output = args[0]
	var scratch: String = "test_material" + ("_review_"+str(OS.get_process_id()) if output != "" else "")
	SaveStore.save_path = "user://"+scratch+"_flow.json"
	SaveStore.profile_path = "user://"+scratch+"_profile.json"
	SaveStore.force_enabled = true
	SaveStore.delete()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	if args.size() > 1:
		game.settings.values.ui_scale = float(args[1])
		game._apply_display()
	await game.start_new_game("kindle-hollow")
	game.session.set_physics_process(false)
	game.set_process_unhandled_key_input(false)
	game._hint_timer.stop()
	_visit(HouseInstances.door(game.area,"home"))
	game.open_build()
	var home: Dictionary = game.area.building("home")
	game.builder.set_tool(BuildMode.Tool.MOVE)
	game.builder._select({"kind":"building","id":"home","at":home.at,"facing":home.facing,"locked":true})
	_choose(game.builder.hud.details,"roof","slate_shingles")
	_choose(game.builder.hud.details,"walls","limewash")
	_check(game.area.building("home").finishes.roof == "slate_shingles","Standing building selectors commit through the real controller")
	await _shot("01-house-materials")
	_choose(game.builder.hud.details,"roof","cedar_shingles")
	await _shot("02-cedar-roof")
	_choose(game.builder.hud.details,"roof","copper_patina")
	await _shot("03-copper-roof")
	game.close_build()
	_visit(Vector2i(35,5))
	game.open_build()
	var placed: Dictionary = game.ledger.place("hollow-wayfarers-chest",Vector2(34,5),"S",game.session.state)
	_check(placed.ok,"A working prop can be placed for material review")
	game.builder._after_edit("Placed chest")
	var id: String = placed.edit.id
	game.close_build()
	game._refresh_interaction()
	game.interact()
	_check(game.session.state.props.get(id,false),"The real F action opens the chest before finishing")
	game.open_build()
	game.builder.set_tool(BuildMode.Tool.MOVE)
	game.builder._select({"kind":"prop","id":id,"at":Vector2(34,5),"facing":"S","locked":false})
	_choose(game.builder.hud.details,"metal","copper_patina")
	_check(game.area.prop(id).finishes.metal == "copper_patina" and (game.view._prop_visuals[id] as PropVisual).active,"A finish rebuild preserves the working object's active visual")
	await _shot("04-working-prop-materials")
	game.close_build()
	game.open_build()
	game.builder.set_tool(BuildMode.Tool.PAINT)
	var patch_index: int = 0
	for material: String in SurfaceFinishes.OPTIONS.floor:
		game.builder.choose_paint(material)
		var cells: Array = []
		var corner := Vector2i(62+(patch_index%2)*7,3+(patch_index/2)*7)
		for y: int in range(corner.y,corner.y+6):
			for x: int in range(corner.x,corner.x+6):cells.append([x,y])
		_check(game.builder.hud._paint_family == "Floors" and game.ledger.paint(material,cells,game.session.state).ok,"The Floors menu offers and applies "+material)
		game.builder._after_edit("Painted "+FinishMaterials.title(material),false)
		patch_index += 1
	game.view.focus_on(Vector2(34,4),true)
	if output != "":await create_timer(4.0).timeout
	await _shot("04b-floor-paints")
	game.close_build()
	game.save_now()
	await game._return_to_title()
	await game.continue_game("kindle-hollow")
	_check(game.area.prop(id).finishes.metal == "copper_patina" and game.session.state.props.get(id,false) and (game.view._prop_visuals[id] as PropVisual).active,"Continue restores both material and interactive state")
	_check(game.area.building("home").finishes.roof == "copper_patina","Continue restores the finished building")
	_visit(HouseInstances.door(game.area,"home"))
	_check(await game.enter_house("home"),"The finished house keeps its real door and room instance")
	game.session.set_physics_process(false)
	game.session.state.memory = {"material_marker":42}
	game.session.state.lamps["hearth-lamp"] = true
	game.view.apply_state(game.session.state)
	var state: Dictionary = game.session.state.duplicate(true)
	var furniture: Array = game.area.interior.furniture.duplicate(true)
	await _shot("05-cottage-original")
	game.open_build()
	var panel: RoomFinishes = game._modals[-1]
	_choose(panel,"floor","encaustic_tile")
	_choose(panel,"walls","sage_wallpaper")
	_check(game.area.interior.finishes.floor == "encaustic_tile" and game.area.interior.finishes.walls == "sage_wallpaper","The room selectors commit both materials")
	_check(game.session.state == state and game.area.interior.furniture == furniture,"Room finishing preserves player, lamp, memory and furniture data")
	panel.undo_requested.emit()
	_check(not game.area.interior.finishes.has("walls") and game.area.interior.finishes.floor == "encaustic_tile","Room Undo changes just the last finish")
	panel.redo_requested.emit()
	_check(game.area.interior.finishes.walls == "sage_wallpaper","Room Redo restores the finish")
	await _shot("06-room-material-controls")
	panel.close()
	await _shot("07-cottage-custom")
	game.save_now()
	await game._return_to_title()
	await game.continue_game("kindle-hollow")
	_check(game.inside_house() and game.area.interior.finishes.floor == "encaustic_tile" and game.session.state.memory.get("material_marker")==42 and game.session.state.lamps["hearth-lamp"],"Continue indoors restores this home's materials and state")
	await _leave()
	_visit(HouseInstances.door(game.area,"row-north-a"))
	await game.enter_house("row-north-a")
	_check(game.area.interior.get("finishes",{}).is_empty() and not game.session.state.memory.has("material_marker"),"A second home has its own material and state history")
	await _leave()
	_visit(HouseInstances.door(game.area,"home"))
	await game.enter_house("home")
	_check(game.area.interior.finishes.floor == "encaustic_tile","Reentering the first home restores its custom palette")
	game.open_build()
	panel = game._modals[-1]
	_choose(panel,"floor","")
	_check(not game.area.interior.finishes.has("floor") and game.area.interior.finishes.walls == "sage_wallpaper","Original removes only the chosen part override")
	panel.close()
	await _leave()
	if output != "":
		for house: String in ["loft-west","riverside-loft","mill"]:
			_visit(HouseInstances.door(game.area,house))
			_check(await game.enter_house(house),"Review template door: "+house)
			game.session.set_physics_process(false)
			game.session.state.lamps["hearth-lamp"] = true
			game.view.apply_state(game.session.state)
			await _shot("room-"+house)
			await _leave()
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	if failures.is_empty(): print("Material controls and saves: %d checks passed." % checks)
	else:
		for failure: String in failures: printerr("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)


func _choose(node: Node, slot: String, material: String) -> void:
	var choice: OptionButton = node.find_child("Finish_"+slot,true,false) as OptionButton
	_check(choice != null,"The actual selector exists for "+slot)
	if choice == null:return
	for index: int in range(choice.item_count):
		if choice.get_item_metadata(index) == material:
			choice.select(index)
			choice.item_selected.emit(index)
			return
	_check(false,"The selector offers "+material)


func _visit(at: Vector2i) -> void:
	game.session.prepare_travel()
	game.session.state.player = [at.x,at.y,0]
	game.view.sync_player(game.session.state)
	game.view.focus_on(Vector2(at),true)
	game._refresh_interaction()


func _leave() -> void:
	var at: Array = game.area.interior.exit
	_visit(Vector2i(at[0],at[1]))
	_check(await game.leave_house(),"The finished room keeps its exit")
	game.session.set_physics_process(false)


func _shot(name: String) -> void:
	if output == "":return
	for frame: int in range(40):await process_frame
	await RenderingServer.frame_post_draw
	var path: String = output.path_join(name+".png")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	root.get_texture().get_image().save_png(path)
	print("Material gameplay ",name)


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ",label)
