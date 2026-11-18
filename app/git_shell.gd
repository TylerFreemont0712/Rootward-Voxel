class_name GitShell
extends RefCounted
## The tablet terminal's command line over the in-game repository (docs/concept/save-vcs/PLAN.md).
## Grammar, wording and refusals copy git's so the practice transfers; colours follow the player's
## `git config color.*` choices. Output is BBCode for a RichTextLabel; `plain()` strips it for tests.
##
## Before any git command the game is asked to sync the working tree (`before`), and after a command
## that changed the tree (switch, checkout, restore, reset, stash) the game is told to reload (`changed`).

const PALETTES: Dictionary = {
	"haverlund": {"red": "f14c4c", "green": "23d18b", "yellow": "f5f543", "blue": "3b8eea", "magenta": "d670d6", "cyan": "29b8db", "white": "e5e5e5", "dim": "858585", "brass": "d7a54a"},
	"parchment": {"red": "b3412f", "green": "3f7d3a", "yellow": "9a6b12", "blue": "2d5f9e", "magenta": "7d3f8c", "cyan": "22717a", "white": "2b2217", "dim": "8a7d68", "brass": "8c6a2c"},
	"ember": {"red": "ff6b57", "green": "9ad36a", "yellow": "ffc857", "blue": "6fa8ff", "magenta": "e08ae0", "cyan": "5fd3d6", "white": "f4ead8", "dim": "9c8f7a", "brass": "f4d186"},
}
const GIT_COMMANDS: PackedStringArray = ["status", "add", "commit", "log", "branch", "switch", "checkout", "diff", "restore", "tag", "stash", "reset", "config", "help"]
const SHELL_COMMANDS: PackedStringArray = ["git", "ls", "cat", "clear", "pwd", "whoami", "help", "exit", "echo", "date", "reset", "logout", "quit"]

var repo: Vcs
var config: Dictionary = SaveRepo.CONFIG_DEFAULTS.duplicate()
var user: String = "player"
var path: String = "~/journey"
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system())
## Called before each git command (sync the working tree) and after one that changed the tree.
var before: Callable = Callable()
var changed: Callable = Callable()
## Writes a config key (the game routes this to SaveRepo so it lands in the tracked config file).
var set_config: Callable = Callable()
## Game actions reachable as plain commands: name -> Callable(args: PackedStringArray) -> String
## (a message) or Dictionary (a full result). The game registers `reset`, `logout` and `quit`.
var commands: Dictionary = {}


func _init(repository: Vcs) -> void:
	repo = repository


# --- Public -----------------------------------------------------------------------------------

## The prompt from `prompt.format`: {user} {path} {branch} {dirty} {time}.
func prompt() -> String:
	var state: Dictionary = repo.status() if repo != null else {"branch": "", "clean": true}
	var branch: String = str(state.get("branch", "")) if str(state.get("branch", "")) != "" else ("HEAD@" + str(state.get("head", "")).substr(0, 7) if str(state.get("head", "")) != "" else "no commits")
	var dirty: String = "" if bool(state.get("clean", true)) else "*"
	var out: String = str(config.get("prompt.format", SaveRepo.CONFIG_DEFAULTS["prompt.format"]))
	out = out.replace("{user}", _c(user, "color.prompt.user"))
	out = out.replace("{path}", _c(path, "color.prompt.path"))
	out = out.replace("{branch}", _c(branch, "color.prompt.branch"))
	out = out.replace("{dirty}", _c(dirty, "color.prompt.dirty"))
	out = out.replace("{time}", _hhmm(int(clock.call())))
	return out


## Runs one line. {ok, output (BBCode), changed, clear, exit}.
func run(line: String) -> Dictionary:
	var words: PackedStringArray = tokenize(line)
	if words.is_empty():
		return _result(true, "")
	var command: String = words[0]
	var args: PackedStringArray = words.slice(1)
	match command:
		"git": return _git(args)
		"ls": return _ls(args)
		"cat": return _cat(args)
		"clear": return {"ok": true, "output": "", "changed": false, "clear": true, "exit": false}
		"pwd": return _result(true, path)
		"whoami": return _result(true, user)
		"echo": return _result(true, " ".join(args))
		"date": return _result(true, Time.get_datetime_string_from_unix_time(int(clock.call()), true))
		"help": return _result(true, _help())
		"exit": return {"ok": true, "output": "", "changed": false, "clear": false, "exit": true}
	if commands.has(command):
		var outcome: Variant = (commands[command] as Callable).call(args)
		if outcome is Dictionary:
			return outcome
		return _result(true, str(outcome))
	return _error("bash: %s: command not found" % command)


## Completions for the word being typed at the end of `line`.
func complete(line: String) -> PackedStringArray:
	var words: PackedStringArray = tokenize(line)
	var trailing: bool = line.ends_with(" ") or line == ""
	var partial: String = "" if trailing else (words[-1] if not words.is_empty() else "")
	var head: PackedStringArray = words if trailing else words.slice(0, maxi(words.size() - 1, 0))
	var pool: PackedStringArray = []
	if head.is_empty():
		pool = SHELL_COMMANDS
	elif head[0] == "git" and head.size() == 1:
		pool = GIT_COMMANDS
	elif head[0] == "git" and head[1] in ["switch", "checkout", "branch", "diff", "reset", "tag", "log"]:
		pool = repo.branches() + repo.tags()
		if head[1] in ["diff", "reset", "log", "checkout"]:
			pool.append("HEAD")
		if head[1] in ["log", "diff", "reset", "switch", "restore"]:
			for flag: String in {"log": ["--oneline", "--graph", "--all"], "diff": ["--staged"], "reset": ["--hard"], "switch": ["-c"], "restore": ["--staged"]}[head[1]]:
				pool.append(flag)
	elif (head[0] == "git" and head[1] in ["add", "restore", "diff", "cat"]) or head[0] == "cat" or head[0] == "ls":
		pool = repo.files()
		if head[0] == "git" and head[1] == "add":
			pool.append(".")
	elif head[0] == "git" and head[1] == "config":
		pool = PackedStringArray(SaveRepo.CONFIG_DEFAULTS.keys())
		pool.append("--list")
	elif head[0] == "git" and head[1] == "stash":
		pool = ["push", "pop", "list"]
	var out: PackedStringArray = []
	for word: String in pool:
		if word.begins_with(partial) and not out.has(word):
			out.append(word)
	out.sort()
	return out


## Shell-style words: spaces separate, quotes group, backslash escapes inside double quotes.
static func tokenize(line: String) -> PackedStringArray:
	var words: PackedStringArray = []
	var word: String = ""
	var quote: String = ""
	var has_word: bool = false
	var i: int = 0
	while i < line.length():
		var ch: String = line[i]
		if quote != "":
			if ch == quote:
				quote = ""
			elif ch == "\\" and quote == "\"" and i + 1 < line.length():
				i += 1
				word += line[i]
			else:
				word += ch
		elif ch == "\"" or ch == "'":
			quote = ch
			has_word = true
		elif ch == " " or ch == "\t":
			if has_word or word != "":
				words.append(word)
			word = ""
			has_word = false
		else:
			word += ch
		i += 1
	if has_word or word != "":
		words.append(word)
	return words


static func plain(bbcode: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\[/?(color|b|i|u)(=[^\\]]*)?\\]")
	return regex.sub(bbcode, "", true)


# --- git --------------------------------------------------------------------------------------

func _git(args: PackedStringArray) -> Dictionary:
	if args.is_empty() or args[0] in ["--help", "-h", "help"]:
		return _result(true, _git_help())
	if repo == null:
		return _error("fatal: not a git repository (or any of the parent directories): .git")
	if before.is_valid():
		before.call()
	var sub: String = args[0]
	var rest: PackedStringArray = args.slice(1)
	match sub:
		"status": return _status()
		"add": return _add(rest)
		"commit": return _commit(rest)
		"log": return _log(rest)
		"branch": return _branch(rest)
		"switch": return _switch(rest)
		"checkout": return _checkout(rest)
		"diff": return _diff(rest)
		"restore": return _restore(rest)
		"tag": return _tag(rest)
		"stash": return _stash(rest)
		"reset": return _reset(rest)
		"config": return _config(rest)
		"init": return _error("fatal: this journey already has a repository; a new profile starts a new one")
		"push", "pull", "fetch", "clone", "remote":
			return _error("fatal: no remote configured for this journey\nhint: this repository lives only on your tablet; there is nowhere to %s to." % sub)
		"merge", "rebase", "cherry-pick":
			return _error("fatal: '%s' is not available yet on this tablet; it arrives with a later chapter" % sub)
	return _error("git: '%s' is not a git command. See 'git --help'." % sub)


func _status() -> Dictionary:
	var state: Dictionary = repo.status()
	var out: Array[String] = []
	if state.detached and str(state.head) != "":
		out.append("HEAD detached at " + str(state.head).substr(0, 7))
	elif str(state.get("branch", "")) != "":
		out.append("On branch " + str(state.branch))
	if str(state.head) == "":
		out.append("\nNo commits yet\n")
	var staged: Dictionary = state.staged
	var unstaged: Dictionary = state.unstaged
	var untracked: PackedStringArray = state.untracked
	if not staged.is_empty():
		out.append("Changes to be committed:")
		out.append(_dim("  (use \"git restore --staged <file>...\" to unstage)"))
		for file: String in _sorted(staged.keys()):
			out.append(_c("\t%s%s" % [_pad(str(staged[file]) + ":", 12), file], "color.status.staged"))
		out.append("")
	if not unstaged.is_empty():
		out.append("Changes not staged for commit:")
		out.append(_dim("  (use \"git add <file>...\" to update what will be committed)"))
		out.append(_dim("  (use \"git restore <file>...\" to discard changes in working directory)"))
		for file: String in _sorted(unstaged.keys()):
			out.append(_c("\t%s%s" % [_pad(str(unstaged[file]) + ":", 12), file], "color.status.unstaged"))
		out.append("")
	if not untracked.is_empty():
		out.append("Untracked files:")
		out.append(_dim("  (use \"git add <file>...\" to include in what will be committed)"))
		for file: String in untracked:
			out.append(_c("\t" + file, "color.status.untracked"))
		out.append("")
	if staged.is_empty() and unstaged.is_empty() and untracked.is_empty():
		out.append("nothing to commit, working tree clean")
	elif staged.is_empty() and not unstaged.is_empty():
		out.append("no changes added to commit (use \"git add\" and/or \"git commit -a\")")
	elif staged.is_empty():
		out.append("nothing added to commit but untracked files present (use \"git add\" to track)")
	return _result(true, "\n".join(out).rstrip("\n"))


func _add(args: PackedStringArray) -> Dictionary:
	if args.is_empty():
		return _error("Nothing specified, nothing added.\nhint: Maybe you wanted to say 'git add .'?")
	var result: Dictionary = repo.add(args)
	return _result(true, "") if result.ok else _error(str(result.error))


func _commit(args: PackedStringArray) -> Dictionary:
	var message: String = ""
	var all: bool = false
	var i: int = 0
	while i < args.size():
		if args[i] == "-m" or args[i] == "--message":
			if i + 1 >= args.size():
				return _error("error: switch `m' requires a value")
			message += ("\n\n" if message != "" else "") + args[i + 1]
			i += 2
			continue
		if args[i].begins_with("-m") and args[i].length() > 2:
			message += ("\n\n" if message != "" else "") + args[i].substr(2)
		elif args[i] == "-a" or args[i] == "--all":
			all = true
		elif args[i] == "-am" or args[i] == "-ma":
			all = true
			if i + 1 >= args.size():
				return _error("error: switch `m' requires a value")
			message += args[i + 1]
			i += 1
		else:
			return _error("error: unknown option `%s'\nusage: git commit -m <message>" % args[i])
		i += 1
	if all:
		var tracked: PackedStringArray = []
		var state: Dictionary = repo.status()
		for file: String in (state.unstaged as Dictionary).keys():
			tracked.append(file)
		if not tracked.is_empty():
			repo.add(tracked)
	if message.strip_edges() == "":
		return _error("Aborting commit due to empty commit message.\nhint: write one with  git commit -m \"what you did\"")
	var branch_before: Dictionary = repo.status()
	var result: Dictionary = repo.commit(message)
	if not result.ok:
		return _error(str(result.error))
	var head: String = str(branch_before.get("branch", ""))
	var label: String = head if head != "" else "detached HEAD"
	var count: int = (branch_before.staged as Dictionary).size()
	var first: String = message.split("\n")[0]
	var out: String = "[%s %s] %s\n %d file%s changed" % [label, result.short, first, count, "" if count == 1 else "s"]
	return _result(true, out)


func _log(args: PackedStringArray) -> Dictionary:
	var oneline: bool = false
	var graph: bool = false
	var all: bool = false
	var limit: int = 0
	var ref: String = "HEAD"
	var i: int = 0
	while i < args.size():
		var arg: String = args[i]
		if arg == "--oneline": oneline = true
		elif arg == "--graph": graph = true
		elif arg == "--all": all = true
		elif arg == "-n" and i + 1 < args.size():
			limit = int(args[i + 1])
			i += 1
		elif arg.begins_with("-") and arg.substr(1).is_valid_int(): limit = int(arg.substr(1))
		elif arg.begins_with("--max-count="): limit = int(arg.get_slice("=", 1))
		elif arg.begins_with("-"): return _error("fatal: unrecognized argument: " + arg)
		else: ref = arg
		i += 1
	var everything: Dictionary = repo.log_all()
	var commits: Array[Dictionary] = []
	if all:
		commits = everything.commits
	else:
		if repo.history(ref, 1).is_empty() and not (everything.commits as Array).is_empty():
			return _error("fatal: ambiguous argument '%s': unknown revision or path not in the working tree." % ref)
		commits = repo.history(ref)
	if commits.is_empty():
		return _error("fatal: your current branch '%s' does not have any commits yet" % str((everything.head as Dictionary).get("branch", "HEAD")))
	if limit > 0 and commits.size() > limit:
		commits.resize(limit)
	var decorations: Dictionary = _decorations(everything)
	var rows: Array[Dictionary] = HistoryLanes.layout(commits)
	var art: Array[Dictionary] = HistoryLanes.text_rows(rows)
	var out: Array[String] = []
	for index: int in range(commits.size()):
		var commit: Dictionary = commits[index]
		var prefix: String = (str(art[index].line) + " ") if graph else ""
		if graph and str(art[index].pre) != "":
			out.append(str(art[index].pre))
		var deco: String = str(decorations.get(commit.id, ""))
		if oneline:
			out.append(prefix + _c(str(commit.short), "color.log.hash") + (" " + deco if deco != "" else "") + " " + str(commit.message).split("\n")[0])
		else:
			var pipe: String = ("| " if graph and (rows[index].active as Array).size() > 0 else ("  " if graph else ""))
			out.append(prefix + _c("commit " + str(commit.id), "color.log.hash") + (" " + deco if deco != "" else ""))
			out.append(pipe + "Author: " + str(commit.author))
			out.append(pipe + "Date:   " + Time.get_datetime_string_from_unix_time(int(commit.time), true))
			out.append(pipe.rstrip(" "))
			for line: String in str(commit.message).split("\n"):
				out.append(pipe + "    " + line)
			if index < commits.size() - 1: out.append(pipe.rstrip(" "))
	return _result(true, "\n".join(out))


func _decorations(everything: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var head: Dictionary = everything.head
	var by_commit: Dictionary = {}
	for ref: String in everything.tips:
		var id: String = str(everything.tips[ref])
		if not by_commit.has(id): by_commit[id] = []
		by_commit[id].append(ref)
	for id: String in by_commit:
		var parts: Array[String] = []
		var refs: Array = by_commit[id]
		refs.sort()
		if str(head.get("id", "")) == id and str(head.get("branch", "")) == "":
			parts.append(_c("HEAD", "color.log.head"))
		for ref: String in refs:
			if ref.begins_with("refs/heads/"):
				var name: String = ref.trim_prefix("refs/heads/")
				if name == str(head.get("branch", "")):
					parts.append(_c("HEAD -> ", "color.log.head") + _c(name, "color.log.branch"))
				else:
					parts.append(_c(name, "color.log.branch"))
		for ref: String in refs:
			if ref.begins_with("refs/tags/"):
				parts.append(_c("tag: " + ref.trim_prefix("refs/tags/"), "color.log.tag"))
		out[id] = _c("(", "color.log.tag").replace(_hex("color.log.tag"), _hex("color.log.tag")) + ", ".join(parts) + _c(")", "color.log.tag")
	return out


func _branch(args: PackedStringArray) -> Dictionary:
	if args.is_empty() or args[0] in ["-l", "--list", "-a", "-v"]:
		var state: Dictionary = repo.status()
		var out: Array[String] = []
		for name: String in repo.branches():
			if name == str(state.get("branch", "")):
				out.append(_c("* " + name, "color.log.branch"))
			else:
				out.append("  " + name)
		if state.detached and str(state.head) != "":
			out.push_front(_c("* (HEAD detached at %s)" % str(state.head).substr(0, 7), "color.log.branch"))
		return _result(true, "\n".join(out))
	if args[0] in ["-d", "-D", "--delete"]:
		if args.size() < 2:
			return _error("fatal: branch name required")
		var gone: Dictionary = repo.branch_delete(args[1])
		return _result(true, str(gone.message)) if gone.ok else _error(str(gone.error))
	if args[0].begins_with("-"):
		return _error("error: unknown option `%s'\nusage: git branch [<name>] | -d <name>" % args[0])
	var made: Dictionary = repo.branch_create(args[0])
	return _result(true, "") if made.ok else _error(str(made.error))


func _switch(args: PackedStringArray) -> Dictionary:
	var create: bool = false
	var name: String = ""
	for arg: String in args:
		if arg == "-c" or arg == "--create": create = true
		elif arg.begins_with("-"): return _error("error: unknown option `%s'\nusage: git switch [-c] <branch>" % arg)
		else: name = arg
	if name == "":
		return _error("fatal: missing branch or commit argument")
	if not create and not repo.branches().has(name) and repo._resolve(name) != "":
		return _error("fatal: a branch is expected, got commit '%s'\nhint: use  git checkout %s  to look at a commit" % [name, name])
	var before_branch: String = str(repo.status().get("branch", ""))
	var moved: Dictionary = repo.switch(name, create)
	if not moved.ok:
		return _error(str(moved.error))
	_changed()
	if create:
		return _result(true, "Switched to a new branch '%s'" % name, true)
	if before_branch == name:
		return _result(true, "Already on '%s'" % name, true)
	return _result(true, "Switched to branch '%s'" % name, true)


func _checkout(args: PackedStringArray) -> Dictionary:
	if args.is_empty():
		return _error("fatal: you must specify a branch or commit to check out")
	if args[0] == "-b":
		if args.size() < 2:
			return _error("fatal: switch `b' requires a value")
		var moved: Dictionary = repo.switch(args[1], true)
		if not moved.ok: return _error(str(moved.error))
		_changed()
		return _result(true, "Switched to a new branch '%s'" % args[1], true)
	if args[0] == "--" and args.size() > 1:
		return _restore(args.slice(1))
	if repo.files().has(args[0]) and repo._resolve(args[0]) == "":
		return _restore(args)
	var result: Dictionary = repo.checkout(args[0])
	if not result.ok:
		return _error(str(result.error))
	_changed()
	if result.has("message"):
		return _result(true, str(result.message), true)
	return _result(true, "Switched to branch '%s'" % args[0], true)


func _diff(args: PackedStringArray) -> Dictionary:
	var staged: bool = false
	var refs: PackedStringArray = []
	for arg: String in args:
		if arg in ["--staged", "--cached"]: staged = true
		elif arg.begins_with("-"): return _error("fatal: unrecognized argument: " + arg)
		else: refs.append(arg)
	for ref: String in refs:
		if repo._resolve(ref) == "":
			return _error("fatal: ambiguous argument '%s': unknown revision" % ref)
	var text: String = repo.diff(refs[0] if refs.size() > 0 else "", refs[1] if refs.size() > 1 else "", staged)
	return _result(true, _color_diff(text))


func _restore(args: PackedStringArray) -> Dictionary:
	var staged: bool = false
	var paths: PackedStringArray = []
	for arg: String in args:
		if arg == "--staged": staged = true
		elif arg.begins_with("-"): return _error("error: unknown option `%s'\nusage: git restore [--staged] <file>..." % arg)
		else: paths.append(arg)
	if paths.is_empty():
		return _error("fatal: you must specify path(s) to restore")
	var touched: bool = false
	for file: String in paths:
		var expanded: PackedStringArray = _expand(file)
		if expanded.is_empty():
			return _error("error: pathspec '%s' did not match any file(s) known to git" % file)
		for one: String in expanded:
			var result: Dictionary = repo.unstage(one) if staged else repo.restore(one)
			if not result.ok:
				return _error(str(result.error))
			touched = touched or not staged
	if touched:
		_changed()
	return _result(true, "", touched)


func _tag(args: PackedStringArray) -> Dictionary:
	if args.is_empty():
		return _result(true, "\n".join(repo.tags()))
	if args[0] == "-d":
		return _error("error: deleting tags is not available on this tablet")
	var made: Dictionary = repo.tag_create(args[0])
	return _result(true, "") if made.ok else _error(str(made.error))


func _stash(args: PackedStringArray) -> Dictionary:
	var sub: String = args[0] if not args.is_empty() else "push"
	match sub:
		"push", "save":
			var message: String = ""
			for i: int in range(1, args.size()):
				if args[i] == "-m" and i + 1 < args.size(): message = args[i + 1]
			var pushed: Dictionary = repo.stash_push(message)
			if not pushed.ok: return _error(str(pushed.error))
			_changed()
			return _result(true, "%s %s" % [str(pushed.message), ("WIP on " + str(repo.status().get("branch", "HEAD")) if message == "" else message)], true)
		"list":
			var out: Array[String] = []
			var entries: Array = repo.stash_list()
			for i: int in range(entries.size()):
				out.append("stash@{%d}: %s" % [i, str((entries[i] as Dictionary).message)])
			return _result(true, "\n".join(out))
		"pop", "apply":
			var popped: Dictionary = repo.stash_pop()
			if not popped.ok: return _error(str(popped.error))
			_changed()
			return _result(true, "Dropped stash entry; working tree restored.", true)
	return _error("error: unknown subcommand: %s\nusage: git stash [push [-m <message>] | list | pop]" % sub)


func _reset(args: PackedStringArray) -> Dictionary:
	var hard: bool = false
	var ref: String = "HEAD"
	for arg: String in args:
		if arg == "--hard": hard = true
		elif arg in ["--soft", "--mixed"]: return _error("error: only  git reset --hard [<commit>]  is available on this tablet")
		elif arg.begins_with("-"): return _error("error: unknown option `%s'" % arg)
		else: ref = arg
	if not hard:
		if args.is_empty():
			var state: Dictionary = repo.status()
			for file: String in (state.staged as Dictionary).keys():
				repo.unstage(file)
			return _result(true, "Unstaged changes after reset:\n" + "\n".join((repo.status().unstaged as Dictionary).keys()))
		return _error("error: only  git reset --hard [<commit>]  is available on this tablet (or plain  git reset  to unstage)")
	var result: Dictionary = repo.reset_hard(ref)
	if not result.ok:
		return _error(str(result.error))
	_changed()
	return _result(true, str(result.message), true)


func _config(args: PackedStringArray) -> Dictionary:
	if args.is_empty() or args[0] in ["--list", "-l"]:
		var out: Array[String] = []
		for key: String in config:
			out.append("%s=%s" % [key, str(config[key])])
		return _result(true, "\n".join(out))
	var key: String = args[0]
	if not config.has(key):
		return _error("error: key does not contain a section: %s\nhint: git config --list  shows what can be set" % key)
	if args.size() == 1:
		return _result(true, str(config[key]))
	var value: String = " ".join(args.slice(1))
	if key.begins_with("color.") and not PALETTES["haverlund"].has(value) and not value.is_valid_html_color():
		return _error("error: unknown colour '%s'. Colours: %s, or #rrggbb" % [value, ", ".join(PALETTES["haverlund"].keys())])
	if key == "theme" and not PALETTES.has(value):
		return _error("error: unknown theme '%s'. Themes: %s" % [value, ", ".join(PALETTES.keys())])
	config[key] = value
	if set_config.is_valid():
		set_config.call(key, value)
	return _result(true, "")


# --- shell ------------------------------------------------------------------------------------

func _ls(args: PackedStringArray) -> Dictionary:
	if repo == null:
		return _result(true, "")
	var prefix: String = (args[0].rstrip("/") + "/") if not args.is_empty() and args[0] != "." else ""
	var entries: PackedStringArray = []
	for file: String in repo.files():
		if not file.begins_with(prefix): continue
		var rest: String = file.trim_prefix(prefix)
		var first: String = rest.get_slice("/", 0) + ("/" if rest.contains("/") else "")
		if not entries.has(first): entries.append(first)
	if entries.is_empty() and prefix != "":
		return _error("ls: cannot access '%s': No such file or directory" % args[0])
	var out: Array[String] = []
	for entry: String in entries:
		out.append(_c(entry, "color.prompt.path") if entry.ends_with("/") else entry)
	return _result(true, "  ".join(out))


func _cat(args: PackedStringArray) -> Dictionary:
	if args.is_empty():
		return _error("usage: cat <file>")
	if repo == null or not repo.files().has(args[0]):
		return _error("cat: %s: No such file or directory" % args[0])
	return _result(true, repo.read_file(args[0]).rstrip("\n"))


func _help() -> String:
	return "\n".join([
		_b("The tablet terminal"),
		"  git status            what changed since your last save",
		"  git add .             stage everything that changed",
		"  git commit -m \"...\"  save: record what is staged, with a message",
		"  git log --oneline     your saves, newest first (--graph --all for every branch)",
		"  git branch <name>     a new save line; git switch <name> moves to it",
		"  git checkout <id>     look at an older save (detached HEAD)",
		"  git diff              what you changed; --staged for what is about to be saved",
		"  git stash / pop       set changes aside and bring them back",
		"  git config --list     prompt and colours; git config theme ember",
		"  ls, cat, clear, exit  look around, read a file, wipe the screen, back to the home screen",
		"  reset                 this room: lamps dark, program memory cleared (your code and pay stay)",
		"  logout / quit         back to the title / close the game (both warn about uncommitted work)",
		_dim("Nothing is saved until it is committed. Quitting with uncommitted changes loses them."),
	])


func _git_help() -> String:
	return "usage: git <command> [<args>]\n\n" + "\n".join([
		"   status     Show the working tree status",
		"   add        Add file contents to the index",
		"   commit     Record changes to the repository",
		"   log        Show commit logs",
		"   branch     List, create, or delete branches",
		"   switch     Switch branches",
		"   checkout   Switch branches or restore working tree files",
		"   diff       Show changes between commits, commit and working tree, etc",
		"   restore    Restore working tree files",
		"   tag        Create or list tags",
		"   stash      Stash the changes in a dirty working directory away",
		"   reset      Reset current HEAD to the specified state",
		"   config     Get and set repository options",
	]) + "\n\n'help' explains these in plain words."


# --- formatting -------------------------------------------------------------------------------

func _changed() -> void:
	if changed.is_valid():
		changed.call()


func _result(ok: bool, output: String, tree_changed: bool = false) -> Dictionary:
	return {"ok": ok, "output": output, "changed": tree_changed, "clear": false, "exit": false}


func _error(text: String) -> Dictionary:
	return _result(false, _c(text, "color.error"))


func _hex(key: String) -> String:
	var name: String = str(config.get(key, SaveRepo.CONFIG_DEFAULTS.get(key, "white")))
	var palette: Dictionary = PALETTES.get(str(config.get("theme", "haverlund")), PALETTES["haverlund"])
	if palette.has(name):
		return str(palette[name])
	return name.trim_prefix("#") if name.is_valid_html_color() else str(palette["white"])


func _c(text: String, key: String) -> String:
	return "[color=#%s]%s[/color]" % [_hex(key), text] if text != "" else ""


func _dim(text: String) -> String:
	var palette: Dictionary = PALETTES.get(str(config.get("theme", "haverlund")), PALETTES["haverlund"])
	return "[color=#%s]%s[/color]" % [palette["dim"], text]


func _b(text: String) -> String:
	return "[b]%s[/b]" % text


func _color_diff(text: String) -> String:
	var out: Array[String] = []
	for line: String in text.rstrip("\n").split("\n"):
		if line.begins_with("+++") or line.begins_with("---") or line.begins_with("diff "):
			out.append(_b(_c(line, "color.diff.header")))
		elif line.begins_with("@@"):
			out.append(_c(line, "color.diff.hunk"))
		elif line.begins_with("+"):
			out.append(_c(line, "color.diff.add"))
		elif line.begins_with("-"):
			out.append(_c(line, "color.diff.remove"))
		else:
			out.append(line)
	return "\n".join(out) if text != "" else ""


func _expand(spec: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var known: PackedStringArray = repo.files()
	for path: String in repo._commit_tree(str(repo._head().get("id", ""))):
		if not known.has(path): known.append(path)
	for path: String in known:
		if path == spec or spec == "." or path.begins_with(spec.rstrip("/") + "/"):
			out.append(path)
	return out


static func _sorted(keys: Array) -> Array:
	var out: Array = keys.duplicate()
	out.sort()
	return out


static func _pad(text: String, width: int) -> String:
	return text + " ".repeat(maxi(0, width - text.length()))


static func _hhmm(unix: int) -> String:
	var parts: Dictionary = Time.get_datetime_dict_from_unix_time(unix)
	return "%02d:%02d" % [int(parts.hour), int(parts.minute)]
