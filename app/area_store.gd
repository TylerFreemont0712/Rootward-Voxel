class_name AreaStore
extends RefCounted
## Loads versioned area documents from content/areas/. File access lives here so core/ stays pure.

const AREA_DIR: String = "res://content/areas/"
const CATALOG: String = "res://pipeline/world-catalog.json"
const BUILD_CATALOG: String = "res://content/build/catalog.json"


## The parsed area, or null (with errors pushed) if the document or its quests are invalid.
static func load_area(id: String) -> AreaDef:
	var result: Dictionary = read(id)
	if not result.ok:
		for message: String in result.errors:
			push_error("Area '%s': %s" % [id, message])
		return null
	return result.area


static func read(id: String) -> Dictionary:
	var source: Dictionary = read_source(id)
	if not source.ok:
		return {"ok": false, "area": null, "errors": source.errors}
	return AreaDef.parse(source.document, source.assets, source.quests, ground_materials())


static func ground_materials() -> Array:
	var result: Array = []
	for id: String in WorldTextures.catalog().materials:
		if WorldTextures.catalog().materials[id].get("ground", false):
			result.append(id)
	return result


## The raw pieces of an area: its document, its quest document and the world catalog's `assets`. Build mode
## keeps these so it can re-apply the player's edits to the untouched document. {ok, document, quests, assets, errors}.
static func read_source(id: String) -> Dictionary:
	var path: String = AREA_DIR + id + ".json"
	var quest_path: String = AREA_DIR + id + ".quests.json"
	if not FileAccess.file_exists(path):
		return {"ok": false, "errors": ["Missing area document %s." % path] as Array[String]}
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not document is Dictionary:
		return {"ok": false, "errors": ["The area document %s is not a JSON object." % path] as Array[String]}
	var quests: Variant = JSON.parse_string(FileAccess.get_file_as_string(quest_path)) if FileAccess.file_exists(quest_path) else {}
	var assets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG)).assets
	return {"ok": true, "document": document, "quests": quests, "assets": assets, "errors": [] as Array[String]}


## What build mode offers: categories, items and who may place them (content/build/catalog.json).
static func read_build_catalog() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BUILD_CATALOG))
	return parsed if parsed is Dictionary else {"items": [], "categories": [], "policies": {}}


## Build mode's land-shaping tools, each with a small sample of land for its picture (content/build/land-tools.json).
## A tool whose sample does not parse is left out and reported.
static func read_land_tools() -> Array[Dictionary]:
	var tools: Array[Dictionary] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/build/land-tools.json"))
	for entry: Variant in (parsed.get("tools", []) if parsed is Dictionary else []):
		if not entry is Dictionary or not str(entry.get("id", "")) in ["stairs"] + AreaBuild.LAND_TOOLS:
			push_error("Unknown land tool in content/build/land-tools.json: %s" % str(entry))
			continue
		var sample: Dictionary = AreaDef.parse(entry.get("sample", {}), {})
		if not sample.ok:
			push_error("Land tool '%s' has a sample that does not parse: %s" % [entry.id, str(sample.errors)])
			continue
		var tool: Dictionary = (entry as Dictionary).duplicate(true)
		tool["area"] = sample.area
		tools.append(tool)
	return tools


static func read_interiors() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/interiors/catalog.json"))
	return parsed if parsed is Dictionary else {}


static func read_villagers() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/villagers.json"))
	var people: Variant = parsed.get("residents", {}) if parsed is Dictionary else {}
	if not people is Dictionary:
		return {}
	for id: String in people:
		if not people[id] is Dictionary:
			push_error("Villager definition must be a dictionary: " + id)
			return {}
		var issues: Array[String] = VillageDialogue.validate(people[id])
		if not issues.is_empty():
			push_error("Invalid dialogue for " + id + ": " + str(issues))
			return {}
	return people
