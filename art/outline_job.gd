extends RefCounted
## Bounded chunks of the existing outline calculation. Sync and loading-screen builds use the same geometry.
var source: Mesh
var result := ArrayMesh.new()
var done: bool = false
var _vertices := PackedVector3Array()
var _normals := PackedVector3Array()
var _indices := PackedInt32Array()
var _sums: Dictionary = {}
var _surface: int = 0
var _points := PackedVector3Array()
var _directions := PackedVector3Array()
var _elements := PackedInt32Array()
var _cursor: int = 0
var _offset: int = 0
var _phase: String = "surface"

func _init(mesh: Mesh) -> void: source = mesh

func advance(budget_usec: int = 4000) -> void:
	var deadline: int = Time.get_ticks_usec() + budget_usec
	while not done:
		match _phase:
			"surface":
				if _surface >= source.get_surface_count():
					_cursor = 0
					_phase = "normals"
					continue
				if source is ArrayMesh and (source as ArrayMesh).surface_get_primitive_type(_surface) != Mesh.PRIMITIVE_TRIANGLES:
					_surface += 1
					continue
				var arrays: Array = source.surface_get_arrays(_surface)
				_points = arrays[Mesh.ARRAY_VERTEX]
				_directions = arrays[Mesh.ARRAY_NORMAL]
				_elements = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				_offset = _vertices.size()
				_cursor = 0
				_phase = "points"
			"points":
				var stop: int = mini(_cursor + 256, _points.size())
				for index: int in range(_cursor, stop):
					var key: Vector3 = _points[index].snapped(Vector3.ONE * .0001)
					_sums[key] = (_sums.get(key, Vector3.ZERO) as Vector3) + _directions[index]
				_cursor = stop
				if _cursor == _points.size():
					_vertices.append_array(_points)
					_cursor = 0
					_phase = "indices"
			"indices":
				var count: int = _points.size() if _elements.is_empty() else _elements.size()
				var stop: int = mini(_cursor + 512, count)
				for index: int in range(_cursor, stop):
					_indices.append(_offset + (index if _elements.is_empty() else _elements[index]))
				_cursor = stop
				if _cursor == count:
					_surface += 1
					_phase = "surface"
			"normals":
				var stop: int = mini(_cursor + 256, _vertices.size())
				for index: int in range(_cursor, stop):
					_normals.append((_sums[_vertices[index].snapped(Vector3.ONE * .0001)] as Vector3).normalized())
				_cursor = stop
				if _cursor == _vertices.size(): _phase = "mesh"
			"mesh":
				if not _vertices.is_empty():
					var arrays: Array = []
					arrays.resize(Mesh.ARRAY_MAX)
					arrays[Mesh.ARRAY_VERTEX] = _vertices
					arrays[Mesh.ARRAY_NORMAL] = _normals
					arrays[Mesh.ARRAY_INDEX] = _indices
					var uv := PackedVector2Array()
					uv.resize(_vertices.size())
					arrays[Mesh.ARRAY_TEX_UV] = uv
					result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				done = true
		if Time.get_ticks_usec() >= deadline: return
