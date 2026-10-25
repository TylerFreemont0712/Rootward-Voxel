extends SceneTree
## Build mode's rules: where things may stand, what stays reachable, undo/redo and the saved edit list.
## Pure rules over Kindle Hollow's real document, so they also prove the new houses fit the town.

var _checks: int = 0
var _failures: Array[String] = []
var _document: Dictionary
var _assets: Dictionary
var _quests: Variant
var _catalog: Dictionary


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/world-catalog.json"))
	_assets = world.assets
	_document = JSON.parse_string(FileAccess.get_file_as_string("res://content/areas/kindle-hollow.json"))
	_quests = JSON.parse_string(FileAccess.get_file_as_string("res://content/areas/kindle-hollow.quests.json"))
	_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://content/build/catalog.json"))
	_catalog_tests()
	_geometry_tests()
	_placement_tests()
	_reach_tests()
	_history_tests()
	_save_tests()
	_prop_tests()
	_policy_tests()
	if _failures.is_empty():
		print("Build rules: %d checks passed (catalog, placement, reachability, undo/redo, saved edits, policy)." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		quit(1)


func _ledger(saved: Array = [], policy: String = "studio") -> BuildLedger:
	return BuildLedger.new(_document, _assets, _quests, _catalog, saved, policy)


## The first spot in a region (rows from the south) where the rules allow this item.
func _spot(ledger: BuildLedger, item_id: String, region: Rect2i, state: Dictionary, facing: String = "S") -> Vector2:
	var step: float = 0.5 if item_id.begins_with("tree") else 1.0
	var y: float = float(region.position.y)
	while y < float(region.end.y):
		var x: float = float(region.position.x)
		while x < float(region.end.x):
			if ledger.check_item(item_id, Vector2(x, y), facing, state).ok:
				return Vector2(x, y)
			x += step
		y += step
	return Vector2(-1, -1)


const MEADOW := Rect2i(31, 2, 14, 12)


func _state(ledger: BuildLedger, cell: Vector2i = Vector2i(28, 3)) -> Dictionary:
	var state: Dictionary = ledger.rules.initial_state()
	state.player = [cell.x, cell.y, 0]
	return state


## The valley's own building count, so the checks follow the area document as it grows.
func _base_buildings() -> int:
	return (_document.buildings as Array).size()


func _catalog_tests() -> void:
	var ids: Dictionary = {}
	for entry: Dictionary in _catalog.items:
		_check(not ids.has(entry.id), "Catalog item %s is unique" % entry.id)
		ids[entry.id] = true
		_check(_catalog.categories.any(func(category: Dictionary) -> bool: return category.id == entry.category), "%s names a real category" % entry.id)
		if entry.kind == "building":
			var footprint: Variant = (_assets.get(entry.asset, {}) as Dictionary).get("logical_footprint")
			_check(footprint is Array and (footprint as Array).size() == 4, "%s has a world-catalog footprint" % entry.id)
		if entry.kind == "prop":
			var spec: Dictionary = _assets.get(entry.asset, {})
			var shape: Variant = spec.get("logical_footprint")
			_check(not spec.is_empty() and FileAccess.file_exists("res://" + str(spec.get("runtime", ""))) and (shape == null or (shape is Array and (shape as Array).size() == 4)), "%s names a built model with no footprint or a rectangular one" % entry.id)
	_check(AreaBuild.allowed_items(_catalog, "studio").size() == _catalog.items.size(), "The studio may place everything")
	var villager: Array[Dictionary] = AreaBuild.allowed_items(_catalog, "player")
	_check(villager.size() < _catalog.items.size() and villager.all(func(entry: Dictionary) -> bool: return entry.audience == "player"), "A villager is offered only player items")
	_check(AreaBuild.allowed_items(_catalog, "player", "trees").size() == 3, "Trees can be listed by category")


func _geometry_tests() -> void:
	var rect: Rect2 = AreaBuild.footprint_rect(_assets, "log-cabin-large", Vector2(24, 6), "S", 1.0)
	_check(rect.size.is_equal_approx(Vector2(4.7, 4.7)) and rect.get_center().is_equal_approx(Vector2(24, 6)), "A large house is 4.7 units square about its centre")
	_check(AreaBuild.footprint_cells(rect).size() == 25, "It covers five by five cells")
	var small: Rect2 = AreaBuild.footprint_rect(_assets, "log-cabin", Vector2(10, 10), "S", 1.0)
	_check(AreaBuild.footprint_cells(small).size() == 9, "A small cabin covers three by three")
	_check(AreaBuild.snap_building(_assets, "log-cabin-large", "S", 1.0, Vector2(24.4, 6.6)) == Vector2(24, 7), "An odd-celled house snaps to a whole cell")
	_check(AreaBuild.snap_building(_assets, "log-cabin", "E", 0.7, Vector2(10.2, 10.2)).is_equal_approx(Vector2(10.5, 10.5)), "An even-celled building snaps to a half cell")
	_check(AreaBuild.snap_tree(Vector2(5.74, 3.2)) == Vector2(5.5, 3.0), "Trees snap to half cells")
	_check(AreaBuild.turned("S") == "E" and AreaBuild.turned("W") == "S" and AreaBuild.turned("S", -1) == "W", "Facings turn in a circle")
	var door: Vector2i = AreaBuild.door_cell(rect, Vector2(24, 6), "E")
	_check(door == Vector2i(27, 6), "An east door opens onto the cell past the doorstep")


func _placement_tests() -> void:
	var ledger: BuildLedger = _ledger()
	var state: Dictionary = _state(ledger)
	var home: Vector2 = _spot(ledger, "house-hollow", MEADOW, state)
	_check(home.x > 0, "The rules find a place for a large house in the meadow east of the landing")
	_check(ledger.check_item("house-hollow", home, "S", state).ok, "...and the house is allowed there")
	var existing: Dictionary = ledger.check_item("house-hollow", Vector2(24, 6), "S", state)
	_check(not existing.ok and existing.reason == "Another building is too close.", "It cannot stand on the existing home, and says why")
	_check(ledger.check_item("house-hollow", Vector2(44, 10), "S", state).reason == "Water is in the way.", "A house cannot stand in the river")
	_check(ledger.check_item("house-hollow", Vector2(1, 1), "S", state).reason != "", "A house cannot hang off the map or stand on rock")
	_check(ledger.check_item("house-hollow", Vector2(29, 3), "S", state).reason == "Keep the starting spot clear.", "A house cannot cover the starting spot")
	_check(ledger.check_item("house-hollow", Vector2(31, 8), "S", state).reason == "A lamp needs room around it.", "A house cannot crowd a lamp")
	var oak: Vector2 = _spot(ledger, "tree-oak", MEADOW, state)
	_check(oak.x > 0, "The rules find a place for an oak")
	var road: Dictionary = ledger.check_item("tree-oak", Vector2(28, 10), "S", state)
	_check(not road.ok and road.reason == "Keep the paths clear.", "A tree cannot stand on a path (%s)" % road.reason)
	_check(not ledger.check_item("tree-oak", Vector2(44, 10), "S", state).ok and ledger.check_item("tree-oak", Vector2(44, 10), "S", state).reason == "Trees do not grow on water.", "A tree cannot stand in water")
	_check(ledger.check_item("tree-oak", Vector2(30.5, 8.0), "S", state).reason == "Too close to a lamp.", "A tree keeps away from a lamp")
	var near: Vector2 = (ledger.area.trees[0].at as Vector2) + Vector2(0.5, 0.0)
	_check(ledger.check_item("tree-oak", near, "S", state).reason == "Trees need a little room.", "Trees keep their distance from each other")
	_check(ledger.check_item("tree-oak", Vector2(9, 22), "S", state).reason == "Too close to a building.", "A tree keeps away from a house (%s)" % ledger.check_item("tree-oak", Vector2(9, 22), "S", state).reason)
	var untouched: int = ledger.area.trees.size()
	_check(untouched == _document.trees.size() and ledger.edits.is_empty(), "Checking changes nothing")
	var standing: Dictionary = _state(ledger, Vector2i(roundi(home.x), roundi(home.y)))
	_check(ledger.check_item("house-hollow", home, "S", standing).reason == "You are standing there.", "You cannot build on yourself")
	_check(ledger.check_item("house-hollow", home, "S", state).door == Vector2i(roundi(home.x), roundi(home.y) - 3), "The door cell is reported for the ghost")
	_check(ledger.check_item("not-a-thing", Vector2(1, 1), "S", state).reason == "That is not on offer.", "Unknown items are refused")
	# The door must open onto ground: face a house at the river with its door in the water.
	var by_river: Dictionary = ledger.check_item("house-hollow", Vector2(40, 8), "E", state)
	_check(not by_river.ok, "A house whose door would open into the river is refused (%s)" % by_river.reason)


func _reach_tests() -> void:
	var ledger: BuildLedger = _ledger()
	var state: Dictionary = _state(ledger)
	var home: Vector2 = _spot(ledger, "house-hollow", MEADOW, state)
	var started: int = Time.get_ticks_msec()
	var placed: Dictionary = ledger.place("house-hollow", home, "S", state)
	var spent: int = Time.get_ticks_msec() - started
	_check(placed.ok, "Placing a house succeeds: %s" % str(placed.get("reason")))
	print("  placing a house took %d ms" % spent)
	_check(spent < 1500, "A placement is decided in about a second at most (%d ms)" % spent)
	_check(ledger.area.buildings.size() == _base_buildings() + 1 and ledger.edits.size() == 1, "The new area has the house")
	# Only the gate and the bridge are chokepoints: the rest of the valley is open meadow. A cabin on the
	# Night Gate's doorway is allowed by the cheap check but would cut the valley's north off from the start.
	var blocker: Vector2 = Vector2(29, 32)
	var cheap: Dictionary = ledger.check_item("cabin-little", blocker, "S", state)
	_check(cheap.ok, "The cheap check cannot see a cut-off (%s)" % cheap.reason)
	started = Time.get_ticks_msec()
	var refused: Dictionary = ledger.place("cabin-little", blocker, "S", state)
	print("  a refused placement took %d ms" % (Time.get_ticks_msec() - started))
	_check(not refused.ok and refused.reason.begins_with("That would cut you off from"), "A cabin in the Night Gate's doorway is refused (%s)" % str(refused.get("reason")))
	_check(ledger.edits.size() == 1 and ledger.area.buildings.size() == _base_buildings() + 1, "A refused edit leaves the ledger alone")
	var dry: Dictionary = ledger.place("cabin-little", blocker, "S", state, false)
	_check(not dry.ok and dry.reason.begins_with("That would cut you off from"), "A dry run gives the same refusal...")
	var spare: Vector2 = _spot(ledger, "house-hollow", MEADOW, state)
	var dry_ok: Dictionary = ledger.place("house-hollow", spare, "S", state, false)
	_check(dry_ok.ok and ledger.edits.size() == 1 and ledger.area.buildings.size() == _base_buildings() + 1 and ledger.can_undo(), "...and a dry run that passes changes nothing")
	_check(ledger.move_building("build-1", spare, "N", state, false).ok and ledger.area.building("build-1").facing == "S", "A dry-run move changes nothing either")
	# Removing a building never cuts anything off, but a locked one cannot go.
	var locked: Dictionary = ledger.remove_building("mill", state)
	_check(not locked.ok and locked.reason.contains("lessons"), "The mill is locked to the lessons")
	_check(ledger.remove_building("row-north-a", state).ok, "An ordinary house can be removed")
	# A bridge must stay reachable: nothing may stand on its sockets.
	_check(ledger.check_item("house-hollow", Vector2(44, 19), "S", state).reason != "", "Nothing may stand on the bridge's crossing")


func _history_tests() -> void:
	var ledger: BuildLedger = _ledger()
	var state: Dictionary = _state(ledger)
	var original_trees: int = ledger.area.trees.size()
	_check(not ledger.can_undo() and not ledger.can_redo() and not ledger.undo(state).ok, "A fresh ledger has nothing to undo")
	var oak: Vector2 = _spot(ledger, "tree-oak", MEADOW, state)
	_check(ledger.place("tree-oak", oak, "S", state).ok, "Place an oak")
	var house: Vector2 = _spot(ledger, "house-hollow", MEADOW, state)
	_check(ledger.place("house-hollow", house, "S", state).ok, "Place a house")
	var again: Vector2 = _spot(ledger, "house-hollow", MEADOW, state, "E")
	_check(ledger.move_building("build-1", again, "E", state).ok, "Move the new house and turn it")
	_check(ledger.area.building("build-1").facing == "E" and ledger.area.building("build-1").at == again, "The move landed")
	_check(ledger.remove_tree(oak, state).ok and ledger.area.trees.size() == original_trees, "Remove the oak again")
	_check(ledger.edits.size() == 4 and ledger.can_undo(), "Four edits are kept in order")
	_check(ledger.undo(state).ok and ledger.area.trees.size() == original_trees + 1, "Undo brings the oak back")
	_check(ledger.undo(state).ok and ledger.area.building("build-1").facing == "S" and ledger.area.building("build-1").at == house, "Undo puts the house back where it was")
	_check(ledger.can_redo() and ledger.redo(state).ok and ledger.area.building("build-1").facing == "E", "Redo does it again")
	_check(ledger.undo(state).ok and ledger.undo(state).ok and ledger.undo(state).ok and ledger.area.buildings.size() == _base_buildings() and ledger.area.trees.size() == original_trees, "Undo all the way restores the document")
	_check(ledger.edits.is_empty() and not ledger.undo(state).ok, "...and then stops")
	_check(ledger.place("tree-oak", oak, "S", state).ok and not ledger.can_redo(), "A new edit clears redo")
	var moved_to: Vector2 = _spot(ledger, "tree-oak", Rect2i(MEADOW.position + Vector2i(3, 0), MEADOW.size - Vector2i(3, 0)), state)
	_check(ledger.move_tree(oak, moved_to, state).ok and ledger.area.trees.any(func(entry: Dictionary) -> bool: return (entry.at as Vector2).is_equal_approx(moved_to)), "A tree can be moved")
	_check(ledger.describe(ledger.edits[-1]) == "Moved a tree" and ledger.describe({"op": "add", "kind": "building", "asset": "log-cabin-large"}) == "Placed Hollow House", "Edits describe themselves")
	# Undo cannot put a house on the player.
	var other: BuildLedger = _ledger()
	var away: Dictionary = _state(other)
	_check(other.place("house-hollow", house, "S", away).ok and other.remove_building("build-1", away).ok, "Place and remove a house")
	var onto: Dictionary = _state(other, Vector2i(roundi(house.x), roundi(house.y)))
	var refused: Dictionary = other.undo(onto)
	_check(not refused.ok and refused.reason == "You are standing there.", "Undoing a removal will not drop a house on you")


func _save_tests() -> void:
	var ledger: BuildLedger = _ledger()
	var state: Dictionary = _state(ledger)
	var house: Vector2 = _spot(ledger, "house-millwright", MEADOW, state, "N")
	ledger.place("house-millwright", house, "N", state)
	var elder: Vector2 = _spot(ledger, "tree-elder", MEADOW, state)
	ledger.place("tree-elder", elder, "S", state)
	ledger.remove_building("row-south-a", state)
	var saved: Array = JSON.parse_string(JSON.stringify(ledger.edits))
	var restored: BuildLedger = _ledger(saved)
	_check(restored.problems.is_empty() and restored.edits.size() == 3, "Saved edits survive a JSON round trip")
	_check(restored.area.buildings.size() == ledger.area.buildings.size() and restored.area.trees.size() == ledger.area.trees.size(), "The restored area matches")
	_check(restored.area.building("build-1").asset == "log-cabin-large-teal" and restored.area.building("build-1").facing == "N", "...including what was placed and how it faces")
	_check(restored.area.building("row-south-a").is_empty(), "...and what was taken away")
	# Edits that no longer fit are skipped and reported, never guessed at.
	var stale: BuildLedger = _ledger([{"op": "remove", "kind": "building", "id": "no-such-house"}, {"op": "add", "kind": "tree", "at": [elder.x, elder.y], "size": 1.0}])
	_check(stale.problems.size() == 1 and stale.edits.size() == 1 and stale.area.trees.size() == _document.trees.size() + 1, "A stale edit is reported and the rest still apply")
	var junk: BuildLedger = _ledger([{"op": "add", "kind": "building", "id": "x", "asset": "log-cabin-large", "at": [1000.0, 1000.0], "facing": "S", "scale": 1.0}])
	_check(not junk.problems.is_empty() and junk.edits.is_empty() and junk.area.buildings.size() == _base_buildings(), "A save that breaks the valley is set aside whole")
	_check(AreaBuild.next_building_id(AreaBuild.apply(_document, ledger.edits).document) == "build-2", "New ids continue the sequence")
	var count_before: int = _base_buildings()
	var pure: Dictionary = AreaBuild.apply(_document, ledger.edits)
	_check(_base_buildings() == count_before and (pure.document.buildings as Array).size() == count_before, "Applying edits never changes the source document")


## Doodads: loose props with no door. One whose asset has a catalog footprint blocks movement; one without does not.
func _prop_tests() -> void:
	var ledger: BuildLedger = _ledger()
	var state: Dictionary = _state(ledger)
	var base: int = ledger.area.props.size()
	var chest: Vector2 = _spot(ledger, "storage-chest", MEADOW, state)
	_check(chest.x > 0, "The rules find room for a chest in the meadow")
	var placed: Dictionary = ledger.place("storage-chest", chest, "S", state)
	_check(placed.ok and ledger.area.props.size() == base + 1 and ledger.edits.size() == 1, "A prop goes down as one edit: %s" % str(placed.get("reason")))
	var made: Dictionary = ledger.area.prop("prop-1")
	_check(made.asset == "storage-chest" and made.solid and made.at == chest and made.facing == "S", "It keeps its model, its spot, its facing and a blocking footprint")
	_check(not ledger.rules.is_walkable(state, Vector2i(roundi(chest.x), roundi(chest.y))), "A prop with a footprint blocks the ground it stands on")
	_check(ledger.describe(placed.edit) == "Placed Storage Chest", "The history names it")
	_check(AreaBuild.object_near(ledger.area, chest).get("kind") == "prop", "Pointing at it finds it")
	var can_at: Vector2 = _spot(ledger, "watering-can", MEADOW, state)
	_check(ledger.place("watering-can", can_at, "S", state).ok, "A watering can goes down too")
	_check(not ledger.area.prop("prop-2").solid and ledger.rules.is_walkable(state, Vector2i(roundi(can_at.x), roundi(can_at.y))), "A prop with no footprint is walked over, not around")
	# Where a prop may not stand.
	var overlap: Dictionary = ledger.check_item("hearth-stool", chest, "S", state)
	_check(not overlap.ok and overlap.reason == "Another doodad is there.", "Two props cannot overlap (%s)" % overlap.reason)
	_check(not ledger.check_item("house-hollow", chest, "S", state).ok, "A house cannot be built over a prop")
	_check(not ledger.check_item("tree-oak", chest + Vector2(0.5, 0.0), "S", state).ok, "A tree keeps clear of a prop")
	_check(ledger.check_item("wooden-chair", Vector2(44, 10), "S", state).reason == "Water is in the way.", "A prop cannot stand in the river")
	_check(ledger.check_item("wooden-chair", Vector2(-1, 5), "S", state).reason == "Keep it inside the valley.", "...or off the map")
	var standing: Dictionary = _state(ledger, Vector2i(34, 5))
	var on_player: Dictionary = ledger.check_item("dining-table", Vector2(34, 5), "S", standing)
	_check(on_player.reason == "You are standing there.", "A prop that blocks cannot be put on the player (%s)" % on_player.reason)
	_check(ledger.check_item("watering-can", Vector2(34, 5), "S", standing).ok, "...but one with no footprint may be set down at the player's feet")
	_check(ledger.check_item("dining-table", Vector2(28, 3), "S", state).reason == "Keep the starting spot clear.", "A prop keeps the starting spot clear")
	var turned: Rect2 = AreaBuild.prop_rect(_assets, "storage-chest", Vector2.ZERO, "E", 1.0)
	_check(turned.size.is_equal_approx(Vector2(0.4, 0.6)), "A turned prop's footprint turns with it")
	# Moving, saving, removing, and history.
	var elsewhere: Vector2 = _spot(ledger, "storage-chest", Rect2i(MEADOW.position + Vector2i(5, 0), MEADOW.size - Vector2i(5, 0)), state, "E")
	_check(ledger.move_prop("prop-1", elsewhere, "E", state).ok and ledger.area.prop("prop-1").at == elsewhere and ledger.area.prop("prop-1").facing == "E", "A prop moves and turns")
	var saved: Array = JSON.parse_string(JSON.stringify(ledger.edits))
	var restored: BuildLedger = _ledger(saved)
	_check(restored.problems.is_empty() and restored.area.props.size() == 2 and restored.area.prop("prop-1").facing == "E" and restored.area.prop("prop-1").at == elsewhere, "Props survive a JSON round trip, where they were put and how they face")
	var removed: Dictionary = ledger.remove_prop("prop-1", state)
	_check(removed.ok and ledger.area.prop("prop-1").is_empty() and ledger.area.props.size() == base + 1, "A prop can be removed")
	_check(ledger.describe(removed.edit) == "Removed Storage Chest", "...and the history still says what it was")
	var stool: Vector2 = _spot(ledger, "hearth-stool", MEADOW, state)
	_check(ledger.place("hearth-stool", stool, "S", state).ok and not ledger.area.prop("prop-3").is_empty(), "A new prop gets a fresh id; a removed one's is not reused")
	_check(ledger.undo(state).ok and ledger.undo(state).ok and ledger.area.prop("prop-1").at == elsewhere, "Undo takes back the stool and the removal")
	_check(ledger.undo(state).ok and ledger.area.prop("prop-1").at == chest and ledger.area.prop("prop-1").facing == "S", "Undo puts the chest back where it was")
	_check(ledger.undo(state).ok and ledger.undo(state).ok and ledger.area.props.size() == base and ledger.edits.is_empty(), "Undo all the way restores the document")
	_check(ledger.redo(state).ok and ledger.area.prop("prop-1").at == chest, "Redo does it again")
	var stale: BuildLedger = _ledger([{"op": "add", "kind": "prop", "id": "prop-9", "asset": "no-such-model", "at": [40.0, 5.0], "facing": "S", "scale": 1.0}])
	_check(not stale.problems.is_empty() and stale.area.props.size() == base and stale.edits.is_empty(), "A saved prop whose model is gone is set aside whole")
	# The shelf: doodads are studio items.
	var doodads: Array[Dictionary] = AreaBuild.allowed_items(_catalog, "studio", "doodads")
	_check(doodads.size() > 20 and doodads.all(func(entry: Dictionary) -> bool: return entry.kind == "prop"), "The studio shelf has a Doodads tab of props (%d)" % doodads.size())
	_check(AreaBuild.allowed_items(_catalog, "player", "doodads").is_empty(), "A villager is not offered doodads yet")


func _policy_tests() -> void:
	var ledger: BuildLedger = _ledger([], "player")
	var state: Dictionary = _state(ledger)
	var home: Vector2 = _spot(ledger, "house-hollow", MEADOW, state)
	_check(ledger.check_item("house-hollow", home, "S", state).ok, "A villager may place a large house")
	_check(ledger.check_item("cottage-plaster", home, "S", state).reason == "That is not open to you yet.", "...but not a studio-only cottage")
	var tight: Dictionary = _catalog.duplicate(true)
	tight.policies.player.limits = {"tree": 3, "building": 1}
	var limited := BuildLedger.new(_document, _assets, _quests, tight, [], "player")
	var placed: int = 0
	for attempt: int in range(6):
		var spot: Vector2 = _spot(limited, "tree-oak", MEADOW, state)
		if limited.place("tree-oak", spot, "S", state).ok:
			placed += 1
	_check(placed == 3, "A villager's allowance of trees runs out (%d placed)" % placed)
	var late: Vector2 = _spot(limited, "tree-oak", MEADOW, state)
	_check(limited.check_item("tree-oak", late, "S", state).reason.begins_with("You can add at most") or late.x < 0, "...with a friendly reason")
	var cabin_spot: Vector2 = _spot(limited, "cabin-little", MEADOW, state)
	_check(limited.place("house-hollow", _spot(limited, "house-hollow", MEADOW, state), "S", state).ok, "The one allowed building goes down")
	cabin_spot = _spot(limited, "cabin-little", MEADOW, state)
	_check(limited.check_item("cabin-little", cabin_spot, "S", state).reason.begins_with("You can add at most 1 buildings"), "...and the next is refused")
	_check(limited.made("tree") == 3 and limited.limit("tree") == 3 and limited.made("building") == 1, "The ledger reports what has been made against the limit")
	var own_tree: Vector2 = Vector2(float(limited.edits[0].at[0]), float(limited.edits[0].at[1]))
	_check(limited.remove_tree(own_tree, state).ok and limited.made("tree") == 2, "Taking down a tree you planted gives its place back")
	var old_tree: Vector2 = limited.area.trees[0].at
	var elsewhere: Vector2 = _spot(limited, "tree-oak", Rect2i(MEADOW.position + Vector2i(5, 0), MEADOW.size - Vector2i(5, 0)), state)
	_check(limited.move_tree(old_tree, elsewhere, state).ok and limited.made("tree") == 2, "Moving a tree that was already there spends nothing")
	_check(limited.remove_building("build-1", state).ok, "Take down the house you added")
	cabin_spot = _spot(limited, "cabin-little", MEADOW, state)
	_check(cabin_spot.x > 0 and limited.check_item("cabin-little", cabin_spot, "S", state).ok, "...which gives the allowance back")
	var studio: BuildLedger = _ledger()
	for attempt: int in range(6):
		studio.place("tree-oak", _spot(studio, "tree-oak", MEADOW, state), "S", state)
	_check(studio.added("tree") == 6, "The studio has no allowance to run out")


func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
