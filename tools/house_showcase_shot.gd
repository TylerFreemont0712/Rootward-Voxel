extends SceneTree
## Evidence for the modular houses in the real title → Asset Showcase (Dev) flow: each house's authored look, a
## curated palette and a shuffled street of three.   -- <output directory> [asset id ...]

var game: Game


func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("res://.cache/house-showcase")
	DirAccess.make_dir_recursive_absolute(out)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(5)
	await create_timer(.85).timeout
	game.open_asset_showcase()
	await _frames(5)
	var screen := game._modals[-1] as AssetShowcase
	var ids: Array = Array(OS.get_cmdline_user_args().slice(1))
	if ids.is_empty():
		ids = ["seaside-rosewash-house", "seaside-saltwind-house"]
	for id: String in ids:
		screen.search.text = "seaside"
		screen._filter()
		screen.show_asset(id)
		screen._filter()
		await _shot(out, id + "-authored")
		screen.variant_mode.select(1)
		screen._choose_look()
		await _shot(out, id + "-palette")
		screen.variant_seed = 4
		screen.shuffle_variant()
		screen.street.button_pressed = true
		await _shot(out, id + "-street")
		screen.street.button_pressed = false
	quit()


func _shot(out: String, name: String) -> void:
	await _frames(12)
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png(out.path_join(name + ".png"))
	print("Saved ", out.path_join(name + ".png"))


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame
