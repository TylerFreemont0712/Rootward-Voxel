extends SceneTree
## Windowed GPU proofs and six transition pairs. -- <output dir>
## Default tones are compared to those same explicit tones; uniform grass is separately compared
## against a single continuous plane, including across 16-cell chunk boundaries.

var viewport: SubViewport
var holder: Node3D
var camera: Camera3D
var out: String
var checks: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("ground_shot requires a window and a real renderer")
		quit(1)
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	out = args[0] if not args.is_empty() else "res://.cache/ground-shot"
	DirAccess.make_dir_recursive_absolute(out)
	_setup()
	for pair: Array in [["grass", "dirt"], ["grass", "path"], ["dirt", "path"], ["grass", "soil"], ["dirt", "pebbles"], ["path", "pebbles"]]:
		var doc: Dictionary = _document(16)
		var paint: Dictionary = _paint(16)
		paint.palette = pair
		for row: int in range(32):
			paint.rows[row] = "0".repeat(16) + "1".repeat(16)
		doc.paint = paint
		var skin: GroundSkin = _skin(doc)
		camera.position = Vector3(7.5, 20, -7.5)
		camera.size = 2.0
		camera.look_at(Vector3(7.5, 0, -7.5), Vector3(0, 0, -1))
		var image: Image = await _capture()
		image.save_png(out.path_join("%s-%s.png" % [pair[0], pair[1]]))
		skin.free()
	await _seams(6, false)
	await _seams(32, true)
	var record: Dictionary = {"checks": checks, "failures": failures, "renderer": RenderingServer.get_current_rendering_method(), "gpu": RenderingServer.get_video_adapter_name(), "pixel_proofs": "derived versus exact explicit tones; uniform ground versus a single continuous plane, including chunk edges"}
	var file := FileAccess.open(out.path_join("review.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(record, "  "))
	print("Ground GPU review: %d checks, %d failures -> %s" % [checks, failures.size(), out])
	for failure: String in failures:
		printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)


func _setup() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(512, 512)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var preview := TextureRect.new()
	preview.texture = viewport.get_texture()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(preview)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("24272a")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.7
	viewport.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-90, 0, 0)
	sun.light_energy = 0.3
	viewport.add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.far = 100.0
	viewport.add_child(camera)
	holder = Node3D.new()
	viewport.add_child(holder)


func _document(side: int) -> Dictionary:
	var rows: Array = []
	for y: int in range(side):
		rows.append(".".repeat(side))
	return {"schema": 1, "id": "ground-shot", "title": "Ground shot", "version": 1, "size": [side, side], "terrain": rows, "spawn": [1, 1]}


func _paint(side: int) -> Dictionary:
	var rows: Array = []
	for y: int in range(side * 2):
		rows.append(".".repeat(side * 2))
	return {"version": 1, "palette": GroundPaint.DEFAULT_PALETTE.duplicate(), "roughen": 0.4, "rows": rows}


func _skin(document: Dictionary) -> GroundSkin:
	var parsed: Dictionary = AreaDef.parse(document, {})
	var skin := GroundSkin.new()
	_check(parsed.ok and skin.build(parsed.area), "The review area builds")
	holder.add_child(skin)
	return skin


func _capture() -> Image:
	for frame: int in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()


func _seams(side: int, chunk_test: bool) -> void:
	var doc: Dictionary = _document(side)
	var skin: GroundSkin = _skin(doc)
	var centre: float = float(side - 1) * 0.5
	camera.position = Vector3(centre, 20, -centre)
	camera.size = 6.0
	camera.look_at(Vector3(centre, 0, -centre), Vector3(0, 0, -1))
	var defaults: Image = await _capture()
	var paint: Dictionary = _paint(side)
	for sy: int in range(side * 2):
		var line: String = ""
		for sx: int in range(side * 2):
			line += GroundPaint.DIGITS[GroundPaint.DEFAULT_PALETTE.find(GroundPaint.material_at(skin.area, Vector2i(sx, sy)))]
		paint.rows[side * 2 - 1 - sy] = line
	doc.paint = paint
	skin.update_area(AreaDef.parse(doc, {}).area)
	var explicit: Image = await _capture()
	_check(defaults.get_data() == explicit.get_data(), "%dx%d defaults and their explicit tones have identical pixels" % [side, side])
	for row: int in range(side * 2):
		doc.paint.rows[row] = "0".repeat(side * 2)
	skin.update_area(AreaDef.parse(doc, {}).area)
	var uniform: Image = await _capture()
	uniform.save_png(out.path_join("uniform-%d.png" % side))
	if not chunk_test:
		defaults.save_png(out.path_join("defaults-6.png"))
		print("Requested default versus all-grass equality: ", defaults.get_data() == uniform.get_data(), " (tone overrides deliberately change appearance)")
	var material: ShaderMaterial = skin.material
	skin.visible = false
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(side, side)
	plane.mesh = mesh
	plane.position = Vector3(centre, GroundSkin.HEIGHT, -centre)
	plane.material_override = material
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(plane)
	var continuous: Image = await _capture()
	_check(uniform.get_data() == continuous.get_data(), "%dx%d uniform sub-tile/chunk skin matches one continuous plane pixel for pixel" % [side, side])
	plane.free()
	skin.free()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
