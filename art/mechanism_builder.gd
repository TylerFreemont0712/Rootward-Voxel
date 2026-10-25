class_name MechanismBuilder
extends RefCounted
## Procedural interactive parts: lamps, the beacon, gates, bridge decks and the mill wheel. These stay
## ordinary nodes because their state changes. Shape only: what they do is decided in core/.
##
## `box` is Callable(parent: Node3D, at: Vector3, size: Vector3, material_id: String) -> MeshInstance3D.

const WorldAssets := preload("res://art/world_assets.gd")

static var _halo_texture: GradientTexture2D


## A lamp is a Node3D with metadata the view reads: `glass` (the MeshInstance3D to light), `unlit` (its material
## when dark, or null to keep the model's own) and a "Halo" glow card. The `post` style is the adopted Blender
## lamppost when the world catalog selects it; a missing selected model is an error, never a silent substitute.
static func lamp(parent: Node3D, box: Callable, style: String) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	if style == "sconce":
		box.call(root, Vector3(0, 1.6, -0.12), Vector3(0.34, 0.7, 0.12), "wood_dark")
		box.call(root, Vector3(0, 1.43, 0.04), Vector3(0.3, 0.08, 0.3), "gold")
		var glass: MeshInstance3D = box.call(root, Vector3(0, 1.68, 0.04), Vector3(0.23, 0.4, 0.23), "lamp_glass")
		box.call(root, Vector3(0, 1.94, 0.04), Vector3(0.34, 0.12, 0.32), "roof_dark")
		_register_glass(root, glass, Vector3(0, 1.68, 0.04), 1.5)
		return root
	if style == "beacon":
		_beacon(root, box)
		return root
	if WorldAssets.is_blender("lamppost"):
		_adopted_post(root)
		return root
	box.call(root, Vector3(0, 0.1, 0), Vector3(0.5, 0.2, 0.5), "stone_light")
	box.call(root, Vector3(0, 0.24, 0), Vector3(0.38, 0.08, 0.38), "stone")
	box.call(root, Vector3(0, 0.79, 0), Vector3(0.12, 1.4, 0.12), "wood_dark")
	box.call(root, Vector3(0, 1.44, 0), Vector3(0.37, 0.1, 0.37), "wood_dark")
	var glass: MeshInstance3D = box.call(root, Vector3(0, 1.67, 0), Vector3(0.25, 0.35, 0.25), "window")
	box.call(root, Vector3(0, 1.89, 0), Vector3(0.39, 0.12, 0.39), "roof_dark")
	box.call(root, Vector3(0, 1.99, 0), Vector3(0.24, 0.1, 0.24), "roof")
	_register_glass(root, glass, glass.position, 1.7)
	return root


static func _adopted_post(root: Node3D) -> void:
	var model: Node3D = WorldAssets.instantiate("lamppost")
	if model == null:
		return
	root.add_child(model)
	var glass: MeshInstance3D = _find_glass(model)
	if glass == null:
		push_error("The lamppost model has no mesh using the lamp_glass material, so the game cannot light it.")
		return
	# The halo and the light sit where the lantern is, wherever the model puts it.
	var to_root: Transform3D = Transform3D.IDENTITY
	var node: Node = glass
	while node != root:
		to_root = (node as Node3D).transform * to_root
		node = node.get_parent()
	_register_glass(root, glass, to_root * glass.get_aabb().get_center(), 1.7)


static func _find_glass(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null and instance.mesh.get_surface_count() > 0:
			var material: Material = instance.get_active_material(0)
			if material != null and material.resource_name == "lamp_glass":
				return instance
	for child: Node in node.get_children():
		var found: MeshInstance3D = _find_glass(child)
		if found != null:
			return found
	return null


static func _register_glass(root: Node3D, glass: MeshInstance3D, center: Vector3, halo_diameter: float) -> void:
	root.set_meta("glass", glass)
	root.set_meta("unlit", glass.material_override)
	_halo(root, center, halo_diameter)


## The Old Watch's beacon: a stone pillar with a caged flame. Big enough to read from across the valley.
static func _beacon(root: Node3D, box: Callable) -> void:
	box.call(root, Vector3(0, 0.12, 0), Vector3(1.5, 0.24, 1.5), "stone_dark")
	box.call(root, Vector3(0, 0.36, 0), Vector3(1.1, 0.24, 1.1), "stone")
	box.call(root, Vector3(0, 1.2, 0), Vector3(0.56, 1.45, 0.56), "stone_light")
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		box.call(root, Vector3(corner.x * 0.37, 0.65, corner.y * 0.37), Vector3(0.14, 0.5, 0.14), "stone")
	box.call(root, Vector3(0, 2.08, 0), Vector3(0.86, 0.14, 0.86), "wood_dark")
	var glass: MeshInstance3D = box.call(root, Vector3(0, 2.52, 0), Vector3(0.6, 0.76, 0.6), "window")
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		box.call(root, Vector3(corner.x * 0.33, 2.52, corner.y * 0.33), Vector3(0.1, 0.84, 0.1), "iron")
	box.call(root, Vector3(0, 3.0, 0), Vector3(0.96, 0.16, 0.96), "roof_dark")
	box.call(root, Vector3(0, 3.16, 0), Vector3(0.62, 0.16, 0.62), "roof")
	box.call(root, Vector3(0, 3.34, 0), Vector3(0.28, 0.2, 0.28), "gold")
	_register_glass(root, glass, Vector3(0, 2.52, 0), 4.2)
	_embers(root, Vector3(0, 3.1, 0))


static func gate(parent: Node3D, box: Callable, axis: String) -> Dictionary:
	var gate_root := Node3D.new()
	# The leaf spans the cell along `axis`. axis "y" is the original orientation, turned a quarter.
	gate_root.rotation.y = PI / 2.0 if axis == "y" else 0.0
	parent.add_child(gate_root)
	for x_offset: float in [-0.62, 0.62]:
		box.call(gate_root, Vector3(x_offset, 0.8, 0), Vector3(0.25, 1.6, 0.34), "stone")
		box.call(gate_root, Vector3(x_offset, 1.63, 0), Vector3(0.34, 0.16, 0.42), "stone_light")
	box.call(gate_root, Vector3(0, 1.58, 0), Vector3(1.0, 0.1, 0.16), "wood_dark")
	var door := Node3D.new()
	door.name = "GateDoor"
	gate_root.add_child(door)
	for slat: int in range(5):
		box.call(door, Vector3(-0.4 + slat * 0.2, 0.65, 0), Vector3(0.12, 1.12, 0.13), "wood")
	box.call(door, Vector3(0, 0.3, 0.09), Vector3(1.04, 0.12, 0.12), "wood_light")
	box.call(door, Vector3(0, 0.95, 0.09), Vector3(1.04, 0.12, 0.12), "wood_light")
	var brace: MeshInstance3D = box.call(door, Vector3(0, 0.63, 0.13), Vector3(1.05, 0.1, 0.08), "wood_light")
	brace.rotation.z = 0.55
	return {"root": gate_root, "door": door}


## One timber deck module. Planks run across the direction of travel, which is `axis` ("x" or "y").
static func deck(parent: Node3D, box: Callable, axis: String, first: bool, last: bool) -> Node3D:
	var section := Node3D.new()
	section.rotation.y = PI / 2.0 if axis == "y" else 0.0
	parent.add_child(section)
	for plank: int in range(6):
		box.call(section, Vector3(-0.4 + plank * 0.16, 0.035, 0), Vector3(0.145, 0.15, 1.1), "wood_light")
	for z_offset: float in [-0.43, 0.43]:
		box.call(section, Vector3(0, -0.09, z_offset), Vector3(1.05, 0.14, 0.14), "wood_dark")
	for side: float in [-0.56, 0.56]:
		box.call(section, Vector3(0, 0.60, side), Vector3(1.04, 0.095, 0.095), "oak")
		for end: float in [-0.46, 0.46]:
			var capped: bool = (end < 0.0 and first) or (end > 0.0 and last)
			if capped:
				box.call(section, Vector3(end, 0.38, side), Vector3(0.14, 0.8, 0.14), "wood")
				box.call(section, Vector3(end, 0.81, side), Vector3(0.19, 0.08, 0.19), "oak_light")
	return section


static func wheel(parent: Node3D, box: Callable, radius: float = 0.72, width: float = 0.62) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.set_meta("radius",radius)
	for side: float in [-width*.42,width*.42]:
		for spoke: int in range(8):
			var beam: MeshInstance3D = box.call(root, Vector3(side, 0, 0), Vector3(0.085, radius*1.92, 0.10), "wood_dark")
			beam.rotation.x = float(spoke) * PI / 8.0
		for segment: int in range(24):
			var angle: float = float(segment)*TAU/24.0
			var rim: MeshInstance3D = box.call(root,Vector3(side,cos(angle)*radius*.92,sin(angle)*radius*.92),Vector3(.10,.10,radius*.255),"oak")
			rim.rotation.x = angle
			var band: MeshInstance3D = box.call(root,Vector3(side*1.04,cos(angle)*radius*.94,sin(angle)*radius*.94),Vector3(.025,.035,radius*.26),"iron")
			band.rotation.x = angle
	for paddle: int in range(24):
		var angle: float = float(paddle) * TAU / 24.0
		var tread: MeshInstance3D = box.call(root, Vector3(0, cos(angle) * radius, sin(angle) * radius), Vector3(width, 0.12, radius*.25), "wood_light")
		tread.rotation.x = angle
	box.call(root, Vector3.ZERO, Vector3(width+.16, .27, .27), "iron")
	return root


## Fixed axle and bearing. It stays still while the separate rotor turns.
static func wheel_support(parent: Node3D, box: Callable, length: float, height: float) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	box.call(root,Vector3(length*.5,0,0),Vector3(length,.19,.19),"wood_dark")
	box.call(root,Vector3(length-.1,-height*.5,0),Vector3(.32,height,.4),"stone")
	box.call(root,Vector3(length-.1,.02,0),Vector3(.42,.31,.46),"iron")
	box.call(root,Vector3(length-.1,.19,0),Vector3(.48,.07,.5),"gold")
	return root


## A soft additive glow card. Hidden until its lamp is lit.
static func _halo(root: Node3D, at: Vector3, diameter: float) -> void:
	if _halo_texture == null:
		_halo_texture = GradientTexture2D.new()
		_halo_texture.width = 64
		_halo_texture.height = 64
		_halo_texture.fill = GradientTexture2D.FILL_RADIAL
		_halo_texture.fill_from = Vector2(0.5, 0.5)
		_halo_texture.fill_to = Vector2(1.0, 0.5)
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1.0, 0.82, 0.45, 0.55))
		gradient.set_color(1, Color(1.0, 0.62, 0.25, 0.0))
		gradient.add_point(0.35, Color(1.0, 0.76, 0.38, 0.22))
		_halo_texture.gradient = gradient
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_texture = _halo_texture
	material.vertex_color_use_as_albedo = false
	var mesh := QuadMesh.new()
	mesh.size = Vector2(diameter, diameter)
	var card := MeshInstance3D.new()
	card.name = "Halo"
	card.mesh = mesh
	card.material_override = material
	card.position = at
	card.visible = false
	card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(card)


## Gold motes that drift up from a burning beacon. Off until the lamp is lit.
static func _embers(root: Node3D, at: Vector3) -> void:
	var motes := CPUParticles3D.new()
	motes.name = "Embers"
	motes.position = at
	motes.emitting = false
	motes.amount = 26
	motes.lifetime = 3.6
	motes.randomness = 0.7
	motes.local_coords = false
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 0.28
	motes.direction = Vector3(0, 1, 0)
	motes.spread = 28.0
	motes.gravity = Vector3(0, 0.35, 0)
	motes.initial_velocity_min = 0.35
	motes.initial_velocity_max = 0.9
	var quad := QuadMesh.new()
	quad.size = Vector2(0.11, 0.11)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	quad.material = material
	motes.mesh = quad
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.85, 0.45, 0.9))
	ramp.set_color(1, Color(1.0, 0.55, 0.2, 0.0))
	motes.color_ramp = ramp
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(motes)
