class_name CodeBuild
extends RefCounted
## Pure rules for what a player's program may do to the valley's houses, trees and doodads. The Python harness
## only records commands; every one is checked here, against the same AreaBuild rules the builder uses, and a
## batch is atomic: one refusal rejects the lot.
##
## A command is a plain dictionary with a strict set of keys:
##   {op: "rotate", entity_id: "home", facing: "N"}      turn a house or doodad on the spot
## and is refused unless
##   - the player's code has earned the ability (a completed quest `unlocks` it),
##   - the thing is within reach (inside a place the player has visited, or within REACH cells of the player),
##   - the builder's own rules allow it (nothing locked, nothing in the way, nothing cut off),
##   - the player is outdoors and the batch is within the budget.
##
## The cheap rules run for every command against the world as the earlier commands left it. The slow
## cut-off check (can the player still reach every lamp, door and place?) runs once, on the whole batch.

## How far from the player (in cells) code can reach beyond the places already visited.
const REACH: float = 12.0
const MAX_BUILD_COMMANDS: int = 16
const BUILD_OPS: Array[String] = ["rotate"]
const FACING_LETTERS: Array[String] = ["S", "E", "N", "W"]
const FACING_WORDS: Dictionary = {"S": "south", "E": "east", "N": "north", "W": "west"}


static func is_build_command(command: Variant) -> bool:
	return command is Dictionary and BUILD_OPS.has(str((command as Dictionary).get("op", "")))


## May code see or touch something standing at `at`? Inside a visited place, or near the player.
static func in_reach(area: AreaDef, state: Dictionary, at: Vector2) -> bool:
	var zone_id: String = area.zone_at(Vector2i(roundi(at.x), roundi(at.y)))
	if zone_id != "" and (state.get("zones_seen", []) as Array).has(zone_id):
		return true
	return Vector2(float(state.player[0]), float(state.player[1])).distance_to(at) <= REACH


# ---------------------------------------------------------------- snapshot
## The lesson that teaches each ability the player's code does not have yet (ability -> quest title), so a refusal
## or a dimmed Reference entry can say where to learn it. An ability no lesson teaches is left out.
static func lessons(area: AreaDef, abilities: Array) -> Dictionary:
	var result: Dictionary = {}
	for ability: String in AreaDef.CAPABILITIES:
		if not abilities.has(ability):
			var teacher: Dictionary = Quests.unlocking(area, ability)
			if not teacher.is_empty():
				result[ability] = str(teacher.title)
	return result


## What the Python harness may know about the valley's structures, as plain data. `abilities` is what the player's
## code may do (see GameSession.abilities). Nothing is listed until `read` is earned, and only what is within reach.
static func snapshot(ledger: BuildLedger, state: Dictionary, abilities: Array[String]) -> Dictionary:
	var area: AreaDef = ledger.area
	var result: Dictionary = {"abilities": abilities, "lessons": lessons(area, abilities), "houses": [], "trees": [], "doodads": []}
	if not abilities.has("read") or not area.interior.is_empty():
		return result
	for house: Dictionary in area.buildings:
		if in_reach(area, state, house.at):
			(result.houses as Array).append(_thing(ledger, house))
	for prop: Dictionary in area.props:
		if in_reach(area, state, prop.at):
			var entry: Dictionary = _thing(ledger, prop)
			entry["solid"] = bool(prop.solid)
			(result.doodads as Array).append(entry)
	for tree: Dictionary in area.trees:
		if in_reach(area, state, tree.at):
			(result.trees as Array).append({"at": [tree.at.x, tree.at.y], "cell": [roundi(tree.at.x), roundi(tree.at.y), 0], "size": float(tree.size),
				"kind": _tree_kind(ledger, tree), "zone": area.zone_at(Vector2i(roundi(tree.at.x), roundi(tree.at.y)))})
	return result


static func _thing(ledger: BuildLedger, thing: Dictionary) -> Dictionary:
	var at: Vector2 = thing.at
	var item: Dictionary = _item_for_asset(ledger, str(thing.asset))
	return {"id": str(thing.id), "kind": str(item.get("id", thing.asset)), "name": ledger.title_for_asset(str(thing.asset)),
		"at": [at.x, at.y], "cell": [roundi(at.x), roundi(at.y), 0], "facing": FACING_WORDS[str(thing.facing)],
		"zone": ledger.area.zone_at(Vector2i(roundi(at.x), roundi(at.y))), "locked": bool(thing.get("locked", false))}


static func _item_for_asset(ledger: BuildLedger, asset: String) -> Dictionary:
	for entry: Variant in ledger.build_catalog.get("items", []):
		if entry is Dictionary and (entry as Dictionary).get("asset") == asset:
			return entry
	return {}


## A tree's kind: its catalog item if it has a model, else the procedural oak nearest in size, else "tree".
static func _tree_kind(ledger: BuildLedger, tree: Dictionary) -> String:
	if str(tree.get("asset", "")) != "":
		return str(_item_for_asset(ledger, str(tree.asset)).get("id", tree.asset))
	for entry: Variant in ledger.build_catalog.get("items", []):
		if entry is Dictionary and entry.get("kind") == "tree" and not entry.has("asset") and absf(float(entry.get("size", 1.0)) - float(tree.size)) < 0.01:
			return str(entry.id)
	return "tree"


# ---------------------------------------------------------------- proposing
## Runs every build command in `commands` (the others are left to LabWorld) against a copy of the world. Returns
## {ok, reason, edits, area, rules, changes}: on success the edits to append to the ledger, the world they make,
## and a plain line for each; on failure nothing changes. `abilities` is what the player's code may do.
static func propose(ledger: BuildLedger, state: Dictionary, commands: Array, abilities: Array[String]) -> Dictionary:
	var count: int = 0
	for command: Variant in commands:
		if is_build_command(command):
			count += 1
	if count == 0:
		return {"ok": true, "reason": "", "edits": [], "area": ledger.area, "rules": ledger.rules, "changes": []}
	if count > MAX_BUILD_COMMANDS:
		return _reject("Use at most %d building commands in one run (you used %d)." % [MAX_BUILD_COMMANDS, count])
	if not ledger.area.interior.is_empty():
		return _reject("Go outside first: your code changes the village from the outside, and each home keeps its own interior.")
	var added: Array[Dictionary] = []
	var changes: Array[String] = []
	var touched: Array[String] = []
	var area: AreaDef = ledger.area
	var rules: LabWorld = ledger.rules
	for index: int in range(commands.size()):
		if not is_build_command(commands[index]):
			continue
		var step: Dictionary = _step(ledger, state, abilities, area, rules, commands[index])
		if not step.ok:
			return _reject("Command %d: %s" % [index + 1, step.reason])
		if step.edit.is_empty():
			continue
		added.append(step.edit)
		changes.append(str(step.label))
		if step.edit.has("id") and not touched.has(str(step.edit.id)):
			touched.append(str(step.edit.id))
		var next: Dictionary = _world_with(ledger, added)
		if not next.ok:
			return _reject("Command %d: %s" % [index + 1, next.reason])
		area = next.area
		rules = next.rules
	if added.is_empty():
		return {"ok": true, "reason": "", "edits": [], "area": ledger.area, "rules": ledger.rules, "changes": []}
	var player := Vector2i(int(state.player[0]), int(state.player[1]))
	var problem: String = AreaBuild.reach_problem({"area": ledger.area, "rules": ledger.rules}, {"area": area, "rules": rules}, player, touched)
	if problem != "":
		return _reject(problem)
	return {"ok": true, "reason": "", "edits": added, "area": area, "rules": rules, "changes": changes}


## One command against the world so far. {ok, reason, edit ({} when it changes nothing), label}.
static func _step(ledger: BuildLedger, state: Dictionary, abilities: Array[String], area: AreaDef, rules: LabWorld, command: Dictionary) -> Dictionary:
	match str(command.op):
		"rotate":
			return _rotate(ledger, state, abilities, area, rules, command)
	return _refuse("Unknown building command.")


static func _rotate(ledger: BuildLedger, state: Dictionary, abilities: Array[String], area: AreaDef, rules: LabWorld, command: Dictionary) -> Dictionary:
	if not _keys_match(command, ["op", "entity_id", "facing"]):
		return _refuse("rotate needs only op, entity_id and facing.")
	if not command.entity_id is String or not command.facing is String or not FACING_LETTERS.has(command.facing):
		return _refuse("Face a house or doodad by its id and one of north, east, south or west.")
	if not abilities.has("turn"):
		return _refuse(_locked(area, "turn", "turn houses and doodads"))
	var id: String = command.entity_id
	var kind: String = "building"
	var thing: Dictionary = area.building(id)
	if thing.is_empty():
		kind = "prop"
		thing = area.prop(id)
	if thing.is_empty():
		return _refuse("There is no house or doodad called '%s'. Read world.houses and world.doodads for the real ids." % id)
	if not in_reach(area, state, thing.at):
		return _refuse("'%s' is out of reach. Visit its place or stand within %d cells of it first." % [id, int(REACH)])
	var removable: Dictionary = AreaBuild.check_remove(area, kind, id)
	if not removable.ok:
		return _refuse("'%s' is part of the lessons and cannot be turned." % id)
	var title: String = ledger.title_for_asset(str(thing.asset))
	if str(thing.facing) == command.facing:
		return {"ok": true, "reason": "", "edit": {}, "label": ""}
	var context: Dictionary = {"area": area, "rules": rules, "state": state, "assets": ledger.assets}
	var checked: Dictionary
	if kind == "building":
		checked = AreaBuild.check_building(context, str(thing.asset), thing.at, command.facing, float(thing.scale), id)
	else:
		checked = AreaBuild.check_prop(context, str(thing.asset), thing.at, command.facing, float(thing.scale), id)
	if not checked.ok:
		return _refuse("%s cannot face %s: %s" % [title, FACING_WORDS[command.facing], str(checked.reason).to_lower()])
	var at: Vector2 = thing.at
	return {"ok": true, "reason": "",
		"edit": {"op": "move", "kind": kind, "id": id, "at": [at.x, at.y], "facing": command.facing, "turned": true, "by": "code"},
		"label": "%s (%s) turned to face %s" % [title, id, FACING_WORDS[command.facing]]}


## The world with these new edits appended to the ledger's: parsed and rebuilt, without the slow cut-off check.
static func _world_with(ledger: BuildLedger, added: Array[Dictionary]) -> Dictionary:
	var longer: Array = ledger.edits.duplicate()
	longer.append_array(added)
	var applied: Dictionary = AreaBuild.apply(ledger.base_document, longer, ledger.paint_materials)
	if not (applied.skipped as Array).is_empty():
		return {"ok": false, "reason": "That does not fit the valley."}
	var parsed: Dictionary = AreaDef.parse(applied.document, ledger.assets, ledger.quest_document, ledger.paint_materials)
	if not parsed.ok:
		return {"ok": false, "reason": "That does not fit the valley: %s" % str(parsed.errors)}
	return {"ok": true, "reason": "", "area": parsed.area, "rules": LabWorld.new(parsed.area)}


static func _locked(area: AreaDef, ability: String, what: String) -> String:
	var teacher: Dictionary = Quests.unlocking(area, ability)
	if teacher.is_empty():
		return "Your code cannot %s in this valley." % what
	return "Your code cannot %s yet. Reach the lesson \"%s\" to learn how." % [what, str(teacher.title)]


static func _refuse(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "edit": {}, "label": ""}


static func _reject(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "edits": [], "changes": []}


static func _keys_match(value: Dictionary, expected: Array[String]) -> bool:
	if value.size() != expected.size():
		return false
	for key: String in expected:
		if not value.has(key):
			return false
	return true
