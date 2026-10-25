class_name FinishMaterials
extends RefCounted
## Explicit saved material overrides, applied only to the asset's declared semantic slots.

const Surfaces := preload("res://art/surface_materials.gd")


static func apply(model: Node3D, asset: Dictionary, finishes: Dictionary) -> void:
	if finishes.is_empty():
		return
	var replacements: Dictionary = {}
	for slot: String in finishes:
		for material_name: String in (asset.get("finish_slots", {}) as Dictionary).get(slot, []):
			replacements[material_name] = str(finishes[slot])
	_apply_node(model, replacements)


static func _apply_node(node: Node, replacements: Dictionary) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		for index: int in range(mesh.mesh.get_surface_count() if mesh.mesh != null else 0):
			var original: Material = mesh.get_active_material(index)
			if original == null or not replacements.has(original.resource_name):
				continue
			var id: String = replacements[original.resource_name]
			var material: StandardMaterial3D = Surfaces.painted(id, Color.WHITE, false)
			var shade: float = 0.82 if original.resource_name.ends_with("_dark") else (1.08 if original.resource_name.ends_with("_light") or original.resource_name.ends_with("_hi") else 1.0)
			material.albedo_color *= Color(shade, shade, shade)
			material.resource_name = "finish:" + id
			mesh.set_surface_override_material(index, material)
	for child: Node in node.get_children():
		_apply_node(child, replacements)


static func title(id: String) -> String:
	return str(WorldTextures.entry(id).get("title", id.replace("_", " ").capitalize()))
