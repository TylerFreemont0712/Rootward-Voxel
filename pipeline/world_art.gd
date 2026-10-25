extends SceneTree
## Seed export, candidate validation and unedited round-trip checks. Called by world_art.py.

const Seed := preload("res://pipeline/world_seed.gd")
const Geometry := preload("res://pipeline/world_geometry.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 3:
		_fail("Expected seed <id> <output>, audit <input> <output>, or compare <seed> <candidate>.")
		return
	match args[0]:
		"seed":
			if FileAccess.file_exists(args[2]):
				_fail("Seed already exists. Create a new version; never overwrite artist sources.")
				return
			var maker := Seed.new()
			var asset: Node3D = maker.create_asset(args[1])
			if asset == null:
				maker.free()
				_fail("Unknown procedural seed.")
				return
			var before: Dictionary = Geometry.audit(asset, true)
			var document := GLTFDocument.new()
			document.image_format = "PNG"
			var state := GLTFState.new()
			DirAccess.make_dir_recursive_absolute(args[2].get_base_dir())
			var error: Error = document.append_from_scene(asset, state)
			if error == OK:
				error = document.write_to_filesystem(state, args[2])
			asset.free()
			maker.free()
			if error != OK:
				_fail("Seed export failed: " + error_string(error))
				return
			var exported: Node3D = Geometry.read_glb(args[2])
			var after: Dictionary = Geometry.audit(exported, true)
			exported.free()
			if not Geometry.equivalent(before, after):
				print("Before: ", before.geometry_sha256, " materials: ", before.material_records)
				print("After: ", after.geometry_sha256, " materials: ", after.material_records)
				_fail("Seed export changed geometry, UVs, normals or materials beyond the declared tolerances.")
				return
			after.erase("corners")
			after.erase("normal_samples")
			_write(args[2] + ".audit.json", after)
			print("Seed exported without geometry loss: ", args[1], " — ", after.triangles, " triangles.")
		"audit":
			var asset: Node3D = Geometry.read_glb(args[1])
			if asset == null:
				_fail("Could not import candidate GLB.")
				return
			var audit: Dictionary = Geometry.audit(asset)
			asset.free()
			if int(audit.triangles) <= 0 or not _valid_bounds(audit.bounds):
				_fail("Candidate is empty, nonfinite, or exceeds the 64-unit prototype asset limit.")
				return
			_write(args[2], audit)
			print("Candidate audited: ", audit.meshes, " meshes, ", audit.triangles, " triangles.")
		"compare":
			var original: Node3D = Geometry.read_glb(args[1])
			var candidate: Node3D = Geometry.read_glb(args[2])
			if original == null or candidate == null:
				_fail("Could not read round-trip models.")
				return
			var before: Dictionary = Geometry.audit(original, true)
			var after: Dictionary = Geometry.audit(candidate, true)
			original.free()
			candidate.free()
			if not Geometry.equivalent(before, after):
				_fail("Round trip differs. Inspect geometry/UVs/normals and material names before adoption.")
				print("Before geometry/materials: ", before.geometry_sha256, "/", before.material_records, "\nAfter: ", after.geometry_sha256, "/", after.material_records)
				return
			print("Round trip preserved geometry/UVs (0.0001), normals (0.001), material colors and lossless texture pixels: ", after.triangles, " triangles.")
		_:
			_fail("Unknown world-art operation.")
			return
	quit(0)


func _valid_bounds(bounds: Array) -> bool:
	for value: Variant in bounds:
		if not is_finite(float(value)) or absf(float(value)) > 64.0:
			return false
	return true


func _write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  ") + "\n")


func _fail(reason: String) -> void:
	printerr(reason)
	quit(1)
