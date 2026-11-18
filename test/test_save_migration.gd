extends SceneTree
## Saves made before a content rename still load: retired ids are renamed, prose is not. Pure rules only.

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_upgrade_rules()
	print("Save migration: %d checks, %d failures." % [_checks, _failures.size()])
	for failure: String in _failures: printerr("FAIL: " + failure)
	quit(0 if _failures.is_empty() else 1)


func _upgrade_rules() -> void:
	var old: Dictionary = {"area":"shop-bookshop", "journey_rooms":{"shop-bookshop":{"area":"shop-bookshop", "state":{"lamps":{"bookshop-window-lamp":true}}}},
		"travel":{"link":"bookshop"}, "note":"Gret's bookshop sign was repainted.", "count":3, "list":["shop-bookshop", 2, null]}
	var new: Dictionary = SaveMigration.upgrade(old)
	_check(new.area == "shop-tailor" and new.journey_rooms.has("shop-tailor") and not new.journey_rooms.has("shop-bookshop"), "A renamed room keeps its saved state under the new id")
	_check(new.journey_rooms["shop-tailor"].area == "shop-tailor" and new.journey_rooms["shop-tailor"].state.lamps.has("tailor-window-lamp"), "Nested ids and lamp keys are renamed")
	_check(new.travel.link == "tailor" and new.list == ["shop-tailor", 2, null] and new.count == 3, "Values in lists are renamed; other values pass through")
	_check(new.note == old.note, "Prose that merely mentions an old id is left alone")
	_check(old.area == "shop-bookshop", "The parsed save is not modified in place")
	_check(SaveMigration.upgrade(new) == new, "Migrating twice changes nothing")
	for retired: String in SaveMigration.RENAMED:
		_check(not SaveMigration.RENAMED.has(SaveMigration.RENAMED[retired]), retired + " is renamed in one step, never into another retired id")
	_check(AreaStore.load_area("shop-tailor") != null and FileAccess.file_exists("res://content/areas/shop-tailor.json") and not FileAccess.file_exists("res://content/areas/shop-bookshop.json"), "The renamed room exists and the retired one does not")


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures.append(message)
