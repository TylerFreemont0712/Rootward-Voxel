extends SceneTree
## Small native loading study after the full gameplay review; uses the real saved-power interface.
func _initialize() -> void:
	Engine.max_fps=60
	_run.call_deferred()
func _run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	var destination: String=args[0]
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(int(args[1]),int(args[2]))
	root.content_scale_size=root.size
	DirAccess.make_dir_recursive_absolute(destination)
	var stage:=Control.new()
	stage.theme=PaperTheme.theme()
	UI.full_rect(stage)
	root.add_child(stage)
	var veil:=GearVeil.new()
	UI.full_rect(veil)
	stage.add_child(veil)
	await process_frame
	var cycle: Dictionary=CityCycle.fresh()
	for value: float in [5.6,8.5,9.5,12.0,15.0]:
		CityCycle.set_pressure(cycle,value)
		veil.set_world_state({"city_power":CityCycle.power(cycle)})
		veil.set_status("Following the conduits…")
		await veil.close(Vector2(.5,.5),.12)
		await create_timer(1.4).timeout
		await RenderingServer.frame_post_draw
		var name: String="12-loading-pressure" if value==5.6 else "14-pressure-"+str(value).replace(".","-")
		root.get_texture().get_image().save_png(destination.path_join(name+".png"))
		await veil.open(Vector2(.5,.5),.12)
	quit()
