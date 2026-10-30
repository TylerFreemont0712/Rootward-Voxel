extends SceneTree
## Every new object through the real catalog/ledger/save boundary, plus the pure interaction and WASI contract.

const Assets := preload("res://art/world_assets.gd")
var checks: int = 0
var failures: Array[String] = []
var assets: Dictionary
var catalog: Dictionary
var specs: Array


func _initialize() -> void:
	_run.call_deferred()


func _document() -> Dictionary:
	var terrain: Array = []
	for _row: int in range(24):
		terrain.append(".".repeat(24))
	return {"schema": 1, "id": "library-test", "title": "Library test", "version": 1, "size": [24,24], "spawn": [1,1], "terrain": terrain,
		"zones": [{"id":"home","title":"Home","rect":[0,0,12,24]}, {"id":"far","title":"Far","rect":[12,0,12,24]}]}


func _run() -> void:
	assets = JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/world-catalog.json")).assets
	catalog = AreaStore.read_build_catalog()
	var historical: Array = JSON.parse_string(FileAccess.get_file_as_string("res://art/source/world/village-library/v1/library.json")).assets
	specs = historical.filter(func(spec: Dictionary) -> bool: return not AreaBuild.item(catalog, str(spec.id)).is_empty())
	_check(specs.size() == 42, "The retained library offers 42 distinct objects")
	var names: Dictionary = {}
	var interactive: int = 0
	for spec: Dictionary in specs:
		var id: String = spec.id
		_check(not names.has(id), "Unique library identity: " + id)
		names[id] = true
		var item: Dictionary = AreaBuild.item(catalog, id)
		_check(not item.is_empty() and item.kind == "prop" and item.asset == id and item.category == spec.category, "The real shelf offers " + id)
		_check(FileAccess.file_exists("res://" + str(assets[id].source)) and FileAccess.file_exists("res://" + str(assets[id].runtime)), "Editable source and runtime exist: " + id)
		var ledger := BuildLedger.new(_document(), assets, {}, catalog)
		var state: Dictionary = ledger.rules.initial_state()
		var placed: Dictionary = ledger.place(id, Vector2(7,7), "S", state)
		_check(placed.ok, "Place " + id + ": " + str(placed.get("reason")))
		if not placed.ok:
			continue
		var prop_id: String = placed.edit.id
		_check(not ledger.rules.is_walkable(state, Vector2i(7,7)), "Its declared body blocks the player: " + id)
		_check(ledger.place(id, Vector2(17,7), "W", state).ok and ledger.area.props.size() == 2, "A second rotated instance works: " + id)
		var restored := BuildLedger.new(_document(), assets, {}, catalog, JSON.parse_string(JSON.stringify(ledger.edits)))
		_check(restored.problems.is_empty() and restored.area.prop(prop_id).asset == id, "Save/restore keeps the selected asset: " + id)
		_check(ledger.move_prop(prop_id, Vector2(7,13), "E", state).ok and ledger.area.prop(prop_id).facing == "E", "Move and turn " + id)
		_check(ledger.remove_prop(prop_id, state).ok and ledger.undo(state).ok and ledger.area.prop(prop_id).asset == id, "Delete/undo preserves " + id)
		var model: Node3D = Assets.instantiate(id)
		_check(model != null, "The selected GLB loads without a fallback: " + id)
		if model == null:
			continue
		root.add_child(model)
		if not (spec.interaction as Dictionary).is_empty():
			interactive += 1
			var visual := PropVisual.new()
			model.add_child(visual)
			visual.setup(model, spec.interaction)
			_check(visual.mechanism != null if spec.interaction.kind != "light" else not (visual._glows.is_empty() and visual._flames.is_empty()), "Authored pivot/material contract: " + id)
			visual.set_active(true, true)
			visual._process(0.25)
			_check(visual.active and (visual.mechanism.rotation != Vector3.ZERO if visual.mechanism != null else visual._light != null and visual._light.visible), "The real model presents an active state: " + id)
			visual.set_active(false, true)
			_check(not visual.active and (visual._light == null or not visual._light.visible), "It can be deactivated: " + id)
		model.free()
	_check(interactive == 14, "Fourteen retained objects have declared working interactions")
	_pure_interactions()
	_sandbox()
	if failures.is_empty():
		print("Builder library: %d checks passed (42 retained models, ledger, state, interaction, discovery and real WASI)." % checks)
	else:
		for failure: String in failures:
			printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)


func _interactive_area() -> AreaDef:
	var document: Dictionary = _document()
	document.props = [{"id":"near","asset":"hollow-brass-lever","at":[7,7]}, {"id":"far","asset":"hollow-shard-lantern","at":[17,7]},
		{"id":"decoration","asset":"hollow-highback-armchair","at":[7,12]}]
	return AreaDef.parse(document, assets).area


func _command(id: String, value: Variant) -> Dictionary:
	return {"op":"set_field","entity_id":id,"field":"active","value":value}


func _pure_interactions() -> void:
	var area: AreaDef = _interactive_area()
	var rules := LabWorld.new(area)
	var state: Dictionary = rules.initial_state()
	_check(rules.snapshot(state).props.size() == 1 and rules.snapshot(state).props[0].id == "near", "Snapshots reveal only interactive props in visited places")
	var changed: Dictionary = rules.propose(state, [_command("near",true)], {"a":1})
	_check(changed.ok and changed.state.props.near and state.props.is_empty(), "A typed command proposes a detached boolean change")
	_check(not rules.propose(state, [_command("near",1)], {}).ok, "Numeric truthiness is rejected")
	_check(not rules.propose(state, [_command("decoration",true)], {}).ok and not rules.propose(state, [_command("unknown",true)], {}).ok, "Decorative and unknown objects cannot gain capabilities")
	var atomic: Dictionary = rules.propose(state, [_command("near",true), _command("far",true)], {})
	_check(not atomic.ok and atomic.state == state, "A hidden target rejects the entire batch atomically")
	var extra: Dictionary = _command("near",true)
	extra["path"] = "mesh"
	_check(not rules.propose(state,[extra],{}).ok, "Commands never accept a NodePath or extra renderer fields")
	_check(not rules.is_walkable(state,Vector2i(7,7)) and not rules.is_walkable(changed.state,Vector2i(7,7)), "The active visual cannot change the declared footprint")
	_check(rules.normalize_state(JSON.parse_string(JSON.stringify(changed.state))).props.near, "Working state survives a JSON save")
	var legacy: Dictionary = state.duplicate(true)
	legacy.erase("props")
	_check(not rules.normalize_state(legacy).is_empty(), "Older saves without prop state remain valid")
	var malformed: Dictionary = changed.state.duplicate(true)
	malformed.props.near = 1
	_check(rules.normalize_state(malformed).is_empty(), "Invalid saved prop booleans are refused")
	var undo: Dictionary = rules.revert(changed.state,state)
	_check(undo.ok and not undo.state.props.get("near",false), "Program undo restores interactive state")
	state.player = [6,7,0]
	_check(PropInteractions.can_use(rules,state,"near").ok, "A nearby reachable object can be used by hand")
	_check(not PropInteractions.can_use(rules,state,"far").ok, "F interactions have a bounded range")
	var blocked: Dictionary = _document()
	blocked.props = [{"id":"near","asset":"hollow-brass-lever","at":[7,7]}]
	blocked.segments = [{"kind":"wall","from":[6.5,6],"to":[6.5,8]}]
	var wall_rules := LabWorld.new(AreaDef.parse(blocked,assets).area)
	_check(not PropInteractions.can_use(wall_rules,state,"near").ok, "A wall blocks reaching an interactive object")
	var bad_assets: Dictionary = assets.duplicate(true)
	bad_assets["hollow-brass-lever"].interaction.kind = "execute_engine_code"
	_check(not AreaDef.parse(blocked,bad_assets).ok, "Unknown interaction kinds are rejected at the data boundary")
	_check(ApiReference.infer_type("thing = world.prop('near')\n", "thing") == "Prop", "The notebook knows the new object's API type")


func _sandbox() -> void:
	var rules := LabWorld.new(_interactive_area())
	var state: Dictionary = rules.initial_state()
	var source: String = "def program(world):\n    lever = world.prop('near')\n    lever.set_active(True)\n    world.memory['active'] = lever.active\n    world.memory['count'] = len(world.here.props)\n"
	var answer: Dictionary = LabProgram.run(source,rules.snapshot(state))
	_check(answer.ok, "Prop code runs in the real Python/WASI sandbox: " + str(answer.reason))
	if answer.ok:
		var proposal: Dictionary = rules.propose(state,answer.commands,answer.memory)
		_check(proposal.ok and proposal.state.props.near and proposal.state.memory.active and proposal.state.memory.count == 1, "Real Python uses the typed capability and zone collection")
	var hidden: Dictionary = LabProgram.run("def program(world):\n    world.prop('far').set_active(True)\n", rules.snapshot(state))
	_check(not hidden.ok and hidden.reason.contains("far"), "WASI cannot fetch an object in an unvisited place")
	var wrong: Dictionary = LabProgram.run("def program(world):\n    world.prop('near').set_active(1)\n", rules.snapshot(state))
	_check(not wrong.ok and wrong.reason.contains("True or False"), "The Python adapter explains a wrong boolean type")


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
