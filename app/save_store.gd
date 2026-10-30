class_name SaveStore
extends RefCounted
## One save slot per journey, plus the player's name. Everything is plain JSON in this project's own user
## directory (RootwardVoxelLab); nothing is shared with the main Rootward game.

const SAVE_PATH: String = "user://kindle_hollow.save.json"
const PROFILE_PATH: String = "user://profile.json"
const DEFAULT_NAME: String = "Wren"

## Tests point these at scratch files and switch saving on, so they never touch a player's own save.
static var save_path: String = SAVE_PATH
static var profile_path: String = PROFILE_PATH
static var force_enabled: bool = false


static func has_save(level: String = "kindle-hollow") -> bool:
	return not read(level).is_empty()


static func level_path(level: String) -> String:
	return save_path if level == "kindle-hollow" else save_path.get_basename() + "." + level.validate_filename() + ".json"


## The parsed save, or {} when there is none or it cannot be read.
static func read(level: String = "kindle-hollow") -> Dictionary:
	var path: String = level_path(level)
	if _fresh() or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or int((parsed as Dictionary).get("version", 0)) != GameSession.SAVE_VERSION:
		return {}
	return parsed


static func write(data: Dictionary, level: String = "kindle-hollow") -> bool:
	if _fresh():
		return false
	var path: String = level_path(level)
	var temporary: String = path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK


static func delete(level: String = "kindle-hollow") -> void:
	if not _fresh() and FileAccess.file_exists(level_path(level)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(level_path(level)))


static func _profile() -> Dictionary:
	if not _fresh() and FileAccess.file_exists(profile_path):
		var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(profile_path))
		if value is Dictionary:return value
	return {}


static func last_level() -> String:
	return str(_profile().get("last_level", "kindle-hollow"))


static func set_last_level(level: String) -> void:
	if _fresh():return
	var data: Dictionary = _profile()
	data["last_level"] = level
	var file := FileAccess.open(profile_path, FileAccess.WRITE)
	if file != null:file.store_string(JSON.stringify(data))


static func player_name() -> String:
	if not _fresh() and FileAccess.file_exists(profile_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(profile_path))
		if parsed is Dictionary and str((parsed as Dictionary).get("name", "")).strip_edges() != "":
			return str(parsed.name).left(16)
	return DEFAULT_NAME


static func set_player_name(value: String) -> String:
	var clean: String = value.strip_edges().left(16)
	if clean == "":
		clean = DEFAULT_NAME
	if not _fresh():
		var data: Dictionary = _profile()
		data["name"] = clean
		var file := FileAccess.open(profile_path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(data))
	return clean


## Review and test runs set VOXEL_LAB_FRESH=1 so they never read or overwrite the player's own saves.
static func _fresh() -> bool:
	return OS.get_environment("VOXEL_LAB_FRESH") == "1" and not force_enabled
