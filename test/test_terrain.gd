extends SceneTree
## Terraced land, stairs and water: the document format, the walking rules across cliffs and stairs, the land tools
## in the build ledger (raise, lower, dig, fill, stairs) with their refusals, undo/redo and saves, and the pure
## geometry the renderer draws from (cliff columns, stairs, waterfalls). Rules run over Kindle Hollow's real document.

var _checks: int = 0
var _failures: Array[String] = []
var _document: Dictionary
var _assets: Dictionary
var _quests: Variant
var _catalog: Dictionary

## Open meadow east of the landing: grass with no trees, houses or lamps, so the land there may be shaped.
const PLATEAU: Array[Vector2i] = [Vector2i(33, 4), Vector2i(34, 4), Vector2i(35, 4), Vector2i(33, 5), Vector2i(34, 5), Vector2i(35, 5), Vector2i(33, 6), Vector2i(34, 6), Vector2i(35, 6)]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/world-catalog.json"))
	_assets = world.assets
	_document = JSON.parse_string(FileAccess.get_file_as_string("res://content/areas/kindle-hollow.json"))
	_quests = JSON.parse_string(FileAccess.get_file_as_string("res://content/areas/kindle-hollow.quests.json"))
	_catalog = JSON.parse_string(FileAccess.get_file_as_string("res://content/build/catalog.json"))
	_document_tests()
	_walking_tests()
	_ledger_tests()
	_water_tests()
	_object_tests()
	_save_tests()
	_geometry_tests()
	if _failures.is_empty():
		print("Terrain: %d checks passed (levels, stairs, cliffs, land tools, water, waterfalls, refusals, history, saves)." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		quit(1)


# ------------------------------------------------------------------ helpers
## An 8×6 test valley. `levels` and `terrain` are north-up rows; row 0 is y = 5.
func _small(levels: Variant, stairs: Array = [], terrain: Array = []) -> Dictionary:
	var rows: Array = terrain if not terrain.is_empty() else ["........", "........", "........", "........", "........", "........"]
	var document: Dictionary = {"schema": 1, "id": "terrace-test", "title": "Terraces", "version": 1, "size": [8, 6], "spawn": [0, 0], "terrain": rows, "stairs": stairs}
	if levels != null:
		document["levels"] = levels
	return document


func _parse(document: Dictionary) -> Dictionary:
	return AreaDef.parse(document, _assets)


func _ledger(saved: Array = []) -> BuildLedger:
	return BuildLedger.new(_document, _assets, _quests, _catalog, saved)


func _state(ledger: BuildLedger, cell: Vector2i = Vector2i(28, 3)) -> Dictionary:
	var state: Dictionary = ledger.rules.initial_state()
	state.player = [cell.x, cell.y, 0]
	return state


func _cells(list: Array[Vector2i]) -> Array:
	var result: Array = []
	for cell: Vector2i in list:
		result.append([cell.x, cell.y])
	return result


## A plateau east of the landing, raised to level 1, with stairs up its west side.
func _terraced() -> BuildLedger:
	var ledger: BuildLedger = _ledger()
	var raised: Dictionary = ledger.shape("raise", 1, _cells(PLATEAU), _state(ledger))
	_check(raised.ok, "The meadow can be raised: %s" % str(raised.get("reason", "")))
	var stairs: Dictionary = ledger.place_stairs(Vector2i(32, 5), "E", _state(ledger))
	_check(stairs.ok, "Stairs can be built at the foot of the new cliff: %s" % str(stairs.get("reason", "")))
	return ledger


# ---------------------------------------------------------------- documents
func _document_tests() -> void:
	var flat: Dictionary = _parse(_small(null))
	_check(flat.ok and (flat.area as AreaDef).level_at(Vector2i(3, 3)) == 0 and (flat.area as AreaDef).stairs.is_empty(), "A document without levels is all valley floor")
	var terraced: Dictionary = _parse(_small(["11110000", "11110000", "22110000", "00000000", "00000000", "00000000"], [{"at": [2, 2], "up": "N"}]))
	_check(terraced.ok, "Levels and stairs parse: %s" % str(terraced.get("errors", [])))
	var area: AreaDef = terraced.area
	_check(area.level_at(Vector2i(0, 5)) == 1 and area.level_at(Vector2i(0, 3)) == 2 and area.level_at(Vector2i(4, 5)) == 0, "Level rows are read north-up, like terrain")
	_check(area.level_at(Vector2i(-1, 3)) == 0 and area.level_at(Vector2i(9, 9)) == 0, "Outside the area the land is the valley floor")
	var flight: Dictionary = area.stair_at(Vector2i(2, 2))
	_check(flight.get("dir") == Vector2i(0, 1) and flight.get("level") == 0 and area.stair_at(Vector2i(2, 3)).is_empty(), "A flight knows its cell, direction and base level")
	_check(is_equal_approx(area.ground_level(Vector2(2, 2)), 0.5) and is_equal_approx(area.ground_level(Vector2(2, 2.5)), 1.0) and is_equal_approx(area.ground_level(Vector2(2, 1.6)), 0.1), "On stairs the surface ramps from the foot edge to the top edge")
	_check(is_equal_approx(area.ground_level(Vector2(1, 4)), 1.0) and is_equal_approx(area.ground_level(Vector2(1, 1)), 0.0), "Off stairs the surface is the cell's level")
	for bad: Array in [
		[_small(["11110000", "11110000", "31110000", "00000000", "00000000", "00000000"]), "a level above the highest"],
		[_small(["1111000", "11110000", "11110000", "00000000", "00000000", "00000000"]), "a short levels row"],
		[_small(["11110000", "11110000"]), "too few level rows"],
		[_small(["11110000", "11110000", "11110000", "00000000", "00000000", "00000000"], [{"at": [5, 2], "up": "N"}]), "stairs with no cliff above"],
		[_small(["11110000", "11110000", "11110000", "00000000", "00000000", "00000000"], [{"at": [2, 2], "up": "S"}]), "stairs climbing the wrong way"],
		[_small(["22220000", "22220000", "22220000", "00000000", "00000000", "00000000"], [{"at": [2, 2], "up": "N"}]), "stairs onto a two-level cliff"],
		[_small(["11110000", "11110000", "11110000", "00000000", "00000000", "00000000"], [{"at": [2, 2], "up": "N"}, {"at": [2, 2], "up": "N"}]), "two flights on one cell"],
		[_small(["22220000", "11110000", "11110000", "00000000", "00000000", "00000000"], [{"at": [2, 2], "up": "N"}, {"at": [2, 3], "up": "N"}]), "stairs leading straight onto stairs"],
		[_small(["11110000", "11110000", "11110000", "00000000", "00000000", "00000000"], [{"at": [2, 2], "up": "N"}], ["........", "........", "........", "..~.....", "........", "........"]), "stairs standing in water"],
		[_small(null, [{"at": [2, 2], "up": "Q"}]), "an unknown climbing direction"],
	]:
		_check(not _parse(bad[0]).ok, "A document with %s is refused" % bad[1])
	var straddle: Dictionary = _small(["11110000", "11110000", "11110000", "00000000", "00000000", "00000000"])
	straddle["buildings"] = [{"id": "across", "asset": "cottage", "at": [3, 3], "facing": "S"}]
	_check(not _parse(straddle).ok, "A building may not straddle two levels")
	straddle["buildings"] = [{"id": "level", "asset": "cottage", "at": [6, 2], "facing": "S"}]
	_check(_parse(straddle).ok, "A building on one level is fine")


# ------------------------------------------------------------------ walking
func _walking_tests() -> void:
	var parsed: Dictionary = _parse(_small(["11110000", "11110000", "11110000", "00000000", "00000000", "00000000"], [{"at": [2, 2], "up": "N"}]))
	var area: AreaDef = parsed.area
	var rules := LabWorld.new(area)
	var state: Dictionary = rules.initial_state()
	_check(rules.can_step(state, Vector2i(2, 1), Vector2i(2, 2)) and rules.can_step(state, Vector2i(2, 2), Vector2i(2, 3)), "Stairs are climbed from their foot to the top")
	_check(rules.can_step(state, Vector2i(2, 3), Vector2i(2, 2)) and rules.can_step(state, Vector2i(2, 2), Vector2i(2, 1)), "Stairs are walked down again")
	_check(not rules.can_step(state, Vector2i(1, 2), Vector2i(2, 2)) and not rules.can_step(state, Vector2i(2, 2), Vector2i(3, 2)), "Nobody steps on or off stairs sideways")
	_check(not rules.can_step(state, Vector2i(1, 2), Vector2i(1, 3)) and not rules.can_step(state, Vector2i(4, 4), Vector2i(3, 4)), "A cliff blocks the way up")
	_check(not rules.can_step(state, Vector2i(1, 3), Vector2i(1, 2)), "A cliff blocks the way down")
	_check(rules.can_step(state, Vector2i(0, 4), Vector2i(1, 4)) and rules.can_step(state, Vector2i(5, 4), Vector2i(4, 4)), "Level ground joins level ground, high or low")
	var path: Array[Vector2i] = rules.find_path(state, Vector2i(0, 5), Vector2i(0, 0))
	_check(path.has(Vector2i(2, 2)) and path.has(Vector2i(2, 3)) and path[-1] == Vector2i(0, 5), "A route up the terrace goes by the stairs")
	var closed: Dictionary = _parse(_small(["11110000", "11110000", "11110000", "00000000", "00000000", "00000000"]))
	var walled := LabWorld.new(closed.area)
	_check(walled.find_path(walled.initial_state(), Vector2i(0, 5), Vector2i(0, 0)).is_empty(), "Without stairs a terrace cannot be reached")


# ------------------------------------------------------------------- ledger
func _ledger_tests() -> void:
	var ledger: BuildLedger = _ledger()
	var state: Dictionary = _state(ledger)
	var before: int = ledger.edits.size()
	var raised: Dictionary = ledger.shape("raise", 1, _cells(PLATEAU), state)
	_check(raised.ok and ledger.edits.size() == before + 1 and ledger.edits[-1].op == "level", "Raising a patch is one edit: %s" % str(raised.get("reason", "")))
	_check(PLATEAU.all(func(cell: Vector2i) -> bool: return ledger.area.level_at(cell) == 1) and ledger.area.level_at(Vector2i(32, 5)) == 0, "Only the chosen cells rise")
	_check(ledger.describe(ledger.edits[-1]) == "Raised the land", "The history calls it raising the land")
	_check(not ledger.rules.can_step(state, Vector2i(32, 5), Vector2i(33, 5)), "The new cliff blocks walking")
	var higher: Dictionary = ledger.shape("raise", 2, _cells([Vector2i(34, 5)]), state)
	_check(higher.ok and ledger.area.level_at(Vector2i(34, 5)) == 2, "Land rises to level 2")
	_check(not ledger.shape("raise", 3, _cells([Vector2i(34, 5)]), state).ok, "Land rises no higher than level 2")
	_check(not ledger.shape("lower", -1, _cells([Vector2i(30, 5)]), state).ok, "The valley floor goes no lower")
	var lowered: Dictionary = ledger.shape("lower", 1, _cells([Vector2i(34, 5)]), state)
	_check(lowered.ok and ledger.area.level_at(Vector2i(34, 5)) == 1 and ledger.describe(ledger.edits[-1]) == "Lowered the land", "Lowering brings it back down a level")
	var same: Dictionary = ledger.shape("raise", 1, _cells(PLATEAU), state)
	_check(not same.ok and str(same.reason).contains("already"), "Raising land that is up there already changes nothing")
	# Stairs.
	_check(ledger.check_stairs(Vector2i(32, 5), "E", state).ok, "Stairs fit at the foot of the cliff, climbing toward it")
	_check(AreaBuild.stairs_direction(ledger.area, Vector2i(32, 5), "S") == "E" and AreaBuild.stairs_direction(ledger.area, Vector2i(30, 5), "S") == "", "The climbing way is found from the cliff beside the cell")
	_check(not ledger.check_stairs(Vector2i(32, 5), "W", state).ok, "Stairs refuse to climb away from the cliff")
	_check(not ledger.check_stairs(Vector2i(30, 5), "E", state).ok, "Stairs refuse open ground with no cliff")
	_check(not ledger.check_stairs(Vector2i(32, 5), "E", _state(ledger, Vector2i(32, 5))).ok, "Stairs are not built where the player stands")
	for crate: String in ["wooden-chair", "wooden-barrel", "woodpile"]:
		var entry: Dictionary = AreaBuild.item(_catalog, crate)
		if entry.is_empty() or not AreaBuild.prop_is_solid(_assets, str(entry.asset)):
			continue
		var blocked_foot: BuildLedger = _ledger(ledger.edits.duplicate(true))
		if blocked_foot.place(crate, Vector2(31, 5), "S", state).ok:
			_check(blocked_foot.check_stairs(Vector2i(32, 5), "E", state).reason == "Leave room at the foot of the stairs.", "Stairs need somewhere to stand at their foot")
			break
	var built: Dictionary = ledger.place_stairs(Vector2i(32, 5), "E", state)
	_check(built.ok and not ledger.area.stair_at(Vector2i(32, 5)).is_empty() and ledger.describe(ledger.edits[-1]) == "Built stairs", "Stairs are built: %s" % str(built.get("reason", "")))
	_check(ledger.rules.find_path(state, Vector2i(34, 6), Vector2i(31, 5)).has(Vector2i(32, 5)), "The plateau is reached by its stairs")
	_check(not ledger.check_stairs(Vector2i(32, 5), "E", state).ok, "A second flight cannot share the cell")
	var blocked: String = ledger.land_reason("lower", Vector2i(33, 5), 0, state)
	_check(blocked.contains("Stairs"), "The ground under and around stairs keeps its shape: %s" % blocked)
	# Standing on the plateau, taking the stairs away would strand the player.
	var up_there: Dictionary = _state(ledger, Vector2i(34, 6))
	var stranded: Dictionary = ledger.remove_stairs(Vector2i(32, 5), up_there)
	_check(not stranded.ok and str(stranded.reason).begins_with("That would cut you off"), "Removing the only stairs under someone on the plateau is refused: %s" % str(stranded.reason))
	var removed: Dictionary = ledger.remove_stairs(Vector2i(32, 5), state)
	_check(removed.ok and ledger.area.stair_at(Vector2i(32, 5)).is_empty() and ledger.describe(ledger.edits[-1]) == "Removed stairs", "Stairs are taken away from below")
	# Undo and redo walk the whole history back and forth.
	var count: int = ledger.edits.size()
	_check(ledger.undo(state).ok and not ledger.area.stair_at(Vector2i(32, 5)).is_empty(), "Undo puts the stairs back")
	_check(ledger.redo(state).ok and ledger.area.stair_at(Vector2i(32, 5)).is_empty() and ledger.edits.size() == count, "Redo takes them away again")
	for _step: int in range(count - before):
		ledger.undo(state)
	_check(ledger.edits.size() == before and PLATEAU.all(func(cell: Vector2i) -> bool: return ledger.area.level_at(cell) == 0), "Undoing every step flattens the meadow")
	# Raising a ring round the player strands them, so it is refused.
	var ring: Array[Vector2i] = []
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			if dx != 0 or dy != 0:
				ring.append(Vector2i(34 + dx, 9 + dy))
	var trapped: Dictionary = ledger.shape("raise", 1, _cells(ring), _state(ledger, Vector2i(34, 9)))
	_check(not trapped.ok and str(trapped.reason).begins_with("That would cut you off"), "A cliff all round the player is refused: %s" % str(trapped.reason))
	# A drag across things keeps the cells it may change and leaves the rest.
	var house: Dictionary = ledger.area.building("home")
	var under: Array[Vector2i] = AreaBuild.footprint_cells(house.rect)
	_check(ledger.land_reason("raise", under[0], 1, state) == "A building stands there.", "Ground under a house keeps its level")
	var door: Vector2i = AreaBuild.door_cell(house.rect, house.at, house.facing)
	_check(ledger.land_reason("raise", door, 1, state).contains("door"), "The ground before a door keeps its level")
	_check(ledger.land_reason("raise", ledger.area.spawn, 1, state).contains("starting"), "The starting spot keeps its level")
	_check(ledger.land_reason("raise", Vector2i(28, 3), 1, state) != "", "The player's own cell keeps its level")
	var mixed: Array[Vector2i] = [under[0], Vector2i(33, 5)]
	var partial: Dictionary = ledger.shape("raise", 1, _cells(mixed), state)
	_check(partial.ok and (ledger.edits[-1].cells as Array).size() == 1 and ledger.area.level_at(under[0]) == 0, "A stroke over a house raises only the open ground")
	ledger.undo(state)
	var tree: Dictionary = ledger.area.trees[0]
	var trunk := Vector2i(floori(tree.at.x + 0.5), floori(tree.at.y + 0.5))
	if ledger.area.in_bounds(trunk):
		_check(ledger.land_reason("raise", trunk, 1, state).contains("tree"), "Ground under a tree keeps its level")
	var lamp: Dictionary = ledger.area.lamps[0]
	_check(ledger.land_reason("raise", lamp.cell, 1, state).contains("lamp"), "Ground under a lamp keeps its level")
	var socket: Vector2i = (ledger.area.bridges[0].sockets as Array)[0]
	_check(ledger.land_reason("land", socket, 0, state).contains("bridge"), "A bridge's crossing keeps its water")
	_check(ledger.land_reason("raise", socket + Vector2i(1, 0), 1, state).contains("bridge") or ledger.land_reason("raise", socket + Vector2i(0, 1), 1, state).contains("bridge"), "A bridge's banks keep their level")
	var rock: Vector2i = Vector2i(-1, -1)
	for y: int in range(ledger.area.height):
		for x: int in range(ledger.area.width):
			if rock.x < 0 and ledger.area.terrain_at(Vector2i(x, y)) == AreaDef.Terrain.ROCK:
				rock = Vector2i(x, y)
	_check(ledger.land_reason("raise", rock, 1, state).contains("Rock"), "Rock keeps its shape")


# -------------------------------------------------------------------- water
func _water_tests() -> void:
	var ledger: BuildLedger = _ledger()
	var state: Dictionary = _state(ledger)
	var pond: Array[Vector2i] = [Vector2i(34, 9), Vector2i(35, 9)]
	var dug: Dictionary = ledger.shape("water", 0, _cells(pond), state)
	_check(dug.ok and ledger.area.terrain_at(Vector2i(34, 9)) == AreaDef.Terrain.WATER and ledger.describe(ledger.edits[-1]) == "Dug water", "Water is dug into dry ground: %s" % str(dug.get("reason", "")))
	_check(not ledger.rules.is_walkable(state, Vector2i(34, 9)), "Nobody walks on the new pond")
	_check(not ledger.shape("water", 0, _cells(pond), state).ok, "Water is not dug twice")
	var filled: Dictionary = ledger.shape("land", 0, _cells([Vector2i(34, 9)]), state)
	_check(filled.ok and ledger.area.terrain_at(Vector2i(34, 9)) == AreaDef.Terrain.GRASS and ledger.describe(ledger.edits[-1]) == "Filled in water", "Water is filled in with grass")
	_check(not ledger.shape("land", 0, _cells([Vector2i(33, 9)]), state).ok, "Dry land cannot be filled in")
	# Painted ground that turns to water loses its paint, so filling it in later shows grass, not old paint.
	var painted: BuildLedger = _ledger([{"op": "paint", "material": "dirt", "cells": [[66, 18], [67, 18], [66, 19], [67, 19]]}])
	var painted_state: Dictionary = _state(painted)
	_check(GroundPaint.override_at(painted.area, Vector2i(66, 18)) == "dirt", "The paint is there first")
	painted.shape("water", 0, _cells([Vector2i(33, 9)]), painted_state)
	_check(GroundPaint.override_at(painted.area, Vector2i(66, 18)) == "" and painted.area.warnings.is_empty(), "Digging water clears the paint under it")
	painted.shape("land", 0, _cells([Vector2i(33, 9)]), painted_state)
	_check(GroundPaint.override_at(painted.area, Vector2i(66, 18)) == "", "Filling it in again leaves natural grass")
	# A pond on a plateau runs off its edge onto a pond below: a waterfall.
	var falls: BuildLedger = _terraced()
	var falls_state: Dictionary = _state(falls)
	_check(falls.shape("water", 0, _cells([Vector2i(35, 5), Vector2i(35, 4)]), falls_state).ok, "Water is dug on the plateau")
	_check(falls.shape("water", 0, _cells([Vector2i(36, 5), Vector2i(37, 5)]), falls_state).ok, "Water is dug below the plateau")
	var drops: Array[Dictionary] = TerrainBuilder.waterfalls(falls.area)
	_check(drops.size() == 1 and drops[0].from == Vector2i(35, 5) and drops[0].to == Vector2i(36, 5) and drops[0].drop == 1, "Water stepping down a level makes one waterfall: %s" % str(drops))
	_check(falls.shape("raise", 2, _cells([Vector2i(35, 4)]), falls_state).ok, "Raised water stays water")
	_check(falls.area.terrain_at(Vector2i(35, 4)) == AreaDef.Terrain.WATER and TerrainBuilder.waterfalls(falls.area).size() == 2, "Water a level higher again falls into the pond in front of it")


# ------------------------------------------------------------------ objects
func _object_tests() -> void:
	var ledger: BuildLedger = _terraced()
	var state: Dictionary = _state(ledger)
	_check(ledger.check_item("tree-oak", Vector2(34.0, 5.0), "S", state).ok, "A tree grows on the plateau")
	_check(ledger.check_item("tree-oak", Vector2(32.5, 4.0), "S", state).reason == "Trees need level ground.", "A tree may not straddle the cliff edge")
	_check(ledger.check_item("tree-oak", Vector2(32.0, 5.0), "S", state).reason == "Stairs are in the way.", "A tree may not grow on stairs")
	var item: String = "wooden-barrel" if not AreaBuild.item(_catalog, "wooden-barrel").is_empty() else ""
	if item != "":
		_check(ledger.check_item(item, Vector2(34.0, 6.0), "S", state).ok, "A doodad stands on the plateau")
		_check(not ledger.check_item(item, Vector2(32.0, 5.0), "S", state).ok, "A doodad may not stand on stairs")
		_check(ledger.check_item(item, Vector2(32.5, 6.0), "S", state).reason == "The ground under it is not level.", "A doodad may not straddle the cliff edge")
	var lift: Dictionary = ledger.shape("raise", 1, _cells([Vector2i(33, 7), Vector2i(34, 7), Vector2i(35, 7), Vector2i(33, 8), Vector2i(34, 8), Vector2i(35, 8), Vector2i(36, 4), Vector2i(36, 5), Vector2i(36, 6), Vector2i(36, 7), Vector2i(36, 8), Vector2i(37, 4), Vector2i(37, 5), Vector2i(37, 6), Vector2i(37, 7), Vector2i(37, 8)]), state)
	_check(lift.ok, "The plateau grows: %s" % str(lift.get("reason", "")))
	var house: String = "house-hollow"
	var spot: Vector2 = Vector2(-1, -1)
	for y: int in range(5, 8):
		for x: int in range(34, 37):
			if spot.x < 0 and ledger.check_item(house, Vector2(x, y), "S", state).ok:
				spot = Vector2(x, y)
	if spot.x < 0:
		_check(ledger.check_item(house, Vector2(35, 6), "S", state).reason in ["The door needs level ground in front of it.", "The ground under it is not level."], "A house too big for the plateau says why: %s" % ledger.check_item(house, Vector2(35, 6), "S", state).reason)
	var straddling: Dictionary = ledger.check_item(house, Vector2(33, 9), "S", state)
	_check(not straddling.ok, "A house half off the plateau is refused: %s" % straddling.reason)
	# Things on another level are out of reach of F and the front door.
	var high_state: Dictionary = _state(ledger, Vector2i(34, 6))
	_check(not HouseInstances.check_enter(ledger.area, ledger.rules, high_state, "home", {"templates": {"village-cottage": "village-cottage"}, "assets": {"log-cabin-large": "village-cottage"}}).ok, "A front door cannot be used from up a cliff")


# -------------------------------------------------------------------- saves
func _save_tests() -> void:
	var ledger: BuildLedger = _terraced()
	var state: Dictionary = _state(ledger)
	ledger.shape("water", 0, _cells([Vector2i(35, 4)]), state)
	var saved: Array = JSON.parse_string(JSON.stringify(ledger.edits))
	var again: BuildLedger = _ledger(saved)
	_check(again.problems.is_empty() and again.edits.size() == ledger.edits.size(), "Terrain edits survive a save round trip")
	_check(PLATEAU.all(func(cell: Vector2i) -> bool: return again.area.level_at(cell) == 1) and again.area.stair_at(Vector2i(32, 5)).get("up") == "E" and again.area.terrain_at(Vector2i(35, 4)) == AreaDef.Terrain.WATER, "A reloaded valley has the same levels, stairs and water")
	_check(again.area.terrain == ledger.area.terrain and again.area.levels == ledger.area.levels, "The reloaded rows are identical")
	var broken: Array = saved.duplicate(true)
	broken.append({"op": "level", "level": 9, "cells": [[1, 1]]})
	broken.append({"op": "level", "level": 1, "cells": [[1, 999]]})
	broken.append({"op": "add", "kind": "stairs", "at": [32, 5], "up": "E"})
	var cleaned: BuildLedger = _ledger(broken)
	_check(cleaned.problems.size() == 3 and cleaned.edits.size() == saved.size(), "Malformed or duplicated terrain edits are skipped and reported")
	var orphan: Array = [{"op": "add", "kind": "stairs", "at": [60, 30], "up": "N"}]
	var refused: BuildLedger = _ledger(orphan)
	_check(not refused.problems.is_empty() and refused.area.stairs.is_empty(), "Saved stairs that no longer fit the valley are set aside")
	var document: Dictionary = AreaBuild.apply(_document, ledger.edits).document
	_check(_document.get("levels") == null and document.levels is Array and (document.levels as Array).size() == int(_document.size[1]), "Edits write levels to a copy; the shipped document stays as it is")


# ----------------------------------------------------------------- geometry
func _geometry_tests() -> void:
	var parsed: Dictionary = _parse(_small(["11110000", "11110000", "11110000", "00000000", "00000000", "00000000"], [{"at": [2, 2], "up": "N"}], ["........", "......~~", "......~~", "........", "........", "........"]))
	var area: AreaDef = parsed.area
	var blocks: Array = []
	TerrainBuilder.build(area, func(at: Vector3, size: Vector3, material: String, _rotation: Vector3 = Vector3.ZERO) -> void: blocks.append({"at": at, "size": size, "material": material}))
	var top := func(cell: Vector2i) -> float:
		var highest: float = -INF
		for block: Dictionary in blocks:
			if absf(block.at.x - float(cell.x)) < 0.45 and absf(block.at.z + float(cell.y)) < 0.45:
				highest = maxf(highest, block.at.y + block.size.y * 0.5)
		return highest
	var rise: float = TerrainBuilder.LEVEL_RISE
	_check(top.call(Vector2i(1, 4)) > rise - 0.1 and top.call(Vector2i(1, 4)) < rise + 0.1, "A level-1 cell's ground stands one rise up: %.2f" % top.call(Vector2i(1, 4)))
	_check(top.call(Vector2i(5, 1)) < 0.1, "A valley-floor cell stays low: %.2f" % top.call(Vector2i(5, 1)))
	var column: Array = blocks.filter(func(block: Dictionary) -> bool: return absf(block.at.x - 1.0) < 0.01 and absf(block.at.z + 4.0) < 0.01 and block.size.x > 0.99 and block.size.z > 0.99)
	var lowest: float = INF
	var spans: float = 0.0
	for block: Dictionary in column:
		lowest = minf(lowest, block.at.y - block.size.y * 0.5)
		spans += block.size.y
	_check(lowest <= TerrainBuilder.FLOOR_TOP + 0.01 and spans >= rise - 0.01, "A raised cell stands on a solid column from the valley floor up: from %.2f, %.2f tall" % [lowest, spans])
	var steps: Array = blocks.filter(func(block: Dictionary) -> bool: return absf(block.at.x - 2.0) < 0.45 and absf(block.at.z + 2.0) < 0.5 and block.at.y > 0.0)
	_check(steps.size() >= 4 and top.call(Vector2i(2, 2)) > rise - 0.05, "Stairs are drawn as steps that reach the top of the cliff")
	_check(TerrainBuilder.waterfalls(area).is_empty(), "Water on one level has no waterfall")
	var deterministic: Array = []
	TerrainBuilder.build(area, func(at: Vector3, size: Vector3, material: String, _rotation: Vector3 = Vector3.ZERO) -> void: deterministic.append({"at": at, "size": size, "material": material}))
	_check(deterministic == blocks, "The same land always draws the same blocks")


func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
