# INACTIVE EXPERIMENT: visually rejected; preserve the original painted runtime character. See pipeline/CHARACTERS.md.
extends RefCounted
## A skin changes attachments, not the bone hierarchy or animation library.


static func load_skin(id: String) -> Dictionary:
	var library: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/character-catalog.json"))
	var path: String = str(library.skins[id].manifest)
	return JSON.parse_string(FileAccess.get_file_as_string(path))


static func texture_for(skin: Dictionary, facing: String, slot: String) -> AtlasTexture:
	var view: Dictionary = skin.views[facing]
	var region: Array = view.parts[slot]
	var texture := AtlasTexture.new()
	texture.atlas = load(view.atlas) as Texture2D
	texture.region = Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
	return texture
