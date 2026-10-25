extends SceneTree
## A skin cannot redefine motion; switching appearance never resets actor state.

const Actor := preload("res://art/sprite_actor.gd")
const Contract := preload("res://pipeline/character_contract.gd")
const Builder := preload("res://pipeline/frame_skin_builder.gd")
const Skins := preload("res://art/frame_skin.gd")
var _checks := 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var template: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Contract.TEMPLATE))
	_check(Contract.template_errors(template).is_empty(), "Common template is valid")
	var broken: Dictionary = template.duplicate(true)
	broken.settings.frame_anchor = [0, 0]
	_check(not Contract.template_errors(broken).is_empty(), "Reject a changed common foot origin")
	broken = template.duplicate(true)
	broken.settings.idle.breath_period = 0
	_check(not Contract.template_errors(broken).is_empty(), "Reject invalid idle cadence")
	var catalog := Builder.read_catalog()
	_check(not catalog.is_empty(), "Shared skin catalog is valid")
	broken = catalog.duplicate(true)
	broken.skins.adventurer.fps = 24
	_check(not Builder.catalog_errors(broken).is_empty(), "Skin cannot override walk timing")
	broken = catalog.duplicate(true)
	broken.skins.adventurer.frame_anchor = [0, 0]
	_check(not Builder.catalog_errors(broken).is_empty(), "Skin cannot override frame registration")
	broken = catalog.duplicate(true)
	broken.active = "missing"
	_check(not Builder.catalog_errors(broken).is_empty(), "Reject an unregistered active skin")
	broken = catalog.duplicate(true)
	broken.skins.mira.selectable = "yes"
	_check(not Builder.catalog_errors(broken).is_empty(), "Appearance visibility must be an explicit boolean")
	broken = catalog.duplicate(true)
	broken.skins.adventurer.tint = [1, 1, 1, 0]
	_check(not Builder.catalog_errors(broken).is_empty(), "Reject an invisible actor tint")
	broken = catalog.duplicate(true)
	broken.skins.adventurer.erase("atlas")
	broken.skins.adventurer.source = "res://art/source/example.png"
	broken.skins.adventurer.runtime = "res://art/source/overwrite.png"
	_check(not Builder.catalog_errors(broken).is_empty(), "Skin output cannot overwrite authored sources")
	broken.skins.adventurer.runtime = "res://assets/characters/skins/example.png"
	_check(not Builder.catalog_errors(broken).is_empty(), "Authored skin requires source provenance")
	var library := Skins.read_library()
	_check(library.active == "adventurer" and library.skins.size() >= 2, "Approved default and second appearance are registered")
	_check(library.template.sha256 == FileAccess.get_sha256(Contract.TEMPLATE), "Runtime library matches common template")
	var actor := Actor.new()
	root.add_child(actor)
	actor.set_process(false)
	await process_frame
	_check(actor.skin_id == "adventurer" and actor.sprite.modulate == Color("fff5e8"), "Approved art remains the unchanged default")
	var frames := actor.sprite.sprite_frames
	actor.set_screen_motion(Vector2(1, 0.5))
	actor.sprite.set_frame_and_progress(5, 0.35)
	var offset := actor.sprite.offset
	var position_before := actor.position
	_check(actor.set_skin("adventurer_twilight"), "Switch to second registered skin")
	_check(actor.sprite.sprite_frames == frames, "Tint skins share the identical SpriteFrames resource")
	_check(actor.sprite.frame == 5 and is_equal_approx(actor.sprite.frame_progress, 0.35) and actor.sprite.is_playing(), "Skin swap preserves active walk frame and subframe")
	_check(actor.sprite.offset == offset and actor.position == position_before, "Skin swap retains foot registration and position")
	_check(actor.sprite.modulate != Color("fff5e8"), "Second skin changes appearance")
	actor.set_screen_motion(Vector2.ZERO)
	actor._advance_idle(actor._next_blink_at + 0.001)
	var idle_seconds := actor._idle_seconds
	var next_blink := actor._next_blink_at
	var breath_scale := actor.sprite.scale
	_check(actor.sprite.frame == 1, "Prepared an active idle blink")
	_check(actor.set_skin("adventurer"), "Restore approved appearance")
	_check(actor.sprite.frame == 1 and not actor.sprite.is_playing(), "Skin swap retains the closed-eye idle state")
	_check(actor._idle_seconds == idle_seconds and actor._next_blink_at == next_blink and actor.sprite.scale == breath_scale, "Skin swap preserves breathing and blink clocks")
	_check(not actor.set_skin("unknown") and actor.skin_id == "adventurer" and actor.sprite.frame == 1, "Unknown skin leaves the current actor unchanged")
	var alternate := ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(library.template.atlas)))
	var retargeted := Skins.frames_for(frames, alternate)
	var same_motion := true
	var separate_art := true
	for animation: StringName in frames.get_animation_names():
		same_motion = same_motion and frames.get_frame_count(animation) == retargeted.get_frame_count(animation) and frames.get_animation_speed(animation) == retargeted.get_animation_speed(animation) and frames.get_animation_loop(animation) == retargeted.get_animation_loop(animation)
		for index in range(frames.get_frame_count(animation)):
			var original := frames.get_frame_texture(animation, index) as AtlasTexture
			var replacement := retargeted.get_frame_texture(animation, index) as AtlasTexture
			same_motion = same_motion and original.region == replacement.region and frames.get_frame_duration(animation, index) == retargeted.get_frame_duration(animation, index)
			separate_art = separate_art and replacement.atlas == alternate and original.atlas != alternate
	_check(same_motion, "Authored alternate atlas inherits every frame, region, duration, speed and loop")
	_check(separate_art, "Retargeting art never mutates the approved frame textures")
	_check(Skins.frames_for(frames, alternate) == retargeted, "Actors reuse cached frames for an alternate atlas")
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(library.template.manifest))
	_check(Builder._check_atlas(library.template.atlas, metadata), "Approved atlas satisfies custom-skin alignment validation")
	_check(library.skins.has("mira") and library.skins.mira.atlas != library.template.atlas, "Mira is a separately authored appearance, not a tint")
	_check(Builder._check_atlas(library.skins.mira.atlas, metadata), "Every Mira walk, neutral and blink frame fits the common footprint and height")
	_check(Builder._verified_source(catalog.skins.mira), "Mira's registered source and every directional painting match their provenance")
	for id: String in ["rowan", "bram", "tessa", "nell"]:
		_check(library.skins.has(id) and not library.skins[id].selectable, id + " is a village resident, not a player replacement")
		_check(Builder._verified_source(catalog.skins[id]), id + " has intact authored source provenance")
		_check(Builder._check_atlas(library.skins[id].atlas, metadata), id + " fits all shared poses, anchors and scale")
		var directory: String = "res://art/source/characters/" + id + "/v1/"
		for pair: Array in [["SE", "SW"], ["NE", "NW"]]:
			var source: Image = Image.load_from_file(ProjectSettings.globalize_path(directory + pair[0] + ".png"))
			var mirror: Image = Image.load_from_file(ProjectSettings.globalize_path(directory + pair[1] + ".png"))
			var exact: bool = true
			for pose: int in range(9):
				var region := Rect2i((pose % 3) * 418, (pose / 3) * 418, 418, 418)
				var expected: Image = source.get_region(region)
				expected.flip_x()
				exact = exact and expected.get_data() == mirror.get_region(region).get_data()
			_check(exact, id + " mirrors every " + pair[0] + " pose without changing order")
		var blink: Image = Image.load_from_file(ProjectSettings.globalize_path(directory + "blink-se.png"))
		var neutral: Image = Image.load_from_file(ProjectSettings.globalize_path(directory + "idle-se.png"))
		var eyes: Array = JSON.parse_string(FileAccess.get_file_as_string(directory + "authoring.json")).eye_rectangles
		var outside_exact: bool = true
		var changed: int = 0
		for y: int in range(418):
			for x: int in range(418):
				if blink.get_pixel(x, y) == neutral.get_pixel(x, y):
					continue
				changed += 1
				var inside: bool = false
				for rect: Array in eyes:
					inside = inside or Rect2(float(rect[0]) + 90, float(rect[1]) + 35, float(rect[2]), float(rect[3])).has_point(Vector2(x, y))
				outside_exact = outside_exact and inside
		_check(outside_exact and changed > 0, id + " blink retains every pixel outside the eye patches")
	_check_mira_mirrors()
	actor.set_screen_motion(Vector2(1, -0.5))
	actor.sprite.set_frame_and_progress(6, 0.4)
	_check(actor.set_skin("mira") and actor.animation_name == "walk_ne" and actor.sprite.frame == 6 and is_equal_approx(actor.sprite.frame_progress, 0.4), "Changing to the authored Mira atlas preserves rear walk phase")
	var mira_frames := actor.sprite.sprite_frames
	var identical_motion := true
	for animation: StringName in frames.get_animation_names():
		identical_motion = identical_motion and mira_frames.get_frame_count(animation) == frames.get_frame_count(animation) and mira_frames.get_animation_speed(animation) == frames.get_animation_speed(animation) and mira_frames.get_animation_loop(animation) == frames.get_animation_loop(animation)
		for index in range(frames.get_frame_count(animation)):
			var reference := frames.get_frame_texture(animation, index) as AtlasTexture
			var painted := mira_frames.get_frame_texture(animation, index) as AtlasTexture
			identical_motion = identical_motion and painted.region == reference.region and mira_frames.get_frame_duration(animation, index) == frames.get_frame_duration(animation, index)
	_check(identical_motion, "Mira inherits every original animation frame, region, duration, speed and loop")
	actor.set_screen_motion(Vector2(-1, 0.5))
	actor.set_screen_motion(Vector2.ZERO)
	actor._advance_idle(actor._next_blink_at + 0.001)
	var mira_idle := actor._idle_seconds
	_check(actor.sprite.frame == 1 and not actor.sprite.is_playing(), "Mira uses the shared front blink and paused neutral idle")
	_check(actor.set_skin("adventurer") and actor.sprite.frame == 1 and actor._idle_seconds == mira_idle, "Switching from Mira back to the original retains the blink clock")
	var image := Image.load_from_file(ProjectSettings.globalize_path(library.template.atlas))
	var first: Array = metadata.animations.walk_se[0].region
	image.fill_rect(Rect2i(int(first[0]), int(first[1]), int(first[2]), int(first[3])), Color.TRANSPARENT)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.cache/skin-contract"))
	var provenance_path := "res://.cache/skin-contract/source.json"
	var provenance := {"output_sha256": FileAccess.get_sha256(library.template.atlas), "sources": {library.template.atlas: FileAccess.get_sha256(library.template.atlas)}}
	var file := FileAccess.open(provenance_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(provenance))
	file.close()
	var authored_skin := {"source": library.template.atlas, "provenance": provenance_path}
	_check(Builder._verified_source(authored_skin), "Accept intact authored skin provenance")
	provenance.output_sha256 = "stale"
	file = FileAccess.open(provenance_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(provenance))
	file.close()
	_check(not Builder._verified_source(authored_skin), "Reject changed authored skin output before promotion")
	image.save_png(ProjectSettings.globalize_path("res://.cache/skin-contract/missing-pose.png"))
	_check(not Builder._check_atlas("res://.cache/skin-contract/missing-pose.png", metadata), "Reject an authored skin with a missing pose")
	actor.queue_free()
	await process_frame
	if _failures.is_empty():
		print("Shared frame skins: %d checks passed." % _checks)
		quit()
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		quit(1)


func _check_mira_mirrors() -> void:
	var directory := "res://art/source/characters/mira/v1/"
	for pair: Array in [["SE", "SW"], ["NE", "NW"]]:
		var source := Image.load_from_file(ProjectSettings.globalize_path(directory + str(pair[0]) + ".png"))
		var mirrored := Image.load_from_file(ProjectSettings.globalize_path(directory + str(pair[1]) + ".png"))
		var exact := true
		for index: int in range(9):
			var region := Rect2i((index % 3) * 418, (index / 3) * 418, 418, 418)
			var frame := source.get_region(region)
			frame.flip_x()
			exact = exact and frame.get_data() == mirrored.get_region(region).get_data()
		_check(exact, "Mira " + str(pair[1]) + " mirrors each corresponding pose without reordering")
	var neutral := Image.load_from_file(ProjectSettings.globalize_path(directory + "idle-se.png"))
	var blink := Image.load_from_file(ProjectSettings.globalize_path(directory + "blink-se.png"))
	var blink_mirror := Image.load_from_file(ProjectSettings.globalize_path(directory + "blink-sw.png"))
	var outside_eyes_unchanged := true
	var eyes_changed := false
	var eye_area := Rect2i(195, 105, 95, 58)
	for y: int in range(418):
		for x: int in range(418):
			if neutral.get_pixel(x, y) != blink.get_pixel(x, y):
				eyes_changed = true
				outside_eyes_unchanged = outside_eyes_unchanged and eye_area.has_point(Vector2i(x, y))
	_check(eyes_changed and outside_eyes_unchanged, "Mira's blink changes only the eyes, preserving every body and hair pixel")
	blink.flip_x()
	_check(blink.get_data() == blink_mirror.get_data(), "Mira's front-left blink is an exact mirror of front-right")


func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
