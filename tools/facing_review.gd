extends SceneTree
## Four actual held-key walks through the game's shared camera/facing adapter, in the real scene.

var _captured: int = 0
var _ticks: int = 0
var _directory: String
var game: Game


func _initialize() -> void:
	_review.call_deferred()


func _review() -> void:
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await physics_frame
	await game.start_new_game("kindle-hollow")
	root.grab_focus()
	game.surface.grab_focus()
	for _tick: int in range(8):
		await physics_frame
	var session: GameSession = game.session
	_directory = ProjectSettings.globalize_path("res://.cache/facing-review")
	DirAccess.make_dir_recursive_absolute(_directory)
	var seen: Array[String] = []
	var axes: Dictionary = {KEY_D: Vector2i(1, 0), KEY_W: Vector2i(0, 1), KEY_A: Vector2i(-1, 0), KEY_S: Vector2i(0, -1)}
	var axis_ok: bool = true
	var cases: Dictionary = {KEY_D: "se", KEY_W: "ne", KEY_A: "nw", KEY_S: "sw"}
	for key: int in cases:
		var before: Vector2i = session.player_cell()
		_key(key, true)
		for _tick: int in range(19):
			await _frame()
			if session.is_walking() and str(game.view._body.animation_name) == "walk_" + str(cases[key]) and not seen.has(cases[key]):
				seen.append(cases[key])
		_key(key, false)
		while session.is_walking():
			await _frame()
		var delta: Vector2i = session.player_cell() - before
		axis_ok = axis_ok and (delta.x * axes[key].x + delta.y * axes[key].y) > 0 and delta.x * axes[key].y - delta.y * axes[key].x == 0
		for _tick: int in range(6):
			await _frame()
	var okay: bool = seen.size() == 4 and axis_ok
	print("Four-direction input review: ", seen, ", each key follows its logical axis=", axis_ok, ", frames=", _captured)
	quit(0 if okay else 1)


func _frame() -> void:
	await physics_frame
	await RenderingServer.frame_post_draw
	if _ticks % 3 == 0:
		game.world_viewport.get_texture().get_image().save_png(_directory.path_join("frame-%03d.png" % _captured))
		_captured += 1
	_ticks += 1


func _key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
