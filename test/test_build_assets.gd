extends SceneTree
## The six new scenery models through the same ledger, rule, save and undo boundary as old shelf items.

var checks: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	var assets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/world-catalog.json")).assets
	var catalog: Dictionary = AreaStore.read_build_catalog()
	var terrain: Array = []
	for y: int in range(32):
		terrain.append(".".repeat(32))
	var document: Dictionary = {"schema": 1, "id": "shelf-test", "title": "Shelf test", "version": 1, "size": [32, 32], "spawn": [1, 1], "terrain": terrain, "buildings": [], "trees": []}
	for id: String in ["hearth-house", "lantern-loft", "brook-mill", "hearth-oak", "ridge-cedar", "river-willow"]:
		var ledger := BuildLedger.new(document, assets, {}, catalog)
		var entry: Dictionary = AreaBuild.item(catalog, id)
		_check(not entry.is_empty() and entry.asset == id, id + " is selectable on the shelf")
		var state: Dictionary = ledger.rules.initial_state()
		var result: Dictionary = ledger.place(id, Vector2(12, 12), "S", state)
		_check(result.ok, id + " can be placed on suitable ground: " + str(result.get("reason")))
		_check(not ledger.rules.is_walkable(state, Vector2i(12, 12)), id + " has a logical blocking footprint")
		var restored := BuildLedger.new(document, assets, {}, catalog, JSON.parse_string(JSON.stringify(ledger.edits)))
		_check(restored.problems.is_empty(), id + " saves and reloads")
		if entry.kind == "tree":
			_check(restored.area.trees[0].asset == id and is_equal_approx(restored.area.trees[0].trunk_radius, float(assets[id].logical_footprint.trunk_radius)), id + " keeps its model and catalog trunk radius")
			_check(ledger.move_tree(Vector2(12, 12), Vector2(17, 12), state).ok and ledger.area.trees[0].asset == id, id + " keeps its appearance when moved")
			_check(ledger.remove_tree(Vector2(17, 12), state).ok and ledger.area.trees.is_empty(), id + " can be removed")
			_check(ledger.undo(state).ok and ledger.area.trees[0].asset == id, id + " returns with the same model on undo")
		else:
			_check(restored.area.buildings[0].asset == id, id + " keeps its selected model")
			_check(ledger.move_building("build-1", Vector2(20, 12), "E", state).ok and ledger.area.building("build-1").facing == "E", id + " moves and rotates")
			_check(ledger.remove_building("build-1", state).ok, id + " can be removed")
			_check(ledger.undo(state).ok and ledger.area.building("build-1").asset == id, id + " returns on undo")
		_check(ledger.undo(state).ok and ledger.undo(state).ok and ledger.edits.is_empty(), id + " undoes back to the original document")
		_check(ledger.redo(state).ok, id + " redoes its original placement")
	var bad: Dictionary = document.duplicate(true)
	bad.trees = [{"at": [3, 3], "asset": "cottage"}]
	_check(not AreaDef.parse(bad, assets).ok, "A building cannot be smuggled into a tree placement")
	bad.trees = [{"at": [3, 3], "asset": "hearth-oak", "size": -1}]
	_check(not AreaDef.parse(bad, assets).ok, "A model tree scale is validated")
	if failures.is_empty():
		print("Builder scenery: %d checks passed (six shelf assets, placement, collision, move, save, undo/redo)." % checks)
	else:
		for failure: String in failures:
			printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
