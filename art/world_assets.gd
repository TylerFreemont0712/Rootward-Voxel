extends RefCounted
## Rendering-only asset selection. Logical footprints come from the world catalog and the area documents; core/ owns traversal.

const CATALOG: String = "res://pipeline/world-catalog.json"
## Scoped to an incremental build; ordinary showcase reloads still read the current catalog.
static var _build_catalog: Dictionary = {}
static var _prepared: Dictionary = {}
static var _story_atlases: Dictionary = {}
static var _catalog_cache: Dictionary = {}
static var _catalog_stamp: int = -1


static func _catalog() -> Dictionary:
	if not _build_catalog.is_empty(): return _build_catalog
	var stamp: int = FileAccess.get_modified_time(CATALOG)
	if _catalog_cache.is_empty() or stamp != _catalog_stamp:
		_catalog_cache = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
		_catalog_stamp = stamp
	return _catalog_cache


static func entry(id: String) -> Dictionary:
	var catalog: Dictionary = _catalog()
	return catalog.assets.get(id, {})


static func is_blender(id: String) -> bool:
	return entry(id).get("authority", "procedural_test") == "blender"


static func area_presentation(id: String) -> Dictionary:
	var catalog: Dictionary = _catalog()
	return (catalog.get("areas", {}).get(id, {}) as Dictionary).get("presentation", {})


## `variant` dresses a modular house (see HouseVariants); such a house always shows one complete look, the authored
## one when no variant is given.
static func instantiate(id: String,cache_mode: int=ResourceLoader.CACHE_MODE_REUSE,variant: Dictionary={},trim_hidden: bool=false) -> Node3D:
	return _instantiate(id, cache_mode, variant, true, trim_hidden)


static func instantiate_async(id: String, variant: Dictionary = {}, trim_hidden: bool = false) -> Node3D:
	var model: Node3D = _instantiate(id, ResourceLoader.CACHE_MODE_REUSE, variant, false, trim_hidden)
	if model != null and entry(id).get("illustrated_edges", false): await IllustratedEdges.apply_async(model)
	return model


static func _instantiate(id: String, cache_mode: int, variant: Dictionary, outline: bool, trim_hidden: bool = false) -> Node3D:
	var spec: Dictionary = entry(id)
	var path: String = "res://" + str(spec.get("runtime", ""))
	if not ResourceLoader.exists(path):
		push_error("Selected Blender asset missing: " + path + ". Build it with scripts/world-art.sh.")
		return null
	var scene: PackedScene = ResourceLoader.load(path,"PackedScene",cache_mode) as PackedScene
	var model: Node3D=scene.instantiate() as Node3D if scene != null else null
	if model != null and HouseVariants.offers(spec):
		HouseVariants.apply(model, spec, variant)
		if trim_hidden: HouseVariants.discard_hidden(model)
	if model != null and outline and spec.get("illustrated_edges", false):
		IllustratedEdges.apply(model)
	if model != null:
		light_power(model)
	if model != null and spec.get("spark_blink",false):
		var blink:=RobotBlink.new()
		blink.name="SparkBlink"
		blink.setup(model)
		model.add_child(blink)
	if model != null and not spec.get("casts_shadow", true):
		_stop_casting(model)
	return model


## The city's power: any part flagged `power_grid` (conduit glass), `power_column` (a pillar's glowing shaft) or
## `power_pillar` (the older carved pilasters) gets its moving-light shader. Presentation only.
static func light_power(model: Node) -> void:
	var glow: ShaderMaterial = null
	var column: ShaderMaterial = null
	for part: Node in model.find_children("*", "MeshInstance3D", true, false):
		if WorldAssetMeta.value(part, "power_grid", false):
			if glow == null:
				glow = ShaderMaterial.new()
				glow.shader = load("res://art/power_grid.gdshader")
			(part as MeshInstance3D).material_override = glow
		elif WorldAssetMeta.value(part, "power_column", false):
			if column == null:
				column = ShaderMaterial.new()
				column.shader = load("res://art/power_column.gdshader")
			(part as MeshInstance3D).material_override = column
		elif WorldAssetMeta.value(part, "power_pillar", false):
			var pillar := ShaderMaterial.new()
			pillar.shader = load("res://art/power_pillar.gdshader")
			var stone := (part as MeshInstance3D).mesh.surface_get_material(0) as StandardMaterial3D
			if stone != null:
				pillar.set_shader_parameter("stone_texture", stone.albedo_texture)
			(part as MeshInstance3D).material_override = pillar


## A rug is a hand's breadth thick and lies on the floor, which casts nothing either. Letting it cast makes its own
## surface fight the shadow map, which shows as a hatched shadow on the weave that grows as the view pulls back.
static func _stop_casting(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_stop_casting(child)


## ResourceLoader owns background IO; scene nodes and materials are constructed only on the main thread.
static func prepare_area(area: AreaDef, character_skin: String = "") -> void:
	_build_catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	var ids: Array[String] = []
	var paths: Dictionary = {}
	var presentation: Dictionary = area_presentation(area.id).get("assets", {})
	if area.interior.has("shell"): ids.append(str(area.interior.shell))
	for item: Dictionary in area.interior.get("assets", []): ids.append(str(item.asset))
	for id: String in ids:
		var chosen: String = str(presentation.get(id, id))
		var asset: Dictionary = entry(chosen)
		if asset.has("runtime"): paths["res://" + str(asset.runtime)] = true
	if area.villagers.any(func(person: Dictionary) -> bool: return person.has("phantom")):
		for profile: Dictionary in PhantomActor.library().profiles.values(): paths[str(profile.frames)] = true
	var library: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/library.json"))
	# Keep the outgoing traveller's template and atlas alive across the swap. Otherwise
	# freeing the old scene drops the final reference and _make_player reloads the large
	# texture synchronously just as the veil is about to open.
	paths[str(library.template.frames)] = true
	var selected: String = str(library.active) if character_skin.is_empty() else character_skin
	if library.skins.has(selected): paths[str(library.skins[selected].atlas)] = true
	for person: Dictionary in area.villagers:
		if person.has("skin") and library.skins.has(person.skin): paths[str(library.skins[person.skin].atlas)] = true
	for id: String in ["braum","iona"]:
		var actor: Dictionary=area.interior.get("welcome",{}).get(id,{})
		if actor.has("skin") and library.skins.has(actor.skin):
			var atlas: String=str(library.skins[actor.skin].atlas)
			paths[atlas]=true
	# The dummy renderer does not support threaded texture initialization. Headless
	# checks use the same resources and placement path with synchronous resource reads.
	if DisplayServer.get_name() == "headless":
		for path: String in paths:
			_prepared[path] = ResourceLoader.load(path)
			await (Engine.get_main_loop() as SceneTree).process_frame
		return
	for path: String in paths:
		if not ResourceLoader.exists(path):
			push_error("Selected area resource is missing: " + path)
			continue
		ResourceLoader.load_threaded_request(path)
	var pending: Array = paths.keys()
	while not pending.is_empty():
		for index: int in range(pending.size() - 1, -1, -1):
			var path: String = str(pending[index])
			var status: int = ResourceLoader.load_threaded_get_status(path)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				_prepared[path] = ResourceLoader.load_threaded_get(path)
				pending.remove_at(index)
			elif status in [ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:
				push_error("Area resource could not be prepared: " + path)
				pending.remove_at(index)
		if not pending.is_empty(): await (Engine.get_main_loop() as SceneTree).process_frame


static func finish_area() -> void:
	_build_catalog.clear()
	_prepared.clear()
	_story_atlases.clear()
	IllustratedEdges.prune_cache()
	preload("res://art/frame_skin.gd").prune_cache()
	HouseVariants.prune_cache()
