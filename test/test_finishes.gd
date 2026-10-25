extends SceneTree
## Texture source/output contracts, declared material slots, cosmetic edit validation and saved history.

const Assets := preload("res://art/world_assets.gd")
var checks: int = 0
var failures: Array[String] = []
var assets: Dictionary
var build: Dictionary


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	assets = JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/world-catalog.json")).assets
	build = AreaStore.read_build_catalog()
	_textures()
	_rules()
	_models()
	if failures.is_empty():
		print("Surface finishes: %d checks passed (15 textures, seam/import/source contracts, semantic slots, cosmetic rules and saved history)." % checks)
	else:
		for failure: String in failures: printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)


func _textures() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/source/world/textures/v2-detail/library.json"))
	var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/source/world/textures/v2-detail/generation.json"))
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/textures/detail-library.json"))
	_check(spec.materials.size() == 15 and manifest.materials.size() == 15,"Fifteen distinct material paintings are selected")
	_check(FileAccess.get_sha256("res://art/source/world/textures/v2-detail/library.json") == record.library_sha256,"Exact design and prompt set preserved")
	var hashes: Dictionary = {}
	for item: Dictionary in record.materials:
		_check(FileAccess.get_sha256("res://"+str(item.source)) == item.sha256 and not hashes.has(item.sha256),"Unique preserved native painting: "+str(item.id))
		hashes[item.sha256] = true
		var recipe: Dictionary = WorldTextures.entry(str(item.id))
		_check(recipe.texture == item.id and float(recipe.tile)>0 and float(recipe.roughness)>0,"Shared recipe defines a usable material scale: "+str(item.id))
		var offered: bool = false
		for options: Array in SurfaceFinishes.OPTIONS.values():offered = offered or options.has(item.id)
		_check(offered,"The material is actually offered by a finish capability")
		for style: String in ["solid","lush"]:
			var output: Dictionary = manifest.materials[item.id].outputs[style]
			_check(FileAccess.get_sha256(output.path) == output.sha256,"Runtime output matches its manifest: "+str(item.id)+"/"+style)
			var image := Image.load_from_file(ProjectSettings.globalize_path(output.path))
			_check(image.get_size() == Vector2i(128,128) and image.detect_alpha() == Image.ALPHA_NONE,"Opaque 128px world tile")
			var periodic: bool = true
			for i: int in range(128):periodic = periodic and image.get_pixel(0,i) == image.get_pixel(127,i) and image.get_pixel(i,0) == image.get_pixel(i,127)
			_check(periodic,"Opposite boundary pixels match: "+str(item.id)+"/"+style)
			var imported := ConfigFile.new()
			imported.load(str(output.path)+".import")
			_check(imported.get_value("params","mipmaps/generate") and imported.get_value("params","compress/mode") == 0,"Lossless mipmapped world import")
	for id: String in assets:
		var spec_asset: Dictionary = assets[id]
		if not spec_asset.has("finish_slots"):continue
		var manifest_path: String = "res://"+str(spec_asset.runtime).get_base_dir()+"/manifest.json"
		var names: Array = JSON.parse_string(FileAccess.get_file_as_string(manifest_path)).audit.materials
		var used: Array = []
		for slot: String in spec_asset.finish_slots:
			_check(SurfaceFinishes.OPTIONS.has(slot),"The declared role is supported: "+id+"/"+slot)
			for name: String in spec_asset.finish_slots[slot]:
				_check(name in names and name not in used and name not in ["state_glow","state_flame","lamp_glass","lit","glow"],"Real, distinct, non-mechanism material binding: "+id+"/"+name)
				used.append(name)


func _document() -> Dictionary:
	var rows: Array = []
	for _row: int in range(24): rows.append(".".repeat(24))
	return {"schema":1,"id":"finish-test","title":"Finishes","version":1,"size":[24,24],"spawn":[1,1],"terrain":rows,"buildings":[{"id":"home","asset":"cottage","at":[8,8]}],"props":[{"id":"chair","asset":"hollow-highback-armchair","at":[18,8]}]}


func _rules() -> void:
	var document: Dictionary = _document()
	var original: Dictionary = document.duplicate(true)
	var ledger := BuildLedger.new(document,assets,{},build)
	var state: Dictionary = ledger.rules.initial_state()
	var original_rules: LabWorld = ledger.rules
	var route: Array = ledger.rules.find_path(state,Vector2i(4,4))
	_check(ledger.finish("building","home","roof","slate_shingles",state).ok,"A house roof can receive a finish")
	_check(ledger.area.building("home").finishes.roof == "slate_shingles" and ledger.rules == original_rules,"Cosmetic changes preserve the rule/cache instance")
	_check(ledger.rules.find_path(state,Vector2i(4,4)) == route and document == original,"Routes and authored source stay unchanged")
	_check(ledger.finish("prop","chair","fabric","tooled_leather",state).ok,"Props have their own supported material parts")
	var kept: Array = ledger.edits.duplicate(true)
	for request: Array in [["building","missing","roof","slate_shingles"],["building","home","node_path","slate_shingles"],["building","home","roof","sage_wallpaper"],["tree","home","roof","slate_shingles"],["room","","floor","terracotta_tile"]]:
		var answer: Dictionary = ledger.finish(request[0],request[1],request[2],request[3],state)
		_check(not answer.ok and answer.reason != "" and ledger.edits == kept,"Unsupported target, part or material is refused without partial edits")
	_check(ledger.undo(state).ok and ledger.area.prop("chair").finishes.is_empty() and ledger.redo(state).ok,"Finish undo/redo restores the selected part")
	var restored := BuildLedger.new(document,assets,{},build,JSON.parse_string(JSON.stringify(ledger.edits)))
	_check(restored.problems.is_empty() and restored.area.prop("chair").finishes.fabric == "tooled_leather","Finish edits round-trip through saved JSON")
	_check(ledger.move_building("home",Vector2(8,15),"E",state).ok and ledger.area.building("home").finishes.roof == "slate_shingles","Moving/turning preserves finishes")
	_check(ledger.finish("building","home","roof","",state).ok and ledger.area.building("home").finishes.is_empty(),"Original removes only the explicit override")
	var malformed: Dictionary = document.duplicate(true)
	malformed.buildings[0].finishes = {"roof":"engine_material"}
	_check(not AreaDef.parse(malformed,assets).ok,"Unknown saved material ids fail the data boundary")
	var extra: Dictionary = {"op":"finish","kind":"building","id":"home","slot":"roof","material":"slate_shingles","node_path":"Mesh"}
	_check(AreaBuild.apply(document,[extra]).skipped.size() == 1,"An edit cannot smuggle renderer paths")
	var room_source: Dictionary = AreaStore.read_source("village-cottage")
	var room := BuildLedger.new(room_source.document,assets,{},build)
	var room_state: Dictionary = room.rules.initial_state()
	var room_rules: LabWorld = room.rules
	_check(room.finish("room","","floor","terracotta_tile",room_state).ok and room.area.interior.finishes.floor == "terracotta_tile","A room's floor is a separate cosmetic capability")
	_check(room.rules == room_rules and room.area.interior.furniture == AreaDef.parse(room_source.document,assets).area.interior.furniture,"Room finishing preserves furniture and walking rules")
	_check(room.undo(room_state).ok and room.area.interior.get("finishes",{}).is_empty(),"Room undo restores its authored palette")
	var legacy: Dictionary = room_source.document.duplicate(true)
	legacy.interior.erase("materials")
	_check(AreaDef.parse(legacy,assets).ok,"Legacy rooms without material palettes still load")


func _models() -> void:
	for pair: Array in [["log-cabin-large","roof","slate_shingles"],["hearth-house","walls","red_brick"],["hollow-highback-armchair","fabric","violet_quilt"],["hollow-wayfarers-chest","metal","copper_patina"]]:
		var model: Node3D = Assets.instantiate(pair[0])
		var second: Node3D = Assets.instantiate(pair[0])
		root.add_child(model)
		root.add_child(second)
		FinishMaterials.apply(model,assets[pair[0]],{pair[1]:pair[2]})
		_check(_overrides(model)>0 and _overrides(second)==0,"The actual model changes without recoloring another instance: "+str(pair[0]))
		model.free()
		second.free()


func _overrides(node: Node) -> int:
	var count: int = 0
	if node is MeshInstance3D:
		for i: int in range(node.mesh.get_surface_count()):
			var material: Material = node.get_surface_override_material(i)
			if material != null and material.resource_name.begins_with("finish:"):count += 1
	for child: Node in node.get_children():count += _overrides(child)
	return count


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:failures.append(label)
