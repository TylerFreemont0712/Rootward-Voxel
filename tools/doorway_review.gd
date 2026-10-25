extends SceneTree
## Actual gameplay-scale steps, doors and travel. Fresh runs leave player saves alone.
var game: Game
var output: String

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	output=args[0] if not args.is_empty() else ".cache/door-review/play"
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game()
	game.session.set_physics_process(false)
	game._hint_timer.stop()
	for house: String in ["home","cedar-lodge","brook-hall","village-bakery"]:
		var cell: Vector2i = HouseInstances.door(game.area,house)
		game.session.prepare_travel()
		game.session.state.player=[cell.x,cell.y,0]
		game.view.sync_player(game.session.state)
		game.view.focus_on(Vector2(cell),true)
		game.view.set_warmth(.65)
		await _settle()
		await _shot(house+"-approach")
		var direction: Vector2i = -(HouseInstances.OUTWARD[game.area.building(house).facing] as Vector2i)
		game.session.request_step(direction)
		await create_timer(.29).timeout
		await _shot(house+"-opening")
		while game._flow_busy:await process_frame
		await _settle()
		await _shot(house+"-inside")
		var exit: Array = game.area.interior.exit
		game.session.state.player=[exit[0],exit[1],0]
		game.view.sync_player(game.session.state)
		game.session.request_step(Vector2i(0,-1))
		while game._flow_busy:await process_frame
	# New model, through the real placement/material/room path.
	var placed: Dictionary = game.ledger.place("concept-cottage",Vector2(34,5),"S",game.session.state)
	if not placed.ok:
		push_error(str(placed));quit(1);return
	game.area=game.ledger.area
	game.view.sync_edits(game.area,false)
	game.session.replace_area(game.area,game.ledger.rules)
	var house: String=placed.edit.id
	var cell: Vector2i=HouseInstances.door(game.area,house)
	game.session.state.player=[cell.x,cell.y,0]
	game.view.sync_player(game.session.state)
	game.view.focus_on(Vector2(34,5),true)
	game.view.set_zoom(13)
	await _settle()
	await _shot("concept-cottage-in-village")
	game.session.request_step(Vector2i(0,1))
	await create_timer(.29).timeout
	await _shot("concept-cottage-opening")
	while game._flow_busy:await process_frame
	await _settle()
	await _shot("concept-cottage-room")
	game.queue_free()
	await process_frame
	# Clear small fixtures allow every stair orientation to be seen at normal zoom.
	for facing: String in ["N","E","S","W"]:
		var dir: Vector2i=HouseInstances.OUTWARD[facing]
		var document: Dictionary={"schema":1,"id":"step-review","title":"Stone stairs","version":1,"size":[12,12],"spawn":[5,5],"terrain":[],"levels":[],"stairs":[{"at":[5,5],"up":facing}]}
		for y: int in range(11,-1,-1):
			document.terrain.append("............")
			var row: String=""
			for x: int in range(12):row+="1" if Vector2(Vector2i(x,y)-Vector2i(5,5)).dot(Vector2(dir))>0 else "0"
			document.levels.append(row)
		var parsed: Dictionary=AreaDef.parse(document,{})
		if not parsed.ok:push_error(str(parsed.errors));quit(1);return
		var view:=ClearingView.new()
		root.add_child(view)
		await process_frame
		view.setup(parsed.area)
		view.set_camera_mode(ClearingView.CameraMode.FIXED)
		view.focus_on(Vector2(5,5),true)
		view.set_zoom(13)
		view.set_warmth(.65)
		view.face_player(Vector2(dir))
		for along: float in [-.45,0.05,.40]:
			var point: Vector2=Vector2(5,5)+Vector2(dir)*along
			view.interpolate_player(point,point,0)
			for frame: int in range(20):await process_frame
			await _shot("stairs-"+facing+"-"+str(along))
		view.queue_free()
		await process_frame
	print("Gameplay steps and walk-through doors captured: ",output)
	quit()

func _settle() -> void:
	for frame: int in range(32):await process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
