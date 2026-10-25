# INACTIVE EXPERIMENT: visually rejected; preserve the original painted runtime character. See pipeline/CHARACTERS.md.
extends SceneTree
## Source-preserving part-atlas compilation. Rig scenes/motion are never overwritten here.

const CATALOG: String = "res://pipeline/character-catalog.json"
const ORDER: Array[String] = ["hair", "head", "torso", "pelvis", "upper_arm_l", "forearm_l", "hand_l", "upper_arm_r", "forearm_r", "hand_r", "thigh_l", "shin_l", "boot_l", "thigh_r", "shin_r", "boot_r"]


func _initialize() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	for id: String in catalog.skins:
		var spec: Dictionary = catalog.skins[id]
		var metadata: Dictionary = {"schema": 1, "id": id, "rig_family": spec.rig_family, "tints": spec.get("tints", {}), "views": {}, "sources": {}}
		for facing: String in ["se", "sw", "ne", "nw"]:
			var view: Dictionary = spec.views[facing]
			var source: String = str(view.source)
			var runtime: String = str(view.runtime)
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(runtime.get_base_dir()))
			if "--prepare" in OS.get_cmdline_user_args():
				if DirAccess.copy_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(runtime)) != OK:
					_fail("Could not copy selected part atlas.")
					return
				continue
			var image := Image.load_from_file(ProjectSettings.globalize_path(source))
			if image == null or not image.detect_alpha():
				_fail("Part atlas needs real alpha: " + source)
				return
			var parts: Dictionary = {}
			var x_edges: Array = view.x_edges
			var y_edges: Array = view.y_edges
			for index: int in range(ORDER.size()):
				var column: int = index % 4
				var row: int = index / 4
				var region := Rect2i(int(x_edges[column]), int(y_edges[row]), int(x_edges[column + 1]) - int(x_edges[column]), int(y_edges[row + 1]) - int(y_edges[row]))
				var bounds: Rect2i = _bounds(image, region)
				if bounds.size.x < 12 or bounds.size.y < 12 or bounds.position.x <= region.position.x + 1 or bounds.position.y <= region.position.y + 1 or bounds.end.x >= region.end.x - 1 or bounds.end.y >= region.end.y - 1:
					_fail("Empty/clipped part " + ORDER[index] + " in " + source)
					return
				parts[ORDER[index]] = [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y]
			metadata.views[facing] = {"atlas": runtime, "mirror": bool(view.mirror), "parts": parts}
			metadata.sources[source] = FileAccess.get_sha256(source)
		if not "--prepare" in OS.get_cmdline_user_args():
			var file := FileAccess.open(spec.manifest, FileAccess.WRITE)
			file.store_string(JSON.stringify(metadata, "  ") + "\n")
	print("Character parts ", "prepared" if "--prepare" in OS.get_cmdline_user_args() else "compiled", "; rig source and motion preserved.")
	quit(0)


func _bounds(image: Image, region: Rect2i) -> Rect2i:
	var first: Vector2i = region.end
	var last := Vector2i(-1, -1)
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			if image.get_pixel(x, y).a > 0.25:
				first = first.min(Vector2i(x, y))
				last = last.max(Vector2i(x, y))
	return Rect2i(first, last - first + Vector2i.ONE)


func _fail(reason: String) -> void:
	printerr(reason)
	quit(1)
