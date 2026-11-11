class_name AreaStore
extends RefCounted
## Loads versioned area documents from content/areas/. File access lives here so core/ stays pure.

const AREA_DIR: String = "res://content/areas/"
const CATALOG: String = "res://pipeline/world-catalog.json"
const BUILD_CATALOG: String = "res://content/build/catalog.json"
const FIXTURE_DIR: String = "res://test/fixtures/"

## Where documents and catalogs are read from. They are the shipped content unless an engine rule test calls
## use_fixtures(): the build, terrain, door and ground rules are still proved over the small documents in
## test/fixtures, which are not part of the game and need no model files.
static var area_dir: String = AREA_DIR
static var build_catalog_path: String = BUILD_CATALOG
static var interiors_path: String = "res://content/interiors/catalog.json"
static var _fixtures: bool = false


static func use_fixtures() -> void:
	_fixtures = true
	area_dir = FIXTURE_DIR + "areas/"
	build_catalog_path = FIXTURE_DIR + "build-catalog.json"
	interiors_path = FIXTURE_DIR + "interiors.json"


static func use_content() -> void:
	_fixtures = false
	area_dir = AREA_DIR
	build_catalog_path = BUILD_CATALOG
	interiors_path = "res://content/interiors/catalog.json"


## The world catalog's `assets`. With fixtures in use they also include the footprint-only entries for models that
## no longer ship, so the village documents in test/fixtures still parse.
static func catalog_assets() -> Dictionary:
	var assets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG)).assets
	if _fixtures:
		var retired: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_DIR + "world-assets.json")).assets
		for id: String in retired:
			if not assets.has(id):
				assets[id] = retired[id]
	return assets


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
	var path: String = area_dir + id + ".json"
	var quest_path: String = area_dir + id + ".quests.json"
	if not FileAccess.file_exists(path):
		return {"ok": false, "errors": ["Missing area document %s." % path] as Array[String]}
	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not document is Dictionary:
		return {"ok": false, "errors": ["The area document %s is not a JSON object." % path] as Array[String]}
	var quests: Variant = JSON.parse_string(FileAccess.get_file_as_string(quest_path)) if FileAccess.file_exists(quest_path) else {}
	var assets: Dictionary = catalog_assets()
	return {"ok": true, "document": document, "quests": quests, "assets": assets, "errors": [] as Array[String]}


## What build mode offers: categories, items and who may place them (content/build/catalog.json).
static func read_build_catalog() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(build_catalog_path))
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
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(interiors_path)) if FileAccess.file_exists(interiors_path) else {}
	return parsed if parsed is Dictionary else {}
