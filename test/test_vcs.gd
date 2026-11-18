extends SceneTree
## The in-game version-control repository behind saving (docs/concept/save-vcs/PLAN.md):
## init, status, add, commit, log, branches, switch/checkout, diff, restore, tags and stash,
## with git's vocabulary and refusals. Everything runs in a scratch directory.

var _checks: int = 0
var _failures: Array[String] = []
var _clock: int = 1000


func _initialize() -> void:
	var root: String = "user://test_vcs_%d" % OS.get_process_id()
	_wipe(root)
	_lifecycle(_repo(root + "/a"))
	_branching(_repo(root + "/b"))
	_diff_and_restore(_repo(root + "/c"))
	_stash(_repo(root + "/d"))
	_diff_text()
	_split_join()
	_lanes()
	_tree_graph(_repo(root + "/f"))
	_shell(_repo(root + "/e"))
	_wipe(root)
	print("Version control: %d checks, %d failures." % [_checks, _failures.size()])
	for failure: String in _failures: printerr("FAIL: " + failure)
	quit(0 if _failures.is_empty() else 1)


func _repo(root: String) -> Vcs:
	var repo := Vcs.new(root)
	repo.author = "Wren"
	repo.now = func() -> int:
		_clock += 10
		return _clock
	repo.init_repo()
	return repo


func _lifecycle(repo: Vcs) -> void:
	_check(repo.is_repo() and repo.status().clean, "init makes an empty, clean repository")
	_check(repo.status().branch == "main", "HEAD starts attached to main")
	repo.write_file("state/quests.json", "{\"done\": []}\n")
	repo.write_file("programs/greeting.py", "print(\"Hello, Hotaru!\")\n")
	var state: Dictionary = repo.status()
	_check((state.untracked as PackedStringArray).size() == 2 and not state.clean, "New files start untracked")
	_check(not repo.commit("first").ok and repo.commit("first").error.contains("untracked files present"), "Commit refuses when nothing is staged and says why")
	_check(repo.add(PackedStringArray(["nope.txt"])).error.begins_with("fatal: pathspec"), "Adding a missing path fails like git")
	repo.add(PackedStringArray(["."]))
	state = repo.status()
	_check((state.staged as Dictionary).size() == 2 and str(state.staged["programs/greeting.py"]) == "new file", "add . stages everything as new files")
	_check(not repo.commit("  ").ok, "An empty message aborts the commit")
	var first: Dictionary = repo.commit("journey begins")
	_check(first.ok and str(first.short).length() == 7, "A staged commit succeeds with a short id")
	_check(repo.status().clean, "After the commit the tree is clean")
	_check(not repo.commit("again").ok and repo.commit("again").error == "nothing to commit, working tree clean", "A clean tree has nothing to commit")
	repo.write_file("programs/greeting.py", "print(\"Good morning!\")\n")
	state = repo.status()
	_check(str((state.unstaged as Dictionary).get("programs/greeting.py", "")) == "modified" and (state.staged as Dictionary).is_empty(), "An edit is unstaged until added")
	_check(repo.commit("x").error == "no changes added to commit (use \"git add\")", "Commit without add explains the staging step")
	repo.add(PackedStringArray(["programs/greeting.py"]))
	var second: Dictionary = repo.commit("teach the morning greeting")
	var entries: Array[Dictionary] = repo.history()
	_check(entries.size() == 2 and str(entries[0].id) == str(second.id) and str(entries[1].message) == "journey begins", "log lists newest first with messages")
	_check(str(entries[0].author) == "Wren" and int(entries[0].time) > int(entries[1].time), "Commits carry author and ordered times")
	repo.delete_file("state/quests.json")
	repo.add(PackedStringArray(["state/quests.json"]))
	_check(str((repo.status().staged as Dictionary).get("state/quests.json", "")) == "deleted", "Staging a removed file records the deletion")
	_check(repo.commit("drop the ledger").ok and not repo.files().has("state/quests.json"), "A deletion commits")


func _branching(repo: Vcs) -> void:
	_check(not repo.branch_create("x").ok, "No branch can be made before the first commit")
	repo.write_file("a.txt", "one\n")
	repo.add(PackedStringArray(["."]))
	var base: Dictionary = repo.commit("base")
	_check(not repo.branch_create("bad name").ok and not repo.branch_create("-x").ok, "Invalid branch names are refused")
	_check(repo.switch("experiment", true).ok and repo.status().branch == "experiment", "switch -c makes and moves to a branch")
	_check(not repo.branch_create("experiment").ok, "A duplicate branch name is refused")
	repo.write_file("a.txt", "two\n")
	repo.add(PackedStringArray(["."]))
	repo.commit("experiment change")
	_check(repo.switch("main").ok and repo.read_file("a.txt") == "one\n", "Switching back restores main's files")
	_check(repo.switch("experiment").ok and repo.read_file("a.txt") == "two\n", "Each branch keeps its own tree")
	_check(repo.switch("nowhere").error == "fatal: invalid reference: nowhere", "A missing branch fails like git")
	repo.write_file("a.txt", "dirty\n")
	var refused: Dictionary = repo.switch("main")
	_check(not refused.ok and refused.error.contains("would be overwritten by checkout") and refused.error.contains("a.txt"), "A dirty tree refuses to switch, naming the files")
	repo.restore("a.txt")
	_check(repo.read_file("a.txt") == "two\n" and repo.status().clean, "restore discards the working change")
	var detached: Dictionary = repo.checkout(str(base.short))
	_check(detached.ok and str(detached.message).contains("detached HEAD") and repo.status().detached, "Checking out a commit id detaches HEAD with git's note")
	_check(repo.read_file("a.txt") == "one\n", "The detached tree matches that commit")
	_check(repo.tag_create("day-one").ok and repo.checkout("day-one").ok, "Tags are made and checked out by name")
	repo.write_file("notes.txt", "untracked survives\n")
	_check(repo.switch("experiment").ok and repo.read_file("notes.txt") == "untracked survives\n", "An untracked file survives a switch")
	var graph: Dictionary = repo.log_all()
	_check((graph.commits as Array).size() == 2 and (graph.tips as Dictionary).has("refs/heads/main") and (graph.tips as Dictionary).has("refs/tags/day-one"), "log_all returns every commit with branch and tag tips")


func _diff_and_restore(repo: Vcs) -> void:
	repo.write_file("greeting.py", "a = 1\nprint(a)\n")
	repo.add(PackedStringArray(["."]))
	repo.commit("base")
	repo.write_file("greeting.py", "a = 2\nprint(a)\n")
	var working: String = repo.diff()
	_check(working.contains("-a = 1") and working.contains("+a = 2") and working.contains(" print(a)"), "diff shows the working change with context")
	_check(repo.diff("", "", true) == "", "Nothing is staged, so diff --staged is empty")
	repo.add(PackedStringArray(["."]))
	_check(repo.diff() == "" and repo.diff("", "", true).contains("+a = 2"), "After add the change moves from diff to diff --staged")
	var second: Dictionary = repo.commit("bump a")
	var between: String = repo.diff("HEAD", "HEAD")
	_check(between == "", "A commit against itself is empty")
	var first_id: String = str((repo.history()[-1] as Dictionary).id)
	_check(repo.diff(first_id, str(second.id)).contains("+a = 2"), "Two commits diff by id")
	_check(repo.restore("missing.py").error.begins_with("error: pathspec"), "Restoring an unknown path fails like git")


func _stash(repo: Vcs) -> void:
	repo.write_file("a.txt", "committed\n")
	repo.add(PackedStringArray(["."]))
	repo.commit("base")
	_check(not repo.stash_push().ok, "A clean tree has no local changes to save")
	repo.write_file("a.txt", "in progress\n")
	repo.write_file("new.txt", "untracked\n")
	_check(repo.stash_push("half-wired lamp").ok and repo.read_file("a.txt") == "committed\n" and not repo.files().has("new.txt"), "stash push sets the tree back to HEAD")
	_check(repo.stash_list().size() == 1 and str((repo.stash_list()[0] as Dictionary).message) == "half-wired lamp", "The stash lists its entry")
	_check(repo.stash_pop().ok and repo.read_file("a.txt") == "in progress\n" and repo.read_file("new.txt") == "untracked\n", "stash pop restores the exact working state")
	_check(not repo.stash_pop().ok and repo.stash_list().is_empty(), "Popping an empty stash fails like git")


func _diff_text() -> void:
	_check(VcsDiff.unified("same\n", "same\n", "x", "x") == "", "Equal texts make no diff")
	var text: String = VcsDiff.unified("", "hello\n", "greeting.py", "greeting.py")
	_check(text.contains("--- /dev/null") and text.contains("+hello"), "A new file diffs from /dev/null")
	var lines: PackedStringArray = PackedStringArray()
	for i: int in range(20): lines.append("line %d" % i)
	var a: String = "\n".join(lines) + "\n"
	var changed: PackedStringArray = lines.duplicate()
	changed[10] = "line ten, changed"
	var hunk: String = VcsDiff.unified(a, "\n".join(changed) + "\n", "x", "x")
	_check(hunk.contains("@@ -8,7 +8,7 @@") and hunk.contains("-line 10") and hunk.contains("+line ten, changed"), "A middle change makes one hunk with three context lines")
	_check(not hunk.contains("line 2\n") and hunk.contains(" line 7"), "Far lines stay out of the hunk")


## SaveRepo.split/join: the granular working tree is a lossless view of the session snapshot.
func _split_join() -> void:
	var room_a: Dictionary = {"version": 1, "area": "workshop-loft", "area_version": 7, "state": {"player": [3, 4, 0], "lamps": {"desk": true}, "memory": {"k": 1}},
		"completed": ["say-hello"], "source": "print(1)\n", "stats": {"runs": 2, "applies": 1}, "greeting_editor": {"mode": "python", "python": "print(\"hi\")"},
		"workshop_pages": {"landing-light": "lamp.set_lit(True)\n"}, "accounts": {"wallet": 25}, "city_cycle": {"day": 1, "minute": 600.0}, "edits": []}
	var room_b: Dictionary = room_a.duplicate(true)
	room_b.area = "workshop-floor"
	room_b.state = {"player": [1, 1, 0], "lamps": {}, "memory": {}}
	room_b.completed = []
	var data: Dictionary = room_a.duplicate(true)
	data.merge({"name": "Wren", "level": "sparks-and-machines", "dialogue_read": {"nell-note": ["read"]}, "workshop_log": [{"scene": "x"}],
		"journey_rooms": {"version": 1, "active": "workshop-floor", "rooms": {"workshop-loft": room_a, "workshop-floor": room_b}},
		"travel": {"version": 1, "active": "", "rooms": {"house-1": {"house": "h", "template": "t"}}}, "odd_key": {"kept": true}})
	var files: Dictionary = SaveRepo.split(data)
	_check(files.has("programs/main.py") and files["programs/main.py"] == "print(1)\n\n" and files.has("programs/landing-light.py") and files.has("programs/greeting.py"), "The player's programs are tracked as .py files")
	_check(files.has("rooms/workshop-loft/state.json") and files.has("rooms/workshop-floor/quests.json") and files.has("houses/house-1.json") and files.has("clock.json") and files.has("accounts.json"), "Rooms, houses, clock and accounts are their own files")
	_check(not files.has("rooms/workshop-loft/room.json") or not str(files["rooms/workshop-loft/room.json"]).contains("print(1)"), "Shared program text is not duplicated into every room")
	var back: Dictionary = SaveRepo.join(files)
	var expected: Dictionary = JSON.parse_string(JSON.stringify(data))
	_check(back == expected, "join(split(x)) gives the snapshot back (as JSON would)")
	room_a.state["time"] = {"hour": 9}
	room_a.state["city_power"] = 1.0
	room_a.city_cycle.minute = 600.4
	var noisy: Dictionary = SaveRepo.split(data)
	_check(not str(noisy["rooms/workshop-loft/state.json"]).contains("city_power") and str(noisy["clock.json"]).contains("\"minute\": 600\n") and noisy["rooms/workshop-loft/quests.json"] == files["rooms/workshop-loft/quests.json"], "Derived clock mirrors and sub-minute time are left out of the tree")
	_check(SaveRepo.join({}).is_empty() and SaveRepo.join({"stats.json": "{}"}).is_empty(), "No journey file means no snapshot")
	var reordered: Dictionary = {"state": {"memory": {"k": 1}, "lamps": {"desk": true}, "player": [3, 4, 0]}, "area": "workshop-loft", "version": 1}
	var ordered: Dictionary = {"version": 1, "area": "workshop-loft", "state": {"player": [3, 4, 0], "lamps": {"desk": true}, "memory": {"k": 1}}}
	_check(SaveRepo.split(reordered) == SaveRepo.split(ordered), "Dictionary order never changes the files (canonical JSON)")
	ordered.state.memory.k = 1.0
	_check(SaveRepo.split(reordered) == SaveRepo.split(ordered) and str(SaveRepo.split(ordered)["rooms/workshop-loft/state.json"]).contains("\"k\": 1\n"), "A whole float and its int write the same text")
	var flat: Dictionary = {"version": 1, "area": "a", "name": "N", "state": {"player": [0, 0, 0]}, "completed": [], "source": "x", "stats": {}, "greeting_editor": {}, "workshop_pages": {}, "accounts": {}, "city_cycle": {}, "edits": [], "travel": {"version": 1, "active": "", "rooms": {}}, "dialogue_read": {}, "level": "l"}
	_check(SaveRepo.join(SaveRepo.split(flat)) == JSON.parse_string(JSON.stringify(flat)), "A single-room snapshot round-trips too")


func _lanes() -> void:
	var c1: Dictionary = {"id": "c1", "parents": [], "time": 1, "message": "a", "author": "x", "short": "c1"}
	var c2: Dictionary = {"id": "c2", "parents": ["c1"], "time": 2, "message": "b", "author": "x", "short": "c2"}
	var c3: Dictionary = {"id": "c3", "parents": ["c1"], "time": 3, "message": "c", "author": "x", "short": "c3"}
	var rows: Array[Dictionary] = HistoryLanes.layout([c3, c2, c1])
	_check(rows.size() == 3 and int(rows[0].lane) == 0 and int(rows[1].lane) == 1 and int(rows[2].lane) == 0, "Two branches from one root take two lanes and rejoin at the root")
	_check(HistoryLanes.width(rows) == 2, "The graph is two lanes wide")
	var art: Array[Dictionary] = HistoryLanes.text_rows(rows)
	_check(art[0].line == "*" and art[1].line == "| *" and art[2].pre == "|/" and art[2].line == "*", "Text rows draw the star on the commit's lane and the join above the root: " + str(art))
	var linear: Array[Dictionary] = HistoryLanes.layout([c2, c1])
	_check(HistoryLanes.width(linear) == 1 and HistoryLanes.text_rows(linear)[0].line == "*" and HistoryLanes.text_rows(linear)[1].pre == "", "A linear history is one lane")


## A real, branching history through the engine, laid out for the graph: three lines, a tag and a
## detached look-around. Lanes, edges, text rows and the HistoryGraph control must all agree.
func _tree_graph(repo: Vcs) -> void:
	var ids: Dictionary = {}
	var save := func(name: String, text: String, message: String) -> void:
		repo.write_file("a.txt", text)
		repo.add(PackedStringArray(["."]))
		ids[name] = str(repo.commit(message).id)
	save.call("m1", "1", "Initial commit")
	save.call("m2", "2", "Second on main")
	repo.switch("lamps", true)
	save.call("l1", "l1", "Lamps one")
	save.call("l2", "l2", "Lamps two")
	repo.switch("main")
	save.call("m3", "3", "Third on main")
	repo.switch("evening", true)
	save.call("e1", "e1", "Evening one")
	repo.switch("main")
	save.call("m4", "4", "Fourth on main")
	repo.tag_create("day-one")
	var graph: Dictionary = repo.log_all()
	_check((graph.commits as Array).size() == 7 and (graph.tips as Dictionary).size() == 4, "Seven commits, three branches and a tag are all reachable")
	var rows: Array[Dictionary] = HistoryLanes.layout(graph.commits)
	var by_id: Dictionary = {}
	for row: Dictionary in rows: by_id[row.id] = row
	_check(int(by_id[ids.m4].lane) == 0 and int(by_id[ids.m3].lane) == 0 and int(by_id[ids.m2].lane) == 0 and int(by_id[ids.m1].lane) == 0, "main holds lane 0 all the way down")
	_check(int(by_id[ids.l2].lane) == int(by_id[ids.l1].lane) and int(by_id[ids.l1].lane) > 0, "The lamps branch keeps one lane of its own")
	_check(int(by_id[ids.e1].lane) > 0, "The evening branch leaves lane 0 too")
	# Evening closes into main before lamps opens below it, so the side lane is reused: two lanes, as git draws it.
	_check(HistoryLanes.width(rows) == 2 and int(by_id[ids.e1].lane) == int(by_id[ids.l2].lane), "A closed side lane is reused by the next branch down")
	_check(by_id[ids.l1].parents == [ids.m2] and by_id[ids.e1].parents == [ids.m3] and by_id[ids.m1].parents == [], "Parents point where the branches forked")
	var merged_rows: int = 0
	for row: Dictionary in rows:
		if not (row.merged as Array).is_empty(): merged_rows += 1
	_check(merged_rows == 2 and not (by_id[ids.m2].merged as Array).is_empty() and not (by_id[ids.m3].merged as Array).is_empty(), "Lanes close into main exactly where the branches began")
	var art: Array[Dictionary] = HistoryLanes.text_rows(rows)
	var stars: int = 0
	for line: Dictionary in art:
		if str(line.line).contains("*"): stars += 1
	_check(stars == 7 and str(art[0].line) == "*", "Every commit draws one star and the tip of main is first")
	var control := HistoryGraph.new()
	control.setup(graph)
	_check(control.rows.size() == 7 and control.selected_id == ids.m4 and str((control.head as Dictionary).get("branch", "")) == "main", "The graph control selects HEAD on main")
	for row: Dictionary in control.rows:
		for parent: String in row.parents:
			_check(control._index.has(parent), "Every edge has a row to draw to: " + parent.substr(0, 7))
	_check(control.custom_minimum_size.y >= HistoryGraph.ROW * 7, "The control asks for a row of height per commit")
	var shell := GitShell.new(repo)
	var text: String = GitShell.plain(shell.run("git log --oneline --graph --all").output)
	_check(text.split("\n").size() == 9 and text.contains("(HEAD -> main, tag: day-one)") and text.contains("(lamps)") and text.contains("(evening)"), "log --graph --all draws seven commits and two joins with every decoration: " + text.replace("\n", " | "))
	repo.checkout(ids.l1)
	control.setup(repo.log_all())
	_check(control.rows.size() == 7 and str((control.head as Dictionary).get("branch", "")) == "" and str((control.head as Dictionary).get("id", "")) == ids.l1, "A detached look-around keeps every lane and marks the detached HEAD")
	control.free()


## The terminal's grammar and wording over a repository.
func _shell(repo: Vcs) -> void:
	var shell := GitShell.new(repo)
	shell.user = "wren"
	shell.clock = func() -> int: return 1000
	var synced: Array[int] = [0]
	shell.before = func() -> void: synced[0] += 1
	var reloaded: Array[int] = [0]
	shell.changed = func() -> void: reloaded[0] += 1
	_check(GitShell.tokenize('git commit -m "a message with spaces" -am x') == PackedStringArray(["git", "commit", "-m", "a message with spaces", "-am", "x"]), "Quotes group words")
	_check(GitShell.tokenize("say 'it''s'  ok") == PackedStringArray(["say", "its", "ok"]), "Single quotes work and empty runs collapse")
	var plain: String = GitShell.plain(shell.prompt())
	_check(plain.begins_with("wren@haverlund ~/journey (main) $"), "The prompt follows prompt.format: " + plain)
	_check(GitShell.plain(shell.run("git status").output).contains("No commits yet") and synced[0] == 1, "git status reports an empty repository and syncs first")
	_check(GitShell.plain(shell.run("git foo").output) == "git: 'foo' is not a git command. See 'git --help'." , "Unknown git commands get git's wording")
	_check(GitShell.plain(shell.run("frobnicate").output) == "bash: frobnicate: command not found", "Unknown shell commands get bash's wording")
	repo.write_file("programs/main.py", "print(1)\n")
	repo.write_file("journey.json", "{}\n")
	var status: String = GitShell.plain(shell.run("git status").output)
	_check(status.contains("Untracked files:") and status.contains("programs/main.py") and status.contains("nothing added to commit"), "Untracked files are listed with the hint")
	_check(GitShell.plain(shell.run("git commit -m x").output).contains("untracked files present"), "Committing before add is refused like git")
	_check(shell.run("git add .").ok and GitShell.plain(shell.run("git status").output).contains("new file:   programs/main.py"), "git add . stages new files")
	_check(not shell.run("git commit").ok and GitShell.plain(shell.run("git commit").output).contains("-m"), "git commit without -m explains -m")
	var committed: String = GitShell.plain(shell.run('git commit -m "first light"').output)
	_check(committed.begins_with("[main ") and committed.contains("] first light") and committed.contains("2 files changed"), "A commit prints its summary line: " + committed)
	_check(GitShell.plain(shell.prompt()).contains("(main)") and not GitShell.plain(shell.prompt()).contains("*"), "A clean tree shows no dirty mark")
	repo.write_file("programs/main.py", "print(2)\n")
	_check(GitShell.plain(shell.prompt()).contains("(main*)"), "A dirty tree marks the prompt")
	var diff: String = shell.run("git diff").output
	_check(GitShell.plain(diff).contains("-print(1)") and GitShell.plain(diff).contains("+print(2)") and diff.contains("[color=#23d18b]+print(2)"), "git diff is coloured: additions green")
	_check(shell.run("git switch -c lamps").ok and reloaded[0] == 1 and repo.status().branch == "lamps", "switch -c creates and moves, and the game is told to reload")
	_check(shell.run("git add programs/main.py").ok and shell.run('git commit -m "brighter"').ok, "Work commits on the branch")
	var oneline: String = GitShell.plain(shell.run("git log --oneline --all --graph").output)
	_check(oneline.split("\n").size() >= 2 and oneline.contains("HEAD -> lamps") and oneline.contains("main") and oneline.begins_with("* "), "log --oneline --graph --all decorates and draws: " + oneline.replace("\n", " | "))
	var full: String = GitShell.plain(shell.run("git log -n 1").output)
	_check(full.contains("commit ") and full.contains("Author: Wren") and full.contains("    brighter"), "Full log shows commit, author and indented message")
	_check(GitShell.plain(shell.run("git branch").output).contains("* lamps"), "git branch marks the current branch")
	_check(shell.run("git switch main").ok and repo.read_file("programs/main.py") == "print(1)\n", "Switching back restores main's program")
	_check(GitShell.plain(shell.run("git switch nowhere").output) == "fatal: invalid reference: nowhere", "A missing branch fails like git")
	var head: String = str(repo.status().head).substr(0, 7)
	_check(GitShell.plain(shell.run("git checkout " + head).output).contains("detached HEAD") and repo.status().detached, "checkout <id> detaches with git's note")
	_check(shell.run("git switch main").ok and shell.run("git config theme ember").ok and shell.config.theme == "ember", "git config sets a known key")
	_check(not shell.run("git config nonsense 1").ok and not shell.run("git config theme nope").ok and not shell.run("git config color.diff.add plaid").ok, "Unknown keys, themes and colours are refused")
	_check(GitShell.plain(shell.run("git config --list").output).contains("prompt.format="), "git config --list prints every key")
	_check(GitShell.plain(shell.run("ls").output).contains("programs/") and GitShell.plain(shell.run("cat programs/main.py").output) == "print(1)", "ls and cat read the working tree")
	_check(shell.run("clear").clear and shell.run("exit").exit, "clear and exit are flagged for the terminal")
	_check(shell.run("git push").output.contains("no remote"), "push explains there is no remote")
	_check(shell.complete("git sw") == PackedStringArray(["switch"]) and shell.complete("git switch ") == PackedStringArray(["-c", "lamps", "main"]) and shell.complete("ca") == PackedStringArray(["cat"]), "Completion offers commands, branches and flags")


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(what)


func _wipe(root: String) -> void:
	var absolute: String = ProjectSettings.globalize_path(root)
	if DirAccess.dir_exists_absolute(absolute):
		OS.move_to_trash(absolute)
