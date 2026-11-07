extends RefCounted
## Shared-frame appearance changes. The actor owns animation and idle state.

const LIBRARY := "res://assets/characters/library.json"
static var _frame_cache: Dictionary = {}


static func read_library() -> Dictionary:
	if not FileAccess.file_exists(LIBRARY):
		push_error("Character library is missing. Run scripts/art.sh.")
		return {}
	return JSON.parse_string(FileAccess.get_file_as_string(LIBRARY))


static func frames_for(template: SpriteFrames, atlas: Texture2D) -> SpriteFrames:
	var first := template.get_frame_texture("walk_se", 0) as AtlasTexture
	if first.atlas == atlas:
		return template
	var key := str(template.get_instance_id()) + "|" + str(atlas.get_instance_id())
	if _frame_cache.has(key):
		var cached := (_frame_cache[key] as WeakRef).get_ref() as SpriteFrames
		if cached != null: return cached
	var frames := template.duplicate() as SpriteFrames
	for animation: StringName in template.get_animation_names():
		for index in range(template.get_frame_count(animation)):
			var texture := (template.get_frame_texture(animation, index) as AtlasTexture).duplicate() as AtlasTexture
			texture.atlas = atlas
			frames.set_frame(animation, index, texture, template.get_frame_duration(animation, index))
	_frame_cache[key] = weakref(frames)
	return frames


static func prune_cache() -> void:
	for key: String in _frame_cache.keys():
		if (_frame_cache[key] as WeakRef).get_ref() == null: _frame_cache.erase(key)
