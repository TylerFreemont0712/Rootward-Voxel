class_name SaveRepo
extends RefCounted
## Profiles and the granular working tree over the in-game version-control repository
## (docs/concept/save-vcs/PLAN.md). A profile is one journey: a directory under `root` holding a
## Vcs repository whose working tree is the player's *uncommitted* save state. Only commits are
## durable: Continue and the load modal check out HEAD (or a chosen commit), discarding whatever
## was never committed. That loss is by design.
##
## The session snapshot (Game.sync_working_tree) is split into small, diffable files:
##   journey.json              level, area, name, dialogue flags, which room is active
##   stats.json                programs run / changes applied
##   accounts.json  clock.json purse, bank, receipts / the shared town clock
##   programs/main.py          the player's current program
##   programs/<job>.py         each Field Notes page the player has written
##   programs/greeting.py/.json  the first greeting's Python and its editor mode
##   rooms/<area>/state.json   that room's world state (lamps, memory, position...)
##   rooms/<area>/quests.json  jobs finished there
##   rooms/<area>/edits.json   the layout studio's saved edits there
##   rooms/<area>/room.json    the room's area version and anything else
##   houses/<instance>.json    saved house interiors (travel rooms)
##   config.json               the player's terminal customization (`git config`)
##   extra.json                any top-level key the writer did not know (round-trip safety)

const ROOT: String = "user://profiles"
const DEV_PROFILE: String = "_dev"
const DEFAULT_NAME: String = "Wren"
const SHARED_KEYS: Array[String] = ["accounts", "city_cycle", "source", "stats", "greeting_editor", "workshop_pages"]
const CONFIG_DEFAULTS: Dictionary = {
	"user.name": "",
	"prompt.format": "{user}@haverlund {path} ({branch}{dirty}) $ ",
	"color.prompt.user": "green", "color.prompt.path": "blue", "color.prompt.branch": "magenta", "color.prompt.dirty": "yellow",
	"color.status.staged": "green", "color.status.unstaged": "red", "color.status.untracked": "red",
	"color.log.hash": "yellow", "color.log.head": "cyan", "color.log.branch": "green", "color.log.tag": "yellow",
	"color.diff.add": "green", "color.diff.remove": "red", "color.diff.hunk": "cyan", "color.diff.header": "white",
	"color.error": "red", "theme": "haverlund",
}

## Tests point `root` at a scratch directory and switch saving on, so they never touch a player's own profiles.
static var root: String = ROOT
static var force_enabled: bool = false
## Development checkpoints write to a hidden profile so Continue never inherits them.
static var development: bool = false
static var _current: String = ""


# --- Profiles ---------------------------------------------------------------------------------

## Visible profiles, newest played first: {slug, name, created, last_played, commits}.
static func profiles() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _fresh():
		return out
	var dir := DirAccess.open(root)
	if dir == null:
		return out
	for slug: String in dir.get_directories():
		if slug.begins_with("_"):
			continue
		var meta: Dictionary = _meta(slug)
		if meta.is_empty():
			continue
		meta["slug"] = slug
		var vcs := Vcs.new(root + "/" + slug)
		var graph: Dictionary = vcs.log_all()
		meta["commits"] = (graph.commits as Array).size()
		meta["branches"] = vcs.branches().size()
		meta["head"] = str((graph.head as Dictionary).get("branch", ""))
		meta["last_commit"] = int((graph.commits[0] as Dictionary).time) if not (graph.commits as Array).is_empty() else 0
		meta["last_message"] = str((graph.commits[0] as Dictionary).message) if not (graph.commits as Array).is_empty() else ""
		out.append(meta)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("last_played", 0)) > int(b.get("last_played", 0)))
	return out


## The active profile's slug, or "" when none exists yet.
static func current() -> String:
	if _fresh():
		return _current
	if _current != "":
		return _current
	var listed: Array[Dictionary] = profiles()
	_current = str(listed[0].slug) if not listed.is_empty() else ""
	return _current


static func select(slug: String) -> bool:
	if slug == "" or (not _fresh() and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(root + "/" + slug))):
		return false
	_current = slug
	_touch(slug)
	return true


## A new profile named after the player, with its repository initialised. Returns the slug.
static func create_profile(player: String) -> String:
	var clean: String = _clean_name(player)
	var base: String = clean.to_lower().replace(" ", "-").validate_filename()
	if base == "" or base.begins_with("_"):
		base = "journey"
	var slug: String = base
	var n: int = 2
	while not _fresh() and DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(root + "/" + slug)):
		slug = "%s-%d" % [base, n]
		n += 1
	if not _fresh():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root + "/" + slug))
		var now: int = int(Time.get_unix_time_from_system())
		_store(root + "/" + slug + "/profile.json", JSON.stringify({"name": clean, "created": now, "last_played": now}))
		var vcs := Vcs.new(root + "/" + slug)
		vcs.init_repo()
	_current = slug
	return slug


static func delete_profile(slug: String) -> void:
	if _fresh() or slug == "":
		return
	_remove_tree(ProjectSettings.globalize_path(root + "/" + slug))
	if _current == slug:
		_current = ""


## Removes every profile under `root` (tests, and the player's own "start over" from the load screen).
static func wipe() -> void:
	if _fresh():
		return
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(root)):
		_remove_tree(ProjectSettings.globalize_path(root))
	_current = ""
	development = false


## The active repository (the hidden development profile while `development` is on), or null.
static func repo() -> Vcs:
	var vcs: Vcs = _raw_repo()
	if vcs != null:
		vcs.author = author_name()
	return vcs


static func has_journey() -> bool:
	var vcs: Vcs = repo()
	return vcs != null and not vcs.history("HEAD", 1).is_empty()


# --- Names and config -------------------------------------------------------------------------

static func player_name() -> String:
	var slug: String = current()
	if slug == "":
		return DEFAULT_NAME
	return _clean_name(str(_meta(slug).get("name", DEFAULT_NAME)))


static func set_player_name(value: String) -> String:
	var clean: String = _clean_name(value)
	var slug: String = current()
	if slug != "" and not _fresh():
		var meta: Dictionary = _meta(slug)
		meta["name"] = clean
		_store(root + "/" + slug + "/profile.json", JSON.stringify(meta))
	return clean


## The committer shown in `git log`: `git config user.name`, else the player's name.
static func author_name() -> String:
	var configured: String = str(config().get("user.name", "")).strip_edges()
	return configured if configured != "" else player_name()


## The tracked `config.json` with defaults filled in (`git config` reads and writes it).
static func config() -> Dictionary:
	var merged: Dictionary = CONFIG_DEFAULTS.duplicate()
	var vcs: Vcs = _raw_repo()
	if vcs != null:
		var parsed: Variant = JSON.parse_string(vcs.read_file("config.json")) if vcs.read_file("config.json") != "" else null
		if parsed is Dictionary:
			merged.merge(parsed, true)
	return merged


static func set_config(key: String, value: String) -> bool:
	var vcs: Vcs = _raw_repo()
	if vcs == null or not CONFIG_DEFAULTS.has(key):
		return false
	var parsed: Variant = JSON.parse_string(vcs.read_file("config.json")) if vcs.read_file("config.json") != "" else null
	var data: Dictionary = parsed if parsed is Dictionary else {}
	data[key] = value
	vcs.write_file("config.json", JSON.stringify(data, "  ") + "\n")
	return true


# --- The working tree -------------------------------------------------------------------------

## Splits a session snapshot (Game.sync_working_tree's dictionary) into the tracked files.
static func write_tree(data: Dictionary) -> bool:
	var vcs: Vcs = repo()
	if vcs == null:
		return false
	var files: Dictionary = split(data)
	if vcs.read_file("config.json") != "":
		files["config.json"] = vcs.read_file("config.json")
	for path: String in vcs.files():
		if not files.has(path):
			vcs.delete_file(path)
	for path: String in files:
		if vcs.read_file(path) != files[path]:
			vcs.write_file(path, files[path])
	return true


## The snapshot the working tree currently holds, or {} when there is none.
static func tree_data() -> Dictionary:
	var vcs: Vcs = repo()
	if vcs == null:
		return {}
	var files: Dictionary = {}
	for path: String in vcs.files():
		files[path] = vcs.read_file(path)
	return join(files)


## The snapshot a commit holds (`ref` as Vcs resolves it), or {}.
static func data_at(ref: String = "HEAD") -> Dictionary:
	var vcs: Vcs = repo()
	return join(vcs.files_at(ref)) if vcs != null else {}


## Makes the working tree HEAD again, discarding uncommitted changes, and returns that snapshot.
## This is what Continue does: whatever was never committed is gone.
static func checkout_head() -> Dictionary:
	var vcs: Vcs = repo()
	if vcs == null:
		return {}
	vcs.reset_hard()
	for path: String in vcs.status().untracked:
		vcs.delete_file(path)
	return tree_data()


## Tracked files changed since HEAD that mean real progress; the town clock alone is not progress.
static func uncommitted_changes() -> PackedStringArray:
	var vcs: Vcs = repo()
	if vcs == null:
		return PackedStringArray()
	var state: Dictionary = vcs.status()
	var out: PackedStringArray = []
	for path: String in (state.staged as Dictionary).keys() + (state.unstaged as Dictionary).keys() + Array(state.untracked as PackedStringArray):
		if path != "clock.json" and not out.has(path):
			out.append(path)
	out.sort()
	return out


# --- Split and join (pure) --------------------------------------------------------------------

## Splits a snapshot into {path: text}. Pure: no file IO, so tests prove join(split(x)) == x.
static func split(data: Dictionary) -> Dictionary:
	var files: Dictionary = {}
	var rest: Dictionary = data.duplicate(true)
	var journey: Dictionary = {}
	for key: String in ["version", "level", "area", "area_version", "name", "dialogue_read", "workshop_log"]:
		if rest.has(key):
			journey[key] = rest[key]
			rest.erase(key)
	var rooms: Dictionary = {}
	var root_area: String = str(data.get("area", ""))
	if rest.get("journey_rooms") is Dictionary:
		var group: Dictionary = rest.journey_rooms
		journey["journey_rooms"] = {"version": group.get("version", 1), "active": group.get("active", root_area)}
		for id: String in group.get("rooms", {}):
			rooms[id] = (group.rooms[id] as Dictionary).duplicate(true)
		rest.erase("journey_rooms")
	var root_room: Dictionary = {}
	for key: String in ["state", "completed", "edits", "area_version"]:
		if rest.has(key):
			root_room[key] = rest[key]
			if key != "area_version":
				rest.erase(key)
	for key: String in SHARED_KEYS:
		if rest.has(key):
			root_room[key] = rest[key]
	if root_area != "" and not rooms.has(root_area) and not root_room.is_empty():
		rooms[root_area] = root_room
	# Shared progress is written once, from the root room (every room carries the same copy).
	var shared: Dictionary = rooms.get(root_area, root_room)
	if shared.has("stats"):
		files["stats.json"] = _json(shared.stats)
	if shared.has("accounts"):
		files["accounts.json"] = _json(shared.accounts)
	if shared.has("city_cycle"):
		# Whole minutes: the clock is real progress, but it should not dirty the tree every frame.
		var clock: Dictionary = (shared.city_cycle as Dictionary).duplicate(true)
		if clock.has("minute"):
			clock.minute = floor(float(clock.minute))
		files["clock.json"] = _json(clock)
	if shared.has("source"):
		files["programs/main.py"] = _text(str(shared.source))
	for page: String in shared.get("workshop_pages", {}):
		files["programs/%s.py" % page] = _text(str(shared.workshop_pages[page]))
	if shared.get("greeting_editor") is Dictionary and not (shared.greeting_editor as Dictionary).is_empty():
		var greeting: Dictionary = (shared.greeting_editor as Dictionary).duplicate(true)
		if greeting.has("python"):
			files["programs/greeting.py"] = _text(str(greeting.python))
			greeting.erase("python")
		files["programs/greeting.json"] = _json(greeting)
	for id: String in rooms:
		var room: Dictionary = (rooms[id] as Dictionary).duplicate(true)
		for key: String in SHARED_KEYS:
			room.erase(key)
		if room.has("state"):
			# `time` and `city_power` are derived from the clock each frame (GameSession.sync_cycle).
			var state: Dictionary = (room.state as Dictionary).duplicate(true)
			state.erase("time")
			state.erase("city_power")
			files["rooms/%s/state.json" % id] = _json(state)
			room.erase("state")
		if room.has("completed"):
			files["rooms/%s/quests.json" % id] = _json(room.completed)
			room.erase("completed")
		if room.has("edits"):
			files["rooms/%s/edits.json" % id] = _json(room.edits)
			room.erase("edits")
		files["rooms/%s/room.json" % id] = _json(room)
	for key: String in SHARED_KEYS:
		rest.erase(key)
	if rest.get("travel") is Dictionary:
		var travel: Dictionary = rest.travel
		journey["travel"] = {"version": travel.get("version", 1), "active": travel.get("active", "")}
		for instance: String in travel.get("rooms", {}):
			files["houses/%s.json" % instance] = _json(travel.rooms[instance])
		rest.erase("travel")
	files["journey.json"] = _json(journey)
	if not rest.is_empty():
		files["extra.json"] = _json(rest)
	return files


## Rebuilds the snapshot from {path: text}; the inverse of split. {} when there is no journey file.
static func join(files: Dictionary) -> Dictionary:
	if not files.has("journey.json"):
		return {}
	var journey: Variant = JSON.parse_string(str(files["journey.json"]))
	if not journey is Dictionary:
		return {}
	var data: Dictionary = {}
	for key: String in ["version", "level", "area", "area_version", "name", "dialogue_read", "workshop_log"]:
		if journey.has(key):
			data[key] = journey[key]
	var shared: Dictionary = {}
	if files.has("stats.json"):
		shared["stats"] = JSON.parse_string(str(files["stats.json"]))
	if files.has("accounts.json"):
		shared["accounts"] = JSON.parse_string(str(files["accounts.json"]))
	if files.has("clock.json"):
		shared["city_cycle"] = JSON.parse_string(str(files["clock.json"]))
	if files.has("programs/main.py"):
		shared["source"] = _untext(str(files["programs/main.py"]))
	var pages: Dictionary = {}
	for path: String in files:
		if path.begins_with("programs/") and path.ends_with(".py") and path != "programs/main.py" and path != "programs/greeting.py":
			pages[path.trim_prefix("programs/").trim_suffix(".py")] = _untext(str(files[path]))
	if files.has("programs/greeting.json"):
		var greeting: Variant = JSON.parse_string(str(files["programs/greeting.json"]))
		if greeting is Dictionary:
			if files.has("programs/greeting.py"):
				greeting["python"] = _untext(str(files["programs/greeting.py"]))
			shared["greeting_editor"] = greeting
	if not pages.is_empty() or shared.has("source") or shared.has("greeting_editor"):
		shared["workshop_pages"] = pages
	if shared.has("source") and not shared.has("greeting_editor"):
		shared["greeting_editor"] = {}
	var rooms: Dictionary = {}
	for path: String in files:
		if not path.begins_with("rooms/"):
			continue
		var id: String = path.get_slice("/", 1)
		if not rooms.has(id):
			var room_file: String = "rooms/%s/room.json" % id
			var meta: Variant = JSON.parse_string(str(files.get(room_file, "{}")))
			rooms[id] = meta if meta is Dictionary else {}
		var room: Dictionary = rooms[id]
		match path.get_file():
			"state.json": room["state"] = JSON.parse_string(str(files[path]))
			"quests.json": room["completed"] = JSON.parse_string(str(files[path]))
			"edits.json": room["edits"] = JSON.parse_string(str(files[path]))
	for id: String in rooms:
		for key: String in shared:
			rooms[id][key] = _dup(shared[key])
	var root_area: String = str(data.get("area", ""))
	if rooms.has(root_area):
		for key: String in rooms[root_area]:
			if key != "area_version" or not data.has("area_version"):
				data[key] = _dup(rooms[root_area][key])
	else:
		for key: String in shared:
			data[key] = _dup(shared[key])
	if journey.get("journey_rooms") is Dictionary:
		var group: Dictionary = journey.journey_rooms
		data["journey_rooms"] = {"version": group.get("version", 1), "active": group.get("active", root_area), "rooms": rooms}
	if journey.get("travel") is Dictionary:
		var houses: Dictionary = {}
		for path: String in files:
			if path.begins_with("houses/") and path.ends_with(".json"):
				houses[path.trim_prefix("houses/").trim_suffix(".json")] = JSON.parse_string(str(files[path]))
		data["travel"] = {"version": journey.travel.get("version", 1), "active": journey.travel.get("active", ""), "rooms": houses}
	if files.has("extra.json"):
		var extra: Variant = JSON.parse_string(str(files["extra.json"]))
		if extra is Dictionary:
			data.merge(extra)
	return SaveMigration.upgrade(data)


# --- Internals --------------------------------------------------------------------------------

## The repository without its author resolved (config() needs it before the author is known).
static func _raw_repo() -> Vcs:
	if _fresh():
		return null
	var slug: String = DEV_PROFILE if development else current()
	if slug == "":
		return null
	var vcs := Vcs.new(root + "/" + slug)
	if not vcs.is_repo():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(vcs.root))
		if not development and _meta(slug).is_empty():
			var now: int = int(Time.get_unix_time_from_system())
			_store(root + "/" + slug + "/profile.json", JSON.stringify({"name": DEFAULT_NAME, "created": now, "last_played": now}))
		vcs.init_repo()
	return vcs


## Canonical JSON: keys sorted at every level, so the same data always serialises to the same text
## and a diff shows real changes, not dictionary order.
static func _json(value: Variant) -> String:
	return JSON.stringify(_canonical(value), "  ") + "\n"


static func _canonical(value: Variant) -> Variant:
	if value is Dictionary:
		var keys: Array = (value as Dictionary).keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
		var out: Dictionary = {}
		for key: Variant in keys:
			out[key] = _canonical(value[key])
		return out
	if value is Array:
		var list: Array = []
		for item: Variant in value:
			list.append(_canonical(item))
		return list
	# JSON has one number type: a whole float and the int it came from are the same saved value.
	if value is float and is_finite(value) and value == floor(value) and absf(value) < 9007199254740992.0:
		return int(value)
	return value


## Program text ends with one newline in the file; `_untext` takes exactly that one back off.
static func _text(source: String) -> String:
	return source + "\n"


static func _untext(text: String) -> String:
	return text.trim_suffix("\n")


static func _dup(value: Variant) -> Variant:
	return value.duplicate(true) if value is Dictionary or value is Array else value


static func _clean_name(value: String) -> String:
	var clean: String = value.strip_edges().left(16)
	return clean if clean != "" else DEFAULT_NAME


static func _meta(slug: String) -> Dictionary:
	var path: String = root + "/" + slug + "/profile.json"
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func _touch(slug: String) -> void:
	if _fresh():
		return
	var meta: Dictionary = _meta(slug)
	if meta.is_empty():
		return
	meta["last_played"] = int(Time.get_unix_time_from_system())
	_store(root + "/" + slug + "/profile.json", JSON.stringify(meta))


static func _store(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)


static func _remove_tree(absolute: String) -> void:
	var dir := DirAccess.open(absolute)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_remove_tree(absolute + "/" + sub)
	for file: String in dir.get_files():
		DirAccess.remove_absolute(absolute + "/" + file)
	DirAccess.remove_absolute(absolute)


## Review and test runs set VOXEL_LAB_FRESH=1 so they never read or overwrite the player's own profiles.
static func _fresh() -> bool:
	return OS.get_environment("VOXEL_LAB_FRESH") == "1" and not force_enabled
