class_name WorldTextures
extends RefCounted
## Which painted texture a shared palette material wears. `pipeline/texture-catalog.json` is the one
## source: the game's procedural surfaces read it here, and `scripts/world-art.sh retexture` bakes the same
## entries into an adopted Blender source. Pure lookup; it creates no materials.

const CATALOG: String = "res://pipeline/texture-catalog.json"

static var _catalog: Dictionary = {}
static var _cache: Dictionary = {}
static var _set_override: String = ""


static func catalog() -> Dictionary:
	if _catalog.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
		_catalog = parsed if parsed is Dictionary else {}
	return _catalog


## "solid" or "lush". The player's setting wins over the catalog's default.
static func active_set() -> String:
	var wanted: String = _set_override if _set_override != "" else str(catalog().get("set", "lush"))
	return wanted if (catalog().get("sets", {}) as Dictionary).has(wanted) else "lush"


static func use_set(set_name: String) -> void:
	if set_name != _set_override:
		_set_override = set_name
		_cache.clear()


static func has(material_id: String) -> bool:
	return (catalog().get("materials", {}) as Dictionary).has(material_id)


## {texture, tile, mode, cells, tint, emission} for a palette id, defaults filled in; {} if none.
static func entry(material_id: String) -> Dictionary:
	var raw: Variant = (catalog().get("materials", {}) as Dictionary).get(material_id)
	if not raw is Dictionary:
		return {}
	var result: Dictionary = {"tile": 1.0, "mode": "world", "cells": 1, "tint": 1.0, "emission": 0.0}
	result.merge(raw as Dictionary, true)
	return result


static func path_for(texture_name: String, set_name: String = "") -> String:
	var chosen: String = set_name if set_name != "" else active_set()
	return str((catalog().sets as Dictionary)[chosen]) + texture_name + ".png"


## The imported texture, or null (with an error) if the picture is missing. Cached per set.
static func texture(texture_name: String) -> Texture2D:
	var path: String = path_for(texture_name)
	if _cache.has(path):
		return _cache[path]
	var loaded: Texture2D = null
	if ResourceLoader.exists(path):
		loaded = load(path) as Texture2D
	if loaded == null:
		push_error("Texture '%s' is missing or not imported. Run the Godot import (scripts/play.sh does)." % path)
	_cache[path] = loaded
	return loaded
