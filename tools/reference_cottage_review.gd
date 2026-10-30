extends SceneTree
## Actual Village Morning placements, approved actor/camera. -- <output directory>
var view: ClearingView
var state: Dictionary
var output: String

func _initialize() -> void:_run.call_deferred()

func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.is_empty():printerr("Expected an absolute output directory.");quit(2);return
	output=args[0]
	var area: AreaDef=AreaStore.load_area("village-morning")
	if area==null:quit(1);return
	view=ClearingView.new();root.add_child(view)
	await process_frame
	view.setup(area)
	view.set_camera_mode(ClearingView.CameraMode.FIXED)
	state=LabWorld.new(area).initial_state()
	view.apply_state(state)
	await _shot("comparison",Vector2(8,17),Vector2i(11,16),20)
	await _shot("reference-house",Vector2(7,20),Vector2i(11,20),13)
	await _shot("existing-house",Vector2(7,13),Vector2i(7,10),13)
	await _shot("entry-detail",Vector2(8,20),Vector2i(11,20),9)
	quit()

func _shot(name: String,focus: Vector2,player: Vector2i,zoom: float) -> void:
	state.player=[player.x,player.y,0]
	view.sync_player(state)
	view.set_zoom(zoom);view.camera.size=zoom
	view.focus_on(focus,true)
	await create_timer(.55).timeout
	for frame: int in range(6):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
	print("Reviewed ",name," at camera ",zoom)
