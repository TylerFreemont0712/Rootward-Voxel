extends SceneTree
## The selected character and application-icon build. Authored source stays unchanged.

const CATALOG: String = "res://pipeline/art-catalog.json"
const Contract := preload("res://pipeline/character_contract.gd")
const SkinBuilder := preload("res://pipeline/frame_skin_builder.gd")
const PortraitBuilder := preload("res://pipeline/portrait_builder.gd")
const DetailTextures := preload("res://pipeline/detail_texture_builder.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	var spec: Dictionary = Contract.resolve(catalog.character)
	var skin_catalog := SkinBuilder.read_catalog()
	if spec.is_empty() or skin_catalog.is_empty():
		quit(1)
		return
	var schema := int(catalog.schema)
	if schema not in [2, 3, 4] or spec.facing_space != "screen_diagonals" or spec.directions.keys() != ["se", "sw", "ne", "nw"] or spec.walk_columns.size() not in [4, 8, 16]:
		printerr("Character catalog must declare four screen-diagonal views and an explicit walk sequence.")
		quit(1)
		return
	var source_path: String = spec.source
	if not _verify_source(schema, spec):
		quit(1)
		return
	var destination: String = spec.runtime_sheet
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination.get_base_dir()))
	if "--prepare" in OS.get_cmdline_user_args():
		for companion: Dictionary in catalog.get("companions",{}).values():
			var origin: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://"+str(companion.provenance)))
			if not origin is Dictionary or FileAccess.get_sha256(companion.source)!=str(origin.get("sha256","")):
				printerr("Companion source does not match its provenance.");quit(1);return
			if origin.has("prompt_sha256") and FileAccess.get_sha256("res://"+str(companion.prompt))!=str(origin.prompt_sha256):
				printerr("Companion prompt does not match its provenance.");quit(1);return
			var picture:=Image.load_from_file(ProjectSettings.globalize_path(companion.source))
			if picture==null or picture.is_empty() or not picture.detect_alpha():
				printerr("Companion source needs RGBA transparency.");quit(1);return
			if companion.has("portrait_runtime"):
				DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(str(companion.portrait_runtime).get_base_dir()))
				if DirAccess.copy_absolute(ProjectSettings.globalize_path(companion.source),ProjectSettings.globalize_path(companion.portrait_runtime))!=OK:quit(1);return
			picture.resize(roundi(float(picture.get_width())*float(companion.height)/float(picture.get_height())),int(companion.height),Image.INTERPOLATE_LANCZOS)
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(str(companion.runtime).get_base_dir()))
			if picture.save_png(ProjectSettings.globalize_path(companion.runtime))!=OK:quit(1);return
		if not DetailTextures.prepare(catalog.get("building_textures", {})):
			quit(1)
			return
		for library: Dictionary in catalog.get("building_texture_libraries", []):
			if not DetailTextures.prepare(library):
				quit(1)
				return
		if not DetailTextures.prepare(catalog.get("detail_textures", {})):
			quit(1)
			return
		if not _prepare_icon(catalog) or not PortraitBuilder.prepare(catalog.get("portraits", {})):
			quit(1)
			return
		for portraits: Dictionary in catalog.get("portrait_libraries", []):
			if not PortraitBuilder.prepare(portraits): quit(1); return
		var error: Error = DirAccess.copy_absolute(ProjectSettings.globalize_path(source_path), ProjectSettings.globalize_path(destination))
		if error != OK:
			printerr("Could not copy the selected source atlas: ", error_string(error))
			quit(1)
			return
		print("Prepared selected atlas: ", destination)
		if not SkinBuilder.prepare(skin_catalog):
			quit(1)
			return
		quit()
		return
	if "--configure-import" in OS.get_cmdline_user_args():
		if not DetailTextures.configure(catalog.get("building_textures", {})):
			quit(1)
			return
		for library: Dictionary in catalog.get("building_texture_libraries", []):
			if not DetailTextures.configure(library):
				quit(1)
				return
		if not DetailTextures.configure(catalog.get("detail_textures", {})):
			quit(1)
			return
		if not PortraitBuilder.configure(catalog.get("portraits", {})):
			quit(1)
			return
		for portraits: Dictionary in catalog.get("portrait_libraries", []):
			if not PortraitBuilder.configure(portraits): quit(1); return
		var rgba_atlases: Array[String]=SkinBuilder.runtime_atlases(skin_catalog, spec)
		for companion: Dictionary in catalog.get("companions",{}).values():rgba_atlases.append(str(companion.runtime))
		for path: String in rgba_atlases:
			var settings := ConfigFile.new()
			if settings.load(path + ".import") != OK:
				printerr("Import the skin atlas before configuring it: ", path)
				quit(1)
				return
			settings.set_value("params", "mipmaps/generate", true)
			settings.set_value("params", "compress/mode", 0)
			settings.set_value("params", "process/fix_alpha_border", true)
			settings.set_value("params", "detect_3d/compress_to", 0)
			settings.save(path + ".import")
		for companion: Dictionary in catalog.get("companions",{}).values():
			if not companion.has("portrait_runtime"):continue
			var path: String=str(companion.portrait_runtime)+".import"
			var preferences:=ConfigFile.new()
			if preferences.load(path)!=OK:quit(1);return
			preferences.set_value("params","mipmaps/generate",false)
			preferences.set_value("params","compress/mode",0)
			preferences.set_value("params","process/fix_alpha_border",true)
			preferences.set_value("params","detect_3d/compress_to",0)
			preferences.save(path)
		print("Pinned character import: lossless RGBA, mipmaps, transparent edge repair.")
		quit()
		return
	if FileAccess.get_sha256(source_path) != FileAccess.get_sha256(destination):
		printerr("Runtime atlas is stale. Run scripts/art.sh.")
		quit(1)
		return
	if not PortraitBuilder.build(catalog.portraits):
		quit(1)
		return
	for portraits: Dictionary in catalog.get("portrait_libraries", []):
		if not PortraitBuilder.build(portraits): quit(1); return
	var image := Image.load_from_file(ProjectSettings.globalize_path(destination))
	if image == null or image.is_empty() or not image.detect_alpha():
		printerr("Character atlas must have transparency. Run scripts/art.sh.")
		quit(1)
		return
	if spec.row_edges.size() != int(spec.grid[1]) + 1 or int(spec.row_edges[0]) != 0 or int(spec.row_edges[-1]) != image.get_height():
		printerr("Explicit atlas row edges must cover the source image.")
		quit(1)
		return
	for row: int in range(int(spec.grid[1])):
		if int(spec.row_edges[row + 1]) <= int(spec.row_edges[row]):
			printerr("Atlas row edges must increase.")
			quit(1)
			return
	var atlas: Texture2D = load(destination) as Texture2D
	if atlas == null:
		printerr("Import the runtime PNG before building its SpriteFrames.")
		quit(1)
		return
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var metadata: Dictionary = {
		"schema": schema, "fps": spec.fps, "id": spec.id, "version": spec.version,
		"source": source_path, "source_sha256": FileAccess.get_sha256(source_path),
		"runtime_sheet": destination, "sheet_size": [image.get_width(), image.get_height()],
		"world_height": spec.world_height, "facing_space": spec.facing_space,
		"alpha_threshold": spec.alpha_threshold, "animations": {},
		"animation_method": spec.animation_method,
		"template_id": spec.template_id, "template_sha256": spec.template_sha256,
	}
	if schema == 4:
		metadata.idle = spec.idle.duplicate(true)
	else:
		metadata.idle_frames = spec.get("idle_frames", [spec.idle_column])
	var heights: Array[float] = []
	for direction: String in spec.directions:
		var row := int(spec.directions[direction])
		var idle_indices: Array = spec.get("idle_frames", [spec.idle_column])
		if schema == 4:
			idle_indices = spec.idle_columns if direction in spec.idle.blink_directions else [spec.idle_column]
		for state: String in ["walk", "idle"]:
			var indices: Array = spec.walk_columns if state == "walk" else idle_indices
			var animation := state + "_" + direction
			frames.add_animation(animation)
			frames.set_animation_speed(animation, float(spec.fps) if state == "walk" else 1.0)
			frames.set_animation_loop(animation, state == "walk")
			var selected: Array[Dictionary] = []
			for index: Variant in indices:
				var source_index := int(index)
				if schema < 4 and state == "idle":
					source_index = int(spec.walk_columns[source_index])
				var frame := _frame_metadata(image, spec, row, source_index)
				if frame.is_empty():
					quit(1)
					return
				heights.append(float(frame.opaque_height))
				selected.append(frame)
				frames.add_frame(animation, _atlas_frame(atlas, frame))
			metadata.animations[animation] = selected
	heights.sort()
	var typical_height: float = heights[heights.size() / 2]
	if heights[-1] / heights[0] > 1.12:
		printerr("Character height differs too much between frames; revise the source atlas.")
		quit(1)
		return
	metadata.pixel_size = float(spec.world_height) / typical_height
	if not SkinBuilder.build(skin_catalog, spec, metadata):
		quit(1)
		return
	var saved := ResourceSaver.save(frames, spec.frames)
	if saved != OK:
		printerr("Could not save SpriteFrames: ", error_string(saved))
		quit(1)
		return
	var file := FileAccess.open(spec.manifest, FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata, "  ") + "\n")
	print("Built ", spec.id, ": four diagonal walks, ", spec.walk_columns.size(), " poses each; anchored idle. Source SHA-256 ", metadata.source_sha256)
	quit()


func _prepare_icon(catalog: Dictionary) -> bool:
	var spec: Dictionary = catalog.application_icon
	if FileAccess.get_sha256(spec.source) != spec.source_sha256:
		printerr("Selected icon source changed. Author a new version and update the art catalog.")
		return false
	var source := Image.load_from_file(ProjectSettings.globalize_path(spec.source))
	if source == null or source.is_empty() or source.get_width() != source.get_height() or not source.detect_alpha():
		printerr("Application icon must be a square PNG with transparency.")
		return false
	for output: Dictionary in spec.outputs:
		var path: String = output.path
		var size := int(output.size)
		var image := source.duplicate() as Image
		image.resize(size, size, Image.INTERPOLATE_LANCZOS)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
		var error := image.save_png(ProjectSettings.globalize_path(path))
		if error != OK:
			printerr("Could not save application icon: ", error_string(error))
			return false
		print("Built application icon: ", path)
	return true


func _verify_source(schema: int, spec: Dictionary) -> bool:
	if schema < 3:
		return true
	var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(spec.provenance))
	if provenance.output_sha256 != FileAccess.get_sha256(spec.source):
		printerr("Painted atlas provenance is stale. Do not overwrite authored inputs.")
		return false
	if schema == 3 and provenance.source_sha256 != FileAccess.get_sha256(spec.base_source):
		printerr("Original painted source provenance is stale.")
		return false
	if schema == 4:
		for source: String in provenance.sources:
			if not FileAccess.file_exists(source) or provenance.sources[source] != FileAccess.get_sha256(source):
				printerr("Approved direction/blink source changed: ", source, ". Author a new version before building.")
				return false
	return true


func _frame_metadata(image: Image, spec: Dictionary, row: int, index: int) -> Dictionary:
	var column := index % int(spec.grid[0])
	var frame_row := row + index / int(spec.grid[0])
	if index < 0 or frame_row >= int(spec.grid[1]):
		printerr("Frame index outside the selected atlas: ", index)
		return {}
	var region := Rect2i(
		roundi(float(column) * image.get_width() / float(spec.grid[0])),
		int(spec.row_edges[frame_row]), 0, 0)
	region.size = Vector2i(
		roundi(float(column + 1) * image.get_width() / float(spec.grid[0])) - region.position.x,
		int(spec.row_edges[frame_row + 1]) - region.position.y)
	var bounds := _opaque_bounds(image, region, float(spec.alpha_threshold))
	if bounds.size.x < 24 or bounds.size.y < 24 or bounds.position.x <= 2 or bounds.position.y <= 2 or bounds.end.x >= region.size.x - 2 or bounds.end.y >= region.size.y - 2:
		printerr("Empty or clipped character in row ", row, " frame ", index)
		return {}
	var anchor: Array = spec.get("frame_anchor", [bounds.position.x + bounds.size.x * 0.5, bounds.end.y])
	return {"region": [region.position.x, region.position.y, region.size.x, region.size.y], "anchor": anchor, "opaque_height": bounds.size.y}


func _opaque_bounds(image: Image, region: Rect2i, threshold: float) -> Rect2i:
	var first := Vector2i(region.size.x, region.size.y)
	var last := Vector2i(-1, -1)
	for y: int in range(region.size.y):
		for x: int in range(region.size.x):
			if image.get_pixel(region.position.x + x, region.position.y + y).a > threshold:
				first = first.min(Vector2i(x, y))
				last = last.max(Vector2i(x, y))
	return Rect2i(first, last - first + Vector2i.ONE)


func _atlas_frame(atlas: Texture2D, frame: Dictionary) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	var box: Array = frame.region
	texture.region = Rect2(float(box[0]), float(box[1]), float(box[2]), float(box[3]))
	texture.filter_clip = true
	return texture
