extends SceneTree
## What a player's program may do to the valley's houses, trees and doodads: the abilities a lesson unlocks, what
## code can see (visited places plus a reach around the player), the rules every command passes, atomic batches,
## the ledger's hooks for applying and undoing, and the real Python/WASI path through the session.
## The abilities come from the shipped second-chapter lesson ("Face the lane"), reached once the five lessons are done.

const Program := preload("res://sandbox/lab_program.gd")
const FACE_THE_ROW: String = "def program(world):\n    row = world.zone(\"cottage-row\")\n    for house in row.houses:\n        if house.cell[1] < 18:\n            house.face(\"north\")\n"

const MAIN_ARC: Array = ["first-light", "light-the-green", "mill-bridge", "night-gate", "kindle-the-hollow"]
var _checks: int = 0
var _failures: Array[String] = []
var _source: Dictionary
var _catalog: Dictionary
var _quests: Dictionary


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveStore.save_path = "user://test_code_save.json"
	SaveStore.profile_path = "user://test_code_profile.json"
	SaveStore.force_enabled = true
	SaveStore.delete()
	_source = AreaStore.read_source("kindle-hollow")
	_catalog = AreaStore.read_build_catalog()
	_quests = (_source.quests as Dictionary).duplicate(true)
	_abilities()
	_reach_and_snapshot()
	_commands()
	_ledger()
	await _interface()
	await _epilogue()
	await _end_to_end()
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_code_profile.json"))
	_finish()


func _ledger_for(unlocked: bool = true) -> BuildLedger:
	return BuildLedger.new(_source.document, _source.assets, _quests, _catalog, [], "studio", AreaStore.ground_materials())


func _state(ledger: BuildLedger, seen: Array = [], player: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var state: Dictionary = ledger.rules.initial_state()
	for zone: String in seen:
		(state.zones_seen as Array).append(zone)
	if player.x >= 0:
		state.player = [player.x, player.y, 0]
	return state


## The abilities a player has once the five lessons are done, as the session computes them.
func _taught(ledger: BuildLedger) -> Array[String]:
	return Quests.capabilities(ledger.area, MAIN_ARC)


func _rotate(id: String, facing: String) -> Dictionary:
	return {"op": "rotate", "entity_id": id, "facing": facing}


# ---------------------------------------------------------------- abilities
func _abilities() -> void:
	var ledger: BuildLedger = _ledger_for()
	var area: AreaDef = ledger.area
	_check(Quests.capabilities(area, []).is_empty(), "Nothing is unlocked before any lesson")
	_check(Quests.capabilities(area, ["first-light"]).is_empty() and Quests.capabilities(area, MAIN_ARC.slice(0, 4)).is_empty(), "The lesson that teaches building opens only after the five before it")
	var earned: Array[String] = Quests.capabilities(area, MAIN_ARC)
	_check(earned.size() == 2 and earned.has("read") and earned.has("turn"), "Reaching the lesson hands over what it unlocks (its own goal needs it)")
	var kept: Array[String] = Quests.capabilities(area, MAIN_ARC + ["face-the-lane"])
	_check(kept.size() == 2, "...and finishing it keeps them")
	_check(Quests.unlocking(area, "turn").get("title") == "Face the lane" and Quests.unlocking(area, "read").get("id") == "face-the-lane", "The lesson that teaches an ability can be found")
	var bad: Dictionary = _quests.duplicate(true)
	((bad.quests as Array)[-1] as Dictionary)["unlocks"] = ["fly"]
	var parsed: Dictionary = AreaDef.parse(_source.document, _source.assets, bad, AreaStore.ground_materials())
	_check(not parsed.ok and str(parsed.errors).contains("unknown ability"), "A lesson cannot unlock an ability that does not exist")
	_check(CodeBuild.lessons(area, []).get("turn") == "Face the lane" and CodeBuild.lessons(area, earned).is_empty(), "The lessons that teach what is still locked can be listed; none once all is earned")
	_check(Quests.main(area).size() == 5 and Quests.main(area).all(func(entry: Dictionary) -> bool: return (entry.unlocks as Array).is_empty()), "The five lessons of the main arc unlock no building ability themselves")


# --------------------------------------------------------------- snapshot
func _reach_and_snapshot() -> void:
	var ledger: BuildLedger = _ledger_for()
	var locked: Dictionary = CodeBuild.snapshot(ledger, _state(ledger, ["cottage-row"]), [])
	_check((locked.houses as Array).is_empty() and (locked.trees as Array).is_empty() and (locked.doodads as Array).is_empty(), "Nothing is listed until the player's code can read")
	_check((locked.abilities as Array).is_empty() and locked.lessons.get("read") == "Face the lane", "...and the snapshot says which lesson teaches reading")
	var area: AreaDef = ledger.area
	var home: Dictionary = area.building("row-north-a")
	_check(area.zone_at(Vector2i(roundi(home.at.x), roundi(home.at.y))) == "cottage-row", "Cottage Row is where its houses stand")
	var far: Dictionary = CodeBuild.snapshot(ledger, _state(ledger), _taught(ledger))
	_check(_ids(far.houses).has("home") and not _ids(far.houses).has("row-north-a"), "A house in a visited place is listed; one in a place never visited and far away is not")
	var seen: Dictionary = CodeBuild.snapshot(ledger, _state(ledger, ["cottage-row"]), _taught(ledger))
	_check(_ids(seen.houses).has("row-north-a") and _ids(seen.houses).has("row-south-a") and _ids(seen.houses).has("row-workshop"), "Visiting the place lists its houses")
	_check(not _ids(seen.houses).has("brook-hall") and (seen.trees as Array).size() < area.trees.size(), "...and not the far side of the valley")
	# The reach around the player: a house in an unvisited place, at exactly 12 cells and a little beyond.
	var at: Vector2 = home.at
	var edge: Dictionary = CodeBuild.snapshot(ledger, _state(ledger, [], Vector2i(int(at.x) + 12, int(at.y))), _taught(ledger))
	var past: Dictionary = CodeBuild.snapshot(ledger, _state(ledger, [], Vector2i(int(at.x) + 13, int(at.y))), _taught(ledger))
	_check(_ids(edge.houses).has("row-north-a") and not _ids(past.houses).has("row-north-a"), "A thing exactly 12 cells from the player is in reach; one cell further is not")
	var tree_far: Dictionary = {}
	for tree: Dictionary in area.trees:
		if area.zone_at(Vector2i(roundi(tree.at.x), roundi(tree.at.y))) == "":
			tree_far = tree
			break
	_check(not tree_far.is_empty() and not CodeBuild.in_reach(area, _state(ledger), tree_far.at), "A tree in the forest, far from the player, is out of reach")
	_check(CodeBuild.in_reach(area, _state(ledger, [], Vector2i(roundi(tree_far.at.x), roundi(tree_far.at.y))), tree_far.at), "...and in reach once the player stands beside it")
	var entry: Dictionary = (seen.houses as Array).filter(func(house: Dictionary) -> bool: return house.id == "row-south-a")[0]
	_check(entry.kind == "house-hollow" and entry.name == "Hollow House" and entry.facing == "east" and entry.cell == [9, 15, 0] and entry.zone == "cottage-row" and entry.locked == false, "A house is described with its kind, name, facing, cell and place: %s" % str(entry))
	var mill: Dictionary = CodeBuild.snapshot(ledger, _state(ledger, ["mill-yard"]), _taught(ledger))
	_check((mill.houses as Array).any(func(house: Dictionary) -> bool: return house.id == "mill" and house.locked), "The mill is listed as locked")
	var room: Dictionary = AreaStore.read_source("village-cottage")
	var inside := BuildLedger.new(room.document, room.assets, room.quests, _catalog, [], "studio", AreaStore.ground_materials())
	var indoors: Dictionary = CodeBuild.snapshot(inside, _state(inside), _taught(ledger))
	_check((indoors.houses as Array).is_empty() and (indoors.trees as Array).is_empty(), "Inside a home there is nothing to list")


func _ids(list: Variant) -> Array:
	return (list as Array).map(func(entry: Dictionary) -> String: return str(entry.id))


# --------------------------------------------------------------- commands
func _commands() -> void:
	var ledger: BuildLedger = _ledger_for()
	var state: Dictionary = _state(ledger, ["cottage-row", "mill-yard"])
	var done: Array[String] = _taught(ledger)
	var before_edits: int = ledger.edits.size()
	_check(CodeBuild.is_build_command(_rotate("home", "N")) and not CodeBuild.is_build_command({"op": "set_field"}), "Rotate is a building command; set_field is not")
	var good: Dictionary = CodeBuild.propose(ledger, state, [_rotate("row-south-a", "N")], done)
	_check(good.ok and (good.edits as Array).size() == 1 and good.edits[0].facing == "N" and good.edits[0].by == "code" and good.edits[0].turned == true, "Turning a house in reach is accepted as one edit tagged as code: %s" % str(good.get("reason")))
	_check(good.area.building("row-south-a").facing == "N" and ledger.area.building("row-south-a").facing == "E" and ledger.edits.size() == before_edits, "...the proposal builds the new world but changes nothing yet")
	_check(str(good.changes[0]).contains("Hollow House") and str(good.changes[0]).contains("north"), "...and says what it does in words: %s" % str(good.changes))
	var none: Dictionary = CodeBuild.propose(ledger, state, [{"op": "set_field", "entity_id": "x", "field": "enabled", "value": true}], done)
	_check(none.ok and (none.edits as Array).is_empty(), "A batch with no building command asks nothing of this rule set")
	var same: Dictionary = CodeBuild.propose(ledger, state, [_rotate("row-south-a", "E")], done)
	_check(same.ok and (same.edits as Array).is_empty(), "Turning a house to how it already faces is harmless and does nothing")
	var locked: Dictionary = CodeBuild.propose(ledger, state, [_rotate("row-south-a", "N")], [])
	_check(not locked.ok and locked.reason.contains("Reach the lesson \"Face the lane\""), "Without the ability, the refusal names the lesson: %s" % locked.reason)
	var missing: Dictionary = CodeBuild.propose(ledger, state, [_rotate("nowhere", "N")], done)
	_check(not missing.ok and missing.reason.begins_with("Command 1:") and missing.reason.contains("world.houses"), "An unknown id says where to look: %s" % missing.reason)
	var unseen: Dictionary = CodeBuild.propose(ledger, _state(ledger), [_rotate("row-south-a", "N")], done)
	_check(not unseen.ok and unseen.reason.contains("out of reach"), "A house far away in a place never visited is out of reach: %s" % unseen.reason)
	var mill: Dictionary = CodeBuild.propose(ledger, state, [_rotate("mill", "N")], done)
	_check(not mill.ok and mill.reason.contains("part of the lessons"), "The mill cannot be turned: %s" % mill.reason)
	var wrong_word: Dictionary = CodeBuild.propose(ledger, state, [_rotate("row-south-a", "up")], done)
	_check(not wrong_word.ok, "A facing that is not a compass letter is refused")
	var extra: Dictionary = CodeBuild.propose(ledger, state, [{"op": "rotate", "entity_id": "row-south-a", "facing": "N", "speed": 3}], done)
	_check(not extra.ok and extra.reason.contains("only op, entity_id and facing"), "A command with extra fields is refused")
	var mixed: Dictionary = CodeBuild.propose(ledger, state, [_rotate("row-south-a", "N"), _rotate("nowhere", "N")], done)
	_check(not mixed.ok and mixed.reason.begins_with("Command 2:") and (mixed.edits as Array).is_empty(), "One refusal rejects the whole batch, and says which command: %s" % mixed.reason)
	var first_wins: Dictionary = CodeBuild.propose(ledger, state, [_rotate("row-south-a", "N"), _rotate("row-south-a", "S")], done)
	_check(first_wins.ok and (first_wins.edits as Array).size() == 2 and first_wins.area.building("row-south-a").facing == "S", "Commands run in order, each against what the earlier ones left")
	var too_many: Array = []
	for index: int in range(CodeBuild.MAX_BUILD_COMMANDS + 1):
		too_many.append(_rotate("row-south-a", "N" if index % 2 == 0 else "S"))
	var over: Dictionary = CodeBuild.propose(ledger, state, too_many, done)
	_check(not over.ok and over.reason.contains("at most 16"), "More than 16 building commands in one run is refused: %s" % over.reason)
	var room: Dictionary = AreaStore.read_source("village-cottage")
	var inside := BuildLedger.new(room.document, room.assets, room.quests, _catalog, [], "studio", AreaStore.ground_materials())
	var indoors: Dictionary = CodeBuild.propose(inside, _state(inside), [_rotate("anything", "N")], done)
	_check(not indoors.ok and indoors.reason.contains("Go outside"), "Indoors, building commands are refused: %s" % indoors.reason)
	# A facing the builder itself would refuse is refused for code too (here: found by asking the builder's rule).
	var blocked: String = ""
	var house: Dictionary = ledger.area.building("row-south-a")
	for letter: String in CodeBuild.FACING_LETTERS:
		if blocked == "" and not AreaBuild.check_building(ledger.context(state), str(house.asset), house.at, letter, float(house.scale), "row-south-a").ok:
			blocked = letter
	if blocked != "":
		var refused: Dictionary = CodeBuild.propose(ledger, state, [_rotate("row-south-a", blocked)], done)
		_check(not refused.ok and refused.reason.contains("cannot face"), "A facing the builder's rules refuse is refused for code too: %s" % refused.reason)
	else:
		_check(true, "(Every facing is allowed for this house, so no refusal to compare)")
	# LabWorld leaves building commands to CodeBuild only when told to.
	var rules: LabWorld = ledger.rules
	var plain: Dictionary = rules.propose(state, [_rotate("row-south-a", "N")], state.memory)
	var routed: Dictionary = rules.propose(state, [_rotate("row-south-a", "N")], state.memory, CodeBuild.BUILD_OPS)
	_check(not plain.ok and routed.ok, "LabWorld refuses an operation it does not know unless another rule set owns it")
	var skip: String = AreaBuild.reach_problem({"area": ledger.area, "rules": ledger.rules}, {"area": ledger.area, "rules": ledger.rules}, Vector2i(30, 8), ["row-south-a", "row-workshop"])
	_check(skip == "", "Reachability accepts a list of buildings whose own doors need not stay reachable")


# ----------------------------------------------------------------- ledger
func _ledger() -> void:
	var ledger: BuildLedger = _ledger_for()
	var state: Dictionary = _state(ledger, ["cottage-row"])
	var proposal: Dictionary = CodeBuild.propose(ledger, state, [_rotate("row-south-a", "N"), _rotate("row-workshop", "N")], _taught(ledger))
	_check(proposal.ok, "Two houses can be turned in one run: %s" % str(proposal.get("reason")))
	var before: AreaDef = ledger.area
	ledger.commit_code(proposal.edits, proposal.area, proposal.rules)
	_check(ledger.edits.size() == 2 and ledger.area.building("row-south-a").facing == "N" and ledger.area.building("row-workshop").facing == "N" and ledger.rules.area == ledger.area, "The ledger keeps what a program proposed and adopts the world it makes")
	var diff: Dictionary = AreaBuild.diff(before, ledger.area)
	_check((diff.changed as Array).size() == 2 and (diff.added as Array).is_empty() and (diff.removed as Array).is_empty() and diff.changed[0].from.facing == "E" and diff.changed[0].facing == "N", "The difference between the two worlds names what turned, and from what")
	_check(ledger.describe(ledger.edits[0]) == "Turned Hollow House", "The history reads it as a turn")
	_check(ledger.truncate_to(0) and ledger.edits.is_empty() and ledger.area.building("row-south-a").facing == "E", "Dropping the edits puts the houses back as they were")
	_check(not ledger.truncate_to(5) and not ledger.truncate_to(-1), "Dropping more edits than there are is refused")
	var rebuilt := BuildLedger.new(_source.document, _source.assets, _quests, _catalog, proposal.edits, "studio", AreaStore.ground_materials())
	_check(rebuilt.area.building("row-south-a").facing == "N" and rebuilt.problems.is_empty(), "A program's edits survive a save: they reload like any other edit")
	var added: Dictionary = AreaBuild.diff(ledger.area, rebuilt.area)
	_check((added.changed as Array).size() == 2, "...and the difference is the same from a reloaded ledger")


# ------------------------------------------------------------- interface
## The World tab lists what code can see; the Reference tab dims what is not learned yet and names the lesson.
func _interface() -> void:
	var ledger: BuildLedger = _ledger_for()
	var state: Dictionary = _state(ledger, ["cottage-row"])
	var snapshot: Dictionary = ledger.rules.snapshot(state)
	snapshot["build"] = CodeBuild.snapshot(ledger, state, _taught(ledger))
	var world := WorldView.new()
	root.add_child(world)
	await process_frame
	world.refresh(snapshot)
	var text: String = world._summary.text
	_check(text.contains("house  [code]row-south-a[/code]  Hollow House · faces east"), "The World tab lists a house with its id and facing")
	_check(text.contains("trees") and text.contains("Between places"), "...counts trees, and lists what is within reach between places")
	snapshot["build"] = CodeBuild.snapshot(ledger, state, [])
	world.refresh(snapshot)
	_check(not world._summary.text.contains("house  [code]") and world._summary.text.contains("once you reach the lesson \"Face the lane\""), "Before the lesson, the World tab says which lesson shows them")
	world.queue_free()
	var reference := ReferenceView.new()
	root.add_child(reference)
	await process_frame
	reference.show_unlocks([], {"read": "Face the lane", "turn": "Face the lane"})
	var dimmed: int = 0
	var tip: String = ""
	for section: Dictionary in reference._sections:
		for row: Control in section.rows:
			if str(row.get_meta("ability", "")) != "" and row.modulate.a < 0.9:
				dimmed += 1
				tip = row.tooltip_text
	_check(dimmed >= 10 and tip.contains("Face the lane"), "The Reference tab dims what is not unlocked, and its tooltip names the lesson (%d rows)" % dimmed)
	reference.show_unlocks(["read", "turn"], {})
	var all_clear: bool = true
	for section: Dictionary in reference._sections:
		for row: Control in section.rows:
			all_clear = all_clear and row.modulate.a > 0.99
	_check(all_clear, "...and nothing is dimmed once everything is learned")
	reference.queue_free()
	await process_frame


# ---------------------------------------------------------------- chapters
## The epilogue still belongs to the main arc: it appears when the fifth quest finishes even though a second chapter
## waits, it points to that chapter, the journal lists the chapter under its own heading, and the title counts five.
func _epilogue() -> void:
	var game: Game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(8)
	await game.start_new_game("kindle-hollow")
	await _frames(6)
	var session: GameSession = game.session
	# Before the main arc is done, the optional chapter is not in the journal or on the character screen.
	game.open_journal()
	await _frames(3)
	_check(not " ".join(_texts((game._modals[-1] as JournalPanel).body)).to_lower().contains("chapter two") and not (game._modals[-1] as JournalPanel)._buttons.has("face-the-lane"), "The second chapter is not in the journal before it has been reached")
	game._pop_all_modals()
	var people := CharacterScreen.new()
	var before_skills: Control = people._skills(session.area, [])
	var after_skills: Control = people._skills(session.area, MAIN_ARC)
	var before: int = before_skills.get_child_count()
	var after: int = after_skills.get_child_count()
	_check(before == 5 and after == 6 and Quests.listed(session.area, []).size() == 5 and Quests.listed(session.area, MAIN_ARC).size() == 6, "...nor among the ideas learned, which stay five until the chapter opens")
	before_skills.free()
	after_skills.free()
	people.free()
	session.completed.assign(MAIN_ARC.slice(0, 4))
	for id: String in session.state.lamps:
		session.state.lamps[id] = true
	session._after_change()
	_check(session.completed.has("kindle-the-hollow") and not session.completed.has("face-the-lane"), "Lighting every lamp finishes the fifth quest, and only that one")
	_check(session.current_quest().get("id") == "face-the-lane", "The second chapter's lesson is what the objective shows next")
	await create_timer(4.0).timeout
	var epilogue: EpilogueScreen = null
	for modal: Modal in game._modals:
		if modal is EpilogueScreen:
			epilogue = modal
	_check(epilogue != null, "The epilogue appears when the fifth quest finishes, even though a second chapter waits")
	if epilogue != null:
		var texts: PackedStringArray = _texts(epilogue.body)
		_check(" ".join(texts).contains("Face the lane") and " ".join(texts).contains("optional"), "...and tells the player a second chapter has opened in the journal")
		var ticks: int = 0
		for quest: Dictionary in Quests.main(session.area):
			if texts.has(str(quest.concept)):
				ticks += 1
		_check(ticks == 5 and not texts.has(str(session.area.quest("face-the-lane").concept)), "...listing what the five lessons taught, and not the chapter that has not been played")
	game._pop_all_modals()
	game.open_journal()
	await _frames(3)
	var journal: JournalPanel = game._modals[-1] as JournalPanel
	_check(journal != null and " ".join(_texts(journal.body)).to_lower().contains("chapter two"), "The journal lists the second chapter under its own heading")
	_check(journal._buttons.has("face-the-lane") and not (journal._buttons["face-the-lane"] as Button).disabled, "...and the lesson can be opened")
	game._pop_all_modals()
	game.queue_free()
	await process_frame


func _texts(node: Node) -> PackedStringArray:
	var found: PackedStringArray = []
	if node is Label:
		found.append((node as Label).text)
	for child: Node in node.get_children():
		found.append_array(_texts(child))
	return found


# ------------------------------------------------------------- end to end
## Real Python/WASI through the real session: snapshot, run, preview, apply, undo, and the save.
func _end_to_end() -> void:
	if not Sandbox.is_available(SandboxJob.PYTHON):
		_check(false, "Python/WASI runtime is available")
		return
	var ledger: BuildLedger = _ledger_for()
	var state: Dictionary = _state(ledger, ["cottage-row"])
	# The harness against the snapshot, with the real runtime: what the program records is what the host accepts.
	var snapshot: Dictionary = ledger.rules.snapshot(state)
	snapshot["build"] = CodeBuild.snapshot(ledger, state, _taught(ledger))
	var answer: Dictionary = Program.run(FACE_THE_ROW, snapshot)
	_check(answer.ok, "The program runs: %s" % str(answer.get("reason")))
	var commands: Array = answer.commands
	_check(commands.size() == 2 and commands.all(func(command: Dictionary) -> bool: return command.op == "rotate" and command.facing == "N"), "It records one rotate for each of the two southern houses: %s" % str(commands))
	var proposal: Dictionary = CodeBuild.propose(ledger, state, commands, _taught(ledger))
	_check(proposal.ok, "...and the host accepts them: %s" % str(proposal.get("reason")))
	var locked_snapshot: Dictionary = ledger.rules.snapshot(state)
	locked_snapshot["build"] = CodeBuild.snapshot(ledger, state, [])
	var denied: Dictionary = Program.run(FACE_THE_ROW, locked_snapshot)
	_check(not denied.ok and str(denied.get("stdout", "") + str(denied.get("error", {}))).contains("Face the lane"), "Before the lesson, the same program is stopped and told which lesson to finish")
	var bad_word: Dictionary = Program.run("def program(world):\n    world.house(\"row-south-a\").face(\"up\")\n", snapshot)
	_check(not bad_word.ok and str(bad_word.get("error", {})).contains("north"), "A facing that is not a direction is explained in words")
	var mirrored: Dictionary = Program.run("def program(world):\n    h = world.house(\"row-south-a\")\n    h.face(\"north\")\n    print(h.facing)\n    h.face(\"north\")\n    h.face(\"south\")\n", snapshot)
	_check(mirrored.ok and str(mirrored.stdout).contains("north") and (mirrored.commands as Array).size() == 2, "The house shows what you just asked for, and an unchanged facing records nothing")
	var tree_look: Dictionary = Program.run("def program(world):\n    print(len(world.trees) > 0, world.tree(%s, %s).kind)\n" % [snapshot.build.trees[0].at[0], snapshot.build.trees[0].at[1]], snapshot) if not (snapshot.build.trees as Array).is_empty() else {"ok": true, "stdout": "True"}
	_check(tree_look.ok, "A tree can be looked up by its place: %s" % str(tree_look.get("reason", "")))
	# Through the session.
	var game: Game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(8)
	await game.start_new_game("kindle-hollow")
	await _frames(6)
	game.ledger = ledger
	game.area = ledger.area
	var session: GameSession = game.session
	_check(session.ledger == ledger, "The game hands its ledger to the session")
	session.replace_area(ledger.area, ledger.rules)
	game.view.sync_edits(ledger.area, false)
	session.state.zones_seen.append("cottage-row")
	session.completed.assign(MAIN_ARC)
	session.set_source(FACE_THE_ROW)
	var built: Array[String] = []
	session.build_changed.connect(func(label: String) -> void: built.append(label))
	var ran: bool = await session.run_preview()
	_check(ran and session.has_preview(), "Run previews the program: %s" % str(session.last_run.get("reason", "")))
	_check(ledger.edits.is_empty() and ledger.area.building("row-south-a").facing == "E", "...and the village is unchanged until Apply")
	_check(game.view._ghost.get_child_count() >= 2, "...with a ghost for each house that would turn (%d)" % game.view._ghost.get_child_count())
	var modals: int = game._modals.size()
	_check(session.apply_preview(), "Apply commits that same proposal")
	await _frames(3)
	_check(session.completed.has("face-the-lane") and game._modals.size() == modals, "The program solves the lesson, and finishing the optional chapter shows no epilogue")
	_check(ledger.edits.size() == 2 and ledger.area.building("row-south-a").facing == "N" and ledger.area.building("row-workshop").facing == "N" and session.area == ledger.area and game.area == ledger.area, "...the ledger, the session and the game all play by the new village")
	_check(built.size() == 1 and game.view.building_node("row-south-a").rotation_degrees.y == 180.0, "...the game is told, and the house is drawn facing north")
	_check(ledger.edits[0].by == "code" and ledger.edits[1].by == "code", "...and the edits are tagged as the program's")
	game.save_now()
	_check((SaveStore.read().get("edits", []) as Array).size() == 2, "The program's building is saved with the journey")
	# Undo.
	_check(session.can_undo() and session.undo_apply(), "Undo takes the program's building away")
	await _frames(3)
	_check(session.completed.has("face-the-lane"), "...but a finished lesson stays finished")
	_check(ledger.edits.is_empty() and ledger.area.building("row-south-a").facing == "E" and session.area == ledger.area and game.view.building_node("row-south-a").rotation_degrees.y == 90.0, "...the houses face as they did before")
	# Undo refuses when things were built by hand since.
	session.set_source(FACE_THE_ROW)
	await session.run_preview()
	session.apply_preview()
	await _frames(2)
	var tree: Dictionary = ledger.place("tree-oak", _free_spot(ledger, session.state), "S", session.state)
	_check(tree.ok and ledger.edits.size() == 3, "A tree is then planted by hand")
	_check(not session.undo_apply() and ledger.edits.size() == 3, "Undo of the program is refused rather than reordering history")
	_check(ledger.undo(session.state).ok and session.undo_apply() and ledger.edits.is_empty(), "...and works again once the hand-built tree is undone")
	# A refused batch rejects the whole run and changes nothing.
	session.state.zones_seen.append("mill-yard")
	session.set_source("def program(world):\n    world.house(\"row-south-a\").face(\"north\")\n    world.house(\"mill\").face(\"north\")\n")
	var reports: Array[Dictionary] = []
	session.run_finished.connect(func(result: Dictionary) -> void: reports.append(result))
	var refused: bool = await session.run_preview()
	var report: Dictionary = reports[-1] if not reports.is_empty() else {}
	_check(not refused and not session.has_preview() and ledger.edits.is_empty(), "A program that asks for something refused is rejected whole")
	_check(not report.get("ok", true) and report.get("rejected", false) and str(report.get("reason", "")).begins_with("Command 2:") and str(report.reason).contains("part of the lessons"), "...with the command and the reason in plain words: %s" % str(report.get("reason", "")))
	game._pop_all_modals()
	game.queue_free()
	await process_frame


func _free_spot(ledger: BuildLedger, state: Dictionary) -> Vector2:
	for y: int in range(30, 70):
		for x: int in range(20, 80):
			if ledger.check_item("tree-oak", Vector2(x, y), "S", state).ok:
				return Vector2(x, y)
	return Vector2(-1, -1)


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)


func _finish() -> void:
	if _failures.is_empty():
		print("Building by code: %d checks passed (abilities, reach, commands, atomic batches, ledger, real Python through the session)." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		quit(1)
