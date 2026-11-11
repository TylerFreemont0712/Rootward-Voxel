extends SceneTree
## Optional source authoring: register approved 3x3 sheets without resampling.
## Normal runtime builds use scripts/art.sh and the already prepared source.

const Contract := preload("res://pipeline/character_contract.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or args[0] != "--source" or not args[1].begins_with("res://art/source/"):
		printerr("Usage: -- --source res://art/source/<authored version folder>")
		quit(1)
		return
	var directory: String = args[1].trim_suffix("/")
	if FileAccess.file_exists(directory + "/sheet.png") or FileAccess.file_exists(directory + "/provenance.json"):
		printerr("Prepared source already exists; use a NEW version directory.")
		quit(1)
		return
	var template: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Contract.TEMPLATE))
	if not Contract.template_errors(template).is_empty():
		printerr("Invalid shared character template.")
		quit(1)
		return
	var cell := Vector2i(int(template.cell_size[0]), int(template.cell_size[1]))
	var anchor := Vector2i(int(template.settings.frame_anchor[0]), int(template.settings.frame_anchor[1]))
	var atlas := Image.create(cell.x * 4, cell.y * 12, false, Image.FORMAT_RGBA8)
	var provenance: Dictionary = {
		"schema": 4, "method": "Approved eight-pose sheets plus neutral idle; integer translation only; eye-only blink patch",
		"cell_size": [cell.x, cell.y], "grid": [4, 12], "anchor": [anchor.x, anchor.y],
		"sources": {}, "directions": {}, "walk_poses": 8, "idle_index": 8, "blink_index": 9,
		"authoring_script_sha256": FileAccess.get_sha256("res://pipeline/prepare_directional_walk.gd"),
	}
	var row := 0
	for direction: String in ["se", "sw", "ne", "nw"]:
		var source: String = directory + "/" + direction.to_upper() + ".png"
		var image := Image.load_from_file(ProjectSettings.globalize_path(source))
		if image == null or image.get_size() != Vector2i(1254, 1254):
			printerr("Expected an approved 1254x1254 RGBA sheet: ", source)
			quit(1)
			return
		provenance.sources[source] = FileAccess.get_sha256(source)
		var transforms: Array[Dictionary] = []
		var keys: Array[String] = []
		var count := 10 if direction in ["se", "sw"] else 9
		for index in range(count):
			var pose: Image
			var input: String = source
			if index == 9:
				input = directory + "/blink-" + direction + ".png"
				pose = Image.load_from_file(ProjectSettings.globalize_path(input))
				provenance.sources[input] = FileAccess.get_sha256(input)
			else:
				pose = image.get_region(Rect2i((index % 3) * 418, (index / 3) * 418, 418, 418))
			if pose == null or pose.get_size() != Vector2i(418, 418):
				printerr("Missing or invalid pose: ", input)
				quit(1)
				return
			var bounds := _opaque_bounds(pose)
			var head := pose.get_region(Rect2i(0, bounds.position.y, 418, roundi(bounds.size.y * 0.4)))
			var head_bounds := _opaque_bounds(head)
			var offset := Vector2i(anchor.x - head_bounds.get_center().x, anchor.y - bounds.end.y)
			if index == 9:
				var neutral: Array = transforms[8].translation
				offset = Vector2i(int(neutral[0]), int(neutral[1]))
			if bounds.position.x + offset.x <= 2 or bounds.end.x + offset.x >= cell.x - 2 or bounds.position.y + offset.y <= 2:
				printerr("Registered source clips: ", direction, " pose ", index + 1)
				quit(1)
				return
			var registered := Image.create(cell.x, cell.y, false, Image.FORMAT_RGBA8)
			registered.blit_rect(pose, Rect2i(Vector2i.ZERO, pose.get_size()), offset)
			atlas.blit_rect(registered, Rect2i(Vector2i.ZERO, cell), Vector2i((index % 4) * cell.x, (row + index / 4) * cell.y))
			transforms.append({"source": input, "source_pose": mini(index, 8), "translation": [offset.x, offset.y]})
			keys.append(_sha(registered.get_data()))
		provenance.directions[direction] = {"row": row, "transforms": transforms, "key_rgba_sha256": keys}
		row += 3
	atlas.save_png(ProjectSettings.globalize_path(directory + "/sheet.png"))
	provenance.output_sha256 = FileAccess.get_sha256(directory + "/sheet.png")
	var file := FileAccess.open(directory + "/provenance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(provenance, "  ") + "\n")
	print("Prepared approved directional walk source with unchanged painted pixels: ", directory)
	quit()


func _opaque_bounds(image: Image) -> Rect2i:
	var first := image.get_size()
	var last := Vector2i(-1, -1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.25:
				first = first.min(Vector2i(x, y))
				last = last.max(Vector2i(x, y))
	return Rect2i(first, last - first + Vector2i.ONE)


func _sha(data: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(data)
	return context.finish().hex_encode()
