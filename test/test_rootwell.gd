extends SceneTree
## The Rootwell landmark: its story parts are separate nodes on true pivots, its glass and light behave as authored,
## the city's conduits climb its steps, it stands only in Rootward Square, and the showcase displays it.

const WorldAssets := preload("res://art/world_assets.gd")
const ID: String = "rootwell-beacon"
# Retain the reviewed foliage geometry pending the user's in-game check.
const TRIANGLE_BUDGET: int = 390000
var checks: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()


func _run() -> void:
	var spec: Dictionary = WorldAssets.entry(ID)
	_check(spec.get("status", "") == "integrated_sparks_square" and spec.get("authority", "") == "blender", "The Rootwell is an adopted Blender master standing in the square")
	var model: Node3D = WorldAssets.instantiate(ID)
	_check(model != null, "The Rootwell instantiates from its built model")
	if model == null:
		_finish()
		return
	root.add_child(model)
	var nodes: Dictionary = {}
	_collect(model, nodes)
	for part: String in spec.get("story_parts", []):
		_check(nodes.has(part) and nodes[part] is MeshInstance3D, "Story part %s is its own mesh node" % part)
	# The needle turns about the dial's axis: its local Z. Its origin is the dial centre, south-east at 1.48 m.
	var needle: MeshInstance3D = nodes.get("gauge_needle")
	if needle != null:
		var box: AABB = needle.mesh.get_aabb()
		_check(needle.position.is_equal_approx(Vector3(1.4178, 1.48, 1.4178)) or needle.position.distance_to(Vector3(1.4178, 1.48, 1.4178)) < 0.01, "The needle's pivot is the dial centre (%s)" % needle.position)
		_check(box.size.z < 0.1 and maxf(box.size.x, box.size.y) > 0.4, "The needle and its hub lie flat in the dial, about its turning axis (%s)" % box.size)
		var outward: Vector3 = (needle.global_basis * Vector3.BACK).normalized()
		_check(outward.dot(Vector3(1, 0, 1).normalized()) > 0.99 or outward.dot(Vector3(-1, 0, -1).normalized()) > 0.99, "The needle's axis is the south-east face normal")
		var tip_before: Vector3 = needle.global_transform * _farthest(needle)
		needle.rotate_object_local(Vector3.BACK, deg_to_rad(-27.0 * 5.0))
		var tip_after: Vector3 = needle.global_transform * _farthest(needle)
		_check(absf(tip_before.distance_to(needle.global_position) - tip_after.distance_to(needle.global_position)) < 0.01 and tip_before.distance_to(tip_after) > 0.3, "Turning the needle sweeps its tip round the dial")
		_check(tip_after.y > tip_before.y, "Raising the pressure lifts the needle toward the top of the dial")
	var door: MeshInstance3D = nodes.get("maintenance_door")
	if door != null:
		var box: AABB = door.mesh.get_aabb()
		_check(box.position.x > -0.12 and box.end.x > 0.75 and box.end.x < 1.0 and box.position.y > -0.05, "The door hangs from its hinge line at its origin (%s)" % box)
		_check(door.position.x > 1.8 and absf(door.position.z) < 0.6, "The door is on the east face")
	for key: String in ["valve_wheel_e", "valve_wheel_n", "valve_wheel_w", "valve_wheel_s", "valve_wheel_service_w", "valve_wheel_service_n"]:
		var wheel: MeshInstance3D = nodes.get(key)
		if wheel != null:
			_check(wheel.mesh.get_aabb().get_center().length() < 0.06, key + " spins about its own hub")
	# Materials: amber glass is transparent, the chamber light is single-sided, lantern glass keeps the lamp contract.
	var glass := _material(model, "rootwell_bell_glass")
	_check(glass != null and glass.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED, "The bell is translucent amber glass")
	var light := _material(model, "rootwell_light")
	_check(light != null and light.cull_mode == BaseMaterial3D.CULL_BACK and light.emission_enabled, "The chamber light glows and draws only its far side")
	var root_material := _material(model, "rootwell_root")
	_check(root_material != null and not root_material.emission_enabled, "The root is lit, so it keeps its drawn outline")
	_check(_count_material(model, "lamp_glass") >= 1, "The lanterns keep separate lamp_glass")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/" + ID + "/manifest.json"))
	var bounds: Array = manifest.audit.bounds
	_check(absf(float(bounds[3]) - float(bounds[0]) - 7.5) < 0.1 and float(bounds[4]) > 9.0 and float(bounds[4]) < 10.5, "The Rootwell is 7.5 m across (its conduits' lips add 3 cm a side) and about 9.5 m tall")
	# The power reaches it: conduits climb the four cardinal flights to the drum, their glass flagged for the grid shader.
	var conduit: MeshInstance3D = nodes.get("rootwell_conduit_glass")
	_check(conduit != null and WorldAssetMeta.value(conduit, "power_grid", false) and conduit.material_override is ShaderMaterial, "Glowing conduits climb the Rootwell's steps")
	if conduit != null:
		var reach: AABB = conduit.get_aabb()
		_check(reach.size.x > 4.5 and reach.size.z > 4.5 and reach.size.y > .4, "They run up all four flights to the drum (%s)" % reach)
	_check(int(manifest.audit.triangles) <= TRIANGLE_BUDGET, "It stays within its foliage review budget (%d / %d triangles)" % [int(manifest.audit.triangles), TRIANGLE_BUDGET])
	# Placed once, at the heart of Rootward Square v3, replacing the earlier beacon.
	var placed: Array[String] = []
	for file: String in DirAccess.get_files_at("res://content/areas"):
		if file.ends_with(".json") and FileAccess.get_file_as_string("res://content/areas/" + file).contains(ID):
			placed.append(file)
	var square: String = FileAccess.get_file_as_string("res://content/areas/haverlund-square.json")
	_check(placed == ["haverlund-square.json"] and not square.contains("\"square-beacon\""), "Only the square places the Rootwell, and its old beacon is gone %s" % [placed])
	model.queue_free()
	# The showcase shows it as an ordinary model, without house looks.
	var screen := AssetShowcase.new()
	screen.setup()
	root.add_child(screen)
	await process_frame
	_check(screen.show_asset(ID) and not screen.variant_row.visible, "Asset Showcase displays the Rootwell")
	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("Rootwell landmark: %d checks passed." % checks)
		quit()
	else:
		for failure: String in failures:
			printerr(failure)
		quit(1)


func _collect(node: Node, nodes: Dictionary) -> void:
	nodes[str(node.name)] = node
	for child: Node in node.get_children():
		_collect(child, nodes)


func _farthest(mesh: MeshInstance3D) -> Vector3:
	var best := Vector3.ZERO
	for point: Vector3 in mesh.mesh.get_faces():
		if point.length() > best.length():
			best = point
	return best


func _material(node: Node, name: String) -> BaseMaterial3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		for index: int in range((node as MeshInstance3D).mesh.get_surface_count()):
			var material := (node as MeshInstance3D).mesh.surface_get_material(index) as BaseMaterial3D
			if material != null and material.resource_name == name:
				return material
	for child: Node in node.get_children():
		var found := _material(child, name)
		if found != null:
			return found
	return null


func _count_material(node: Node, name: String) -> int:
	var count: int = 0
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		for index: int in range((node as MeshInstance3D).mesh.get_surface_count()):
			var material: Material = (node as MeshInstance3D).mesh.surface_get_material(index)
			if material != null and material.resource_name == name:
				count += 1
	for child: Node in node.get_children():
		count += _count_material(child, name)
	return count


func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
