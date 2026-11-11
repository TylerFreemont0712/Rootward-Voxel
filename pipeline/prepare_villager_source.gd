extends SceneTree
## One-time authored source assembly, before the existing shared-template packer.
## Exact per-cell mirrors; only the eye patches use the generated blink crop.


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1 or args[0] not in ["rowan", "bram", "tessa", "nell"]:
		printerr("usage: -- rowan|bram|tessa|nell")
		quit(1)
		return
	var id: String = args[0]
	var directory: String = "res://art/source/characters/" + id + "/v1/"
	if FileAccess.file_exists(directory + "sheet.png") or FileAccess.file_exists(directory + "provenance.json"):
		printerr("Prepared source already exists; use a new version.")
		quit(1)
		return
	for pair: Array in [["SE", "SW"], ["NE", "NW"]]:
		var source: Image = Image.load_from_file(ProjectSettings.globalize_path(directory + pair[0] + ".png"))
		if source == null or source.get_size() != Vector2i(1254, 1254):
			printerr("Expected nine 418-square painted source cells.")
			quit(1)
			return
		var mirror := Image.create(1254, 1254, false, Image.FORMAT_RGBA8)
		for index: int in range(9):
			var region := Rect2i((index % 3) * 418, (index / 3) * 418, 418, 418)
			var pose: Image = source.get_region(region)
			pose.flip_x()
			mirror.blit_rect(pose, Rect2i(0, 0, 418, 418), region.position)
		mirror.save_png(ProjectSettings.globalize_path(directory + pair[1] + ".png"))
	var blink: Image = Image.load_from_file(ProjectSettings.globalize_path(directory + "idle-se.png"))
	var generated: Image = Image.load_from_file(ProjectSettings.globalize_path(directory + "blink-generated.png"))
	generated.resize(250, 250, Image.INTERPOLATE_LANCZOS)
	var eyes: Array[Rect2] = [Rect2(116, 72, 42, 46), Rect2(167, 61, 33, 47)]
	if id == "bram":
		eyes = [Rect2(110, 78, 43, 49), Rect2(162, 69, 34, 47)]
	elif id == "nell":
		eyes = [Rect2(120, 76, 36, 36), Rect2(167, 65, 30, 37)]
	for y: int in range(250):
		for x: int in range(250):
			for eye: Rect2 in eyes:
				var relative: Vector2 = (Vector2(x, y) - eye.get_center()) / (eye.size * 0.5)
				var radius: float = relative.length()
				if radius >= 1.0:
					continue
				var original: Color = blink.get_pixel(x + 90, y + 35)
				var painted: Color = generated.get_pixel(x, y)
				painted.a = original.a
				blink.set_pixel(x + 90, y + 35, original.lerp(painted, smoothstep(1.0, 0.82, radius)))
	blink.save_png(ProjectSettings.globalize_path(directory + "blink-se.png"))
	blink.flip_x()
	blink.save_png(ProjectSettings.globalize_path(directory + "blink-sw.png"))
	var edits: Dictionary = {"tool": "built-in image_gen.imagegen", "model": "not exposed", "seed": "not exposed", "method": "SE/NE are original 3x3 generated paintings. SW/NW are exact per-cell mirrors. Generated blink crop is resized to its reference; only two feathered eye ellipses are composited. All other neutral pixels remain exact. Existing shared-template packer performs integer translation only.", "blink_crop": [90, 35, 250, 250], "eye_rectangles": [], "inputs": {}}
	for eye: Rect2 in eyes:
		edits.eye_rectangles.append([eye.position.x, eye.position.y, eye.size.x, eye.size.y])
	for name: String in ["SE.png", "NE.png", "SW.png", "NW.png", "idle-se.png", "blink-reference.png", "blink-generated.png", "blink-se.png", "blink-sw.png", "prompt-se.txt", "prompt-ne.txt", "prompt-blink.txt"]:
		edits.inputs[name] = FileAccess.get_sha256(directory + name)
	var file := FileAccess.open(directory + "authoring.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(edits, "  ") + "\n")
	print("Assembled exact mirrors and eye-only blink: ", id)
	quit()
