extends RefCounted
## Compile appearance entries against the one painted-frame animation contract.

const CATALOG := "res://pipeline/character-catalog.json"


static func catalog_errors(catalog: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if catalog.get("schema") != 2 or catalog.get("mode") != "shared_frame_skins" or not catalog.has("skins"):
		return PackedStringArray(["Expected the shared-frame skin catalog."])
	if catalog.get("template") != "res://pipeline/character-template.json" or catalog.get("runtime_library") != "res://assets/characters/library.json":
		errors.append("The skin catalog must use the shared template and runtime library.")
	if not catalog.skins.has(str(catalog.get("active", ""))):
		errors.append("Active skin is not registered.")
	for id: String in catalog.skins:
		var skin: Dictionary = catalog.skins[id]
		if not id.is_valid_identifier():
			errors.append("Invalid skin ID: " + id)
		for key: String in skin:
			if key not in ["label", "atlas", "source", "runtime", "provenance", "tint", "selectable"]:
				errors.append(id + ": skins may change appearance only, not " + key)
		if skin.has("selectable") and not skin.selectable is bool:
			errors.append(id + ": selectable must be a boolean.")
		var tint: Array = skin.get("tint", [])
		if tint.size() != 4:
			errors.append(id + ": tint requires four RGBA values.")
		else:
			var valid_tint := true
			for value: Variant in tint:
				if (not value is float and not value is int) or not is_finite(float(value)) or float(value) < 0.0 or float(value) > 1.0:
					errors.append(id + ": tint must contain finite values from zero to one.")
					valid_tint = false
					break
			if valid_tint and float(tint[3]) != 1.0:
				errors.append(id + ": keep the actor opaque; transparency belongs to the source alpha.")
		if skin.get("atlas") == "template":
			if skin.has("source") or skin.has("runtime"):
				errors.append(id + ": choose template atlas or an authored atlas, not both.")
		elif skin.has("atlas") or not str(skin.get("source", "")).begins_with("res://art/source/") or not str(skin.get("runtime", "")).begins_with("res://assets/characters/skins/") or not str(skin.get("provenance", "")).begins_with("res://art/source/") or ".." in str(skin.get("runtime", "")) or ".." in str(skin.get("source", "")) or ".." in str(skin.get("provenance", "")):
			errors.append(id + ": authored skins need source under art/source and output under assets/characters/skins.")
	return errors


static func read_catalog() -> Dictionary:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	var errors := catalog_errors(catalog)
	for message: String in errors:
		printerr(message)
	return catalog if errors.is_empty() else {}


static func runtime_atlases(catalog: Dictionary, spec: Dictionary) -> Array[String]:
	var paths: Array[String] = [str(spec.runtime_sheet)]
	for id: String in catalog.skins:
		var skin: Dictionary = catalog.skins[id]
		if skin.get("atlas") != "template" and str(skin.runtime) not in paths:
			paths.append(str(skin.runtime))
	return paths


static func prepare(catalog: Dictionary) -> bool:
	for id: String in catalog.skins:
		var skin: Dictionary = catalog.skins[id]
		if skin.get("atlas") == "template":
			continue
		if not _verified_source(skin):
			printerr("Missing or stale authored skin provenance: ", id)
			return false
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(str(skin.runtime).get_base_dir()))
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(skin.source), ProjectSettings.globalize_path(skin.runtime)) != OK:
			printerr("Could not prepare skin atlas: ", id)
			return false
	return true


static func build(catalog: Dictionary, spec: Dictionary, metadata: Dictionary) -> bool:
	var library: Dictionary = {
		"schema": 1, "active": catalog.active,
		"template": {"id": spec.template_id, "sha256": spec.template_sha256, "manifest": spec.manifest, "frames": spec.frames, "atlas": spec.runtime_sheet, "sheet_size": metadata.sheet_size},
		"skins": {},
	}
	for id: String in catalog.skins:
		var skin: Dictionary = catalog.skins[id]
		var atlas: String = spec.runtime_sheet if skin.get("atlas") == "template" else skin.runtime
		var source: String = spec.source if skin.get("atlas") == "template" else skin.source
		if skin.get("atlas") != "template" and not _verified_source(skin):
			printerr("Authored skin provenance changed: ", id)
			return false
		if FileAccess.get_sha256(source) != FileAccess.get_sha256(atlas):
			printerr("Stale skin atlas: ", id, ". Run scripts/art.sh.")
			return false
		if skin.get("atlas") != "template" and not _check_atlas(atlas, metadata):
			printerr("Skin does not fit the common frame layout/foot origin: ", id)
			return false
		library.skins[id] = {"label": skin.get("label", id), "atlas": atlas, "source_sha256": FileAccess.get_sha256(source), "tint": skin.tint, "selectable": skin.get("selectable", true)}
	var file := FileAccess.open(catalog.runtime_library, FileAccess.WRITE)
	file.store_string(JSON.stringify(library, "  ") + "\n")
	print("Built ", library.skins.size(), " shared-frame skins; active=", catalog.active)
	return true


static func _verified_source(skin: Dictionary) -> bool:
	if not FileAccess.file_exists(skin.source) or not FileAccess.file_exists(skin.provenance):
		return false
	var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(skin.provenance))
	if provenance.get("output_sha256") != FileAccess.get_sha256(skin.source):
		return false
	for source: String in provenance.get("sources", {}):
		if not FileAccess.file_exists(source) or FileAccess.get_sha256(source) != provenance.sources[source]:
			return false
	return true


static func _check_atlas(path: String, metadata: Dictionary) -> bool:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.get_size() != Vector2i(int(metadata.sheet_size[0]), int(metadata.sheet_size[1])) or not image.detect_alpha():
		return false
	for animation: String in metadata.animations:
		for frame: Dictionary in metadata.animations[animation]:
			var region := Rect2i(int(frame.region[0]), int(frame.region[1]), int(frame.region[2]), int(frame.region[3]))
			var first := region.size
			var last := Vector2i(-1, -1)
			for y in range(region.size.y):
				for x in range(region.size.x):
					if image.get_pixel(region.position.x + x, region.position.y + y).a > float(metadata.alpha_threshold):
						first = first.min(Vector2i(x, y))
						last = last.max(Vector2i(x, y))
			if first.x <= 2 or first.y <= 2 or last.x >= region.size.x - 3 or absi(last.y + 1 - int(frame.anchor[1])) > 2:
				return false
			var height := last.y - first.y + 1
			if float(height) / float(frame.opaque_height) < 0.88 or float(height) / float(frame.opaque_height) > 1.12:
				return false
	return true
