class_name JourneyStory
extends RefCounted
## A journey's story text (opening pages, Nell's note, ticket numbers, one-line responses), read from the
## file a level catalog entry names in "story". Journeys without one get {}.


static func read(path: String) -> Dictionary:
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary or int(raw.get("schema", 0)) != 1:
		push_error("Journey story '%s' must be a schema-1 object." % path)
		return {}
	if raw.has("scenes") and not WorkshopStory.valid(raw.scenes):
		push_error("Journey story '%s' has an invalid workshop scene." % path)
		return {}
	return raw
