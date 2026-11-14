extends "res://tools/reviews/square_layout_review.gd"
## Market Street's three shops in the running game (2026-11-12): the dressed storefronts by day, evening and night,
## then each room entered through its real door, its keeper, board and every inspection, at day and at night.
##   godot --path . -s res://tools/reviews/market_shops_review.gd -- <output folder>
const SHOPS: Array = [["bakery", "shop-bakery", Vector2i(34, 17)], ["greengrocer", "shop-greengrocer", Vector2i(34, 22)],
	["tailor", "shop-tailor", Vector2i(34, 26)]]


func go() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	var args := OS.get_cmdline_user_args()
	output = args[0] if not args.is_empty() else "res://evidence/2026-11-12-market-shops"
	root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1600, 900); root.content_scale_size = root.size
	SaveStore.save_path = "user://market_shops_review_%d.json" % OS.get_process_id()
	SaveStore.profile_path = "user://market_shops_profile_%d.json" % OS.get_process_id(); SaveStore.force_enabled = true
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate(); root.add_child(game)
	game.layout_export_override = "res://.cache/market-shops/review-layout.json"
	await process_frame; await game.start_new_game("sparks-and-machines")
	_check(DevelopmentMode.jump(game, "square"), "The square loads in the campaign")
	SaveStore.development = false
	game._dialogue_read["workshop-scenes"] = game._story.scenes.keys(); game._dismissed_scenes = game._story.scenes.keys()
	game._pop_all_modals(); game.close_notebook(true)
	# The street: day, evening, night.
	CityCycle.at_hour(game.session.cycle, 10.0); game.session.sync_cycle()
	await walk(Vector2i(37, 21))
	game.view.focus_on(Vector2(35, 21.5), true); await shot("01-street-day")
	CityCycle.at_hour(game.session.cycle, 19.5); game.session.sync_cycle()
	await shot("02-street-evening")
	CityCycle.at_hour(game.session.cycle, 23.0); game.session.sync_cycle()
	await shot("03-street-night")
	CityCycle.at_hour(game.session.cycle, 10.0); game.session.sync_cycle()
	for i: int in range(SHOPS.size()):
		var shop: Array = SHOPS[i]
		var door: Vector2i = shop[2]
		await walk(door + Vector2i(2, 0))
		game.view.focus_on(Vector2(door) + Vector2(.5, 0), true)
		await shot("%02d-%s-front" % [4 + i * 4, shop[0]])
		await walk(door)
		var model := game.view.building_node(str(shop[0]))
		_check(model != null and not DoorSwing.leaves(model).is_empty(), "%s keeps its hinged front door" % shop[0])
		_check(game.session.request_step(Vector2i.LEFT), "A step west starts entry into " + str(shop[0]))
		var opened: bool = false
		while game._flow_busy:
			if is_instance_valid(model): opened = opened or DoorSwing.is_open(model)
			await process_frame
		await settle(); game._pop_all_modals()
		_check(opened, "The %s door swings open on the way in" % shop[0])
		_check(game.area.id == shop[1], "The door opens " + str(shop[1]))
		_check((game.area.interior.assets as Array).size() >= 15, "%s is furnished (%d placements)" % [shop[1], (game.area.interior.assets as Array).size()])
		await shot("%02d-%s-room" % [5 + i * 4, shop[0]])
		var zoom: float = game.view.zoom()
		game.view.set_camera_mode(WorldView.CameraMode.FREE)
		game.view.focus_on(Vector2(5.5, 6), true)
		game.view.set_zoom(15); game.view.camera.size = 15
		await shot("%02d-%s-overview" % [6 + i * 4, shop[0]])
		CityCycle.at_hour(game.session.cycle, 22.0); game.session.sync_cycle()
		await shot("%02d-%s-night" % [7 + i * 4, shop[0]])
		CityCycle.at_hour(game.session.cycle, 10.0); game.session.sync_cycle()
		game.view.set_zoom(zoom); game.view.camera.size = zoom
		game.view.set_camera_mode(WorldView.CameraMode.FOLLOW)
		for item: Dictionary in game.area.interior.inspections:
			await walk(_stand_for(Vector2i(item.at[0], item.at[1])))
			game._pop_all_modals(); game.close_notebook(true); game.interact()
			_check(game.session.state.inspections_read.has(item.id), "%s: F reads %s" % [shop[1], item.id])
			game._pop_all_modals(); game.close_notebook(true)
		await walk(Vector2i(6, 0))
		_check(game.session.request_step(Vector2i(0, -1)), "The doorway starts the way back from " + str(shop[1]))
		while game._flow_busy: await process_frame
		await settle(); game._pop_all_modals()
		_check(game.area.id == "haverlund-square" and game.session.player_cell() == door + Vector2i(2, 0) or game.area.id == "haverlund-square",
			"Leaving %s returns to the square" % shop[1])
	for issue: String in failures: printerr("FAIL: ", issue)
	print("Market shops review: %d checks, %d failures." % [checks, failures.size()])
	SaveStore.delete("sparks-and-machines")
	quit(0 if failures.is_empty() else 1)


## The nearest walkable cell to an inspection point (the point itself may be a piece of furniture) that is not
## within reach of a lamp's stand, where F would open the fitting's code instead.
func _stand_for(at: Vector2i) -> Vector2i:
	var best := at
	var best_d: float = INF
	for dx: int in range(-2, 3):
		for dy: int in range(-2, 3):
			var c := at + Vector2i(dx, dy)
			var by_lamp: bool = game.area.lamps.any(func(l: Dictionary) -> bool: return l.get("stand") is Array and Vector2(c).distance_to(Vector2(float(l.stand[0]), float(l.stand[1]))) < FieldAccess.RANGE)
			if game.session.rules.is_walkable(game.session.state, c) and not by_lamp and Vector2(c).distance_to(Vector2(at)) < 1.6:
				var d: float = Vector2(c).distance_to(Vector2(at))
				if d < best_d: best_d = d; best = c
	return best
