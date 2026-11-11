class_name PropVisual
extends Node3D
## Presents a validated boolean state. The authored semantic pivot/material roles own visual placement.

var kind: String = ""
var active: bool = false
var mechanism: Node3D
var _rest_rotation := Vector3.ZERO
var _glows: Array[Dictionary] = []
var _flames: Array[MeshInstance3D] = []
var _light: OmniLight3D
var _water: CPUParticles3D
var _phase: float = 0.0
var _blend: float = 0.0
var _initialized: bool = false


func setup(model: Node3D, interaction: Dictionary) -> void:
	kind = str(interaction.kind)
	_scan(model, model)
	if mechanism != null:
		_rest_rotation = mechanism.rotation
	elif kind != "light":
		push_error("Interactive model has no authored mechanism pivot: " + str(model.name))
	if not _glows.is_empty() or not _flames.is_empty():
		var mesh: MeshInstance3D = _glows[0].mesh if not _glows.is_empty() else _flames[0]
		var point: Vector3 = model.to_local(mesh.global_transform * mesh.get_aabb().get_center())
		if kind == "pump":
			_make_water(point + Vector3(0, mesh.get_aabb().size.y * 0.4, 0))
		else:
			_light = OmniLight3D.new()
			_light.position = point
			_light.light_color = Color("ffd18b") if not _flames.is_empty() else Color("8bddcf")
			_light.omni_range = 2.7
			_light.light_energy = 0.8
			_light.shadow_enabled = false
			add_child(_light)
	set_active(false, true)


func _scan(node: Node, model: Node3D) -> void:
	if node is Node3D and node.name == &"mechanism":
		mechanism = node as Node3D
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if mesh.mesh != null:
			for surface: int in range(mesh.mesh.get_surface_count()):
				var original: Material = mesh.get_active_material(surface)
				if not original is StandardMaterial3D:
					continue
				if original.resource_name == "state_glow":
					var material := original.duplicate() as StandardMaterial3D
					mesh.set_surface_override_material(surface, material)
					_glows.append({"mesh": mesh, "material": material, "color": material.albedo_color})
				elif original.resource_name == "state_flame":
					_flames.append(mesh)
	for child: Node in node.get_children():
		_scan(child, model)


func set_active(value: bool, instant: bool = false) -> void:
	if _initialized and value == active and not instant:
		return
	active = value
	if instant or not _initialized:
		_blend = 1.0 if active else 0.0
	_initialized = true
	for record: Dictionary in _glows:
		var material: StandardMaterial3D = record.material
		material.emission_enabled = active and kind != "pump"
		material.albedo_color = record.color if active else (record.color as Color).darkened(0.63)
		(record.mesh as MeshInstance3D).visible = active if kind == "pump" else true
	for mesh: MeshInstance3D in _flames:
		mesh.visible = active
	if _light != null:
		_light.visible = active
	if _water != null:
		_water.emitting = active
	_pose()


func _process(delta: float) -> void:
	if active:
		_phase += delta
	_blend = move_toward(_blend, 1.0 if active else 0.0, delta * 3.2)
	_pose()
	if active and _light != null:
		_light.light_energy = 0.78 + sin(_phase * 3.1) * 0.06


func _pose() -> void:
	if mechanism == null:
		return
	var rotation: Vector3 = _rest_rotation
	var eased: float = smoothstep(0.0, 1.0, _blend)
	match kind:
		"hinge": rotation.x -= eased * 1.34
		"lever": rotation.x += eased * 0.92
		"spin_x": rotation.x += _phase * 2.7
		"spin_y": rotation.y += _phase * 2.0
		"bell": rotation.x += sin(_phase * 4.8) * 0.32 * eased
		"pump": rotation.x += sin(_phase * 5.2) * 0.32 * eased
	mechanism.rotation = rotation


func _make_water(point: Vector3) -> void:
	_water = CPUParticles3D.new()
	_water.name = "PumpDroplets"
	_water.position = point
	_water.amount = 12
	_water.lifetime = 0.4
	_water.direction = Vector3.DOWN
	_water.spread = 6.0
	_water.gravity = Vector3(0, -4.0, 0)
	_water.initial_velocity_min = 0.2
	_water.initial_velocity_max = 0.4
	_water.scale_amount_min = 0.025
	_water.scale_amount_max = 0.045
	var drop := SphereMesh.new()
	drop.radius = 0.5
	drop.height = 1.0
	_water.mesh = drop
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("85d3d0")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_water.material_override = material
	_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_water)
