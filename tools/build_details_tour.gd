extends SceneTree
## Drives build mode's details panel through the real game and saves a PNG of each state, for review at gameplay size:
## a placed house chosen and turned, a tree, a doodad, and a lamp's code (visited and not).
## Usage: -- <absolute output directory>

var game: Game
var out: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "/tmp/build_details_tour"
	DirAccess.make_dir_recursive_absolute(out)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(30)
	await game.start_new_game("kindle-hollow")
	await _frames(60)
	game.open_build()
	await _frames(70)
	var builder: BuildMode = game.builder
	await _point_at(Vector2(34, 5))
	builder._click()
	await _frames(30)
	builder.set_tool(BuildMode.Tool.MOVE)
	await _point_at(Vector2(34, 5))
	await _frames(20)
	builder._click()
	await _frames(40)
	await _shot("20-house-chosen")
	builder.set_facing("N")
	await _frames(50)
	await _shot("21-house-turned")
	builder.set_tool(BuildMode.Tool.PLACE)
	builder.choose_item("tree-elder")
	await _point_at(Vector2(39.5, 5.5))
	await _frames(20)
	builder._click()
	await _frames(20)
	builder.set_tool(BuildMode.Tool.MOVE)
	await _point_at(Vector2(39.5, 5.5))
	await _frames(20)
	builder._click()
	await _frames(40)
	await _shot("22-tree-chosen")
	builder.set_tool(BuildMode.Tool.PLACE)
	builder.hud._choose_category("doodads")
	builder.choose_item("park-bench")
	await _point_at(Vector2(37, 9))
	await _frames(40)
	await _shot("23-doodad-ghost")
	while builder.ledger.can_undo():
		builder.undo()
	var lamp: Dictionary = game.area.lamp("landing-lamp")
	builder.set_tool(BuildMode.Tool.MOVE)
	await _point_at(lamp.at)
	await _frames(20)
	builder._click()
	await _frames(40)
	await _shot("24-lamp-code")
	var far: Dictionary = game.area.lamp("road-lamp-6")
	await _point_at(far.at)
	await _frames(20)
	builder._click()
	await _frames(40)
	await _shot("25-lamp-unvisited")
	builder.set_tool(BuildMode.Tool.PLACE)
	builder.choose_item("house-hollow")
	builder.hud.open_tray(false)
	await _frames(40)
	await _shot("26-tray-hidden")
	print("Details tour saved to ", out)
	quit(0)


func _point_at(logical: Vector2) -> void:
	game.view.focus_on(logical, true)
	await process_frame
	var viewport_point: Vector2 = game.view.camera.unproject_position(Vector3(logical.x, 0.0, -logical.y))
	game.builder._pointer = viewport_point * game.surface.size / Vector2(game.world_viewport.size)
	game.builder._pointer_in = true
	game.builder._hover_dirty = true
	await _frames(4)


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
