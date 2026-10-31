class_name SlateLink
extends Node3D
## How the field slate reaches what its code works on, drawn in the room while the code is open: a cord from the
## traveller to the socket under a zone's screen, or, for a single fitting, small signal sparks hopping over the air
## from the traveller to it. Presentation only; reach is decided by `FieldAccess`.

const SIDES: int = 6
const SEGMENTS: int = 18
const RADIUS: float = 0.034

var wired: bool = true
var _player: Node3D
var _target: Node3D
var _socket := Vector3.ZERO
var _cord: MeshInstance3D
var _sparks: Array[MeshInstance3D] = []
var _time: float = 0.0


func setup(player: Node3D, target: Node3D, is_wired: bool) -> void:
	name = "SlateLink"
	_player = player
	_target = target
	wired = is_wired
	if wired:
		_socket = _socket_point(target)
		_cord = MeshInstance3D.new()
		_cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var rubber := StandardMaterial3D.new()
		rubber.albedo_color = Color("8d8a82")
		rubber.roughness = 0.55
		_cord.material_override = rubber
		add_child(_cord)
		var plug := MeshInstance3D.new()
		var barrel := CylinderMesh.new()
		barrel.top_radius = 0.07
		barrel.bottom_radius = 0.07
		barrel.height = 0.2
		plug.mesh = barrel
		var brass := StandardMaterial3D.new()
		brass.albedo_color = PaperPal.BRASS
		brass.metallic = 0.6
		brass.roughness = 0.35
		plug.material_override = brass
		plug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		plug.name = "Plug"
		add_child(plug)
	else:
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.albedo_color = PaperPal.TEAL_HI
		glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		for index: int in range(6):
			var spark := MeshInstance3D.new()
			var ball := SphereMesh.new()
			ball.radius = 0.07
			ball.height = 0.14
			spark.mesh = ball
			spark.material_override = glow
			spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(spark)
			_sparks.append(spark)
	_update()


## Low on the panel, under the glass: where a screen's brass-collared socket sits.
static func _socket_point(target: Node3D) -> Vector3:
	var box := AABB(target.global_position, Vector3.ZERO)
	var first: bool = true
	for node: Node in target.find_children("*", "MeshInstance3D", true, false):
		if node.name == &"IllustratedOutline": continue
		var part: AABB = BuildOverlay.world_aabb(node as MeshInstance3D)
		box = part if first else box.merge(part)
		first = false
	var centre: Vector3 = box.get_center()
	return Vector3(centre.x, box.position.y + box.size.y * 0.12, centre.z)


func _hand() -> Vector3:
	return _player.global_position + Vector3(0.0, 0.78, 0.0)


func _process(delta: float) -> void:
	_time += delta
	_update()


func _update() -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_target): return
	var from: Vector3 = _hand()
	if wired:
		var to: Vector3 = _socket
		var sag: float = 0.35 + from.distance_to(to) * 0.12
		var points: PackedVector3Array = []
		for step: int in range(SEGMENTS + 1):
			var t: float = float(step) / float(SEGMENTS)
			var point: Vector3 = from.lerp(to, t)
			point.y -= sin(t * PI) * sag + sin(_time * 1.3 + t * 3.0) * 0.01
			points.append(point)
		_cord.mesh = _tube(points)
		var plug := get_node("Plug") as MeshInstance3D
		plug.global_position = to
		plug.look_at(to + (to - points[SEGMENTS - 1]).normalized(), Vector3.UP if absf((to - points[SEGMENTS - 1]).normalized().y) < 0.95 else Vector3.RIGHT)
		plug.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		return
	var to_spark: Vector3 = _target.global_position
	for index: int in range(_sparks.size()):
		var t: float = fposmod(_time * 0.55 + float(index) / float(_sparks.size()), 1.0)
		var point: Vector3 = from.lerp(to_spark, t)
		point.y += sin(t * PI) * 0.45
		_sparks[index].global_position = point
		_sparks[index].scale = Vector3.ONE * (0.4 + 0.6 * sin(t * PI))


## A thin tube along the points, built fresh each frame (a few hundred vertices).
func _tube(points: PackedVector3Array) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for index: int in range(points.size()):
		var ahead: Vector3 = (points[mini(index + 1, points.size() - 1)] - points[maxi(index - 1, 0)]).normalized()
		var side: Vector3 = ahead.cross(Vector3.UP).normalized()
		if side.length() < 0.01: side = Vector3.RIGHT
		var up: Vector3 = side.cross(ahead).normalized()
		for corner: int in range(SIDES):
			var angle: float = TAU * float(corner) / float(SIDES)
			var normal: Vector3 = side * cos(angle) + up * sin(angle)
			vertices.append(points[index] + normal * RADIUS)
			normals.append(normal)
	for index: int in range(points.size() - 1):
		for corner: int in range(SIDES):
			var a: int = index * SIDES + corner
			var b: int = index * SIDES + (corner + 1) % SIDES
			var c: int = a + SIDES
			var d: int = b + SIDES
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
