extends "res://scenes/clearing_view.gd"
## One-way bootstrap from prototype recipes. Never runs while exporting an artist's .blend.

const Recipes := preload("res://pipeline/world_recipes.gd")


func _ready() -> void:
	pass


func create_asset(id: String) -> Node3D:
	_make_materials()
	# glTF cannot store a colour factor above 1, so a seed's "lighter" variants (tint > 1) would not survive the
	# round trip. A seed is plain geometry; `retexture` bakes the real tints into the pictures afterwards.
	for material: Variant in _materials.values():
		if material is StandardMaterial3D:
			var color: Color = (material as StandardMaterial3D).albedo_color
			(material as StandardMaterial3D).albedo_color = Color(minf(color.r, 1.0), minf(color.g, 1.0), minf(color.b, 1.0), color.a)
	match id:
		"cottage":
			_make_house(Vector3.ZERO, false)
		"mill-house":
			_make_house(Vector3.ZERO, true)
		"tree":
			_make_tree(Vector3.ZERO, 1.0, 0)
		"clearing-ground":
			_make_island()
			_make_paths()
		"log-cabin":
			Recipes.new(Callable(self, "_block")).cabin()
		"log-cabin-large":
			Recipes.new(Callable(self, "_block"), Recipes.LARGE).cabin()
		"log-cabin-large-teal":
			Recipes.new(Callable(self, "_block"), Recipes.LARGE.merged({"roof": "teal"})).cabin()
		"lamppost":
			Recipes.new(Callable(self, "_block")).lamppost()
		_:
			return null
	var asset := Node3D.new()
	asset.name = id.replace("-", "_")
	for material_id: String in _batches:
		if _materials[material_id] is ShaderMaterial:
			continue  # Animated water remains a Godot effect, not a Blender mesh material.
		var group_name: String = _group_for(material_id)
		var group: Node3D = asset.get_node_or_null(NodePath(group_name)) as Node3D
		if group == null:
			group = Node3D.new()
			group.name = group_name
			asset.add_child(group)
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE
		for transform: Transform3D in _batches[material_id]:
			tool.append_from(cube, 0, transform)
		var material: StandardMaterial3D = _materials[material_id]
		material.resource_name = material_id
		tool.set_material(material)
		var instance := MeshInstance3D.new()
		instance.name = material_id + "_geometry"
		instance.mesh = tool.commit()
		group.add_child(instance)
	_batches.clear()
	return asset


func _group_for(material_id: String) -> String:
	if material_id.begins_with("roof") or material_id.begins_with("teal"):
		return "Roof"
	if material_id.begins_with("plaster"):
		return "Walls"
	if material_id.begins_with("stone") or material_id.begins_with("path"):
		return "Masonry"
	if material_id.begins_with("leaf"):
		return "Canopy"
	if material_id.begins_with("grass") or material_id.begins_with("soil"):
		return "Ground"
	if material_id.begins_with("window"):
		return "Windows"
	if material_id in ["iron", "gold"]:
		return "Metal"
	if material_id.begins_with("lamp"):
		return "Lantern"
	return "Timber"
