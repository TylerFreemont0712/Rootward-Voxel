extends SceneTree
## Drives build mode through the real game and saves a PNG of each state, for review at gameplay size.
## Usage: -- <absolute output directory>
## The pointer is moved by pointing the builder at where a ground point is drawn on screen, then letting it
## decide, exactly as a mouse would.

var game: Game
var out: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "/tmp/build_tour"
	DirAccess.make_dir_recursive_absolute(out)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(30)
	await game.start_new_game()
	await _frames(60)
	await _shot("00-play-hud")
	game.open_build()
	await _frames(70)
	await _shot("01-build-open")
	var builder: BuildMode = game.builder
	await _point_at(Vector2(34, 5))
	await _frames(40)
	await _shot("02-place-ok")
	await _point_at(Vector2(24, 7))
	await _frames(20)
	await _shot("03-place-refused")
	builder.rotate()
	await _point_at(Vector2(34, 5))
	await _frames(40)
	await _shot("04-place-rotated")
	builder._click()
	await _frames(30)
	await _shot("05-placed")
	builder.choose_item("tree-elder")
	await _point_at(Vector2(38.5, 5.5))
	await _frames(30)
	await _shot("06-tree-ghost")
	builder._click()
	await _frames(20)
	builder.set_tool(BuildMode.Tool.MOVE)
	await _point_at(Vector2(34, 5))
	await _frames(30)
	await _shot("07-move-hover")
	builder._click()
	await _point_at(Vector2(36, 9))
	await _frames(40)
	await _shot("08-move-carrying")
	builder.set_tool(BuildMode.Tool.DELETE)
	await _point_at(Vector2(38.5, 5.5))
	await _frames(30)
	await _shot("09-delete-hover")
	await _point_at(Vector2(49.1, 24.6))
	await _frames(30)
	await _shot("10-locked-mill")
	builder.undo()
	await _frames(25)
	await _shot("11-undo")
	builder.set_tool(BuildMode.Tool.PAINT)
	builder.choose_paint("dirt")
	builder.hud._choose_paint_family("Dirt")
	builder.set_brush_size(2)
	await _point_at(Vector2(35.5, 10.5))
	await _frames(12)
	builder._click()
	await _point_at(Vector2(35.5, 12.5))
	await _frames(12)
	await _shot("13-paint-stroke")
	builder._finish_stroke()
	await _frames(15)
	await _shot("14-paint-committed")
	while builder.ledger.can_undo():
		builder.undo()
	builder.set_tool(BuildMode.Tool.PLACE)
	builder.choose_item("hearth-house")
	await _point_at(Vector2(34, 5))
	await _frames(25)
	await _shot("15-new-house")
	builder._click()
	await _frames(25)
	if builder.ledger.area.buildings.back().asset != "hearth-house":
		printerr("Review house placement was refused")
		quit(1)
		return
	builder.choose_item("hearth-oak")
	await _point_at(Vector2(38.5, 5.5))
	await _frames(25)
	await _shot("16-new-trees")
	builder._click()
	await _frames(25)
	var planted: Node3D = game.view._asset_tree_nodes.get(AreaBuild.tree_key(Vector2(38.5, 5.5))) as Node3D
	if planted == null or not planted.visible:
		printerr("Review model-tree placement was not drawn")
		quit(1)
		return
	builder._pointer_in = false
	builder.overlay.hide_ghost()
	builder.hud.hide_bubble()
	await create_timer(3.0).timeout
	await _shot("17-new-scenery-placed")
	game.close_build()
	await _frames(40)
	await _shot("12-back-to-play")
	print("Build tour saved to ", out)
	quit(0)


## Points the builder at a ground cell, as if the mouse were there. Frames the camera on it first.
func _point_at(logical: Vector2) -> void:
	game.view.focus_on(logical - Vector2(0, 0), true)
	await process_frame
	var viewport_point: Vector2 = game.view.camera.unproject_position(Vector3(logical.x, 0.0, -logical.y))
	game.builder._pointer = viewport_point * game.surface.size / Vector2(game.world_viewport.size)
	game.builder._pointer_in = true
	game.builder._hover_dirty = true


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
