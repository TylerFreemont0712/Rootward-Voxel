class_name IllustratedEdges
extends RefCounted
## Fine sepia silhouettes for selected world models. Original surfaces and their
## imported materials stay intact. Smoothed hull normals close hard mesh corners.

const OutlineJob := preload("res://art/outline_job.gd")

static var _meshes: Dictionary = {}
static var _material: ShaderMaterial


static func apply(model: Node3D) -> void:
	for child: Node in model.get_children():
		if child is Node3D and child.name != &"IllustratedOutline":
			apply(child as Node3D)
	if not model is MeshInstance3D: return
	var instance := model as MeshInstance3D
	if not _eligible(instance): return
	var hull := _cached(instance.mesh)
	if hull == null:
		hull = _hull(instance.mesh)
		_remember(instance.mesh, hull)
		BuildPump.pump()
	_attach(instance, hull)

static func _hull(source: Mesh) -> ArrayMesh:
	var job := OutlineJob.new(source)
	while not job.done: job.advance()
	return job.result


## The same hull, in bounded chunks while a loading veil has the screen.
static func apply_async(model: Node3D) -> void:
	var instances: Array[Node] = model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D: instances.push_front(model)
	for node: Node in instances:
		var instance := node as MeshInstance3D
		if not _eligible(instance): continue
		var hull := _cached(instance.mesh)
		if hull == null:
			var job := OutlineJob.new(instance.mesh)
			while not job.done:
				job.advance()
				if not job.done: await (Engine.get_main_loop() as SceneTree).process_frame
			hull = job.result
			_remember(instance.mesh, hull)
		_attach(instance, hull)


## Live instances own their meshes. A cache must not retain an entire departed
## district's source materials/textures through strong Mesh dictionary keys.
static func _cached(source: Mesh) -> ArrayMesh:
	var key: int = source.get_instance_id()
	if not _meshes.has(key): return null
	var entry: Dictionary = _meshes[key]
	if entry.source.get_ref() == source:
		var hull := entry.hull.get_ref() as ArrayMesh
		if hull != null: return hull
	_meshes.erase(key)
	return null


static func _remember(source: Mesh, hull: ArrayMesh) -> void:
	_meshes[source.get_instance_id()] = {"source":weakref(source), "hull":weakref(hull)}


static func prune_cache() -> void:
	for key: int in _meshes.keys():
		var entry: Dictionary = _meshes[key]
		if entry.source.get_ref() == null or entry.hull.get_ref() == null: _meshes.erase(key)


static func _eligible(instance: MeshInstance3D) -> bool:
	if instance.mesh == null or instance.has_node("IllustratedOutline") or WorldAssetMeta.value(instance, "grid_inlay", false): return false
	# Authored fine metalwork and tightly nested faces can retain their modeled rims without an expanded ink hull.
	if not bool(WorldAssetMeta.value(instance, "illustrated_edges", true)): return false
	for surface: int in range(instance.mesh.get_surface_count()):
		var material := instance.get_active_material(surface) as StandardMaterial3D
		if material == null or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.emission_enabled: return false
		if "glass" in material.resource_name or "window" in material.resource_name: return false
		# Painted ground tops have no readable silhouette; hundreds of separate
		# outline hulls would double their submissions after spatial subdivision.
		if WorldAssetMeta.value(instance, "ground_chunk", false) and material.resource_name.begins_with("ground_"): return false
	return true


static func _attach(instance: MeshInstance3D, mesh: ArrayMesh) -> void:
	if mesh.get_surface_count() == 0: return
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = preload("res://art/illustrated_edges.gdshader")
	var outline := MeshInstance3D.new()
	outline.name = "IllustratedOutline"
	outline.mesh = mesh
	outline.material_override = _material
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	outline.extra_cull_margin = .05
	instance.add_child(outline)
