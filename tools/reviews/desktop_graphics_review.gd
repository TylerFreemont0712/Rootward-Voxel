extends "res://test/test_square.gd"
## Native crowd/import and actual-adapter readout review; uses isolated saves.

func go() -> void:
	var args := OS.get_cmdline_user_args()
	output = args[0] if not args.is_empty() else "res://.cache/memory-gpu/desktop"
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 1000)
	root.content_scale_size = root.size
	SaveStore.save_path = "user://graphics_review_%d.json" % OS.get_process_id()
	SaveStore.profile_path = "user://graphics_profile_%d.json" % OS.get_process_id()
	SaveStore.force_enabled = true
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	game.layout_export_override = "res://.cache/memory-gpu/layout.json"
	await process_frame
	await game.start_new_game("sparks-and-machines")
	await game._activate_journey_room_async(AreaStore.read_source("haverlund-square"), {})
	# A direct review load has no transition veil to restore continuous rendering.
	game.world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	game._pop_all_modals()
	game.view.set_camera_mode(WorldView.CameraMode.FREE)
	game.view.focus_on(Vector2(43, 23), true)
	await shot("12-compressed-crowd")
	game.open_settings()
	await shot("13-settings-gpu-1600")
	var panels := game._modals.filter(func(modal: Modal) -> bool: return modal is SettingsPanel)
	_check(panels.size() == 1, "Settings opens over the real square")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	await shot("14-settings-gpu-1280")
	if not panels.is_empty():
		var panel := panels[0] as SettingsPanel
		var bounds := panel.card.get_global_rect()
		_check(root.get_visible_rect().encloses(bounds), "Settings fits the smaller desktop with the GPU name")
	print("Desktop graphics native review: %d checks, %d failures." % [checks, failures.size()])
	for failure: String in failures:
		printerr("FAIL: ", failure)
	SaveStore.delete("sparks-and-machines")
	quit(0 if failures.is_empty() else 1)
