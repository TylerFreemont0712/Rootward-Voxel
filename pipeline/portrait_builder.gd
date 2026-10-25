extends RefCounted
## Dialogue portraits share the existing offline art build, with source hashes and lossless UI imports.


static func prepare(spec: Dictionary) -> bool:
	if spec.is_empty():
		return true
	var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(spec.provenance)))
	if FileAccess.get_sha256(str(spec.prompt)) != str(provenance.get("prompt_sha256", "")):
		push_error("Portrait prompt provenance changed. Preserve the original and author a new version.")
		return false
	for record: Dictionary in provenance.get("portraits", []):
		for reference: String in record.reference_sha256:
			if FileAccess.get_sha256("res://" + reference) != str(record.reference_sha256[reference]):
				push_error("Portrait identity/style reference changed: " + reference)
				return false
	for id: String in spec.get("items", {}):
		var entry: Dictionary = spec.items[id]
		if FileAccess.get_sha256(entry.source) != str(entry.source_sha256):
			push_error("Portrait source changed: " + id + ". Author a new version and update the art catalog.")
			return false
		var image := Image.load_from_file(ProjectSettings.globalize_path(entry.source))
		if image == null or image.is_empty() or not image.detect_alpha() or image.get_height() < 1000:
			push_error("Portrait must be a high-definition PNG with transparency: " + id)
			return false
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(str(entry.runtime).get_base_dir()))
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(entry.source), ProjectSettings.globalize_path(entry.runtime)) != OK:
			return false
	return true


static func configure(spec: Dictionary) -> bool:
	for id: String in spec.get("items", {}):
		var path: String = str(spec.items[id].runtime) + ".import"
		var settings := ConfigFile.new()
		if settings.load(path) != OK:
			push_error("Import portrait before configuring: " + id)
			return false
		settings.set_value("params", "compress/mode", 0)
		settings.set_value("params", "mipmaps/generate", false)
		settings.set_value("params", "process/fix_alpha_border", true)
		settings.set_value("params", "detect_3d/compress_to", 0)
		if settings.save(path) != OK:
			return false
	return true


static func build(spec: Dictionary) -> bool:
	var library: Dictionary = {"schema": 1, "version": spec.get("version", ""), "portraits": {}}
	for id: String in spec.get("items", {}):
		var entry: Dictionary = spec.items[id]
		if FileAccess.get_sha256(entry.source) != str(entry.source_sha256) or FileAccess.get_sha256(entry.runtime) != str(entry.source_sha256):
			push_error("Stale portrait output: " + id + ". Run scripts/art.sh.")
			return false
		var image := Image.load_from_file(ProjectSettings.globalize_path(entry.runtime))
		library.portraits[id] = {"source": entry.source, "runtime": entry.runtime, "sha256": entry.source_sha256, "size": [image.get_width(), image.get_height()]}
	var file := FileAccess.open(str(spec.manifest), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(library, "  ") + "\n")
	print("Built ", library.portraits.size(), " selected high-definition dialogue portraits.")
	return true
