extends SceneTree
## Windowed gameplay review; uses isolated scratch saves and real house transitions.
## VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1600x1000 -s res://tools/village_tour.gd

const DEST: String = "res://.cache/village-expansion/tour"
const SELECTED: Array[String] = ["01-start-boundary", "02-mira-conversation", "03-north-common", "05-east-bank", "06-water-a", "conversation-nell", "room-home", "room-mira-house", "builder-houses", "builder-trees"]
var game: Game
var output: String = DEST
var select_evidence: bool = true


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
		select_evidence = false
	SaveStore.save_path = "user://village_review_save.json"
	SaveStore.profile_path = "user://village_review_profile.json"
	SaveStore.force_enabled = true
	SaveStore.delete()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game("kindle-hollow")
	# Desktop keys typed while an authoring window is focused must not move the review subject.
	game.session.set_physics_process(false)
	game.set_process_unhandled_key_input(false)
	game._hint_timer.stop()
	if args.size() > 1 and args[1] == "menus":
		await _room_menus()
		return
	await _capture("01-start-boundary")
	for resident: Dictionary in game.area.villagers:
		if resident.id != "mira":
			continue
		_teleport(resident.at + Vector2i(0, -1))
		game._refresh_interaction()
		game.interact()
	await _capture("02-mira-conversation")
	game._pop_all_modals()
	# Review the new districts with the existing quest crossings open.
	for id: String in game.session.state.gates:
		game.session.state.gates[id] = true
	for bridge: Dictionary in game.area.bridges:
		game.session.state.bridges[bridge.id] = bridge.sockets.size()
	game.view.apply_state(game.session.state)
	for shot: Array in [["03-north-common", HouseInstances.door(game.area, "mira-house")], ["04-cedar-rise", HouseInstances.door(game.area, "cedar-lodge")], ["05-east-bank", Vector2i(73, 32)], ["06-water-a", Vector2i(48, 21)]]:
		_teleport(shot[1])
		await _capture(shot[0])
	await _capture("07-water-b")
	for id: String in ["rowan", "bram", "tessa", "nell"]:
		game.view.villagers.paused = true
		game.view.villagers.set_process(false)
		var actor: SpriteAdventurer = game.view.villagers.actors[id]
		var at := Vector2i(roundi(actor.position.x), roundi(-actor.position.z))
		_teleport(at + Vector2i(0, -1))
		(game.view.villagers.actors[id] as SpriteAdventurer).set_screen_motion(Vector2.ZERO)
		await _capture("resident-" + id)
		game._refresh_interaction()
		if game._interaction.get("kind") != "talk" or game._interaction.get("id") != id:
			push_error("Review must talk to " + id + ": " + str(game._interaction))
			quit(1)
			return
		game.interact()
		await _capture("conversation-" + id)
		game._pop_all_modals()
		game.view.villagers.set_process(true)
	for id: String in ["home", "loft-west", "riverside-loft", "mill", "mira-house"]:
		_teleport(HouseInstances.door(game.area, id))
		if not await game.enter_house(id):
			push_error("Review could not enter " + id)
			quit(1)
			return
		game.session.state.lamps["hearth-lamp"] = true
		game.view.apply_state(game.session.state)
		await _capture("room-" + id)
		game.session.set_physics_process(true)
		Engine.time_scale = 3.0
		var destination := Vector2i(game.area.width - 2, game.area.height - 2)
		var walking: bool = game.session.walk_to(destination)
		var guard: int = 0
		while walking and game.session.player_cell() != destination and guard < 1200:
			await physics_frame
			guard += 1
		Engine.time_scale = 1.0
		game.session.set_physics_process(false)
		if not walking or game.session.player_cell() != destination:
			push_error("Room review could not walk around furniture in " + id)
			quit(1)
			return
		await _capture("room-far-" + id)
		var exit: Array = game.area.interior.exit
		_teleport(Vector2i(int(exit[0]), int(exit[1])))
		if not await game.leave_house():
			push_error("Review could not leave " + id)
			quit(1)
			return
	game.open_build()
	game.builder.hud._choose_category("houses")
	await _capture("builder-houses", 240)
	game.builder.hud._choose_category("trees")
	await _capture("builder-trees", 240)
	game.close_build()
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	quit()


func _room_menus() -> void:
	_teleport(HouseInstances.door(game.area, "mira-house"))
	if not await game.enter_house("mira-house"):
		quit(1)
		return
	game.open_pause()
	await _capture("room-pause")
	game._open_character("view", {})
	await _capture("room-character")
	game._pop_all_modals()
	game._confirm_reset()
	await _capture("room-reset")
	game._pop_all_modals()
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	quit()


func _teleport(at: Vector2i) -> void:
	game.session.prepare_travel()
	game.session.state.player = [at.x, at.y, 0]
	if not game.session.rules.is_walkable(game.session.state, at):
		push_error("Review position must be walkable: " + str(at))
	game.view.sync_player(game.session.state)
	game.session._after_change(false)
	game.view.focus_on(Vector2(at), true)
	game._refresh_interaction()


func _capture(id: String, frames: int = 100) -> void:
	for _frame: int in range(frames):
		await process_frame
	await RenderingServer.frame_post_draw
	var started: int = Time.get_ticks_msec()
	for _frame: int in range(60):
		await process_frame
	var fps: float = 60000.0 / maxf(1.0, Time.get_ticks_msec() - started)
	var path: String = ProjectSettings.globalize_path(output.path_join(id + ".png"))
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	root.get_texture().get_image().save_png(path)
	if select_evidence and id in SELECTED:
		var selected: String = ProjectSettings.globalize_path("res://evidence/village-expansion/" + id + ".png")
		DirAccess.make_dir_recursive_absolute(selected.get_base_dir())
		DirAccess.copy_absolute(path, selected)
	print("Village review %s: %.0f fps -> %s" % [id, fps, path])
