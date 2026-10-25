class_name BuildLedger
extends RefCounted
## The player's edits over one area document, in order, with undo and redo. The document stays the source of
## truth; the ledger is a layer over it that saves with the player's game. Every change goes through the rules
## in AreaBuild and is kept only if the new world is still whole (nothing the player needs is cut off).
##
## Pure data and rules: it never creates nodes and never touches files. The area and rules it exposes are the
## ones for the document with all current edits applied.

var base_document: Dictionary
var assets: Dictionary
var quest_document: Variant
var build_catalog: Dictionary
var policy_id: String = "studio"
var edits: Array[Dictionary] = []
var area: AreaDef
var rules: LabWorld
## Saved edits that no longer fit the document (it changed since the save), for a quiet note to the player.
var problems: Array[String] = []
var _redo: Array[Dictionary] = []
var paint_materials: Array = GroundPaint.DEFAULT_PALETTE.duplicate()
## Room instances use stable building ids. Removing/undoing a house must not give its room to a new house.
var _building_serial: int = 0
## Props get fresh ids too, so an undone or removed prop's id is never given to a new one.
var _prop_serial: int = 0
## Why each cell's ground must stay as it is (AreaBuild.land_blockers), for `_blockers_area`; worked out again
## when the world changes, since a drag asks about every cell it crosses.
var _blockers: Dictionary = {}
var _blockers_area: AreaDef


func _init(document: Dictionary, world_assets: Dictionary, quests: Variant, catalog: Dictionary, saved: Array = [], policy_name: String = "studio", ground_materials: Array = GroundPaint.DEFAULT_PALETTE) -> void:
	base_document = document
	assets = world_assets
	quest_document = quests
	build_catalog = catalog
	policy_id = policy_name
	paint_materials = ground_materials.duplicate()
	_building_serial = AreaBuild.next_building_id(base_document).substr(6).to_int() - 1
	_prop_serial = AreaBuild.next_prop_id(base_document).substr(5).to_int() - 1
	for edit: Variant in saved:
		if edit is Dictionary and edit.get("kind") == "building":
			var id: String = str(edit.get("id", ""))
			if id.begins_with("build-") and id.substr(6).is_valid_int():
				_building_serial = maxi(_building_serial, id.substr(6).to_int())
		elif edit is Dictionary and edit.get("kind") == "prop":
			var prop_id: String = str(edit.get("id", ""))
			if prop_id.begins_with("prop-") and prop_id.substr(5).is_valid_int():
				_prop_serial = maxi(_prop_serial, prop_id.substr(5).to_int())
	var applied: Dictionary = AreaBuild.apply(base_document, saved, paint_materials)
	for edit: Variant in applied.skipped:
		problems.append("An old edit no longer fits the valley: %s" % JSON.stringify(edit))
	var parsed: Dictionary = AreaDef.parse(applied.document, assets, quest_document, paint_materials)
	if parsed.ok:
		for edit: Variant in saved:
			if edit is Dictionary and not (applied.skipped as Array).has(edit):
				edits.append(edit)
	else:
		problems.append("Saved edits were set aside: %s" % str(parsed.errors))
		parsed = AreaDef.parse(base_document, assets, quest_document, paint_materials)
	area = parsed.area
	rules = LabWorld.new(area)


func context(state: Dictionary) -> Dictionary:
	return {"area": area, "rules": rules, "state": state, "assets": assets}


func can_undo() -> bool:
	return not edits.is_empty()


func can_redo() -> bool:
	return not _redo.is_empty()


## What the player has placed of this kind that still stands, and the policy's limit (-1 for none).
func made(kind: String) -> int:
	return AreaBuild.player_made(edits, kind)


func limit(kind: String) -> int:
	return AreaBuild.limit_for(build_catalog, policy_id, kind)


## Edits that added something of this kind, whether or not it still stands.
func added(kind: String) -> int:
	var count: int = 0
	for edit: Dictionary in edits:
		if edit.get("kind") == kind and edit.op == "add":
			count += 1
	return count


# -------------------------------------------------------------- checking
## May this item stand here? Cheap, for a moving ghost. {ok, reason, rect, door} for a building, {ok, reason, rect}
## for a prop and {ok, reason} for a tree.
func check_item(item_id: String, at: Vector2, facing: String, state: Dictionary) -> Dictionary:
	var entry: Dictionary = AreaBuild.item(build_catalog, item_id)
	if entry.is_empty():
		return {"ok": false, "reason": "That is not on offer."}
	if not AreaBuild.allowed_items(build_catalog, policy_id).has(entry):
		return {"ok": false, "reason": "That is not open to you yet."}
	var limit: String = AreaBuild.limit_reason(build_catalog, policy_id, edits, str(entry.kind))
	if limit != "":
		return {"ok": false, "reason": limit}
	if entry.kind == "building":
		return AreaBuild.check_building(context(state), str(entry.asset), at, facing, 1.0)
	if entry.kind == "prop":
		return AreaBuild.check_prop(context(state), str(entry.asset), at, facing, 1.0)
	return AreaBuild.check_tree(context(state), at, float(entry.get("size", 1.0)), "", str(entry.get("asset", "")))


func check_move_building(id: String, at: Vector2, facing: String, state: Dictionary) -> Dictionary:
	var building: Dictionary = area.building(id)
	var removable: Dictionary = AreaBuild.check_remove(area, "building", id)
	if not removable.ok:
		return removable
	return AreaBuild.check_building(context(state), str(building.asset), at, facing, float(building.scale), id)


func check_move_prop(id: String, at: Vector2, facing: String, state: Dictionary) -> Dictionary:
	var prop: Dictionary = area.prop(id)
	var removable: Dictionary = AreaBuild.check_remove(area, "prop", id)
	if not removable.ok:
		return removable
	return AreaBuild.check_prop(context(state), str(prop.asset), at, facing, float(prop.scale), id)


func check_move_tree(from: Vector2, at: Vector2, state: Dictionary) -> Dictionary:
	var size: float = 1.0
	var asset: String = ""
	for tree: Dictionary in area.trees:
		if AreaBuild.tree_key(tree.at) == AreaBuild.tree_key(from):
			size = float(tree.size)
			asset = str(tree.get("asset", ""))
	return AreaBuild.check_tree(context(state), at, size, AreaBuild.tree_key(from), asset)


# -------------------------------------------------------------- changing
## Places an item. {ok, reason, edit}; on success the ledger and its area have changed. With `commit` false it only
## answers (running the full cut-off check, which takes about a tenth of a second) and changes nothing.
func place(item_id: String, at: Vector2, facing: String, state: Dictionary, commit: bool = true) -> Dictionary:
	var checked: Dictionary = check_item(item_id, at, facing, state)
	if not checked.ok:
		return checked
	var entry: Dictionary = AreaBuild.item(build_catalog, item_id)
	var edit: Dictionary
	if entry.kind == "building":
		edit = {"op": "add", "kind": "building", "id": "build-%d" % (_building_serial + 1), "item": item_id,
			"asset": str(entry.asset), "at": [at.x, at.y], "facing": facing, "scale": 1.0}
	elif entry.kind == "prop":
		edit = {"op": "add", "kind": "prop", "id": "prop-%d" % (_prop_serial + 1), "item": item_id,
			"asset": str(entry.asset), "at": [at.x, at.y], "facing": facing, "scale": 1.0}
	else:
		edit = {"op": "add", "kind": "tree", "item": item_id, "at": [at.x, at.y], "size": float(entry.get("size", 1.0))}
		if entry.has("asset"):
			edit["asset"] = entry.asset
	var result: Dictionary = _commit(edit, state, str(edit.get("id", "")), commit)
	if result.ok and commit and entry.kind == "building":
		_building_serial += 1
	if result.ok and commit and entry.kind == "prop":
		_prop_serial += 1
	return result


func move_building(id: String, at: Vector2, facing: String, state: Dictionary, commit: bool = true) -> Dictionary:
	var checked: Dictionary = check_move_building(id, at, facing, state)
	if not checked.ok:
		return checked
	return _commit({"op": "move", "kind": "building", "id": id, "at": [at.x, at.y], "facing": facing}, state, id, commit)


func move_prop(id: String, at: Vector2, facing: String, state: Dictionary, commit: bool = true) -> Dictionary:
	var checked: Dictionary = check_move_prop(id, at, facing, state)
	if not checked.ok:
		return checked
	return _commit({"op": "move", "kind": "prop", "id": id, "at": [at.x, at.y], "facing": facing}, state, id, commit)


## Turns a standing building on the spot: a move to where it already is, with a new facing. The same rules
## apply as to any move, so a house that would then touch its neighbour is refused with the reason.
func turn_building(id: String, facing: String, state: Dictionary, commit: bool = true) -> Dictionary:
	var at: Vector2 = area.building(id).get("at", Vector2.ZERO)
	var checked: Dictionary = check_move_building(id, at, facing, state)
	if not checked.ok:
		return checked
	return _commit({"op": "move", "kind": "building", "id": id, "at": [at.x, at.y], "facing": facing, "turned": true}, state, id, commit)


func turn_prop(id: String, facing: String, state: Dictionary, commit: bool = true) -> Dictionary:
	var at: Vector2 = area.prop(id).get("at", Vector2.ZERO)
	var checked: Dictionary = check_move_prop(id, at, facing, state)
	if not checked.ok:
		return checked
	return _commit({"op": "move", "kind": "prop", "id": id, "at": [at.x, at.y], "facing": facing, "turned": true}, state, id, commit)


## Keeps the edits a program proposed (CodeBuild has already checked them as a batch) and adopts the world they make.
func commit_code(new_edits: Array, new_area: AreaDef, new_rules: LabWorld) -> void:
	for edit: Variant in new_edits:
		edits.append(edit)
	_redo.clear()
	_adopt({"area": new_area, "rules": new_rules})


## Drops the edits after the first `count` (undoing what a program built) and rebuilds the world without them.
## False if that world cannot be built, in which case nothing changes.
func truncate_to(count: int) -> bool:
	if count < 0 or count > edits.size():
		return false
	var shorter: Array = edits.slice(0, count)
	var applied: Dictionary = AreaBuild.apply(base_document, shorter, paint_materials)
	var parsed: Dictionary = AreaDef.parse(applied.document, assets, quest_document, paint_materials)
	if not parsed.ok or not (applied.skipped as Array).is_empty():
		return false
	edits.assign(shorter)
	_redo.clear()
	_adopt({"area": parsed.area, "rules": LabWorld.new(parsed.area)})
	return true


func move_tree(from: Vector2, at: Vector2, state: Dictionary, commit: bool = true) -> Dictionary:
	var checked: Dictionary = check_move_tree(from, at, state)
	if not checked.ok:
		return checked
	return _commit({"op": "move", "kind": "tree", "from": [from.x, from.y], "at": [at.x, at.y]}, state, "", commit)


func remove_building(id: String, state: Dictionary) -> Dictionary:
	var checked: Dictionary = AreaBuild.check_remove(area, "building", id)
	if not checked.ok:
		return checked
	return _commit({"op": "remove", "kind": "building", "id": id}, state, id)


## The edit names the asset so the history can say what was taken away after it is gone.
func remove_prop(id: String, state: Dictionary) -> Dictionary:
	var checked: Dictionary = AreaBuild.check_remove(area, "prop", id)
	if not checked.ok:
		return checked
	return _commit({"op": "remove", "kind": "prop", "id": id, "asset": str(area.prop(id).asset)}, state, id)


func remove_tree(at: Vector2, state: Dictionary) -> Dictionary:
	var checked: Dictionary = AreaBuild.check_remove(area, "tree", AreaBuild.tree_key(at))
	if not checked.ok:
		return checked
	return _commit({"op": "remove", "kind": "tree", "at": [at.x, at.y]}, state, "")


func paint(material: String, cells: Array, state: Dictionary) -> Dictionary:
	if not area.ground.is_empty():
		return {"ok": false, "reason": "This area's ground is an authored model. Paint generated ground instead."}
	if material != "" and not paint_materials.has(material):
		return {"ok": false, "reason": "Choose a ground material from the palette."}
	var unique: Dictionary = {}
	var kept: Array = []
	for cell: Variant in cells:
		if not cell is Array or cell.size() != 2 or not AreaDef._whole(cell[0]) or not AreaDef._whole(cell[1]):
			return {"ok": false, "reason": "A paint stroke needs whole sub-tile coordinates."}
		var sub := Vector2i(int(cell[0]), int(cell[1]))
		if sub.x < 0 or sub.y < 0 or sub.x >= area.width * 2 or sub.y >= area.height * 2:
			return {"ok": false, "reason": "Keep paint inside the valley."}
		if GroundPaint.is_ground(area, sub) and not unique.has(sub):
			unique[sub] = true
			kept.append([sub.x, sub.y])
	if kept.is_empty():
		return {"ok": false, "reason": "Paint only grass, paths or cobble."}
	return _commit({"op": "paint", "material": material, "cells": kept}, state, "")


# --------------------------------------------------------------- terrain
func land_blockers() -> Dictionary:
	if _blockers_area != area:
		_blockers = AreaBuild.land_blockers(area)
		_blockers_area = area
	return _blockers


## "" if this land tool may change this cell (raise and lower toward `level`), else why not. Cheap.
func land_reason(tool: String, cell: Vector2i, level: int, state: Dictionary) -> String:
	if not area.ground.is_empty() or not area.interior.is_empty():
		return "This ground is an authored model. Shape the valley's generated land instead."
	return AreaBuild.land_reason(area, land_blockers(), state, tool, cell, level)


## Raises or lowers cells to `level`, digs water into them or fills it in (AreaBuild.LAND_TOOLS): one undo step for a
## whole drag. Cells that cannot change are left out; it is refused only when none can, or the valley would not stay whole.
func shape(tool: String, level: int, cells: Array, state: Dictionary) -> Dictionary:
	if not tool in AreaBuild.LAND_TOOLS:
		return {"ok": false, "reason": "Choose a land tool."}
	var kept: Array = []
	var seen: Dictionary = {}
	var first: String = ""
	for raw: Variant in cells:
		var cell: Vector2i
		if raw is Vector2i:
			cell = raw
		elif raw is Array and (raw as Array).size() == 2 and AreaDef._whole(raw[0]) and AreaDef._whole(raw[1]):
			cell = Vector2i(int(raw[0]), int(raw[1]))
		else:
			return {"ok": false, "reason": "A land stroke needs whole cell coordinates."}
		if seen.has(cell):
			continue
		seen[cell] = true
		var reason: String = land_reason(tool, cell, level, state)
		if reason == "":
			kept.append([cell.x, cell.y])
		elif first == "":
			first = reason
	if kept.is_empty():
		return {"ok": false, "reason": first if first != "" else "Nothing there can change."}
	var edit: Dictionary = {"op": "level", "tool": tool, "level": level, "cells": kept} if tool in ["raise", "lower"] else {"op": tool, "cells": kept}
	return _commit(edit, state, "")


func check_stairs(at: Vector2i, up: String, state: Dictionary) -> Dictionary:
	if not area.ground.is_empty() or not area.interior.is_empty():
		return {"ok": false, "reason": "This ground is an authored model. Build stairs in the valley's generated land."}
	return AreaBuild.check_stairs(context(state), at, up)


## Builds a flight of stairs on `at` climbing toward `up`. With `commit` false it only answers (with the cut-off check).
func place_stairs(at: Vector2i, up: String, state: Dictionary, commit: bool = true) -> Dictionary:
	var checked: Dictionary = check_stairs(at, up, state)
	if not checked.ok:
		return checked
	return _commit({"op": "add", "kind": "stairs", "at": [at.x, at.y], "up": up}, state, "", commit)


## Takes a flight of stairs away, unless that would leave someone stranded up a cliff. The edit keeps which way it
## climbed, for the history.
func remove_stairs(at: Vector2i, state: Dictionary) -> Dictionary:
	var checked: Dictionary = AreaBuild.check_remove(area, "stairs", at)
	if not checked.ok:
		return checked
	return _commit({"op": "remove", "kind": "stairs", "at": [at.x, at.y], "up": str(area.stair_at(at).up)}, state, "")


func finish(kind: String, id: String, slot: String, material: String, state: Dictionary) -> Dictionary:
	var checked: Dictionary = SurfaceFinishes.check(area, assets, kind, id, slot, material)
	if not checked.ok:
		return checked
	return _commit({"op":"finish", "kind":kind, "id":id, "slot":slot, "material":material}, state, "")


func undo(state: Dictionary) -> Dictionary:
	if edits.is_empty():
		return {"ok": false, "reason": "Nothing to undo."}
	var last: Dictionary = edits[-1]
	var result: Dictionary = _swap_to(edits.slice(0, edits.size() - 1), state, str(last.get("id", "")), last.get("op") in ["paint", "finish"])
	if result.ok:
		_redo.append(edits.pop_back())
		_adopt(result)
	return result


func redo(state: Dictionary) -> Dictionary:
	if _redo.is_empty():
		return {"ok": false, "reason": "Nothing to redo."}
	var next: Dictionary = _redo[-1]
	var longer: Array = edits.duplicate()
	longer.append(next)
	var result: Dictionary = _swap_to(longer, state, str(next.get("id", "")), next.get("op") in ["paint", "finish"])
	if result.ok:
		_redo.pop_back()
		edits.append(next)
		_adopt(result)
	return result


## A short label for the history and for toasts: "Placed Hollow House", "Removed a tree".
func describe(edit: Dictionary) -> String:
	if edit.get("op") == "finish":
		return "%s %s" % ["Restored" if edit.material == "" else "Finished", str(SurfaceFinishes.TITLES.get(edit.slot, edit.slot)).to_lower()]
	if edit.get("op") == "paint":
		return "Painted %s" % str(edit.material).replace("_", " ") if edit.material != "" else "Restored ground"
	match str(edit.get("op")):
		"level":
			return "Raised the land" if edit.get("tool") == "raise" else "Lowered the land"
		"water":
			return "Dug water"
		"land":
			return "Filled in water"
	if edit.get("kind") == "stairs":
		return "Built stairs" if edit.get("op") == "add" else "Removed stairs"
	var verb: String = {"add": "Placed", "move": "Turned" if edit.get("turned", false) else "Moved", "remove": "Removed"}.get(str(edit.get("op")), "Changed")
	if edit.kind == "tree":
		return "%s a tree" % verb
	var asset: String = str(edit.get("asset", ""))
	if asset == "":
		var id: String = str(edit.get("id", ""))
		asset = str((area.prop(id) if edit.kind == "prop" else area.building(id)).get("asset", ""))
	return "%s %s" % [verb, title_for_asset(asset)]


func title_for_asset(asset: String) -> String:
	for entry: Variant in build_catalog.get("items", []):
		if entry is Dictionary and (entry as Dictionary).get("asset") == asset:
			return str((entry as Dictionary).get("title", asset))
	return asset.replace("-", " ").capitalize()


# ---------------------------------------------------------------- plumbing
func _commit(edit: Dictionary, state: Dictionary, skip_building: String, commit: bool = true) -> Dictionary:
	var longer: Array = edits.duplicate()
	longer.append(edit)
	var result: Dictionary = _swap_to(longer, state, skip_building, edit.get("op") in ["paint", "finish"])
	if not result.ok:
		return result
	if not commit:
		return {"ok": true, "reason": "", "edit": edit}
	edits.append(edit)
	_redo.clear()
	_adopt(result)
	result["edit"] = edit
	return result


## Builds the world for a list of edits and checks it is whole. {ok, reason, area, rules}; changes nothing.
func _swap_to(list: Array, state: Dictionary, skip_building: String, appearance_only: bool = false) -> Dictionary:
	var applied: Dictionary = AreaBuild.apply(base_document, list, paint_materials)
	if not (applied.skipped as Array).is_empty():
		return {"ok": false, "reason": "That edit does not fit the valley."}
	var parsed: Dictionary = AreaDef.parse(applied.document, assets, quest_document, paint_materials)
	if not parsed.ok:
		return {"ok": false, "reason": "That edit does not fit the valley: %s" % str(parsed.errors)}
	var candidate: AreaDef = parsed.area
	if appearance_only:
		return {"ok": true, "reason": "", "area": candidate, "rules": rules}
	var next_rules := LabWorld.new(candidate)
	var player: Vector2i = Vector2i(int(state.player[0]), int(state.player[1]))
	var problem: String = AreaBuild.reach_problem({"area": area, "rules": rules}, {"area": candidate, "rules": next_rules}, player, skip_building)
	if problem != "":
		return {"ok": false, "reason": problem}
	return {"ok": true, "reason": "", "area": candidate, "rules": next_rules}


func _adopt(result: Dictionary) -> void:
	area = result.area
	rules = result.rules
	rules.area = area
