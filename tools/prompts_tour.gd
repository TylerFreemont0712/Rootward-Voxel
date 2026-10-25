extends SceneTree
## Windowed review of F's prompts in the world: the speech bubble over a resident, residents' "!" and "?" marks,
## the hand over a working thing, and the apprentice stopping at a resident instead of walking through.
## VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1600x1000 -s res://tools/prompts_tour.gd -- <absolute output directory>

var game: Game
var out: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else ProjectSettings.globalize_path("res://.cache/prompts-tour")
	DirAccess.make_dir_recursive_absolute(out)
	SaveStore.save_path = "user://prompts_tour_save.json"
	SaveStore.profile_path = "user://prompts_tour_profile.json"
	SaveStore.force_enabled = true
	SaveStore.delete()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(30)
	await game.start_new_game()
	game.session.set_physics_process(false)
	game._hint_timer.stop()
	game.view.villagers.set_process(false)
	var mira: SpriteAdventurer = game.view.villagers.actors.mira
	var cell := Vector2i(Vector2(mira.position.x, -mira.position.z).round())
	# A little way off: Mira wears her "!" (she has never been met).
	_teleport(cell + Vector2i(3, -3))
	await _shot("01-mark")
	# Beside her: the bubble, carrying her mark, with the F key.
	_teleport(cell + Vector2i(0, -1))
	await _shot("02-bubble")
	# Everything heard: just the bubble.
	game._dialogue_read["mira"] = VillageDialogue.page_keys(game._people.mira)
	game._met_villagers["mira"] = true
	await _shot("03-bubble-plain")
	# The current lesson is one a resident can help with: "?".
	game.session.completed = ["first-light"]
	game.session.quest_changed.emit()
	for id: String in game.session.state.gates:
		game.session.state.gates[id] = true
	for bridge: Dictionary in game.area.bridges:
		game.session.state.bridges[bridge.id] = bridge.sockets.size()
	game.view.apply_state(game.session.state)
	var rowan: SpriteAdventurer = game.view.villagers.actors.rowan
	_teleport(Vector2i(Vector2(rowan.position.x, -rowan.position.z).round()) + Vector2i(-2, -3))
	await _shot("04-help-marks")
	# A working chest gets a hand.
	_teleport(cell + Vector2i(6, -3))
	game.open_build()
	var placed: Dictionary = game.ledger.place("hollow-wayfarers-chest", Vector2(cell.x + 6, cell.y - 2), "S", game.session.state)
	if placed.ok:
		game.builder._after_edit("Placed a chest")
	game.close_build()
	await _frames(10)
	_teleport(cell + Vector2i(6, -3))
	await _shot("05-hand")
	# Walking into Mira stops beside her.
	_teleport(cell + Vector2i(0, -1))
	game.session.request_step(Vector2i(0, 1))
	print("Prompts tour: walked into Mira -> stayed at %s, facing %s" % [str(game.session.player_cell()), str(game.session.facing)])
	await _shot("06-blocked")
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	quit()


func _teleport(at: Vector2i) -> void:
	game.session.prepare_travel()
	game.session.state.player = [at.x, at.y, 0]
	game.view.sync_player(game.session.state)
	game.session._after_change(false)
	game.view.focus_on(Vector2(at), true)
	game._refresh_interaction()


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame


func _shot(name: String) -> void:
	await _frames(40)
	game._refresh_interaction()
	await _frames(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("Prompts tour: ", name, " target=", game.prompts.target, " marks=", game.prompts.markers)
