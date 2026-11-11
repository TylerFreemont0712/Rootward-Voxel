extends RefCounted
## Geometry comparison ignores vertex/index ordering. UVs and normals remain tied to their corners.


static func audit(root: Node3D, retain_corners: bool = false) -> Dictionary:
	var result: Dictionary = {"meshes": 0, "triangles": 0, "corners": [], "normal_samples": {}, "materials": [], "material_records": {}, "min": Vector3.INF, "max": -Vector3.INF}
	_collect(root, Transform3D.IDENTITY, result)
	result.corners.sort()
	result["geometry_sha256"] = "\n".join(result.corners).sha256_text()
	if not retain_corners:
		result.erase("corners")
		result.erase("normal_samples")
	result.materials.sort()
	result["bounds"] = [result.min.x, result.min.y, result.min.z, result.max.x, result.max.y, result.max.z]
	result.erase("min")
	result.erase("max")
	return result


static func read_glb(path: String) -> Node3D:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(path, state, GLTFDocument.IMPORT_FLAG_FORCE_DISABLE_MESH_COMPRESSION) != OK:
		return null
	return document.generate_scene(state) as Node3D


static func _collect(node: Node, parent_transform: Transform3D, result: Dictionary) -> void:
	var transform: Transform3D = parent_transform
	if node is Node3D:
		transform *= (node as Node3D).transform
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		result.meshes += 1
		for surface: int in range(instance.mesh.get_surface_count()):
			var arrays: Array = instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var count: int = indices.size() if not indices.is_empty() else vertices.size()
			result.triangles += count / 3
			for corner: int in range(count):
				var index: int = indices[corner] if not indices.is_empty() else corner
				var at: Vector3 = transform * vertices[index]
				var normal: Vector3 = (transform.basis.inverse().transposed() * normals[index]).normalized()
				var uv: Vector2 = uvs[index]
				result.min = (result.min as Vector3).min(at)
				result.max = (result.max as Vector3).max(at)
				var key: String = "%s,%s,%s|%s,%s" % [_q(at.x), _q(at.y), _q(at.z), _q(uv.x), _q(uv.y)]
				result.corners.append(key)
				if not result.normal_samples.has(key):
					result.normal_samples[key] = []
				result.normal_samples[key].append(normal)
			var material: Material = instance.get_active_material(surface)
			if material != null and not result.materials.has(material.resource_name):
				result.materials.append(material.resource_name)
				if material is StandardMaterial3D:
					var standard := material as StandardMaterial3D
					var texture_hash: String = ""
					if standard.albedo_texture != null:
						var pixels: Image = standard.albedo_texture.get_image()
						pixels.clear_mipmaps()
						pixels.convert(Image.FORMAT_RGBA8)
						var hashing := HashingContext.new()
						hashing.start(HashingContext.HASH_SHA256)
						hashing.update(pixels.get_data())
						texture_hash = hashing.finish().hex_encode()
					result.material_records[material.resource_name] = {"texture_rgba_sha256": texture_hash, "albedo": [_q(standard.albedo_color.r), _q(standard.albedo_color.g), _q(standard.albedo_color.b), _q(standard.albedo_color.a)], "roughness": _q(standard.roughness)}
	for child: Node in node.get_children():
		_collect(child, transform, result)


static func _q(number: float) -> int:
	return roundi(number * 10000.0)  # 0.0001 world unit/UV/normal precision, not a bitwise file comparison.


static func equivalent(before: Dictionary, after: Dictionary) -> bool:
	if before.geometry_sha256 != after.geometry_sha256 or before.material_records != after.material_records:
		return false
	for key: String in before.normal_samples:
		var remaining: Array = after.normal_samples.get(key, []).duplicate()
		for normal: Vector3 in before.normal_samples[key]:
			var found: int = -1
			for index: int in range(remaining.size()):
				if normal.distance_to(remaining[index]) <= 0.001:
					found = index
					break
			if found < 0:
				return false
			remaining.remove_at(found)
		if not remaining.is_empty():
			return false
	return true
