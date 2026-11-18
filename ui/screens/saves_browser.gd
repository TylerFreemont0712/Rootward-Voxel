class_name SavesBrowser
extends VBoxContainer
## Saves as repositories: the profiles, the chosen one's commit graph, git-like properties of the
## selected commit, and a command line pre-filled with the command that loads it. Two layouts share
## the parts: `portrait` for the field tablet's Saves app (one column, the repository chosen from a
## quiet selector that marks the current one) and landscape for the title's load modal (repositories
## listed down the left). Enter runs the line through GitShell against that repository; a command
## that moves the working tree asks the game to load from it (docs/concept/save-vcs/PLAN.md).

signal load_requested(slug: String)
signal deleted
signal closed
## A commit was tapped in the graph (lessons listen).
signal graph_tapped(id: String)

## The lesson's example tree: an invented little history, shown instead of the repository while
## Hotaru explains what the dots and lines mean. Nothing can be run against it.
const PHANTOM_IDS: Array[String] = ["c3a9f1d2e4b5061728394a5b6c7d8e9f0a1b2c3d", "7b2e4d6f8a0c1e3f5a7b9d1f3e5c7a9b1d3f5e7c", "a1c3e5f7b9d1f3a5c7e9b1d3f5a7c9e1b3d5f7a9", "f0e1d2c3b4a5968778695a4b3c2d1e0f1a2b3c4d"]

var game: Game
var portrait: bool = false
var _slug: String = ""
var _profiles: Array[Dictionary] = []
var _list: VBoxContainer
var _selector: OptionButton
var _repo_title: Label
var _repo_meta: Label
var _branches_row: HBoxContainer
var _graph: HistoryGraph
var _details: VBoxContainer
var _command: LineEdit
var _output: RichTextLabel
var _vcs: Vcs
var _shell: GitShell
var _graph_data: Dictionary = {}
var _files: VBoxContainer
var _run: FButton
var _phantom: bool = false
var _example_note: Label


func setup(owner: Game, one_column: bool) -> void:
	game = owner
	portrait = one_column
	add_theme_constant_override("separation", 10)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profiles = SaveRepo.profiles()
	_slug = SaveRepo.current()
	if (_slug == "" or _find_profile(_slug).is_empty()) and not _profiles.is_empty():
		_slug = str(_profiles[0].slug)
	if portrait:
		_build_portrait()
	else:
		_build_landscape()
	_show_profile(_slug)


# --- Layouts ----------------------------------------------------------------------------------

func _build_portrait() -> void:
	# The repository: a quiet selector, the current one marked.
	var repo_row := UI.hbox(10)
	repo_row.add_child(UI.caps("Repository", Pal.BRASS))
	_selector = OptionButton.new()
	_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selector.add_theme_font_override("font", UITheme.mono_font())
	_selector.item_selected.connect(func(index: int) -> void: _show_profile(str(_selector.get_item_metadata(index))))
	repo_row.add_child(_selector)
	add_child(repo_row)
	var head_row := UI.hbox(10)
	_repo_title = UI.label("", &"", 14, Pal.PARCHMENT)
	_repo_title.add_theme_font_override("font", UITheme.mono_font())
	head_row.add_child(_repo_title)
	_repo_meta = UI.label("", &"LabelDim", 13)
	_repo_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(_repo_meta)
	add_child(head_row)
	_branches_row = UI.hbox(6)
	add_child(_branches_row)
	var frame := UI.panel(&"PanelInset")
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(frame)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 220
	frame.add_child(scroll)
	_graph = HistoryGraph.new()
	_graph.min_width = 420.0
	_graph.compact = true
	_graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph.selected.connect(_show_commit)
	_graph.selected.connect(func(id: String) -> void: graph_tapped.emit(id))
	scroll.add_child(_graph)
	_example_note = UI.label("AN EXAMPLE · not your saves", &"LabelCaps", 0, Pal.VIOLET)
	_example_note.visible = false
	_example_note.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_example_note.offset_left = -220
	_example_note.offset_right = -10
	_example_note.offset_top = 6
	_example_note.offset_bottom = 26
	_example_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	frame.add_child(_example_note)
	# The selected commit: its properties on the left, the files it altered on the right.
	var columns := UI.hbox(16)
	columns.custom_minimum_size.y = 250
	add_child(columns)
	var details_scroll := ScrollContainer.new()
	details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_scroll.size_flags_stretch_ratio = 1.25
	columns.add_child(details_scroll)
	_details = UI.vbox(6)
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_scroll.add_child(_details)
	var files_scroll := ScrollContainer.new()
	files_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	files_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(files_scroll)
	_files = UI.vbox(4)
	_files.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	files_scroll.add_child(_files)
	_build_command_row(false)


func _build_landscape() -> void:
	var split := UI.hbox(16)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(split)
	var left := UI.vbox(8)
	left.custom_minimum_size.x = 270
	split.add_child(left)
	left.add_child(UI.caps("Repositories", Pal.BRASS))
	var list_scroll := ScrollContainer.new()
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(list_scroll)
	_list = UI.vbox(8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(_list)
	left.add_child(UI.button("Delete repository", &"trash", &"ButtonDanger", _confirm_delete))
	var middle := UI.vbox(6)
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(middle)
	var head := UI.hbox(10)
	_repo_title = UI.label("", &"", 15, Pal.PARCHMENT)
	_repo_title.add_theme_font_override("font", UITheme.mono_font())
	head.add_child(_repo_title)
	_repo_meta = UI.label("", &"LabelDim", 13)
	_repo_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_repo_meta)
	middle.add_child(head)
	_branches_row = UI.hbox(6)
	middle.add_child(_branches_row)
	var frame := UI.panel(&"PanelInset")
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_child(frame)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(520, 360)
	frame.add_child(scroll)
	_graph = HistoryGraph.new()
	_graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph.selected.connect(_show_commit)
	_graph.selected.connect(func(id: String) -> void: graph_tapped.emit(id))
	scroll.add_child(_graph)
	var right_scroll := ScrollContainer.new()
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_scroll.custom_minimum_size.x = 380
	split.add_child(right_scroll)
	_details = UI.vbox(8)
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(_details)
	add_child(UI.rule())
	_build_command_row(true)


func _build_command_row(with_back: bool) -> void:
	var prompt_row := UI.hbox(8)
	add_child(prompt_row)
	var dollar := UI.label("$", &"", 16, Pal.TEAL)
	dollar.add_theme_font_override("font", UITheme.mono_font())
	prompt_row.add_child(dollar)
	_command = LineEdit.new()
	_command.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_command.add_theme_font_override("font", UITheme.mono_font())
	_command.add_theme_font_size_override("font_size", 15)
	_command.placeholder_text = "git switch <branch>  ·  git checkout <commit>"
	_command.text_submitted.connect(func(_text: String) -> void: run_command())
	prompt_row.add_child(_command)
	_run = UI.button("Run", &"play", &"ButtonPrimary", run_command)
	_run.custom_minimum_size = Vector2(110, 38)
	prompt_row.add_child(_run)
	if with_back:
		var back := UI.button("Back", &"cross", &"", func() -> void: closed.emit())
		back.custom_minimum_size = Vector2(100, 38)
		prompt_row.add_child(back)
	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.fit_content = true
	_output.scroll_active = false
	_output.custom_minimum_size.y = 44
	_output.add_theme_font_override("normal_font", UITheme.mono_font())
	_output.add_theme_font_size_override("normal_font_size", 13)
	_output.add_theme_color_override("default_color", Pal.PARCH_DIM)
	add_child(_output)


# --- Behaviour --------------------------------------------------------------------------------

## The lesson's example tree in place of the repository (or the repository again).
func show_phantom(on: bool) -> void:
	_phantom = on
	if _example_note != null:
		_example_note.visible = on
	if _run != null:
		_run.disabled = on
	if on:
		_graph_data = phantom_graph()
		_graph.selected_id = str((_graph_data.head as Dictionary).get("id", ""))
		_graph.setup(_graph_data)
		_show_commit(_graph.selected_id)
	else:
		_refresh_graph()


## The invented history: main with three commits, a side branch from the second, a tag on the tip.
static func phantom_graph() -> Dictionary:
	var now: int = int(Time.get_unix_time_from_system())
	var c1 := {"id": PHANTOM_IDS[3], "short": PHANTOM_IDS[3].substr(0, 7), "parents": [], "message": "Initial commit", "author": "Nell", "time": now - 86400 * 3, "files": ["journey.json", "rooms/workshop-loft/state.json", "programs/main.py"]}
	var c2 := {"id": PHANTOM_IDS[2], "short": PHANTOM_IDS[2].substr(0, 7), "parents": [PHANTOM_IDS[3]], "message": "Lit the landing lamp", "author": "Nell", "time": now - 86400 * 2, "files": ["rooms/workshop-floor/state.json", "programs/landing-light.py"]}
	var t1 := {"id": PHANTOM_IDS[1], "short": PHANTOM_IDS[1].substr(0, 7), "parents": [PHANTOM_IDS[2]], "message": "Tried a brighter lamp", "author": "Nell", "time": now - 86400 - 3600, "files": ["programs/landing-light.py"]}
	var c3 := {"id": PHANTOM_IDS[0], "short": PHANTOM_IDS[0].substr(0, 7), "parents": [PHANTOM_IDS[2]], "message": "Wrote the morning round", "author": "Nell", "time": now - 86400, "files": ["rooms/workshop-floor/state.json", "rooms/workshop-floor/quests.json", "programs/morning-round.py"]}
	var commits: Array[Dictionary] = [c3, t1, c2, c1]
	return {"commits": commits, "tips": {"refs/heads/main": PHANTOM_IDS[0], "refs/heads/try-something": PHANTOM_IDS[1], "refs/tags/day-one": PHANTOM_IDS[0]}, "head": {"branch": "main", "id": PHANTOM_IDS[0]}}


## Runs the command line against the shown repository. A command that moved its working tree asks
## the game to load from it; anything else just prints, as the terminal would.
func run_command() -> void:
	if _shell == null or _phantom:
		return
	var line: String = _command.text.strip_edges()
	if line == "":
		return
	var result: Dictionary = _shell.run(line)
	var echo: String = "[color=#%s]$ %s[/color]" % [Pal.TEAL.to_html(false), line.replace("[", "[lb]")]
	_output.text = echo + ("\n" + str(result.output) if str(result.output) != "" else "")
	if result.changed:
		load_requested.emit(_slug)
	elif result.ok:
		_refresh_graph()


func _show_profile(slug: String) -> void:
	_slug = slug
	var profile: Dictionary = _find_profile(slug)
	_vcs = Vcs.new(SaveRepo.root + "/" + slug) if slug != "" else null
	if _vcs != null and _vcs.is_repo():
		# Outside play, or for another repository, the working tree is whatever was never committed:
		# by design that is gone, so the repository shows HEAD and switching is never blocked by it.
		if not (game.playing and slug == SaveRepo.current()):
			_vcs.reset_hard()
			for path: String in _vcs.status().untracked:
				_vcs.delete_file(path)
		_shell = GitShell.new(_vcs)
		var parsed: Variant = JSON.parse_string(_vcs.read_file("config.json")) if _vcs.read_file("config.json") != "" else null
		if parsed is Dictionary:
			_shell.config.merge(parsed, true)
		_shell.user = str(profile.get("name", "player")).to_lower().replace(" ", "")
		_shell.before = func() -> void:
			if game.playing and _slug == SaveRepo.current(): game.sync_working_tree()
		_shell.set_config = func(key: String, value: String) -> void:
			var data: Variant = JSON.parse_string(_vcs.read_file("config.json")) if _vcs.read_file("config.json") != "" else {}
			if not data is Dictionary: data = {}
			data[key] = value
			_vcs.write_file("config.json", JSON.stringify(data, "  ") + "\n")
	else:
		_shell = null
	_output.text = ""
	_phantom = false
	if _example_note != null: _example_note.visible = false
	if _run != null: _run.disabled = false
	_refresh_graph()
	if portrait:
		_fill_selector()
	else:
		_build_list()


func _refresh_graph() -> void:
	_graph_data = _vcs.log_all() if _vcs != null and _vcs.is_repo() else {"commits": [], "tips": {}, "head": {}}
	var head: Dictionary = _graph_data.head
	var profile: Dictionary = _find_profile(_slug)
	var current: bool = _slug == SaveRepo.current()
	_repo_title.text = "%s/journey" % str(profile.get("name", _slug)).to_lower().replace(" ", "-") + ("  ● current" if current else "")
	_repo_title.add_theme_color_override("font_color", Pal.GREEN if current else Pal.PARCHMENT)
	var branches: PackedStringArray = _vcs.branches() if _vcs != null else PackedStringArray()
	var commits: int = (_graph_data.commits as Array).size()
	_repo_meta.text = "%s · %d commit%s · %d branch%s" % [("on " + str(head.branch)) if str(head.get("branch", "")) != "" else "HEAD detached at " + str(head.get("id", "")).substr(0, 7), commits, "" if commits == 1 else "s", branches.size(), "" if branches.size() == 1 else "es"]
	for child: Node in _branches_row.get_children():
		child.queue_free()
	_branches_row.add_child(UI.label("branches", &"LabelDim", 12))
	if _phantom:
		branches = PackedStringArray(["main", "try-something"])
	for name: String in branches:
		var on_it: bool = name == str(head.get("branch", ""))
		var chip := UI.button(("● " if on_it else "") + name, &"", &"ButtonPrimary" if on_it else &"ButtonQuiet", func() -> void:
			_command.text = "git switch " + name
			_command.caret_column = _command.text.length()
			_graph.select(str(_graph_data.tips.get("refs/heads/" + name, ""))))
		chip.custom_minimum_size.y = 28
		chip.add_theme_font_override("font", UITheme.mono_font())
		chip.tooltip_text = ("Your current save line" if on_it else "Fill the command to switch to " + name)
		_branches_row.add_child(chip)
	_graph.selected_id = str(head.get("id", ""))
	_graph.setup(_graph_data)
	_show_commit(_graph.selected_id)


func _fill_selector() -> void:
	_selector.clear()
	for index: int in range(_profiles.size()):
		var profile: Dictionary = _profiles[index]
		var slug: String = str(profile.slug)
		var current: bool = slug == SaveRepo.current()
		_selector.add_item("%s%s · %s · %d commit%s" % ["● " if current else "", str(profile.name), str(profile.get("head", "")) if str(profile.get("head", "")) != "" else "detached", int(profile.commits), "" if int(profile.commits) == 1 else "s"])
		_selector.set_item_metadata(index, slug)
		if slug == _slug:
			_selector.select(index)


func _build_list() -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	for profile: Dictionary in _profiles:
		var slug: String = str(profile.slug)
		var current: bool = slug == SaveRepo.current()
		var card_button := Button.new()
		for state: StringName in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
			card_button.add_theme_stylebox_override(state, _card_style(slug == _slug, state == &"hover" or state == &"focus"))
		card_button.custom_minimum_size = Vector2(0, 84)
		card_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card_button.pressed.connect(func() -> void: _show_profile(slug))
		var inner := UI.vbox(2)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 12
		inner.offset_top = 8
		inner.offset_right = -12
		inner.offset_bottom = -8
		var name_row := UI.hbox(8)
		name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var who := UI.label(str(profile.name), &"LabelHeading", 18)
		who.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_row.add_child(who)
		var branch := UI.label(("● " if current else "") + (str(profile.get("head", "")) if str(profile.get("head", "")) != "" else "detached"), &"", 12, Pal.GREEN)
		branch.add_theme_font_override("font", UITheme.mono_font())
		branch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		branch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		branch.tooltip_text = "The current repository" if current else ""
		name_row.add_child(branch)
		inner.add_child(name_row)
		var counts := UI.label("%d commit%s · %d branch%s%s" % [int(profile.commits), "" if int(profile.commits) == 1 else "s", int(profile.branches), "" if int(profile.branches) == 1 else "es", " · current" if current else ""], &"LabelDim", 13)
		counts.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(counts)
		var last := UI.label(_age(int(profile.get("last_commit", 0))) + (" · " + str(profile.get("last_message", "")).split("\n")[0] if str(profile.get("last_message", "")) != "" else ""), &"LabelDim", 12)
		last.mouse_filter = Control.MOUSE_FILTER_IGNORE
		last.clip_text = true
		inner.add_child(last)
		card_button.add_child(inner)
		_list.add_child(card_button)


func _show_commit(id: String) -> void:
	for child: Node in _details.get_children():
		_details.remove_child(child)
		child.queue_free()
	var commit: Dictionary = {}
	for entry: Dictionary in _graph_data.commits:
		if str(entry.id) == id:
			commit = entry
	if commit.is_empty():
		_details.add_child(UI.caps("Commit", Pal.BRASS))
		_details.add_child(UI.dim("This repository has no commits yet. Only committed progress can be loaded.", 15))
		_command.text = ""
		return
	var head: Dictionary = _graph_data.head
	var is_head: bool = str(head.get("id", "")) == id
	_details.add_child(UI.caps("Commit" + ("  ·  you are here" if is_head else ""), Pal.GREEN if is_head else Pal.BRASS))
	_details.add_child(UI.heading(str(commit.message).split("\n")[0], 20 if portrait else 22))
	var more: PackedStringArray = str(commit.message).split("\n").slice(1)
	if not " ".join(more).strip_edges().is_empty():
		_details.add_child(UI.dim(" ".join(more).strip_edges(), 14))
	var ref: String = _ref_for(id)
	var parents: Array = commit.get("parents", [])
	var parent_text: String = ", ".join(parents.map(func(p: Variant) -> String: return str(p).substr(0, 7))) if not parents.is_empty() else "(root commit)"
	var changed: PackedStringArray = PackedStringArray(commit.get("files", [])) if _phantom else _vcs.changed_paths(str(parents[0]) if not parents.is_empty() else "", id)
	var refs: Array[String] = []
	if is_head:
		refs.append("HEAD" + (" -> " + str(head.branch) if str(head.get("branch", "")) != "" else ""))
	for tip: String in _graph_data.tips:
		if str(_graph_data.tips[tip]) == id:
			var name: String = tip.trim_prefix("refs/heads/").trim_prefix("refs/tags/")
			if not (tip.begins_with("refs/heads/") and name == str(head.get("branch", ""))):
				refs.append(("tag: " if tip.begins_with("refs/tags/") else "") + name)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 3)
	for row: Array in [["commit", str(commit.id).substr(0, 12)], ["author", str(commit.author)], ["date", Time.get_datetime_string_from_unix_time(int(commit.time), true).replace("T", " ")], ["parent", parent_text], ["refs", ", ".join(refs) if not refs.is_empty() else "—"], ["changed", "%d file%s" % [changed.size(), "" if changed.size() == 1 else "s"]]]:
		var key := UI.label(row[0], &"LabelDim", 13)
		key.add_theme_font_override("font", UITheme.mono_font())
		grid.add_child(key)
		var value := UI.label(row[1], &"", 13, Pal.PARCHMENT)
		value.add_theme_font_override("font", UITheme.mono_font())
		value.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(value)
	_details.add_child(grid)
	if _files != null:
		for child: Node in _files.get_children():
			_files.remove_child(child)
			child.queue_free()
		_files.add_child(UI.caps("Altered files · %d" % changed.size(), Pal.BRASS))
		for path: String in changed:
			var file := UI.label(path, &"", 12, Pal.PARCHMENT)
			file.add_theme_font_override("font", UITheme.mono_font())
			file.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
			_files.add_child(file)
		if changed.is_empty():
			_files.add_child(UI.dim("Nothing differs from its parent.", 12))
	elif not changed.is_empty():
		var files := UI.label("\n".join(changed.slice(0, 8)) + ("\n…" if changed.size() > 8 else ""), &"LabelDim", 12)
		files.add_theme_font_override("font", UITheme.mono_font())
		_details.add_child(files)
	_details.add_child(UI.rule())
	if _phantom:
		_details.add_child(UI.dim("An example, for the lesson. Tap the dots; the command below fills in for each.", 13))
		var example_branch: bool = ref == "main" or ref == "try-something"
		_command.text = "git " + ("switch " if example_branch else "checkout ") + ref
		_command.caret_column = _command.text.length()
		return
	var data: Dictionary = SaveRepo.join(_vcs.files_at(id))
	if not data.is_empty():
		_details.add_child(UI.label(game.head_summary(data), &"LabelHeading", 15))
		var active: String = str((data.get("journey_rooms", {}) as Dictionary).get("active", data.get("area", "")))
		var where: AreaDef = AreaStore.load_area(active)
		var clock: Dictionary = CityCycle.restore(data.get("city_cycle", {}))
		var purse: Dictionary = data.get("accounts", {})
		var programs: int = 0
		for path: String in _vcs.files_at(id):
			if path.begins_with("programs/") and path.ends_with(".py"): programs += 1
		_details.add_child(UI.dim("%s · day %d, %02d:%02d · %d p · %d program%s" % [where.title if where != null else active, int(clock.day), int(CityCycle.time(clock).hour), int(clock.minute) % 60, int(purse.get("wallet", 0)), programs, "" if programs == 1 else "s"], 14))
	var is_branch: bool = _vcs.branches().has(ref)
	_details.add_child(UI.dim(("You are on this save line now." if is_head and is_branch else "Loads this save line and continues it.") if is_branch else "Looks at this older save with a detached HEAD. To keep going from it:  git switch -c <name>", 13))
	_command.text = "git " + ("switch " if is_branch else "checkout ") + ref
	_command.caret_column = _command.text.length()


func _confirm_delete() -> void:
	var profile: Dictionary = _find_profile(_slug)
	if profile.is_empty():
		return
	var confirm := ConfirmDialog.new()
	confirm.ask("Delete %s?" % str(profile.get("name", "this repository")), "Every commit, branch and the working tree of this repository are removed. There is no undo.", "Delete", true)
	confirm.confirmed.connect(func() -> void:
		SaveRepo.delete_profile(_slug)
		_profiles = SaveRepo.profiles()
		deleted.emit()
		if _profiles.is_empty():
			closed.emit()
		else:
			_show_profile(str(_profiles[0].slug)))
	game._push_modal(confirm)


## A branch name when the commit is a branch tip (preferring the checked-out branch), else its short id.
func _ref_for(id: String) -> String:
	var head: Dictionary = _graph_data.head
	if str(head.get("id", "")) == id and str(head.get("branch", "")) != "":
		return str(head.branch)
	var names: Array = _graph_data.tips.keys()
	names.sort()
	for tip: String in names:
		if tip.begins_with("refs/heads/") and str(_graph_data.tips[tip]) == id:
			return tip.trim_prefix("refs/heads/")
	return id.substr(0, 7)


## A lesson's highlight target inside the browser.
func lesson_target(name: String) -> Control:
	match name:
		"graph": return _graph
		"branches": return _branches_row
		"command": return _command
	return null


func _find_profile(slug: String) -> Dictionary:
	for entry: Dictionary in _profiles:
		if str(entry.slug) == slug:
			return entry
	return {}


## A repository row: dark leather, brass-edged when it is the one shown.
static func _card_style(selected: bool, hot: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Pal.WOOD_HI if selected else (Pal.PANEL_HI if hot else Pal.PANEL)
	box.border_color = Pal.BRASS if selected else (Pal.BRASS_LO if hot else Pal.WOOD)
	box.set_border_width_all(2 if selected else 1)
	box.set_corner_radius_all(6)
	return box


static func _age(time: int) -> String:
	if time <= 0: return "never"
	var seconds: int = maxi(0, int(Time.get_unix_time_from_system()) - time)
	if seconds < 60: return "just now"
	if seconds < 3600: return "%d min ago" % (seconds / 60)
	if seconds < 86400: return "%d h ago" % (seconds / 3600)
	if seconds < 86400 * 14: return "%d days ago" % (seconds / 86400)
	return Time.get_date_string_from_unix_time(time)
