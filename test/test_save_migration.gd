extends SceneTree
## Saves made before a content rename still load: retired ids are renamed, prose is not, and a save under the old
## filename is read once and then set aside. Every file here is a scratch file; a player's own save is never touched.

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_upgrade_rules()
	_legacy_file()
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


func _legacy_file() -> void:
	var pid: int = OS.get_process_id()
	SaveStore.force_enabled = true
	SaveStore.save_path = "user://test_save_migration_%d.json" % pid
	_check(SaveStore.legacy_level_path("sparks-and-machines") == "", "A scratch save never falls back to the player's real old-name save")
	SaveStore.legacy_save_path = "user://test_save_migration_legacy_%d.json" % pid
	var legacy: String = SaveStore.legacy_level_path("sparks-and-machines")
	var current: String = SaveStore.level_path("sparks-and-machines")
	var file := FileAccess.open(legacy, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":GameSession.SAVE_VERSION, "area":"shop-bookshop"}))
	file.close()
	var read: Dictionary = SaveStore.read("sparks-and-machines")
	_check(read.get("area") == "shop-tailor", "An old-name save is read and migrated when no current save exists")
	_check(SaveStore.write(read, "sparks-and-machines") and FileAccess.file_exists(current), "The next save goes to the current name")
	_check(not FileAccess.file_exists(legacy) and FileAccess.file_exists(legacy + ".bak"), "The old-name save is set aside, never read again")
	_check(SaveStore.read("sparks-and-machines").get("area") == "shop-tailor", "Continue reads the current save")
	SaveStore.delete("sparks-and-machines")
	_check(not SaveStore.has_save("sparks-and-machines"), "Starting over leaves nothing to continue")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy + ".bak"))
	SaveStore.save_path = SaveStore.SAVE_PATH
	SaveStore.legacy_save_path = SaveStore.LEGACY_SAVE_PATH
	SaveStore.force_enabled = false


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures.append(message)
