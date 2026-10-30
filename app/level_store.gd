class_name LevelStore
extends RefCounted
## Content-owned starting points. Houses keep using the ordinary saved-room flow.

const MAIN_LEVEL: String="sparks-and-machines"

static func default_id()->String:
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://content/levels/catalog.json"))
	return str(raw.get("default",MAIN_LEVEL))

static func available_entries()->Array[Dictionary]:
	return entries().filter(func(item: Dictionary)->bool:return not item.get("archived",false))

static func entries() -> Array[Dictionary]:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/levels/catalog.json"))
	var result: Array[Dictionary] = []
	for item: Dictionary in raw.get("levels", []):result.append(item)
	return result

static func entry(id: String) -> Dictionary:
	for item: Dictionary in entries():
		if item.id == id:return item
	return {}

static func resumable() -> String:
	var last: String = SaveStore.last_level()
	var available: Array[Dictionary]=available_entries()
	if available.any(func(item: Dictionary)->bool:return item.id==last) and SaveStore.has_save(last):return last
	for item: Dictionary in available:
		if SaveStore.has_save(item.id):return item.id
	return default_id()
