extends SceneTree
## Shapes land through build mode as a player would (Land → Terrain and Water) and saves a PNG of each step, for
## review at gameplay size: a raise stroke's proposal, two terraces, a stairs ghost and stairs, a stream that falls
## down both terraces, then the apprentice climbing the stairs in play.
## VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1600x1000 -s res://tools/terrain_tour.gd -- <absolute output directory>

var game: Game
var out: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else ProjectSettings.globalize_path("res://.cache/terrain-tour")
	DirAccess.make_dir_recursive_absolute(out)
	SaveStore.save_path = "user://terrain_tour_save.json"
	SaveStore.profile_path = "user://terrain_tour_profile.json"
	SaveStore.force_enabled = true
	SaveStore.delete()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(30)
	await game.start_new_game("kindle-hollow")
	game.session.set_physics_process(false)
	game._hint_timer.stop()
	await _frames(30)
	game.open_build()
	var builder: BuildMode = game.builder
	var waited: int = 0
	while waited < 1800 and builder.hud._paint_cards.values().any(func(card: BuildCard) -> bool: return card.item_id.begins_with("shape:") and card._picture.texture == null):
		await process_frame
		waited += 1
	# A terrace one level up: one drag with the biggest brush.
	builder.choose_shape("raise")
	builder.set_brush_size(4)
	await _stroke([Vector2(34, 6), Vector2(36, 6), Vector2(36, 9), Vector2(34, 9)], "01-raise-stroke")
	await _shot("02-terrace")
	# A second level at the back of it.
	builder.set_brush_size(2)
	await _stroke([Vector2(34, 9), Vector2(35, 10)], "")
	await _shot("03-two-levels")
	# Stairs up each cliff.
	builder.choose_shape("stairs")
	await _point_at(Vector2(34, 4))
	await _shot("04-stairs-ghost")
	builder._click()
	await _frames(10)
	await _point_at(Vector2(34, 8), 1)
	await _shot("05a-upper-stairs-ghost")
	builder._click()
	await _frames(10)
	_report("stairs", builder.ledger.area.stairs.size() == 2)
	await _shot("05-stairs")
	# A stream from the top terrace down both cliffs.
	builder.choose_shape("water")
	builder.set_brush_size(1)
	await _stroke([Vector2(35, 10), Vector2(35, 3)], "06-water-stroke")
	_report("waterfalls", TerrainBuilder.waterfalls(builder.ledger.area).size() >= 2)
	await _point_at(Vector2(35, 6), 1)
	await _frames(30)
	await _shot("07-waterfalls")
	game.view.set_zoom(9.0)
	await _frames(60)
	await _shot("08-waterfalls-close")
	game.close_build()
	await _frames(20)
	# Walk up both flights in play.
	game.session.set_physics_process(true)
	game.view.set_zoom(11.0)
	var goal := Vector2i(34, 9)
	_report("route", game.session.walk_to(goal))
	var climbed: bool = false
	var guard: int = 0
	while game.session.player_cell() != goal and guard < 2400:
		await process_frame
		guard += 1
		if not climbed and not game.area.stair_at(game.session.player_cell()).is_empty() and game.session.player_cell() == Vector2i(34, 4):
			climbed = true
			await _frames(4)
			await _shot("09-climbing")
	_report("arrived", game.session.player_cell() == goal)
	await _frames(40)
	await _shot("10-on-top")
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	quit()


## One drag with the chosen land tool through these points (on the ground at their own level), shot just before it
## is let go if `name` is given.
func _stroke(points: Array, name: String) -> void:
	var builder: BuildMode = game.builder
	await _point_at(points[0], game.area.level_at(Vector2i(points[0])))
	builder._left_down = true
	builder._click()
	for index: int in range(1, points.size()):
		await _point_at(points[index], game.area.level_at(Vector2i(points[index])))
	if name != "":
		await _shot(name)
	builder._left_released()
	await _frames(20)


func _point_at(logical: Vector2, level: int = 0) -> void:
	game.view.focus_on(logical, true)
	await process_frame
	var viewport_point: Vector2 = game.view.camera.unproject_position(Vector3(logical.x, float(level) * TerrainBuilder.LEVEL_RISE, -logical.y))
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
	print("Terrain tour: ", name)


func _report(label: String, ok: bool) -> void:
	print("Terrain tour %s: %s" % [label, "ok" if ok else "FAILED"])
