class_name WaterSurface
extends Node3D
## Continuous, subdivided water tops, waterfalls and spray. It has no traversal/collision authority.
## Each water cell lies at its own land level; where water runs on to lower water (TerrainBuilder.waterfalls) a
## sheet of falling water spills over the kerb, with white water where it tips and where it lands.

## Waterfalls that throw spray at their foot, at most (a long cascade would otherwise fill the air).
const MAX_SPRAYS: int = 24

var material: ShaderMaterial
var fall_material: ShaderMaterial
var _elapsed: float = 0.0
var _rings := PackedVector4Array()
var _water_cells: Array[Vector2i] = []
var _set: String = ""


func build(area: AreaDef, spray: bool = true) -> void:
	name = "WaterSurface"
	material = ShaderMaterial.new()
	material.shader = preload("res://art/water.gdshader")
	fall_material = ShaderMaterial.new()
	fall_material.shader = preload("res://art/waterfall.gdshader")
	_bind_textures()
	_water_cells.clear()
	var wet := func(cell: Vector2i, level: int) -> bool: return area.terrain_at(cell) == AreaDef.Terrain.WATER and area.level_at(cell) == level
	var control := Image.create(area.width, area.height, false, Image.FORMAT_RGB8)
	control.fill(Color(0.0, 0.5, 1.0))
	for y: int in range(area.height):
		for x: int in range(area.width):
			var at := Vector2i(x, y)
			if area.terrain_at(at) != AreaDef.Terrain.WATER:
				continue
			_water_cells.append(at)
			# Shallow, foamy water near any shore, including where the water steps down or up a level.
			var distance: float = 4.0
			for dy: int in range(-3, 4):
				for dx: int in range(-3, 4):
					var other: Vector2i = at + Vector2i(dx, dy)
					if area.in_bounds(other) and not wet.call(other, area.level_at(at)):
						distance = minf(distance, Vector2(dx, dy).length())
			control.set_pixel(x, y, Color(clampf(distance / 3.0, 0.0, 1.0), 0.5, 1.0))
	material.set_shader_parameter("depth_map", ImageTexture.create_from_image(control))
	material.set_shader_parameter("map_size", Vector2(area.width, area.height))
	var chunks: Dictionary = {}
	if area.ground.is_empty():
		for cell: Vector2i in _water_cells:
			var key := Vector2i(cell.x / 16, cell.y / 16)
			if not chunks.has(key):
				chunks[key] = []
			chunks[key].append([Rect2(cell.x - 0.5, -cell.y - 0.5, 1, 1), float(area.level_at(cell)) * TerrainBuilder.LEVEL_RISE])
	else:
		chunks[Vector2i.ZERO] = []
		for rect: Array in area.ground.get("water_rects", []):
			chunks[Vector2i.ZERO].append([Rect2(float(rect[0]), -float(rect[1]) - float(rect[3]), float(rect[2]), float(rect[3])), 0.0])
	for key: Vector2i in chunks:
		var vertices := PackedVector3Array()
		var normals := PackedVector3Array()
		for piece: Array in chunks[key]:
			var rect: Rect2 = piece[0]
			var surface: float = float(piece[1]) - TerrainBuilder.WATER_DROP
			var nx: int = maxi(1, ceili(rect.size.x * 3.0))
			var ny: int = maxi(1, ceili(rect.size.y * 3.0))
			for y: int in range(ny):
				for x: int in range(nx):
					var a := Vector3(rect.position.x + rect.size.x * float(x) / float(nx), surface, rect.position.y + rect.size.y * float(y) / float(ny))
					var b := a + Vector3(rect.size.x / float(nx), 0, 0)
					var c := b + Vector3(0, 0, rect.size.y / float(ny))
					var d := a + Vector3(0, 0, rect.size.y / float(ny))
					vertices.append_array(PackedVector3Array([a, b, c, a, c, d]))
					for k: int in range(6):
						normals.append(Vector3.UP)
		if vertices.is_empty():
			continue
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var chunk := MeshInstance3D.new()
		chunk.mesh = mesh
		chunk.material_override = material
		chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(chunk)
	var drops: Array[Dictionary] = TerrainBuilder.waterfalls(area)
	if not drops.is_empty():
		_falls(area, drops, spray)
	_rings.resize(4)
	if spray:
		for wheel: Dictionary in area.wheels:
			_spray(Vector3(wheel.at.x, float(area.level_at(Vector2i(floori(wheel.at.x + 0.5), floori(wheel.at.y + 0.5)))) * TerrainBuilder.LEVEL_RISE - 0.05, -wheel.at.y))


## After the land was shaped: everything is made again for the new water.
func rebuild(area: AreaDef) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	build(area)


## Every waterfall as one mesh: a sheet that bulges over the kerb at the top edge, then drops straight to the
## water below. UV.x runs along the edge; UV.y is the distance fallen and UV2.y the distance still to fall, so the
## shader can scroll the water down and whiten where it tips and where it lands.
func _falls(area: AreaDef, drops: Array[Dictionary], spray: bool) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sprays: int = 0
	for drop: Dictionary in drops:
		var from: Vector2i = drop.from
		var to: Vector2i = drop.to
		var outward := Vector3(float(to.x - from.x), 0.0, -float(to.y - from.y))
		var across := Vector3(-outward.z, 0.0, outward.x)
		var centre := Vector3(from.x, 0.0, -from.y)
		var top: float = float(area.level_at(from)) * TerrainBuilder.LEVEL_RISE - TerrainBuilder.WATER_DROP
		var bottom: float = float(area.level_at(to)) * TerrainBuilder.LEVEL_RISE - TerrainBuilder.WATER_DROP
		# The profile from the lip down: (how far out from the cell centre, height).
		var profile: Array[Vector2] = [Vector2(0.4, top + 0.004), Vector2(0.52, top - 0.06), Vector2(0.57, top - 0.2), Vector2(0.59, lerpf(top, bottom, 0.55)), Vector2(0.6, bottom - 0.01)]
		var fallen: Array[float] = [0.0]
		for index: int in range(1, profile.size()):
			fallen.append(fallen[-1] + profile[index].distance_to(profile[index - 1]))
		var length: float = fallen[-1]
		for index: int in range(profile.size() - 1):
			var quad: Array = []
			for corner: Array in [[index, -0.5], [index, 0.5], [index + 1, 0.5], [index + 1, -0.5]]:
				var row: int = corner[0]
				var side: float = corner[1]
				var point: Vector3 = centre + outward * profile[row].x + across * (side * 0.98) + Vector3(0, profile[row].y, 0)
				quad.append([point, Vector2(side + 0.5, fallen[row]), Vector2(0.0, length - fallen[row])])
			for corner: int in [0, 1, 2, 0, 2, 3]:
				tool.set_normal(outward)
				tool.set_uv(quad[corner][1])
				tool.set_uv2(quad[corner][2])
				tool.add_vertex(quad[corner][0])
		if spray and sprays < MAX_SPRAYS:
			sprays += 1
			_foot_spray(centre + outward * 0.62 + Vector3(0, bottom + 0.02, 0), across)
	var sheet := MeshInstance3D.new()
	sheet.name = "Waterfalls"
	sheet.mesh = tool.commit()
	sheet.material_override = fall_material
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sheet)


func _bind_textures() -> void:
	_set = WorldTextures.active_set()
	for target: ShaderMaterial in [material, fall_material]:
		if target == null:
			continue
		target.set_shader_parameter("water_texture", WorldTextures.texture("water"))
		target.set_shader_parameter("foam_texture", WorldTextures.texture("water_foam"))
	material.set_shader_parameter("detail_noise", GroundSkin._warp_texture())


func _process(delta: float) -> void:
	_elapsed += delta
	if _set != WorldTextures.active_set():
		_bind_textures()
	if _water_cells.is_empty():
		return
	for index: int in range(4):
		var time: float = _elapsed * 0.38 + float(index) * 0.79
		var cycle: int = floori(time)
		var at: Vector2i = _water_cells[posmod(cycle * 193 + index * 137, _water_cells.size())]
		_rings[index] = Vector4(at.x + 0.12, -at.y + 0.17, fmod(time, 1.0), 1.0)
	material.set_shader_parameter("ripples", _rings)


## White water bursting up where a waterfall lands, spread along its edge.
func _foot_spray(at: Vector3, across: Vector3) -> void:
	var droplets := _droplets("WaterfallSpray", at, 14, Color(0.86, 0.96, 0.97, 0.8))
	droplets.emission_box_extents = Vector3(absf(across.x) * 0.45 + 0.04, 0.02, absf(across.z) * 0.45 + 0.04)
	droplets.direction = Vector3(0, 1, 0)
	droplets.spread = 38.0
	droplets.initial_velocity_min = 0.35
	droplets.initial_velocity_max = 0.8
	droplets.lifetime = 0.6
	add_child(droplets)


func _spray(at: Vector3) -> void:
	var droplets := _droplets("MillWheelSpray", at, 28, Color(0.65, 0.93, 0.95, 0.75))
	droplets.emission_box_extents = Vector3(0.1, 0.02, 0.25)
	droplets.direction = Vector3(-0.3, 1.0, 0.3)
	droplets.spread = 28.0
	droplets.initial_velocity_min = 0.75
	droplets.initial_velocity_max = 1.5
	droplets.lifetime = 0.85
	add_child(droplets)


func _droplets(node_name: String, at: Vector3, amount: int, colour: Color) -> CPUParticles3D:
	var droplets := CPUParticles3D.new()
	droplets.name = node_name
	droplets.position = at
	droplets.amount = amount
	droplets.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	droplets.gravity = Vector3(0, -2.3, 0)
	droplets.scale_amount_min = 0.025
	droplets.scale_amount_max = 0.055
	droplets.color = colour
	var drop := SphereMesh.new()
	drop.radius = 0.5
	drop.height = 1.0
	droplets.mesh = drop
	var shine := StandardMaterial3D.new()
	shine.albedo_color = Color(colour, 0.8)
	shine.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shine.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	droplets.material_override = shine
	droplets.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return droplets
