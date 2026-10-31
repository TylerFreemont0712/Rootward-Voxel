extends RefCounted
## Offline gray masks of the selected painted cast. Preserve source alpha and the exact common frame contract.
const BUILDER := "res://pipeline/phantom_builder.gd"
const Skins := preload("res://art/frame_skin.gd")
const PREPARED := "res://.cache/phantom-art/prepared.json"

static func prepare(spec: Dictionary) -> bool:
	if spec.is_empty(): return true
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(spec.source))
	var directory: String = str(spec.runtime)
	if not directory.begins_with("res://assets/characters/phantoms") or ".." in directory: return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var manifest: Dictionary = {"schema":2, "family":source.family, "source":spec.source,
		"source_sha256":FileAccess.get_sha256(spec.source), "builder_sha256":FileAccess.get_sha256(BUILDER),
		"motion_sha256":FileAccess.get_sha256("res://pipeline/character-template.json"),
		"opacity":source.opacity, "gray":source.gray, "profiles":{}}
	for id: String in source.profiles:
		var appearance: Dictionary = source.profiles[id]
		var image := Image.load_from_file(ProjectSettings.globalize_path(appearance.source))
		if image == null: return false
		image.convert(Image.FORMAT_RGBA8)
		var pixels: PackedByteArray = image.get_data()
		for index: int in range(0, pixels.size(), 4):
			pixels[index] = 255
			pixels[index+1] = 255
			pixels[index+2] = 255
		var mask := Image.create_from_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, pixels)
		var path: String = directory.path_join(id + ".png")
		if mask.save_png(ProjectSettings.globalize_path(path)) != OK: return false
		manifest.profiles[id] = {"skin":appearance.skin, "painted_source":appearance.source,
			"painted_source_sha256":FileAccess.get_sha256(appearance.source), "scale":appearance.scale,
			"atlas":path, "atlas_sha256":FileAccess.get_sha256(path), "frames":directory.path_join(id + ".tres")}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREPARED.get_base_dir()))
	var file := FileAccess.open(PREPARED, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	print("Prepared gray crowd appearances from the original painted sheets; source alpha preserved exactly.")
	return true

static func configure(spec: Dictionary) -> bool:
	if spec.is_empty(): return true
	for id: String in ["man", "woman", "child"]:
		var path: String = str(spec.runtime).path_join(id + ".png.import")
		var config := ConfigFile.new()
		if config.load(path) != OK: return false
		config.set_value("params", "compress/mode", 0)
		config.set_value("params", "mipmaps/generate", true)
		config.set_value("params", "process/fix_alpha_border", true)
		config.set_value("params", "detect_3d/compress_to", 0)
		if config.save(path) != OK: return false
	return true

static func build(spec: Dictionary, metadata: Dictionary, template: SpriteFrames) -> bool:
	if spec.is_empty(): return true
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PREPARED))
	if manifest.source_sha256 != FileAccess.get_sha256(spec.source) or manifest.builder_sha256 != FileAccess.get_sha256(BUILDER): return false
	for profile: Dictionary in manifest.profiles.values():
		var atlas := load(profile.atlas) as Texture2D
		if atlas == null or profile.atlas_sha256 != FileAccess.get_sha256(profile.atlas) or profile.painted_source_sha256 != FileAccess.get_sha256(profile.painted_source): return false
		var frames: SpriteFrames = Skins.frames_for(template, atlas)
		if ResourceSaver.save(frames, profile.frames) != OK: return false
		for field: String in ["pixel_size", "fps", "idle", "animations"]:
			profile[field] = metadata[field].duplicate(true) if metadata[field] is Dictionary else metadata[field]
	var pending: String = str(spec.manifest) + ".tmp"
	var file := FileAccess.open(pending, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	file.close()
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(pending), ProjectSettings.globalize_path(spec.manifest)) != OK: return false
	print("Built painted crowd: unchanged gait/anchors, gray Bram/Mira and a slightly smaller boy.")
	return true
