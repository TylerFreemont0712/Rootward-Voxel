class_name IllustratedEdges
extends RefCounted
## Fine sepia silhouettes for selected world models. Original surfaces and their
## imported materials stay intact. Smoothed hull normals close hard mesh corners.

static var _meshes: Dictionary = {}
static var _material: ShaderMaterial


static func apply(model: Node3D) -> void:
	for child: Node in model.get_children():
		if child is Node3D and child.name != &"IllustratedOutline":
			apply(child as Node3D)
	if not model is MeshInstance3D or model.has_node("IllustratedOutline"):
		return
	var instance := model as MeshInstance3D
	# Recessed conduit frames already have narrow authored edges; an expanded
	# silhouette hull would cover their inset glass and the neighboring paving.
	if WorldAssetMeta.value(instance, "grid_inlay", false):
		return
	if instance.mesh == null:
		return
	# Light panes and effects keep clear interiors. The dark cage supplies their ink.
	for surface: int in range(instance.mesh.get_surface_count()):
		var material := instance.get_active_material(surface) as StandardMaterial3D
		if material == null or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.emission_enabled:
			return
		if "glass" in material.resource_name or "window" in material.resource_name:
			return
	if not _meshes.has(instance.mesh):
		_meshes[instance.mesh] = _hull(instance.mesh)
		BuildPump.pump()
	var mesh: ArrayMesh = _meshes[instance.mesh]
	if mesh.get_surface_count() == 0:
		return
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = preload("res://art/illustrated_edges.gdshader")
	var outline := MeshInstance3D.new()
	outline.name = "IllustratedOutline"
	outline.mesh = mesh
	outline.material_override = _material
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	outline.extra_cull_margin = 0.05
	instance.add_child(outline)


static func _hull(source: Mesh) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var sums: Dictionary = {}
	for surface: int in range(source.get_surface_count()):
		if source is ArrayMesh and (source as ArrayMesh).surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays: Array = source.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var directions: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var elements: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var offset: int = vertices.size()
		for i: int in range(points.size()):
			var key: Vector3 = points[i].snapped(Vector3.ONE * 0.0001)
			sums[key] = (sums.get(key, Vector3.ZERO) as Vector3) + directions[i]
		vertices.append_array(points)
		if elements.is_empty():
			for i: int in range(points.size()):
				indices.append(offset + i)
		else:
			for index: int in elements:
				indices.append(offset + index)
	for point: Vector3 in vertices:
		normals.append((sums[point.snapped(Vector3.ONE * 0.0001)] as Vector3).normalized())
	var hull := ArrayMesh.new()
	if not vertices.is_empty():
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_INDEX] = indices
		var uv := PackedVector2Array()
		uv.resize(vertices.size())
		arrays[Mesh.ARRAY_TEX_UV] = uv
		hull.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return hull
