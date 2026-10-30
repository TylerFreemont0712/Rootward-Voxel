extends SceneTree
## Two surfaces in one plane cannot be ordered by the depth buffer, so they flicker against each other as the camera
## follows the apprentice. `art/source/world/square-hub/v1/coplanar_revision.py` stood the layers of these models a few
## millimetres apart; this checks they stay that way after any later edit or rebuild. Only faces turned towards the
## camera at one of the four placement turns count, and the `alt_*` parts (per-placement alternatives of which one is
## ever shown) are left out, as they are in the revision.

const TOLERANCE: float = 0.003
const CAMERA: Vector3 = Vector3(21.0, 17.8, 21.0)
## Models with the most overlapped area they may keep: slivers where tiny details touch, never a wall or a basin.
## The fountain is one mesh and one material, painted by texture coordinates, so there two faces also fight when their
## pictures differ (water on the bowl); the buildings' same-material overlaps are hidden joins between blocks.
const MODELS: Dictionary = {
	"town-fountain": {"allowed": 0.0, "pictures": true},
	"haverlund-cafe": {"allowed": 0.3},
	"haverlund-bookshop": {"allowed": 0.3},
	"haverlund-bakery": {"allowed": 0.3},
	"haverlund-post-office": {"allowed": 0.3},
	"haverlund-greengrocer": {"allowed": 0.5},
	"seaside-saltwind-house": {"allowed": 0.6},
	"seaside-eaveside-terrace": {"allowed": 0.6},
	"seaside-lantern-row-house": {"allowed": 0.6},
	"seaside-rosewash-house": {"allowed": 0.6},
	"seaside-shingle-court-cottage": {"allowed": 0.6},
}

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()


func _run() -> void:
	for id: String in MODELS:
		var rule: Dictionary = MODELS[id]
		var overlapped: float = _overlap_area("res://assets/world/%s/model.glb" % id, bool(rule.get("pictures", false)))
		_check(overlapped <= float(rule.allowed), "%s: %.3f m2 of coplanar overlap (allowed %.2f)" % [id, overlapped, float(rule.allowed)])
	print("Coplanar surfaces: %d checks passed" % (checks - failures))
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _overlap_area(path: String, pictures: bool) -> float:
	var scene := load(path) as PackedScene
	if scene == null:
		_check(false, "%s loads" % path)
		return 0.0
	var model: Node = scene.instantiate()
	var triangles: Array[Dictionary] = []
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null or str(mesh_node.name).begins_with("alt_") or mesh_node.name == &"IllustratedOutline":
			continue
		_collect(mesh_node, model, triangles)
	model.free()
	var buckets: Dictionary = {}
	for tri: Dictionary in triangles:
		var normal: Vector3 = tri.normal
		var key := Vector4i(roundi(normal.x * 25.0), roundi(normal.y * 25.0), roundi(normal.z * 25.0), roundi(float(tri.d) / (TOLERANCE * 2.0)))
		if not buckets.has(key):
			buckets[key] = []
		(buckets[key] as Array).append(tri)
	var area: float = 0.0
	for key: Vector4i in buckets:
		var pool: Array = (buckets[key] as Array).duplicate()
		for step: int in [-1, 1]:
			pool.append_array(buckets.get(Vector4i(key.x, key.y, key.z, key.w + step), []))
		for a: Dictionary in buckets[key]:
			if not _faces_camera(a.normal):
				continue
			for b: Dictionary in pool:
				if a == b or absf(float(a.d) - float(b.d)) > TOLERANCE or (a.normal as Vector3).dot(b.normal) < 0.999:
					continue
				if a.material == b.material and not (pictures and (a.uv as Vector2).distance_to(b.uv) >= 0.04):
					continue
				if _covers(a, b):
					area += float(a.area)
					break
	return area


func _collect(mesh_node: MeshInstance3D, root: Node, out: Array[Dictionary]) -> void:
	var to_root: Transform3D = Transform3D.IDENTITY
	var walker: Node = mesh_node
	while walker != null and walker != root:
		to_root = (walker as Node3D).transform * to_root
		walker = walker.get_parent()
	var mesh: Mesh = mesh_node.mesh
	for surface: int in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var material: Material = mesh.surface_get_material(surface)
		var name: String = material.resource_name if material != null else ""
		var count: int = indices.size() if not indices.is_empty() else vertices.size()
		for i: int in range(0, count - 2, 3):
			var ids: Array[int] = []
			if indices.is_empty():
				ids.assign([i, i + 1, i + 2])
			else:
				ids.assign([indices[i], indices[i + 1], indices[i + 2]])
			var p0: Vector3 = to_root * vertices[ids[0]]
			var p1: Vector3 = to_root * vertices[ids[1]]
			var p2: Vector3 = to_root * vertices[ids[2]]
			# Godot draws the clockwise side as the front, so the outward normal runs the other way round.
			var cross: Vector3 = (p2 - p0).cross(p1 - p0)
			if cross.length() < 2e-5:
				continue
			var normal: Vector3 = cross.normalized()
			var uv := Vector2.ZERO
			if not uvs.is_empty():
				uv = (uvs[ids[0]] + uvs[ids[1]] + uvs[ids[2]]) / 3.0
			out.append({"p": [p0, p1, p2], "normal": normal, "d": normal.dot(p0), "material": name, "uv": uv, "area": cross.length() * 0.5})


func _faces_camera(normal: Vector3) -> bool:
	for turn: int in [0, 90, 180, 270]:
		if (Basis(Vector3.UP, deg_to_rad(float(turn))) * normal).dot(CAMERA) > 0.02:
			return true
	return false


## Whether `a`'s middle and most of its corners lie inside `b`.
func _covers(a: Dictionary, b: Dictionary) -> bool:
	var pts: Array = a.p
	var centre: Vector3 = ((pts[0] as Vector3) + (pts[1] as Vector3) + (pts[2] as Vector3)) / 3.0
	var hits: int = 0
	var samples: Array[Vector3] = [centre]
	for p: Vector3 in pts:
		samples.append(centre + (p - centre) * 0.6)
	for sample: Vector3 in samples:
		if _inside(sample, b.p, a.normal):
			hits += 1
	return hits >= 2


func _inside(point: Vector3, tri: Array, normal: Vector3) -> bool:
	var a: Vector3 = tri[0]
	var b: Vector3 = tri[1]
	var c: Vector3 = tri[2]
	var s0: float = (b - a).cross(point - a).dot(normal)
	var s1: float = (c - b).cross(point - b).dot(normal)
	var s2: float = (a - c).cross(point - c).dot(normal)
	return (s0 >= -1e-7 and s1 >= -1e-7 and s2 >= -1e-7) or (s0 <= 1e-7 and s1 <= 1e-7 and s2 <= 1e-7)
