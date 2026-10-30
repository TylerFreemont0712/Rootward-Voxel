extends SceneTree
## All six identities in four views at approximately gameplay pixel height, including real idle blinks.

const IDS: Array[String] = ["adventurer", "sparks_nell", "sparks_mira", "sparks_rowan", "sparks_bram", "sparks_tessa"]
const DIRS: Array[Vector2] = [Vector2(1, 0.5), Vector2(-1, 0.5), Vector2(1, -0.5), Vector2(-1, -0.5)]
var actors: Array[SpriteAdventurer] = []
var output: String


func _initialize() -> void:
	Engine.max_fps = 32
	_run.call_deferred()


func _run() -> void:
	output = ProjectSettings.globalize_path("res://.cache/sparks-v072-native-%dx%d" % [root.size.x,root.size.y])
	for folder: String in ["walk", "idle"]:
		DirAccess.make_dir_recursive_absolute(output.path_join(folder))
	var view := ClearingView.new()
	root.add_child(view)
	view.set_process(false)
	view.camera.size = 13.5
	view.camera.look_at_from_position(Vector3(21, 17.8, 21), Vector3(0, 0.5, 0))
	var across := Vector3(0.7071, 0, -0.7071)
	var back := Vector3(-0.7071, 0, -0.7071)
	for row: int in range(IDS.size()):
		for column: int in range(DIRS.size()):
			var at: Vector3 = across * (-5.25 + column * 3.5) + back * (10.0 - row * 4.0)
			view._block(at + Vector3(0, -0.07, 0), Vector3(1.4, 0.14, 1.4), "path")
			var actor := SpriteAdventurer.new()
			actor.skin_id = IDS[row]
			view.add_child(actor)
			actor.position = at
			actor.set_screen_motion(DIRS[column])
			actors.append(actor)
			var label := Label3D.new()
			label.text = ("Boy" if row == 0 else IDS[row].trim_prefix("sparks_").capitalize()) + " · " + ["SE", "SW", "NE", "NW"][column]
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.font_size = 32
			label.pixel_size = 0.006
			label.position = at + Vector3(0, 1.85, 0)
			view.add_child(label)
	view._flush_batches()
	await _frames(20)
	await _shot("directions")
	for index: int in range(32):
		await _frames(2)
		await _shot("walk/frame-%03d" % index)
	for actor: SpriteAdventurer in actors:
		actor.set_screen_motion(Vector2.ZERO)
		actor.set_process(false)
		actor._next_blink_at = 6.2
	var blink_seen: int = 0
	for index: int in range(64):
		await _frames(4)
		var closed: int = 0
		for actor: SpriteAdventurer in actors:
			actor._advance_idle(0.125)
			if actor.sprite.frame == 1:
				closed += 1
		blink_seen = maxi(blink_seen, closed)
		await _shot("idle/frame-%03d" % index)
		if closed == IDS.size() * 2:
			await _shot("blink")
	print("Sparks cast review: 24 actors, four walks per identity; %d front blinks, rear views remain open." % blink_seen)
	quit(0 if blink_seen == IDS.size() * 2 else 1)


func _frames(count: int) -> void:
	for _index: int in range(count):
		await process_frame


func _shot(id: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(id + ".png"))
