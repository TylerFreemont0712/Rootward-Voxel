class_name MediaLock
extends RefCounted
## For tests: pictures and models live in release packs pinned by media.lock (docs/RELEASES.md), and a checkout that
## fetched only the game's packs has no art sources on disk. A file counts as present when it is on disk or pinned in
## the lock, and its SHA-256 is the file's own or, when absent, the one the lock pins (the lock names exact bytes, so
## a hash comparison stays exact). Tests that read a source's pixels need the files themselves: they are marked
## `"needs": ["dev"]` in test/manifest.json and skipped until `scripts/fetch-media.sh dev`.

const LOCK := "res://media.lock"
static var _files: Dictionary = {}


static func _load() -> void:
	if not _files.is_empty():
		return
	for line in FileAccess.get_file_as_string(LOCK).split("\n"):
		var cols := line.split("\t")
		if cols.size() == 5 and cols[0] == "file":
			_files["res://" + cols[4]] = cols[2]


static func _res(path: String) -> String:
	return path if path.begins_with("res://") else "res://" + path


static func exists(path: String) -> bool:
	_load()
	var res := _res(path)
	return FileAccess.file_exists(res) or _files.has(res)


static func sha256(path: String) -> String:
	_load()
	var res := _res(path)
	if FileAccess.file_exists(res):
		return FileAccess.get_sha256(res)
	return str(_files.get(res, ""))


static func on_disk(path: String) -> bool:
	return FileAccess.file_exists(_res(path))
