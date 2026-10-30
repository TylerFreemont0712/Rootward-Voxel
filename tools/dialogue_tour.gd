extends SceneTree
## Real conversations, all five new portraits and optional code, with isolated saves.
## VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1600x1000 -s res://tools/dialogue_tour.gd -- <out> [ui_scale]

var game: Game
var out: String = "res://.cache/vn-dialogue/tour"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty(): out = args[0]
	SaveStore.save_path = "user://dialogue_review.json"
	SaveStore.profile_path = "user://dialogue_review_profile.json"
	SaveStore.force_enabled = true
	SaveStore.delete()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game("kindle-hollow")
	game.session.set_physics_process(false)
	game.set_process_unhandled_key_input(false)
	game._hint_timer.stop()
	game.view.villagers.set_process(false)
	if args.size() > 1:
		game.settings.set_value("ui_scale",float(args[1]))
	for id: String in ["mira","rowan","bram","tessa","nell"]:
		var actor: SpriteAdventurer = game.view.villagers.actors[id]
		var at := Vector2i(roundi(actor.position.x),roundi(-actor.position.z))
		var found: bool = false
		for offset: Vector2i in [Vector2i(0,-1),Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1)]:
			var spot: Vector2i = at+offset
			if game.session.rules.is_walkable(game.session.state,spot):
				game.session.state.player = [spot.x,spot.y,0]
				found = true
				break
		if not found:
			push_error("No review approach to "+id)
			quit(1)
			return
		game.view.sync_player(game.session.state)
		game.view.focus_on(Vector2(game.session.player_cell()),true)
		game._refresh_interaction()
		if game._interaction.get("id") != id:
			push_error("Review must use the real F prompt for "+id+": "+str(game._interaction))
			quit(1)
			return
		var before: Dictionary = game.session.state.duplicate(true)
		var source: String = game.session.source
		game.interact()
		var scene: VillageConversation = game._modals[-1]
		_key(KEY_SPACE)
		await process_frame
		if scene.text.visible_characters != -1:
			push_error("Space must reveal the real dialogue page")
			quit(1)
			return
		await _shot(id+"-greeting")
		scene.advance()
		scene.reveal()
		await _shot(id+"-choices")
		scene.choose(str(scene.dialogue.person.topics[1].id))
		scene.reveal()
		scene.advance()
		scene.reveal()
		scene.show_panel("code")
		await _shot(id+"-code")
		if not scene.code_button.visible or game.session.state != before or game.session.source != source:
			push_error("Optional code must leave world and draft unchanged")
			quit(1)
			return
		if id == "mira":
			scene.show_panel("history")
			await _shot("history")
			scene.show_panel("settings")
			await _shot("settings")
			scene.show_panel("")
			_key(KEY_H)
			await process_frame
			await _shot("hidden-ui")
			_key(KEY_ESCAPE)
			await process_frame
			scene.notebook_requested.emit()
			await _shot("notebook-draft-preserved")
			game.close_notebook(true)
		else:
			scene.close()
	game.save_now()
	await game._return_to_title()
	await game.continue_game("kindle-hollow")
	for id: String in ["mira","rowan","bram","tessa","nell"]:
		if not game._dialogue_read.has(id):
			push_error("Continue lost read dialogue for "+id)
			quit(1)
			return
	print("Dialogue tour: all five F conversations, smaller portraits, choices, optional code, controls and saved reads at ",root.size)
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	quit()


func _shot(name: String) -> void:
	for _frame: int in range(40):
		await process_frame
	await RenderingServer.frame_post_draw
	if not game._modals.is_empty() and game._modals[-1] is VillageConversation:
		var scene: VillageConversation = game._modals[-1]
		if not scene.ui_hidden:
			if scene.card.get_rect().end.x > scene.size.x + 2 or scene.card.get_rect().end.y > scene.size.y + 2 or scene.portrait.size.y > scene.size.y * 0.5 + 1:
				push_error("Dialogue and the smaller portrait must fit the viewport")
				quit(1)
				return
			if scene.extra.visible and scene.extra.get_rect().end.y > scene._nameplate.position.y - 4:
				push_error("The optional panel must not cover the speaker's nameplate")
				quit(1)
				return
	var path: String = ProjectSettings.globalize_path(out.path_join(name+".png"))
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	root.get_texture().get_image().save_png(path)
	print("Dialogue reviewed ",name)


func _key(key: Key) -> void:
	var down := InputEventKey.new()
	down.keycode = key
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventKey.new()
	up.keycode = key
	Input.parse_input_event(up)
