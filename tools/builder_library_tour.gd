extends SceneTree
## The real builder and all sixteen interactions, using scratch saves. Run in a window.
## -- <output directory>

var game: Game
var out: String
var specs: Array
var placed: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	out = args[0] if not args.is_empty() else ProjectSettings.globalize_path("res://.cache/builder-library-50/tour")
	SaveStore.save_path = "user://builder_library_review.json"
	SaveStore.profile_path = "user://builder_library_review_profile.json"
	SaveStore.force_enabled = true
	SaveStore.delete()
	specs = JSON.parse_string(FileAccess.get_file_as_string("res://art/source/world/village-library/v1/library.json")).assets
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game()
	game.session.set_physics_process(false)
	game.set_process_unhandled_key_input(false)
	game._hint_timer.stop()
	game.open_build()
	var waiting: int = 0
	while game.builder.pictures_done < game.builder._entries.size() and waiting < 2500:
		await process_frame
		waiting += 1
	for category: String in ["furniture","workshop","market","garden","village-magic"]:
		var sample: String = ""
		for spec: Dictionary in specs:
			if spec.category == category:
				sample = str(spec.id)
				break
		game.builder.choose_item(sample)
		await _shot("builder-"+category)
		var search_rect: Rect2 = game.builder.hud.search.get_global_rect()
		# Compare in the HUD's canvas coordinates; the viewport stretches this canvas at 1280×720.
		if search_rect.end.x > game.builder.hud.get_global_rect().end.x + 2 or game.builder.hud._tray.size.x > game.builder.hud.size.x + 16:
			push_error("The category/search header must fit the review window.")
			quit(1)
			return
	game.builder.hud.search.text = "churn"
	game.builder.hud._filter_cards()
	await _shot("builder-search")
	game.builder.hud.clear_search()
	# A studio review placement, through the actual ledger and controller, never changing the area source.
	var index: int = 0
	for spec: Dictionary in specs:
		if (spec.interaction as Dictionary).is_empty():
			continue
		var around := Vector2(58 + (index%4)*4, 57 + (index/4)*4)
		var spot: Vector2 = _spot(str(spec.id),around)
		var result: Dictionary = game.ledger.place(str(spec.id),spot,"S",game.session.state)
		if not result.ok:
			push_error("Review could not place " + str(spec.id) + ": " + str(result.reason))
			quit(1)
			return
		game.builder._after_edit("Placed " + str(spec.title))
		placed.append({"id":result.edit.id,"spec":spec})
		index += 1
	# Let the rapid review-only placement toasts clear before photographing the details.
	await create_timer(3.5).timeout
	for item: Dictionary in placed:
		if item.spec.id == "hollow-wayfarers-chest":
			var chest: Dictionary = game.area.prop(str(item.id))
			_visit(_approach(chest))
			game.builder.set_tool(BuildMode.Tool.MOVE)
			game.builder._select({"kind":"prop","id":item.id,"at":chest.at,"facing":"S","locked":false})
			await _shot("builder-working-code")
	game.close_build()
	for item: Dictionary in placed:
		var prop: Dictionary = game.area.prop(str(item.id))
		var approach: Vector2i = _approach(prop)
		if approach.x < 0:
			push_error("No safe approach to " + str(item.spec.id))
			quit(1)
			return
		_visit(approach)
		game._refresh_interaction()
		if game._interaction.get("kind") != "prop" or game._interaction.get("id") != item.id:
			push_error("The real F prompt selected the wrong target: " + str(game._interaction))
			quit(1)
			return
		game.interact()
		if not game.session.state.props.get(item.id,false):
			push_error("The F action did not commit " + str(item.id))
			quit(1)
			return
		await _shot("working/"+str(item.spec.id))
		if item.spec.id == "hollow-wayfarers-chest":
			await _clip("chest")
		if item.spec.id == "hollow-water-pump":
			await _clip("pump")
		if item.spec.id == "hollow-village-bell":
			await _clip("bell")
	# A real notebook proposal on the lever: show it while the active model stays committed.
	var target: Dictionary = placed[0]
	for item: Dictionary in placed:
		if item.spec.id == "hollow-brass-lever":
			target = item
	_visit(_approach(game.area.prop(str(target.id))))
	game.open_notebook()
	game.notebook.editor.replace_program("def program(world):\n    prop = world.prop('%s')\n    prop.set_active(False)\n" % target.id)
	for _frame: int in range(4):
		await process_frame
	await game.session.run_preview()
	if not game.session.has_preview() or not game.session.state.props.get(target.id,false):
		push_error("Code preview must leave the committed prop active: " + JSON.stringify(game.session.last_run))
		quit(1)
		return
	await _shot("python-preview")
	game.session.apply_preview()
	game.session.undo_apply()
	game.close_notebook(true)
	game.save_now()
	await game._return_to_title()
	await game.continue_game()
	for item: Dictionary in placed:
		if not game.session.state.props.get(item.id,false):
			push_error("Continue lost working state for " + str(item.id))
			quit(1)
			return
	game.view.set_camera_mode(ClearingView.CameraMode.FIXED)
	game.view.set_zoom(20)
	game.view.focus_on(Vector2(64,63),true)
	await _shot("working-yard")
	print("Builder library tour: all 50 shelf entries; all 16 F actions; Python preview/Apply/Undo; saved Continue at ",root.size)
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	quit()


func _spot(id: String, around: Vector2) -> Vector2:
	for radius: int in range(8):
		for y: int in range(-radius,radius+1):
			for x: int in range(-radius,radius+1):
				var at: Vector2 = around + Vector2(x,y)*0.5
				if game.ledger.check_item(id,at,"S",game.session.state).ok:
					return at
	return Vector2(-1,-1)


func _approach(prop: Dictionary) -> Vector2i:
	for offset: Vector2i in [Vector2i(0,-1),Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-2),Vector2i(2,0),Vector2i(-2,0),Vector2i(0,2)]:
		var at: Vector2i = Vector2i(Vector2(prop.at).round())+offset
		var state: Dictionary = game.session.state.duplicate(true)
		state.player = [at.x,at.y,0]
		state.zones_seen = []
		for zone: Dictionary in game.area.zones:
			state.zones_seen.append(zone.id)
		if game.session.rules.is_walkable(state,at) and PropInteractions.can_use(game.session.rules,state,str(prop.id)).ok:
			return at
	return Vector2i(-1,-1)


func _visit(at: Vector2i) -> void:
	game.session.prepare_travel()
	game.session.state.player = [at.x,at.y,0]
	var zone: String = game.area.zone_at(at)
	if zone != "" and not (game.session.state.zones_seen as Array).has(zone):
		game.session.state.zones_seen.append(zone)
	game.view.sync_player(game.session.state)
	game.view.focus_on(Vector2(at),true)
	game.session._after_change(false)


func _shot(name: String) -> void:
	for _frame: int in range(90):
		await process_frame
	await RenderingServer.frame_post_draw
	var path: String = out.path_join(name+".png")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	root.get_texture().get_image().save_png(path)
	print("Library gameplay ",name)


func _clip(name: String) -> void:
	var old_limit: int = Engine.max_fps
	Engine.max_fps = 30
	for index: int in range(24):
		if name == "chest" and index in [0,12]:
			game.interact()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var path: String = out.path_join("clips/%s/frame-%03d.png" % [name,index])
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		root.get_texture().get_image().save_png(path)
	Engine.max_fps = old_limit
