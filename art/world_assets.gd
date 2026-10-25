extends RefCounted
## Rendering-only asset selection. Logical footprints come from the world catalog and the area documents; core/ owns traversal.

const CATALOG: String = "res://pipeline/world-catalog.json"


static func entry(id: String) -> Dictionary:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	return catalog.assets.get(id, {})


static func is_blender(id: String) -> bool:
	return entry(id).get("authority", "procedural_test") == "blender"


static func instantiate(id: String) -> Node3D:
	var spec: Dictionary = entry(id)
	var path: String = "res://" + str(spec.get("runtime", ""))
	if not ResourceLoader.exists(path):
		push_error("Selected Blender asset missing: " + path + ". Build it with scripts/world-art.sh.")
		return null
	var scene: PackedScene = load(path) as PackedScene
	return scene.instantiate() as Node3D if scene != null else null
