extends SceneTree
## Read-only production Finished-list review. -- <output-folder>

func _initialize()->void:run.call_deferred()

func run()->void:
	OS.set_environment("VOXEL_LAB_FRESH","1")
	var args:=OS.get_cmdline_user_args()
	if args.is_empty():quit(2);return
	var game: Game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await create_timer(.9).timeout
	game.open_asset_showcase()
	var screen:=game._modals[-1] as AssetShowcase
	screen.refresh_workflow()
	screen.filter.select(2)
	screen.filter.item_selected.emit(2)
	var visible: Array[String]=[]
	for index: int in range(screen.models.item_count):visible.append(str(screen.models.get_item_metadata(index)))
	for name: String in ["pip","wick","trowel","heron","tender","tally"]:
		if not visible.has("robot-"+name):printerr("Missing Finished robot: ",name);quit(1);return
	screen.show_asset("robot-pip")
	for index: int in range(6):await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(str(args[0]))
	root.get_texture().get_image().save_png(str(args[0]).path_join("finished-robots.png"))
	print("Production Finished list: six refined robots visible.")
	quit()
