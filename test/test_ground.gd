extends SceneTree
## Ground appearance never participates in the world's rules.

var checks: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validation()
	_defaults()
	_geometry()
	_history()
	if failures.is_empty():
		print("Ground: %d checks passed (documents, correlated defaults, symmetric roughening, dilation, atomic paint, rules, history, saves)." % checks)
	else:
		for failure: String in failures:
			printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)


func document(side: int = 4) -> Dictionary:
	var rows: Array = []
	for y: int in range(side):
		rows.append(".".repeat(side))
	return {"schema": 1, "id": "ground-test", "title": "Ground test", "version": 1, "size": [side, side], "terrain": rows, "spawn": [1, 1]}


func paint_block(side: int = 4) -> Dictionary:
	var rows: Array = []
	for y: int in range(side * 2):
		rows.append(".".repeat(side * 2))
	return {"version": 1, "palette": GroundPaint.DEFAULT_PALETTE.duplicate(), "roughen": 0.4, "rows": rows}


func _validation() -> void:
	var doc: Dictionary = document()
	_check(AreaDef.parse(doc, {}).ok, "Absent paint uses defaults")
	doc.paint = paint_block()
	doc.paint.rows[0] = "a......."
	var parsed: Dictionary = AreaDef.parse(doc, {})
	_check(parsed.ok, "Valid base-36 paint parses")
	_check(GroundPaint.material_at(parsed.area, Vector2i(0, 7)) == "pebbles", "Paint rows are north-up")
	for bad: Dictionary in [{"version": 2}, {"rows": []}, {"rows": ["x"]}, {"palette": ["roof"]}, {"palette": ["grass", "grass"]}, {"palette": range(37)}, {"roughen": -0.1}, {"roughen": 1.1}, {"roughen": "wet"}]:
		var changed: Dictionary = doc.duplicate(true)
		changed.paint.merge(bad, true)
		var result: Dictionary = AreaDef.parse(changed, {})
		_check(not result.ok and not result.errors.is_empty(), "Invalid paint rejected: %s" % bad)
	for glyph: String in ["?", "z", "A"]:
		var changed: Dictionary = doc.duplicate(true)
		changed.paint.rows[0] = glyph + "......."
		_check(not AreaDef.parse(changed, {}).ok, "Bad/unknown digit rejected: " + glyph)
	doc.terrain[0] = "~#.."
	doc.paint.rows[0] = "0000...."
	parsed = AreaDef.parse(doc, {})
	_check(parsed.ok and parsed.warnings.size() == 4, "Paint on water/rock warns instead of failing")
	_check(GroundPaint.override_at(parsed.area, Vector2i(0, 7)) == "", "Non-ground overrides are ignored")
	var textures: Dictionary = WorldTextures.catalog().materials
	for id: String in GroundPaint.DEFAULT_PALETTE:
		_check(textures.has(id) and textures[id].get("ground", false), "Schema material is a catalog ground picture: " + id)


func _defaults() -> void:
	var area: AreaDef = AreaDef.parse(document(32), {}).area
	var first: PackedByteArray = GroundPaint.control(area)
	_check(first == GroundPaint.control(area), "Default map is deterministic")
	var adjacent: int = 0
	var distant: int = 0
	var count: int = 0
	for y: int in range(64):
		for x: int in range(48):
			count += 1
			adjacent += int(first[y * 64 + x] != first[y * 64 + x + 1])
			distant += int(first[y * 64 + x] != first[y * 64 + x + 16])
	_check(adjacent * 3 < distant and distant > 0, "Tone changes are spatially correlated: %d near, %d distant / %d" % [adjacent, distant, count])
	var doc: Dictionary = document(16)
	for y: int in range(16):
		doc.terrain[y] = "........,,,,,,,,"
	doc.paint = paint_block(16)
	doc.paint.roughen = 1.0
	area = AreaDef.parse(doc, {}).area
	var flips: int = 0
	for y: int in range(32):
		for x: int in range(32):
			var sub := Vector2i(x, y)
			if GroundPaint.family(GroundPaint.material_at(area, sub)) != GroundPaint.terrain_family(area.terrain_at(Vector2i(x / 2, y / 2))):
				flips += 1
				_check(x == 15 or x == 16, "Roughening stays within one sub-tile of the family boundary")
	_check(flips > 8 and flips < 55, "Roughening has a useful deterministic probability: %d / 64" % flips)
	for y: int in range(32):
		var a := Vector2i(15, y)
		var b := Vector2i(16, y)
		_check(GroundPaint.edge_hash(a, b) == GroundPaint.edge_hash(b, a), "Edge hash is symmetric")
	doc.terrain[7] = ".......~#,,,,,,,"
	area = AreaDef.parse(doc, {}).area
	for sub: Vector2i in [Vector2i(13, 16), Vector2i(13, 17), Vector2i(18, 16), Vector2i(18, 17)]:
		_check(GroundPaint.material_at(area, sub) == GroundPaint.derived(area, sub, false), "No roughening beside water or rock")
	doc = document()
	doc.terrain = ["~~~~", "~~~~", "~.~~", "~~~~"]
	doc.spawn = [1, 1]
	area = AreaDef.parse(doc, {}).area
	var control: PackedByteArray = GroundPaint.control(area)
	_check(control.size() == 64 and not control.has(255), "Non-ground control texels are filled by nearest-ground dilation")
	_check(control[0] == control[2 * 8 + 2], "Dilation extends the nearest ground material")


func _geometry() -> void:
	var source: Dictionary = AreaStore.read_source("kindle-hollow")
	var area: AreaDef = AreaDef.parse(source.document, source.assets, source.quests).area
	var legacy: Array = []
	var current: Array = []
	TerrainBuilder.build(area, func(at: Vector3, size: Vector3, id: String, rotation: Vector3 = Vector3.ZERO) -> void:
		if not ((id.begins_with("grass") or id.begins_with("dirt") or id.begins_with("path")) and size.y <= 0.061):
			legacy.append([at, size, id, rotation]))
	TerrainBuilder.build(area, func(at: Vector3, size: Vector3, id: String, rotation: Vector3 = Vector3.ZERO) -> void:
		current.append([at, size, id, rotation]), true)
	_check(current == legacy, "Soil sides, banks, water, rocks, walls and fences exactly preserve their previous geometry/materials")
	_check(not AreaStore.load_area("rune-mill").ground.is_empty(), "Rune Mill retains its authored ground model")


func _history() -> void:
	var doc: Dictionary = document()
	doc.terrain[0] = "~#.."
	var ledger := BuildLedger.new(doc, {}, {}, {})
	var state: Dictionary = ledger.rules.initial_state()
	var before: LabWorld = ledger.rules
	var rule_snapshot: Dictionary = _rules_snapshot(before, state)
	var original: PackedByteArray = GroundPaint.control(ledger.area)
	var edit: Dictionary = ledger.paint("dirt", [[2, 2], [3, 2], [2, 3], [3, 3], [0, 7]], state)
	_check(edit.ok and ledger.edits.size() == 1, "One stroke is one compact edit")
	_check(ledger.edits[0].cells.size() == 4, "Water cells are omitted from a stroke")
	_check(ledger.rules == before, "Paint keeps the rules and their navigation cache (no flood/rebuild)")
	_check(ledger.describe(ledger.edits[0]) == "Painted dirt", "Paint has a useful history label")
	_check(GroundPaint.material_at(ledger.area, Vector2i(2, 2)) == "dirt", "Paint overrides the default")
	_check(not doc.has("paint"), "Painting never rewrites the source document")
	_check(rule_snapshot == _rules_snapshot(LabWorld.new(ledger.area), state), "Every walkability and path result is identical after painting a whole cell (independently rebuilt rules)")
	var saved: Array = JSON.parse_string(JSON.stringify(ledger.edits))
	var restored := BuildLedger.new(doc, {}, {}, {}, saved)
	_check(GroundPaint.control(restored.area) == GroundPaint.control(ledger.area), "Paint survives a JSON/save round trip")
	_check(ledger.undo(state).ok and GroundPaint.control(ledger.area) == original and ledger.rules == before, "Undo restores defaults without touching rules")
	_check(ledger.redo(state).ok and GroundPaint.material_at(ledger.area, Vector2i(2, 2)) == "dirt" and ledger.rules == before, "Redo restores the whole stroke without touching rules")
	_check(ledger.paint("", [[2, 2], [3, 2], [2, 3], [3, 3]], state).ok and GroundPaint.control(ledger.area) == original, "Eraser restores derived defaults")
	for bad: Dictionary in [{"op": "paint", "material": "roof", "cells": [[2, 2]]}, {"op": "paint", "material": "dirt", "cells": [[2, 2], [2.5, 3]]}, {"op": "paint", "material": "dirt", "cells": [[2, 2], [-1, 0]]}]:
		var applied: Dictionary = AreaBuild.apply(doc, [bad])
		_check(applied.skipped.size() == 1 and applied.document == doc, "Invalid stroke is rejected atomically")
	_check(not ledger.paint("dirt", [[0, 7]], state).ok, "An all-water stroke reports no paintable ground")


func _rules_snapshot(rules: LabWorld, state: Dictionary) -> Dictionary:
	var walkable: Array = []
	var paths: Array = []
	for y: int in range(4):
		for x: int in range(4):
			var cell := Vector2i(x, y)
			walkable.append(rules.is_walkable(state, cell))
			for ty: int in range(4):
				for tx: int in range(4):
					paths.append(rules.find_path(state, cell, Vector2i(tx, ty)))
	return {"walkable": walkable, "paths": paths}


func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
