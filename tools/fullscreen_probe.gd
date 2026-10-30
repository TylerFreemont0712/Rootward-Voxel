extends SceneTree
## Fullscreen review inside houses: enters one house of each room template, walks the apprentice round the room,
## leaves again, and checks every rendered frame for strongly green pixels while indoors (the reported "green
## flash"; a room has no green surfaces). Saves the first suspect frames. With `toggle` it stays in the first house
## and switches fullscreen off and on every 45 frames instead. It takes over the screen while it runs; record the real
## screen alongside it (for example `ffmpeg -f x11grab`) to catch what happens after the game's own output.
## VOXEL_LAB_FRESH=1 scripts/play.sh -s res://tools/fullscreen_probe.gd -- <out dir> [frames per room] [toggle]

const HOUSES: Array[String] = ["home", "row-workshop", "cedar-lodge", "mill", "mira-house"]
var game: Game
var output: String = "res://.cache/fullscreen-probe"
var suspects: int = 0
var frames_seen: int = 0
var _room: String = ""
var _frame: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
	var frames: int = int(args[1]) if args.size() > 1 else 300
	var toggling: bool = args.size() > 2 and args[2] == "toggle"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	SaveStore.save_path = "user://probe_save.json"
	SaveStore.profile_path = "user://probe_profile.json"
	SaveStore.force_enabled = true
	SaveStore.delete()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	game.settings.set_value("ui_scale", 0.8)
	game.settings.set_value("fullscreen", true)
	await game.start_new_game("kindle-hollow")
	game._hint_timer.stop()
	for id: String in game.session.state.gates:
		game.session.state.gates[id] = true
	for bridge: Dictionary in game.area.bridges:
		game.session.state.bridges[bridge.id] = bridge.sockets.size()
	game.view.apply_state(game.session.state)
	RenderingServer.frame_post_draw.connect(_check)
	print("PROBE window=%s viewport=%s world=%s" % [str(root.size), str(root.get_visible_rect().size), str(game.world_viewport.size)])
	for house: String in (["home"] as Array[String]) if toggling else HOUSES:
		var door: Vector2i = HouseInstances.door(game.area, house)
		game.session.prepare_travel()
		game.session.state.player = [door.x, door.y, 0]
		game.view.sync_player(game.session.state)
		game.session._after_change(false)
		game.view.focus_on(Vector2(door), true)
		for _tick: int in range(20):
			await process_frame
		_room = house
		if not await game.enter_house(house):
			push_error("Probe could not enter " + house)
			continue
		var corners: Array[Vector2i] = [Vector2i(game.area.width - 2, game.area.height - 2), Vector2i(1, 1), Vector2i(game.area.width - 2, 1), Vector2i(1, game.area.height - 2)]
		var leg: int = 0
		for _step: int in range(frames):
			if toggling and _step % 45 == 0:
				game.settings.set_value("fullscreen", not bool(game.settings.get_value("fullscreen")))
			if not game.session.is_walking():
				game.session.walk_to(corners[leg % corners.size()])
				leg += 1
			await process_frame
		var exit: Array = game.area.interior.exit
		game.session.prepare_travel()
		game.session.state.player = [int(exit[0]), int(exit[1]), 0]
		game.view.sync_player(game.session.state)
		game.session._after_change(false)
		await game.leave_house()
	RenderingServer.frame_post_draw.disconnect(_check)
	print("PROBE done: %d of %d indoor frames had green pixels" % [suspects, frames_seen])
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	quit()


func _check() -> void:
	_frame += 1
	if game == null or not is_instance_valid(game) or not game.inside_house():
		return
	var label: String = _room
	var frame: int = _frame
	frames_seen += 1
	var image: Image = root.get_texture().get_image()
	var found: Dictionary = _green(image)
	if found.count == 0:
		return
	suspects += 1
	if suspects <= 12:
		image.save_png(ProjectSettings.globalize_path(output.path_join("suspect-%s-%04d.png" % [label, frame])))
	print("PROBE %s frame %d: %d green pixels, first at %s, colour %s" % [label, frame, found.count, str(found.at), str(found.colour)])


## Strongly green pixels anywhere in the frame: green well above red and blue.
func _green(image: Image) -> Dictionary:
	var result: Dictionary = {"count": 0, "at": Vector2i(-1, -1), "colour": Color()}
	for y: int in range(0, image.get_height(), 3):
		for x: int in range(0, image.get_width(), 3):
			var c: Color = image.get_pixel(x, y)
			if c.g > 0.35 and c.g > c.r + 0.15 and c.g > c.b + 0.1:
				if result.count == 0:
					result.at = Vector2i(x, y)
					result.colour = c
				result.count += 1
	return result
