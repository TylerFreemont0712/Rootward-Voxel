extends RefCounted
## Repeated immutable barrier bays share draw submissions in local 8 m groups.
## Placement roots remain addressable; area/catalog data retain collision authority.
static func batch_barriers(parent: Node3D, area: AreaDef) -> void:
	var groups: Dictionary = {}
	var retired: Array[MeshInstance3D] = []
	for item: Dictionary in area.interior.get("assets", []):
		var id: String = str(item.asset)
		if not (id.begins_with("town-railing") or id.begins_with("town-balustrade") or id.begins_with("town-garden-wall") or id == "town-garden-pier"): continue
		var model := parent.get_node_or_null(NodePath(str(item.id))) as Node3D
		if model == null: continue
		for node: Node in model.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			if mesh.mesh == null: continue
			var transform: Transform3D = parent.global_transform.affine_inverse() * mesh.global_transform
			var chunk := Vector2i(floori(transform.origin.x / 8), floori(transform.origin.z / 8))
			var key: String = "%s|%s|%s|%s" % [mesh.mesh.get_instance_id(), mesh.material_override.get_instance_id() if mesh.material_override != null else 0, mesh.cast_shadow, chunk]
			if not groups.has(key): groups[key] = {"mesh":mesh.mesh, "material":mesh.material_override, "shadow":mesh.cast_shadow, "transforms":[]}
			groups[key].transforms.append(transform)
			retired.append(mesh)
	for group: Dictionary in groups.values():
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = group.mesh
		multi.instance_count = group.transforms.size()
		for index: int in range(multi.instance_count): multi.set_instance_transform(index, group.transforms[index])
		var batch := MultiMeshInstance3D.new()
		batch.name = "BarrierBatch%d" % parent.get_child_count()
		batch.multimesh = multi
		batch.material_override = group.material
		batch.cast_shadow = group.shadow
		parent.add_child(batch)
	for mesh: MeshInstance3D in retired:
		if is_instance_valid(mesh): mesh.free()
