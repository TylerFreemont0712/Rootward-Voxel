extends SceneTree
## Refreshed building contracts, bounded wheel/axle collision and real shop travel/saves.

const Assets := preload("res://art/world_assets.gd")
var checks: int = 0
var failures: Array[String] = []
var game: Game
var output: String = ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():output=args[0]
	var source: Dictionary = AreaStore.read_source("kindle-hollow")
	var catalog: Dictionary = AreaStore.read_build_catalog()
	var area: AreaDef = AreaStore.load_area("kindle-hollow")
	var wheel: Dictionary = area.wheels[0]
	_check(area.terrain_at(Vector2i(wheel.at.round()))==AreaDef.Terrain.WATER,"The quest mill wheel occupies river water")
	_check(wheel.size.y>2 and wheel.axle_to.x>47.8 and wheel.rect.has_point(Vector2(47.4,24.6)),"The full-size wheel reaches its mill through a solid axle footprint")
	var rules := LabWorld.new(area)
	_check(not rules.is_walkable(rules.initial_state(),Vector2i(47,25)),"The axle/bearing block walking through the bank machinery")
	for bad: Dictionary in [{"size":[0,2]},{"size":[1,-2]},{"size":[1,5]},{"axle_to":[100,24.6]},{"axle_to":[48,22]},{"axle_to":[NAN,24.6]}]:
		var document: Dictionary = source.document.duplicate(true)
		document.wheels[0].merge(bad,true)
		_check(not AreaDef.parse(document,source.assets,source.quests).ok,"Malformed or unbounded wheel geometry is refused")
	var plain: Dictionary = source.document.duplicate(true)
	plain.wheels[0].erase("axle_to")
	_check(AreaDef.parse(plain,source.assets,source.quests).ok,"Legacy wheels without axle metadata still load")
	for id: String in ["cottage","mill-house","log-cabin","log-cabin-large","log-cabin-large-teal","hearth-house","lantern-loft","brook-mill","lamppost"]:
		var entry: Dictionary = source.assets[id]
		var note: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://"+str(entry.source).get_base_dir()+"/building-polish.json"))
		_check(FileAccess.get_sha256("res://"+str(entry.source).get_base_dir()+"/"+str(note.backup))==note.before_sha256,"The original editable master is preserved: "+id)
		var later: String = "res://"+str(entry.source).get_base_dir()+"/doorways.json"
		var selected: String = "res://"+str(entry.source)
		if FileAccess.file_exists(later):
			var revision: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(later))
			selected = "res://"+str(entry.source).get_base_dir()+"/"+str(revision.backup)
			_check(FileAccess.get_sha256("res://"+str(entry.source))==revision.source_sha256,"The later doorway revision matches the saved master: "+id)
		_check(FileAccess.get_sha256(selected)==note.source_sha256,"The recorded building edit is preserved in the source history: "+id)
	for id: String in ["hollow-bakery","hollow-smithy","concept-cottage"]:
		var ledger := BuildLedger.new(source.document,source.assets,source.quests,catalog)
		var state: Dictionary = ledger.rules.initial_state()
		var result: Dictionary = ledger.place(id,Vector2(34,5),"E",state)
		_check(result.ok,"The new building can be placed/rotated through the builder: "+id)
		if not result.ok:continue
		var house: String = result.edit.id
		_check(ledger.finish("building",house,"roof","slate_shingles",state).ok,"The new roof supports saved part finishes")
		var restored := BuildLedger.new(source.document,source.assets,source.quests,catalog,JSON.parse_string(JSON.stringify(ledger.edits)))
		_check(restored.area.building(house).facing=="E" and restored.area.building(house).finishes.roof=="slate_shingles","New building and its finish round-trip through saved JSON")
		_check(ledger.undo(state).ok and ledger.undo(state).ok and ledger.redo(state).ok,"New buildings use normal undo/redo")
	SaveStore.save_path="user://building_refresh_"+str(OS.get_process_id())+".json"
	SaveStore.profile_path="user://building_refresh_profile_"+str(OS.get_process_id())+".json"
	SaveStore.force_enabled=true
	SaveStore.delete()
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game()
	game.session.set_physics_process(false)
	game.set_process_unhandled_key_input(false)
	game._hint_timer.stop()
	for pair: Array in [["village-bakery","hollow-bakery"],["village-smithy","hollow-smithy"]]:
		var door: Vector2i = HouseInstances.door(game.area,pair[0])
		_visit(door)
		game.open_build()
		game.builder.choose_item(pair[1])
		_check(game.builder.hud._cards.has(pair[1]),"The real shelf offers "+str(pair[1]))
		await _shot(pair[1]+"-builder")
		game.close_build()
		game._refresh_interaction()
		_check(HouseInstances.crossing(game.area,game.session.rules,game.session.state,Vector2i(0,1),game._interior_catalog).get("house")==pair[0],"Walking inward through the centred doorway opens the correct shop")
		_check(await game.enter_house(pair[0]),"The authored shop enters its own room")
		game.session.set_physics_process(false)
		game.session.state.memory={"shop":pair[1]}
		game.open_build()
		var panel: RoomFinishes = game._modals[-1]
		panel.finish_chosen.emit("floor","terracotta_tile")
		panel.close()
		game.save_now()
		await game._return_to_title()
		await game.continue_game()
		_check(game.inside_house() and game.session.state.memory.get("shop")==pair[1] and game.area.interior.finishes.floor=="terracotta_tile","Continue restores this shop's room state and finish")
		await _shot(pair[1]+"-room")
		_visit(Vector2i(game.area.interior.exit[0],game.area.interior.exit[1]))
		_check(await game.leave_house(),"The shop exits through the correct original doorstep")
		game.session.set_physics_process(false)
	_visit(Vector2i(49,21))
	game.session.state.lamps["mill-lamp-yard"]=true
	game.view.apply_state(game.session.state)
	var lamp: Node3D = game.view._lamps["mill-lamp-yard"]
	_check((lamp.get_meta("glass") as MeshInstance3D).material_override==game.view._materials.lit,"The polished lamp's real glass still follows validated state")
	var rotation: float = game.view._wheels[0].rotation.x
	var support: Node3D = game.view._content.get_node("mill_wheel_support")
	var mount: Transform3D = support.transform
	for frame: int in range(12):await process_frame
	_check(game.view._wheels[0].rotation.x!=rotation and support.transform==mount,"The rotor turns while its axle bearing remains fixed")
	await _shot("mill-and-lamps")
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	if failures.is_empty():print("Building refresh: %d checks passed." % checks)
	else:
		for failure: String in failures:printerr("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)


func _visit(at: Vector2i) -> void:
	game.session.prepare_travel()
	game.session.state.player=[at.x,at.y,0]
	game.view.sync_player(game.session.state)
	game.view.focus_on(Vector2(at),true)
	game._refresh_interaction()


func _shot(name: String) -> void:
	if output=="":return
	for frame: int in range(40):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name+".png"))


func _check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures.append(label)
		printerr("FAIL: ",label)
