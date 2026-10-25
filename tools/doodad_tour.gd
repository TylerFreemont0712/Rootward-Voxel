extends SceneTree
## Drives build mode through the real game to review the Doodads tab: the shelf with its pictures, a ghost, a yard of
## placed props, and the move and delete hovers. Saves a PNG of each state, for review at gameplay size.
## Usage: -- <absolute output directory>
## Run in a window (`scripts/play.sh --resolution 1600x1000 -s res://tools/doodad_tour.gd -- <dir>`); a headless
## run has no renderer, so the card pictures and screenshots are empty.

## What the yard holds: [item id, where to look for room, facing]. Positions are relative to (37, 7); the tour moves
## them to the roomiest open ground. Each is put on the nearest spot the rules allow.
const YARD: Array = [
	["stone-well", Vector2(31.5, 11), "S"], ["market-stall", Vector2(37, 11), "S"], ["notice-board", Vector2(41, 11), "S"],
	["hanging-sign", Vector2(34, 8.5), "S"], ["park-bench", Vector2(37, 8), "S"], ["signpost", Vector2(40, 8), "S"],
	["dining-table", Vector2(33, 5.5), "S"], ["wooden-chair", Vector2(31.5, 5.5), "E"], ["wooden-chair", Vector2(34.5, 5.5), "W"],
	["cottage-bed", Vector2(38, 5.5), "S"], ["bookshelf", Vector2(41, 5.5), "S"], ["storage-chest", Vector2(43, 5.5), "S"],
	["hay-bale", Vector2(32, 3), "S"], ["woodpile", Vector2(35.5, 3), "S"], ["wooden-barrel", Vector2(38.5, 3), "S"],
	["crate-stack", Vector2(40, 3), "S"], ["wheelbarrow", Vector2(42, 3), "S"], ["flower-pot", Vector2(36.5, 6.5), "S"],
	["milk-churn", Vector2(39.5, 6.8), "S"], ["watering-can", Vector2(35, 6.8), "S"],
]

var game: Game
var out: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "/tmp/doodad_tour"
	DirAccess.make_dir_recursive_absolute(out)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(30)
	await game.start_new_game()
	await _frames(60)
	game.open_build()
	await _frames(70)
	var builder: BuildMode = game.builder
	builder.choose_item("wooden-chair")
	var waited: int = 0
	while waited < 1500 and builder.pictures_done < builder._entries.size():
		await process_frame
		waited += 1
	await _frames(30)
	await _shot("01-doodads-tab")
	var centre: Vector2 = _open_ground()
	builder.choose_item("park-bench")
	await _point_at(centre)
	await _frames(40)
	await _shot("02-bench-ghost")
	builder.facing = "E"
	await _point_at(centre)
	await _frames(20)
	await _shot("03-bench-ghost-turned")
	builder.facing = "S"
	builder.hud.open_tray(false)
	await _frames(30)
	var placed: int = 0
	for entry: Array in YARD:
		var spot: Vector2 = _nearest_spot(str(entry[0]), centre + (entry[1] as Vector2) - Vector2(37, 7), str(entry[2]))
		if spot.x < 0.0:
			printerr("No room for ", entry[0])
			continue
		builder.choose_item(str(entry[0]))
		builder.facing = str(entry[2])
		await _point_at(spot)
		await _frames(4)
		builder._click()
		await _frames(4)
		placed += 1
	builder._pointer_in = false
	builder.overlay.hide_ghost()
	builder.hud.hide_bubble()
	game.view.focus_on(centre, true)
	await create_timer(3.0).timeout
	await _shot("04-yard")
	builder.set_tool(BuildMode.Tool.MOVE)
	await _point_at(_first_prop_at("park-bench"))
	await _frames(30)
	await _shot("05-move-hover")
	builder.set_tool(BuildMode.Tool.DELETE)
	await _point_at(_first_prop_at("wooden-barrel"))
	await _frames(30)
	await _shot("06-delete-hover")
	print("Doodad tour saved to ", out, " (", placed, " of ", YARD.size(), " props placed)")
	game.close_build()
	await _frames(20)
	quit(0)


## The closest spot to `around`, in half cells, where the rules allow this item. (-1, -1) if there is none within 6.
func _nearest_spot(item_id: String, around: Vector2, facing: String) -> Vector2:
	var best := Vector2(-1, -1)
	var best_distance: float = INF
	for dy: int in range(-12, 13):
		for dx: int in range(-12, 13):
			var spot: Vector2 = AreaBuild.snap_prop(around + Vector2(dx, dy) * 0.5)
			var distance: float = spot.distance_to(around)
			if distance < best_distance and game.builder.ledger.check_item(item_id, spot, facing, game.session.state).ok:
				best_distance = distance
				best = spot
	return best


## The middle of the roomiest patch of ground in the valley: the centre where the most nearby spots take a small prop.
func _open_ground() -> Vector2:
	var best := Vector2(37, 7)
	var best_count: int = -1
	for cy: int in range(10, game.area.height - 8, 3):
		for cx: int in range(10, game.area.width - 8, 3):
			var count: int = 0
			for dy: int in range(-6, 7, 2):
				for dx: int in range(-6, 7, 2):
					if game.builder.ledger.check_item("hearth-stool", Vector2(cx + dx, cy + dy), "S", game.session.state).ok:
						count += 1
			if count > best_count:
				best_count = count
				best = Vector2(cx, cy)
	return best


func _first_prop_at(asset: String) -> Vector2:
	for prop: Dictionary in game.builder.ledger.area.props:
		if prop.asset == asset:
			return prop.at
	return Vector2(37, 7)


## Points the builder at a ground cell, as if the mouse were there. Frames the camera on it first.
func _point_at(logical: Vector2) -> void:
	game.view.focus_on(logical, true)
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
