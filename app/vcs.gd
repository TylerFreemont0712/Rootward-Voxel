class_name Vcs
extends RefCounted
## The in-game version-control repository (docs/concept/save-vcs/PLAN.md): the save/load system
## the player drives through the tablet terminal. Vocabulary, command grammar and error wording
## copy git exactly; the implementation is the game's own. One repository per profile directory:
##
##   <root>/tree/          the working tree (the player's uncommitted save files)
##   <root>/.vcs/objects/  content-addressed blobs
##   <root>/.vcs/commits/  commit objects (JSON)
##   <root>/.vcs/refs/     heads/<branch>, tags/<tag>, stash.json
##   <root>/.vcs/HEAD      "ref: refs/heads/<branch>" or a detached commit id
##   <root>/.vcs/index.json  the staging area: {path: blob id}
##
## No node, scene or network use; every method is synchronous file IO under `root` only.
## Results are {ok, error, ...} dictionaries whose error strings read like git's.

const DEFAULT_BRANCH: String = "main"

var root: String
var author: String = "player"
## Injectable clock for deterministic tests; returns unix seconds.
var now: Callable = func() -> int: return int(Time.get_unix_time_from_system())


func _init(repo_root: String) -> void:
	root = repo_root.rstrip("/")


func is_repo() -> bool:
	return FileAccess.file_exists(_vcs("HEAD"))


## `git init`. Creates an empty repository; refuses nothing (re-init is harmless, like git).
func init_repo(default_branch: String = DEFAULT_BRANCH) -> Dictionary:
	if is_repo():
		return {"ok": true, "message": "Reinitialized existing repository in " + root}
	for dir: String in ["tree", ".vcs/objects", ".vcs/commits", ".vcs/refs/heads", ".vcs/refs/tags"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root + "/" + dir))
	_store(_vcs("HEAD"), "ref: refs/heads/" + default_branch)
	_store(_vcs("index.json"), "{}")
	return {"ok": true, "message": "Initialized empty repository in " + root}


# --- The working tree -------------------------------------------------------------------------

func write_file(path: String, text: String) -> void:
	var absolute: String = root + "/tree/" + path
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(absolute.get_base_dir()))
	_store(absolute, text)


func read_file(path: String) -> String:
	var absolute: String = root + "/tree/" + path
	return FileAccess.get_file_as_string(absolute) if FileAccess.file_exists(absolute) else ""


func delete_file(path: String) -> void:
	if FileAccess.file_exists(root + "/tree/" + path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(root + "/tree/" + path))


## Every path in the working tree, sorted, repo-relative.
func files() -> PackedStringArray:
	var found: PackedStringArray = []
	_walk(root + "/tree", "", found)
	found.sort()
	return found


## Every tracked file of a commit as {path: text}; {} for an unknown ref.
func files_at(ref: String = "HEAD") -> Dictionary:
	var out: Dictionary = {}
	for path: String in _commit_tree(_resolve(ref)):
		out[path] = _read_blob(str(_commit_tree(_resolve(ref))[path]))
	return out


## `git reset --hard [ref]`: HEAD's branch, index and working tree all become `ref` (default HEAD).
## Untracked files are left alone, as git leaves them.
func reset_hard(ref: String = "HEAD") -> Dictionary:
	var id: String = _resolve(ref)
	if id == "" and ref != "HEAD":
		return {"ok": false, "error": "fatal: ambiguous argument '%s': unknown revision" % ref}
	var head: Dictionary = _head()
	var old_tree: Dictionary = _commit_tree(str(head.get("id", "")))
	var tree: Dictionary = _commit_tree(id)
	if id != "":
		if str(head.get("branch", "")) != "":
			_store(_vcs("refs/heads/" + str(head.branch)), id)
		else:
			_store(_vcs("HEAD"), id)
	_restore_tree(tree, old_tree, false)
	_store(_vcs("index.json"), JSON.stringify(tree, "  "))
	return {"ok": true, "id": id, "message": "HEAD is now at %s %s" % [id.substr(0, 7), str(_commit(id).get("message", ""))] if id != "" else ""}


# --- Status, add, commit ----------------------------------------------------------------------

## `git status`: branch (or detached id), staged/unstaged {path: "new file"|"modified"|"deleted"},
## untracked paths and `clean` (nothing staged, unstaged or untracked).
func status() -> Dictionary:
	var head: Dictionary = _head()
	var head_tree: Dictionary = _commit_tree(str(head.get("id", "")))
	var index: Dictionary = _index()
	var staged: Dictionary = {}
	var unstaged: Dictionary = {}
	var untracked: PackedStringArray = []
	for path: String in index:
		if not head_tree.has(path):
			staged[path] = "new file"
		elif head_tree[path] != index[path]:
			staged[path] = "modified"
	for path: String in head_tree:
		if not index.has(path):
			staged[path] = "deleted"
	var working: PackedStringArray = files()
	for path: String in working:
		var blob: String = _blob_id(read_file(path))
		if not index.has(path):
			untracked.append(path)
		elif index[path] != blob:
			unstaged[path] = "modified"
	for path: String in index:
		if not working.has(path):
			unstaged[path] = "deleted"
	return {"branch": head.get("branch", ""), "detached": head.get("branch", "") == "", "head": head.get("id", ""),
		"staged": staged, "unstaged": unstaged, "untracked": untracked,
		"clean": staged.is_empty() and unstaged.is_empty() and untracked.is_empty()}


## `git add <path>...`; "." or "-A" stages everything, including deletions.
func add(paths: PackedStringArray) -> Dictionary:
	var index: Dictionary = _index()
	var working: PackedStringArray = files()
	if paths.has(".") or paths.has("-A") or paths.has("--all"):
		index.clear()
		for path: String in working:
			index[path] = _write_blob(read_file(path))
	else:
		for path: String in paths:
			if working.has(path):
				index[path] = _write_blob(read_file(path))
			elif index.has(path):
				index.erase(path)  # Staging a deleted file records the deletion, as git does.
			else:
				return {"ok": false, "error": "fatal: pathspec '%s' did not match any files" % path}
	_store(_vcs("index.json"), JSON.stringify(index, "  "))
	return {"ok": true}


## `git commit -m <message>`. Commits the index; refuses an empty message or no staged changes.
func commit(message: String) -> Dictionary:
	if message.strip_edges() == "":
		return {"ok": false, "error": "Aborting commit due to empty commit message."}
	var head: Dictionary = _head()
	var index: Dictionary = _index()
	if index == _commit_tree(str(head.get("id", ""))):
		var state: Dictionary = status()
		var hint: String = "nothing added to commit but untracked files present (use \"git add\" to track)" \
			if not (state.untracked as PackedStringArray).is_empty() else \
			("no changes added to commit (use \"git add\")" if not (state.unstaged as Dictionary).is_empty() else "nothing to commit, working tree clean")
		return {"ok": false, "error": hint}
	var data: Dictionary = {"tree": index.duplicate(), "parents": [] if str(head.get("id", "")) == "" else [head.id],
		"message": message, "author": author, "time": int(now.call())}
	var id: String = _blob_id(JSON.stringify(data))
	data["id"] = id
	_store(_vcs("commits/" + id + ".json"), JSON.stringify(data, "  "))
	if str(head.get("branch", "")) != "":
		_store(_vcs("refs/heads/" + str(head.branch)), id)
	else:
		_store(_vcs("HEAD"), id)
	return {"ok": true, "id": id, "short": id.substr(0, 7), "message": message}


# --- History ----------------------------------------------------------------------------------

## `git log`: commits reachable from `ref` (default HEAD), newest first, each
## {id, short, parents, message, author, time}. `limit` 0 means all.
func history(ref: String = "HEAD", limit: int = 0) -> Array[Dictionary]:
	var start: String = _resolve(ref)
	var out: Array[Dictionary] = []
	var queue: Array[String] = []
	if start != "":
		queue.append(start)
	var seen: Dictionary = {}
	while not queue.is_empty():
		var id: String = queue.pop_front()
		if id == "" or seen.has(id):
			continue
		seen[id] = true
		var entry: Dictionary = _commit(id)
		if entry.is_empty():
			continue
		out.append(entry)
		for parent: Variant in entry.parents:
			queue.append(str(parent))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.time) > int(b.time))
	if limit > 0 and out.size() > limit:
		out.resize(limit)
	return out


## Every commit reachable from any branch or tag, with branch/tag tips attached: the load
## modal's graph and `git log --all --graph` both read from this.
func log_all() -> Dictionary:
	var tips: Dictionary = {}
	for branch: String in branches():
		tips["refs/heads/" + branch] = _resolve(branch)
	for tag_name: String in tags():
		tips["refs/tags/" + tag_name] = _resolve(tag_name)
	var seen: Dictionary = {}
	var commits: Array[Dictionary] = []
	for tip: String in tips.values():
		for entry: Dictionary in history(tip):
			if not seen.has(entry.id):
				seen[entry.id] = true
				commits.append(entry)
	commits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.time) > int(b.time))
	return {"commits": commits, "tips": tips, "head": _head()}


# --- Branches, tags, switching ----------------------------------------------------------------

func branches() -> PackedStringArray:
	return _refs("heads")


func tags() -> PackedStringArray:
	return _refs("tags")


## `git branch <name>`: a new branch at HEAD, without switching to it.
func branch_create(name: String) -> Dictionary:
	if not _valid_ref_name(name):
		return {"ok": false, "error": "fatal: '%s' is not a valid branch name" % name}
	if branches().has(name):
		return {"ok": false, "error": "fatal: a branch named '%s' already exists" % name}
	var head: Dictionary = _head()
	if str(head.get("id", "")) == "":
		return {"ok": false, "error": "fatal: not a valid object name: 'HEAD'"}
	_store(_vcs("refs/heads/" + name), str(head.id))
	return {"ok": true}


## `git tag <name>` at HEAD.
func tag_create(name: String) -> Dictionary:
	if not _valid_ref_name(name):
		return {"ok": false, "error": "fatal: '%s' is not a valid tag name" % name}
	if tags().has(name):
		return {"ok": false, "error": "fatal: tag '%s' already exists" % name}
	var head: Dictionary = _head()
	if str(head.get("id", "")) == "":
		return {"ok": false, "error": "fatal: not a valid object name: 'HEAD'"}
	_store(_vcs("refs/tags/" + name), str(head.id))
	return {"ok": true}


## `git branch -d <name>`: refuses the checked-out branch, as git does.
func branch_delete(name: String) -> Dictionary:
	if not branches().has(name):
		return {"ok": false, "error": "error: branch '%s' not found." % name}
	if str(_head().get("branch", "")) == name:
		return {"ok": false, "error": "error: Cannot delete branch '%s' checked out at '%s'" % [name, root]}
	var id: String = _resolve(name)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_vcs("refs/heads/" + name)))
	return {"ok": true, "message": "Deleted branch %s (was %s)." % [name, id.substr(0, 7)]}


## `git restore --staged <path>`: the index entry goes back to HEAD's; the working file is untouched.
func unstage(path: String) -> Dictionary:
	var index: Dictionary = _index()
	var tree: Dictionary = _commit_tree(str(_head().get("id", "")))
	if not index.has(path) and not tree.has(path):
		return {"ok": false, "error": "error: pathspec '%s' did not match any file(s) known to git" % path}
	if tree.has(path):
		index[path] = tree[path]
	else:
		index.erase(path)
	_store(_vcs("index.json"), JSON.stringify(index, "  "))
	return {"ok": true}


## `git switch <branch>` (create=true is `-c`). Like git, refuses to lose local changes.
func switch(name: String, create: bool = false) -> Dictionary:
	if create:
		var made: Dictionary = branch_create(name)
		if not made.ok:
			return made
	if not branches().has(name):
		return {"ok": false, "error": "fatal: invalid reference: " + name}
	return _move_head(_resolve(name), name)


## `git checkout <ref>`: a commit id (prefix), tag or branch. A non-branch ref detaches HEAD,
## with git's detached-HEAD advice in `message`.
func checkout(ref: String) -> Dictionary:
	if branches().has(ref):
		return switch(ref)
	var id: String = _resolve(ref)
	if id == "":
		return {"ok": false, "error": "error: pathspec '%s' did not match any file(s) known to git" % ref}
	var moved: Dictionary = _move_head(id, "")
	if moved.ok:
		moved["message"] = "Note: switching to '%s'.\n\nYou are in 'detached HEAD' state. You can look around, and you can\nkeep this state by making a new branch: git switch -c <new-branch-name>" % ref
	return moved


## `git restore <path>`: the file as HEAD has it, discarding working changes to it.
func restore(path: String) -> Dictionary:
	var tree: Dictionary = _commit_tree(str(_head().get("id", "")))
	if not tree.has(path):
		return {"ok": false, "error": "error: pathspec '%s' did not match any file(s) known to git" % path}
	write_file(path, _read_blob(str(tree[path])))
	var index: Dictionary = _index()
	index[path] = tree[path]
	_store(_vcs("index.json"), JSON.stringify(index, "  "))
	return {"ok": true}


## Paths whose content differs between two commits ("" means the empty tree), sorted.
func changed_paths(a_ref: String, b_ref: String) -> PackedStringArray:
	var a_tree: Dictionary = _commit_tree(_resolve(a_ref)) if a_ref != "" else {}
	var b_tree: Dictionary = _commit_tree(_resolve(b_ref)) if b_ref != "" else {}
	var out: PackedStringArray = []
	for path: String in a_tree:
		if not b_tree.has(path) or b_tree[path] != a_tree[path]:
			out.append(path)
	for path: String in b_tree:
		if not a_tree.has(path):
			out.append(path)
	out.sort()
	return out


# --- Diff and stash ---------------------------------------------------------------------------

## `git diff` (working vs index), `git diff --staged` (index vs HEAD), or two refs.
func diff(a_ref: String = "", b_ref: String = "", staged: bool = false) -> String:
	var old_tree: Dictionary
	var new_sides: Dictionary = {}  # path -> text
	if a_ref != "":
		old_tree = _commit_tree(_resolve(a_ref))
		var b_tree: Dictionary = _commit_tree(_resolve(b_ref)) if b_ref != "" else _index()
		for path: String in b_tree:
			new_sides[path] = _read_blob(str(b_tree[path]))
	elif staged:
		old_tree = _commit_tree(str(_head().get("id", "")))
		for path: String in _index():
			new_sides[path] = _read_blob(str(_index()[path]))
	else:
		old_tree = _index()
		for path: String in files():
			if old_tree.has(path):  # diff ignores untracked files, as git does
				new_sides[path] = read_file(path)
	var paths: Array = new_sides.keys()
	for path: String in old_tree:
		if not paths.has(path):
			paths.append(path)
	paths.sort()
	var out: String = ""
	for path: String in paths:
		var old_text: String = _read_blob(str(old_tree[path])) if old_tree.has(path) else ""
		var new_text: String = str(new_sides.get(path, ""))
		out += VcsDiff.unified(old_text, new_text, path, path)
	return out


## `git stash push/list/pop`. A stash entry snapshots the working tree and restores it exactly.
func stash_push(message: String = "") -> Dictionary:
	var state: Dictionary = status()
	if (state.unstaged as Dictionary).is_empty() and (state.staged as Dictionary).is_empty() and (state.untracked as PackedStringArray).is_empty():
		return {"ok": false, "error": "No local changes to save"}
	var snapshot: Dictionary = {}
	for path: String in files():
		snapshot[path] = _write_blob(read_file(path))
	var stash: Array = _stash()
	stash.push_front({"tree": snapshot, "index": _index(), "message": message if message != "" else "WIP on " + str(state.get("branch", "HEAD")), "time": int(now.call())})
	_store(_vcs("refs/stash.json"), JSON.stringify(stash))
	_restore_tree(_commit_tree(str(_head().get("id", ""))))
	return {"ok": true, "message": "Saved working directory and index state"}


func stash_list() -> Array:
	return _stash()


func stash_pop() -> Dictionary:
	var stash: Array = _stash()
	if stash.is_empty():
		return {"ok": false, "error": "No stash entries found."}
	var entry: Dictionary = stash.pop_front()
	_store(_vcs("refs/stash.json"), JSON.stringify(stash))
	_restore_tree(entry.tree)
	_store(_vcs("index.json"), JSON.stringify(entry.index, "  "))
	return {"ok": true}


# --- Internals --------------------------------------------------------------------------------

func _vcs(path: String) -> String:
	return root + "/.vcs/" + path


func _store(absolute: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(absolute.get_base_dir()))
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	if file != null:
		file.store_string(text)


func _walk(base: String, prefix: String, found: PackedStringArray) -> void:
	var dir := DirAccess.open(base + ("/" + prefix if prefix != "" else ""))
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var rel: String = (prefix + "/" + entry).lstrip("/")
		if dir.current_is_dir():
			_walk(base, rel, found)
		else:
			found.append(rel)
		entry = dir.get_next()


static func _blob_id(text: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(text.to_utf8_buffer())
	return ctx.finish().hex_encode()


func _write_blob(text: String) -> String:
	var id: String = _blob_id(text)
	if not FileAccess.file_exists(_vcs("objects/" + id)):
		_store(_vcs("objects/" + id), text)
	return id


func _read_blob(id: String) -> String:
	return FileAccess.get_file_as_string(_vcs("objects/" + id))


func _index() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_vcs("index.json")))
	return parsed if parsed is Dictionary else {}


func _head() -> Dictionary:
	var text: String = FileAccess.get_file_as_string(_vcs("HEAD")).strip_edges()
	if text.begins_with("ref: refs/heads/"):
		var branch: String = text.trim_prefix("ref: refs/heads/")
		return {"branch": branch, "id": FileAccess.get_file_as_string(_vcs("refs/heads/" + branch)).strip_edges()}
	return {"branch": "", "id": text}


func _commit(id: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_vcs("commits/" + id + ".json")))
	if not parsed is Dictionary:
		return {}
	var entry: Dictionary = parsed
	entry["short"] = str(entry.get("id", "")).substr(0, 7)
	return entry


func _commit_tree(id: String) -> Dictionary:
	return _commit(id).get("tree", {}) if id != "" else {}


## A ref to a commit id: HEAD, a branch, a tag, or a unique id prefix (4+ characters).
func _resolve(ref: String) -> String:
	if ref == "HEAD" or ref == "":
		return str(_head().get("id", ""))
	if branches().has(ref):
		return FileAccess.get_file_as_string(_vcs("refs/heads/" + ref)).strip_edges()
	if tags().has(ref):
		return FileAccess.get_file_as_string(_vcs("refs/tags/" + ref)).strip_edges()
	if ref.length() >= 4:
		var matches: PackedStringArray = []
		var dir := DirAccess.open(_vcs("commits"))
		if dir != null:
			for file: String in dir.get_files():
				if file.begins_with(ref):
					matches.append(file.get_basename())
		if matches.size() == 1:
			return matches[0]
	return ""


func _refs(kind: String) -> PackedStringArray:
	var dir := DirAccess.open(_vcs("refs/" + kind))
	var out: PackedStringArray = PackedStringArray(dir.get_files()) if dir != null else PackedStringArray()
	out.sort()
	return out


func _stash() -> Array:
	if not FileAccess.file_exists(_vcs("refs/stash.json")):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_vcs("refs/stash.json")))
	return parsed if parsed is Array else []


static func _valid_ref_name(name: String) -> bool:
	return name != "" and name == name.validate_filename() and not name.contains(" ") and not name.begins_with("-") and name != "HEAD"


## Moves HEAD to `id` (attached to `branch` when given), refusing to overwrite local changes.
## Untracked files survive the move, as in git, unless the target commit would overwrite one.
func _move_head(id: String, branch: String) -> Dictionary:
	var state: Dictionary = status()
	var target: Dictionary = _commit_tree(id)
	if id == str(_head().get("id", "")):
		# Same commit (switch -c, or re-attaching): only HEAD moves; local changes come along.
		_store(_vcs("HEAD"), "ref: refs/heads/" + branch if branch != "" else id)
		return {"ok": true, "branch": branch, "id": id}
	if not (state.unstaged as Dictionary).is_empty() or not (state.staged as Dictionary).is_empty():
		var touched: Array = (state.unstaged as Dictionary).keys() + (state.staged as Dictionary).keys()
		return {"ok": false, "error": "error: Your local changes to the following files would be overwritten by checkout:\n\t%s\nPlease commit your changes or stash them before you switch branches.\nAborting" % "\n\t".join(touched)}
	var colliding: Array = Array(state.untracked as PackedStringArray).filter(func(path: String) -> bool: return target.has(path))
	if not colliding.is_empty():
		return {"ok": false, "error": "error: The following untracked working tree files would be overwritten by checkout:\n\t%s\nPlease move or remove them before you switch branches.\nAborting" % "\n\t".join(colliding)}
	_store(_vcs("HEAD"), "ref: refs/heads/" + branch if branch != "" else id)
	_restore_tree(target, _commit_tree(str(state.get("head", ""))), false)
	_store(_vcs("index.json"), JSON.stringify(target, "  "))
	return {"ok": true, "branch": branch, "id": id}


## Makes the tracked working tree `tree` ({path: blob id}). With remove_all (the stash case)
## every other file goes; otherwise only files tracked by `old_tree` are removed, so untracked
## files survive a checkout as they do in git.
func _restore_tree(tree: Dictionary, old_tree: Dictionary = {}, remove_all: bool = true) -> void:
	for path: String in files():
		if not tree.has(path) and (remove_all or old_tree.has(path)):
			delete_file(path)
	for path: String in tree:
		write_file(path, _read_blob(str(tree[path])))
