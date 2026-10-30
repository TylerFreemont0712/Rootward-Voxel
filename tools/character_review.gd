extends SceneTree
## Actual shared-frame boy/Mira actors, the boy's Character screen and grid movement.
## Usage: scripts/play.sh --resolution 1600x1000 -s res://tools/character_review.gd -- <output dir>

var output: String


func _initialize() -> void:
	Engine.max_fps = 32
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	output = args[0] if not args.is_empty() else ProjectSettings.globalize_path("res://.cache/mira-review")
	DirAccess.make_dir_recursive_absolute(output.path_join("walk"))
	DirAccess.make_dir_recursive_absolute(output.path_join("idle"))
	var study := load("res://tools/skin_study.tscn").instantiate() as Node3D
	root.add_child(study)
	await _frames(20)
	await _shot("directions")
	for index: int in range(32):
		await _frames(2)
		await _shot("walk/frame-%03d" % index)
	for node: Node in get_nodes_in_group("skin_review_actors"):
		var actor := node as SpriteAdventurer
		actor.set_screen_motion(Vector2.ZERO)
		actor.set_process(false)
		actor._next_blink_at = 6.2
	var blink_seen := 0
	for index: int in range(64):
		await _frames(4)
		var closed := 0
		for node: Node in get_nodes_in_group("skin_review_actors"):
			var actor := node as SpriteAdventurer
			actor._advance_idle(0.125)
			if actor.sprite.frame == 1:
				closed += 1
		blink_seen = maxi(blink_seen, closed)
		await _shot("idle/frame-%03d" % index)
		if closed == 4:
			await _shot("blink")
	if blink_seen != 4:
		printerr("Expected both front-facing blinks on both characters, observed ", blink_seen)
		quit(1)
		return
	root.remove_child(study)
	study.queue_free()
	# Keep review New Journey and profile operations away from player files.
	SaveStore.save_path = "user://mira_review.save.json"
	SaveStore.profile_path = "user://mira_review.profile.json"
	var game := load("res://scenes/game.tscn").instantiate() as Game
	root.add_child(game)
	await _frames(40)
	game._open_character("view", {})
	await _frames(12)
	var character := game._modals[-1] as CharacterScreen
	(character._skin_buttons.adventurer as BaseButton).pressed.emit()
	await _frames(12)
	await _shot("character")
	if character._actor.skin_id != "adventurer" or (game.view._body as SpriteAdventurer).skin_id != "adventurer" or character._skin_buttons.has("mira"):
		printerr("The Character screen must keep the boy as the player and Mira as a resident.")
		quit(1)
		return
	game._pop_all_modals()
	await game.start_new_game("kindle-hollow")
	await _frames(20)
	await _shot("gameplay")
	root.grab_focus()
	game.surface.grab_focus()
	if DisplayServer.get_name() == "X11":
		var handle := DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE)
		# An automated second window can be denied focus by the desktop's focus-stealing policy.
		# This is an optional authoring-tool aid; normal play does not call wmctrl.
		OS.execute("wmctrl", PackedStringArray(["-ia", "0x%x" % handle]))
	await _frames(8)
	var target := Vector2i(29, 14)
	game.session.click_cell(target)
	var waited := 0
	while game.session.player_cell() != target and waited < 600:
		if not DisplayServer.window_is_focused():
			root.grab_focus()
		if game.session._route.is_empty() and not game.session.is_walking():
			game.session.click_cell(target)
		await process_frame
		waited += 1
	if game.session.player_cell() != target:
		printerr("The boy could not follow the real grid route to the green; cell=", game.session.player_cell(), "; window focused=", DisplayServer.window_is_focused())
		quit(1)
		return
	await _frames(10)
	await _shot("green")
	print("Character review: boy/Mira shared walks, four front blinks, boy-only player controls and grid route at ", root.size)
	quit()


func _frames(count: int) -> void:
	for _index: int in range(count):
		await process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))
