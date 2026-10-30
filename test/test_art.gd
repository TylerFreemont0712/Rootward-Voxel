extends SceneTree
## Approved painted keys, mirrors, neutral idle, cosmetic timing and walk phase.

const Actor := preload("res://art/sprite_actor.gd")
var _failures: Array[String] = []
var _checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/art-catalog.json"))
	var spec: Dictionary = preload("res://pipeline/character_contract.gd").resolve(config.character)
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(spec.manifest))
	var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(spec.provenance))
	_check(metadata.facing_space == "screen_diagonals", "Atlas declares screen-diagonal facings")
	_check(metadata.source_sha256 == FileAccess.get_sha256(spec.source), "Manifest matches selected source")
	_check(FileAccess.get_sha256(spec.source) == FileAccess.get_sha256(spec.runtime_sheet), "Runtime preserves prepared atlas bytes")
	_check(provenance.output_sha256 == FileAccess.get_sha256(spec.source), "Provenance matches selected atlas")
	for source: String in provenance.sources:
		_check(FileAccess.get_sha256(source) == provenance.sources[source], "Approved input remains unchanged: " + source.get_file())
	var image := Image.load_from_file(ProjectSettings.globalize_path(spec.runtime_sheet))
	_check(image.detect_alpha(), "Character atlas has real transparency")
	_check((load(spec.runtime_sheet) as Texture2D).get_image().has_mipmaps(), "Sprite imports mipmaps")
	_check(is_equal_approx(8.0 / float(spec.fps), 2.0 * preload("res://core/lab_world.gd").STEP_SECONDS), "Eight poses retain their two-step cycle")
	for direction: String in spec.directions:
		var record: Dictionary = provenance.directions[direction]
		var exact := true
		for index in range(record.transforms.size()):
			var transform: Dictionary = record.transforms[index]
			var raw := Image.load_from_file(ProjectSettings.globalize_path(transform.source))
			if index < 9:
				raw = raw.get_region(Rect2i((index % 3) * 418, (index / 3) * 418, 418, 418))
			var padded := Image.create(384, 448, false, Image.FORMAT_RGBA8)
			padded.blit_rect(raw, Rect2i(Vector2i.ZERO, raw.get_size()), Vector2i(int(transform.translation[0]), int(transform.translation[1])))
			var output := image.get_region(Rect2i((index % 4) * 384, (int(record.row) + index / 4) * 448, 384, 448))
			exact = exact and padded.get_data() == output.get_data() and _sha(output.get_data()) == record.key_rgba_sha256[index]
		_check(exact, direction + " preserves all approved pose/idle/blink pixels after integer registration")
		var idle_frame: Dictionary = metadata.animations["idle_" + direction][0]
		_check(idle_frame.region == [0.0, float((int(record.row) + 2) * 448), 384.0, 448.0], direction + " uses source pose 9 for neutral idle")
	_check_mirror("SE", "SW")
	_check_mirror("NE", "NW")
	var source_dir: String = spec.source.get_base_dir()
	var blink := Image.load_from_file(ProjectSettings.globalize_path(source_dir + "/blink-se.png"))
	var neutral := Image.load_from_file(ProjectSettings.globalize_path(source_dir + "/SE.png")).get_region(Rect2i(836, 836, 418, 418))
	var eye_changes := 0
	var outside_unchanged := true
	for y in range(418):
		for x in range(418):
			if neutral.get_pixel(x, y) != blink.get_pixel(x, y):
				eye_changes += 1
				outside_unchanged = outside_unchanged and Rect2i(194, 105, 86, 51).has_point(Vector2i(x, y))
	_check(eye_changes > 0 and eye_changes < 2000 and outside_unchanged, "Blink changes only the two eye patches")
	blink.flip_x()
	var sw_blink := Image.load_from_file(ProjectSettings.globalize_path(source_dir + "/blink-sw.png"))
	_check(blink.get_data() == sw_blink.get_data(), "SW blink exactly mirrors SE blink")
	var actor := Actor.new()
	root.add_child(actor)
	actor.set_process(false)
	await process_frame
	_check(actor.sprite is AnimatedSprite3D and not actor.sprite.no_depth_test, "Painted sprite respects 3D depth")
	_check(actor.sprite.animation == &"idle_se" and actor.sprite.frame == 0, "Actor starts in open-eye neutral SE idle")
	var directions: Dictionary = {"se": Vector2(1, 0.5), "sw": Vector2(-1, 0.5), "ne": Vector2(1, -0.5), "nw": Vector2(-1, -0.5)}
	for direction: String in directions:
		actor.set_screen_motion(directions[direction])
		_check(actor.sprite.sprite_frames.get_frame_count("walk_" + direction) == 8, direction + " has the eight approved walk poses")
		_check(str(actor.sprite.animation) == "walk_" + direction and not actor.sprite.flip_h, direction + " selects its compiled directional art")
		actor.sprite.set_frame_and_progress(5, 0.3)
		actor.set_screen_motion(directions[direction])
		_check(actor.sprite.frame == 5 and is_equal_approx(actor.sprite.frame_progress, 0.3), direction + " held input keeps walk phase")
		actor.set_screen_motion(Vector2.ZERO)
		_check(actor.animation_name == "idle_" + direction and actor.sprite.frame == 0 and not actor.sprite.is_playing(), direction + " stops on its neutral idle")
		var expected_count := 2 if direction in ["se", "sw"] else 1
		_check(actor.sprite.sprite_frames.get_frame_count("idle_" + direction) == expected_count, direction + " has only the required idle art")
		var first_blink := actor._next_blink_at
		_check(first_blink >= 6.0 and first_blink <= 7.0, direction + " first blink timer is 6-7 seconds")
		var offset := actor.sprite.offset
		var location := actor.position
		actor._advance_idle(float(spec.idle.breath_period) * 0.5)
		var amplitude: float = float(spec.idle.breath_amplitude if direction in ["se", "sw"] else spec.idle.rear_breath_amplitude)
		_check(is_equal_approx(actor.sprite.scale.y, 1.0 + amplitude) and actor.sprite.scale.x == 1.0, direction + " has a slight vertical breath")
		_check(actor.position == location and actor.sprite.offset == offset, direction + " breath retains foot origin and authoritative position")
		var elapsed := actor._idle_seconds
		var scale_before := actor.sprite.scale
		actor.set_screen_motion(Vector2.ZERO)
		_check(actor._idle_seconds == elapsed and actor._next_blink_at == first_blink and actor.sprite.scale == scale_before, direction + " repeated idle input does not restart breath/blink")
		actor._advance_idle(float(spec.idle.breath_period) * 0.5)
		_check(is_equal_approx(actor.sprite.scale.y, 1.0), direction + " breath returns after a few seconds")
		actor._advance_idle(first_blink - actor._idle_seconds + 0.001)
		_check(actor.sprite.frame == (1 if direction in ["se", "sw"] else 0), direction + " blink deadline closes only visible front-facing eyes")
		_check(actor._next_blink_at - first_blink >= 6.0 and actor._next_blink_at - first_blink <= 7.0, direction + " repeated blink starts remain 6-7 seconds apart")
		actor._advance_idle(float(spec.idle.blink_duration) + 0.01)
		_check(actor.sprite.frame == 0, direction + " blink reopens promptly")
		actor._advance_idle(actor._next_blink_at - actor._idle_seconds + 0.001)
		_check(actor.sprite.frame == (1 if direction in ["se", "sw"] else 0), direction + " idle continues blinking without a loop reset")
		actor.set_screen_motion(directions[direction])
		_check(actor.sprite.scale == Vector3.ONE and actor.sprite.frame == 0 and actor.sprite.is_playing(), direction + " starting to walk cancels idle effects")
		actor.sprite.set_frame_and_progress(2, 0.3)
		actor._advance_idle(8.0)
		_check(actor.sprite.frame == 2 and actor.sprite.scale == Vector3.ONE, direction + " never breathes or blinks during walking")
	actor.sprite.set_frame_and_progress(2, 0.3)
	actor.set_screen_motion(directions.se)
	_check(actor.sprite.frame == 2 and is_equal_approx(actor.sprite.frame_progress, 0.3), "Changing direction retains walk phase")
	for animation: String in metadata.animations:
		var valid := true
		for frame: Dictionary in metadata.animations[animation]:
			valid = valid and frame.anchor == [192.0, 420.0] and float(frame.anchor[1]) < float(frame.region[3])
		_check(valid, animation + " keeps one fixed foot origin")
	actor.queue_free()
	await process_frame
	if _failures.is_empty():
		print("Painted art and idle contract: %d checks passed." % _checks)
		quit()
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		quit(1)


func _check_mirror(right: String, left: String) -> void:
	var directory := "res://art/source/adventurer/v9-directional-walk/"
	var original := Image.load_from_file(ProjectSettings.globalize_path(directory + right + ".png"))
	var mirror := Image.load_from_file(ProjectSettings.globalize_path(directory + left + ".png"))
	var exact := true
	for i in range(9):
		var region := Rect2i((i % 3) * 418, (i / 3) * 418, 418, 418)
		var pose := original.get_region(region)
		pose.flip_x()
		exact = exact and pose.get_data() == mirror.get_region(region).get_data()
	_check(exact, left + " mirrors all matching " + right + " cells without reordering")


func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)


func _sha(data: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(data)
	return context.finish().hex_encode()
