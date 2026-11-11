class_name DialoguePortraits
extends RefCounted
## Read the compiled portrait selection, independent of walking-frame skins.

const LIBRARY: String = "res://assets/portraits/library.json"
static var _library: Dictionary = {}


static func texture_for(id: String) -> Texture2D:
	if _library.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LIBRARY))
		if not parsed is Dictionary or not parsed.get("portraits") is Dictionary:
			push_error("The portrait library is missing or invalid. Run scripts/art.sh.")
			return null
		_library = parsed.portraits
		var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/art-catalog.json"))
		for spec: Dictionary in catalog.get("portrait_libraries", []):
			var extra: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(spec.manifest)))
			if extra is Dictionary and extra.get("portraits") is Dictionary: _library.merge(extra.portraits)
	var path: String = str((_library.get(id, {}) as Dictionary).get("runtime", ""))
	if path=="":
		var catalog: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/art-catalog.json"))
		if catalog is Dictionary:path=str(catalog.get("companions",{}).get(id,{}).get("portrait_runtime",""))
	if path == "" or not ResourceLoader.exists(path):
		push_error("Selected dialogue portrait is missing: " + id + ". Run scripts/art.sh.")
		return null
	return load(path) as Texture2D
