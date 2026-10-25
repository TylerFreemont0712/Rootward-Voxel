extends SceneTree
## Windowed art review: each of the 50 new GLBs individually, then five labelled category scenes.
## -- <output directory> [gallery-only]

const Assets := preload("res://art/world_assets.gd")
var view: ClearingView
var stage: Node3D
var out: String
var specs: Array


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	out = args[0] if not args.is_empty() else ProjectSettings.globalize_path("res://.cache/builder-library-50/review")
	specs = JSON.parse_string(FileAccess.get_file_as_string("res://art/source/world/village-library/v1/library.json")).assets
	view = ClearingView.new()
	root.add_child(view)
	view.set_process(false)
	view.set_warmth(0.65)
	view._apply_warmth(0.65)
	var grass := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(70,70)
	grass.mesh = plane
	grass.material_override = view._materials["grass"]
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.add_child(grass)
	if args.size() < 2 or args[1] != "gallery-only":
		for spec: Dictionary in specs:
			await _clear_stage()
			var model: Node3D = _model(spec,Vector3.ZERO)
			_player(Vector3(2.3,0.055,1.8))
			_camera(13,Vector3(0,0.65,0))
			await _shot("individual/%02d-%s-gameplay" % [spec.number,spec.id])
			_camera(5,Vector3(0,0.75,0))
			if not (spec.interaction as Dictionary).is_empty():
				(model.get_meta("working_visual") as PropVisual).set_active(true)
			await _shot("individual/%02d-%s-detail" % [spec.number,spec.id])
	for category: String in ["furniture","workshop","market","garden","village-magic"]:
		await _clear_stage()
		var across := Vector3(0.7071,0,-0.7071)
		var back := Vector3(-0.7071,0,-0.7071)
		var index: int = 0
		for spec: Dictionary in specs:
			if spec.category != category:
				continue
			var at: Vector3 = across * (-6.4 + (index%5)*3.2) + back * (3.3 if index<5 else -3.3)
			var model: Node3D = _model(spec,at)
			if model.has_meta("working_visual"):
				(model.get_meta("working_visual") as PropVisual).set_active(true)
			var label := Label3D.new()
			label.text = "%02d  %s" % [spec.number,spec.title]
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.font_size = 30
			label.pixel_size = 0.006
			label.outline_size = 6
			label.position = at + Vector3(0,2.55,0)
			stage.add_child(label)
			index += 1
		_player(across * 8.7 + back * -1.8 + Vector3(0,0.055,0))
		_camera(13,Vector3(0,0.75,0))
		await _shot("gallery/"+category)
	print("Library visual review: 50 individual models, gameplay/detail views and five category scenes at ",root.size)
	quit()


func _model(spec: Dictionary, at: Vector3) -> Node3D:
	var model: Node3D = Assets.instantiate(spec.id)
	stage.add_child(model)
	model.position = at
	if not (spec.interaction as Dictionary).is_empty():
		var visual := PropVisual.new()
		model.add_child(visual)
		visual.setup(model,spec.interaction)
		model.set_meta("working_visual",visual)
	return model


func _player(at: Vector3) -> void:
	var actor := SpriteAdventurer.new()
	stage.add_child(actor)
	actor.position = at


func _camera(zoom: float, focus: Vector3) -> void:
	view.camera.size = zoom
	view.camera.look_at_from_position(focus + ClearingView.CAMERA_OFFSET,focus)


func _clear_stage() -> void:
	if stage != null:
		stage.queue_free()
		await process_frame
	stage = Node3D.new()
	view.add_child(stage)


func _shot(name: String) -> void:
	for _frame: int in range(35):
		await process_frame
	await RenderingServer.frame_post_draw
	var path: String = out.path_join(name+".png")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	root.get_texture().get_image().save_png(path)
	print("Reviewed ",name)
