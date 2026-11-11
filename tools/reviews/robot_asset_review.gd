extends SceneTree
## Native comparison: source concept / previous GLB / current GLB, all four diagonal views.
## -- <robot-id> <output-folder> [previous-GLB-path]

var panels: Array[AssetShowcaseStage]=[]

func _initialize()->void:run.call_deferred()

func run()->void:
	root.content_scale_size=root.size
	var args:=OS.get_cmdline_user_args()
	if args.size()<2:printerr("Use robot-id output-folder [previous-GLB]");quit(2);return
	var id:=str(args[0])
	var output:=str(args[1])
	DirAccess.make_dir_recursive_absolute(output)
	var page:=VBoxContainer.new()
	page.theme=UITheme.theme()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(page)
	page.add_child(UI.heading(id.replace("robot-","").capitalize()+" · concept and model review",28))
	var row:=HBoxContainer.new()
	row.size_flags_vertical=Control.SIZE_EXPAND_FILL
	page.add_child(row)
	var reference_column:=VBoxContainer.new()
	reference_column.custom_minimum_size.x=360
	row.add_child(reference_column)
	reference_column.add_child(UI.heading("Concept",20))
	var source:=Image.load_from_file(ProjectSettings.globalize_path("res://docs/concept/v0.72/art/robots/"+id.trim_prefix("robot-")+"-sheet.png"))
	var atlas:=AtlasTexture.new()
	atlas.atlas=ImageTexture.create_from_image(source)
	atlas.region=Rect2(0,0,source.get_width()/4.0,source.get_height()/3.0)
	var reference:=TextureRect.new()
	reference.texture=atlas
	reference.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	reference.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reference.size_flags_vertical=Control.SIZE_EXPAND_FILL
	reference_column.add_child(reference)
	for previous: bool in [true,false] if args.size()>2 else [false]:
		var column:=VBoxContainer.new()
		column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(column)
		column.add_child(UI.heading("Previous model" if previous else "Refined model",20))
		var stage:=AssetShowcaseStage.new()
		stage.size_flags_vertical=Control.SIZE_EXPAND_FILL
		column.add_child(stage)
		var model: Node3D
		if previous:
			model=load("res://pipeline/world_geometry.gd").read_glb(str(args[2]))
			IllustratedEdges.apply(model)
		else:model=load("res://art/world_assets.gd").instantiate(id)
		stage.set_guide(false)
		stage.display(model)
		panels.append(stage)
	for angle: int in [0,90,180,270]:
		for stage: AssetShowcaseStage in panels:stage._pivot.rotation_degrees.y=angle
		await frames(4)
		await shot(output,"view-%d"%angle)
	var current:=panels[-1]._pivot.get_child(0)
	var blink:=current.get_node_or_null("SparkBlink") as RobotBlink
	if blink!=null:
		blink.set_process(false)
		blink.blink()
		blink._process(.065)
		for panel: AssetShowcaseStage in panels:panel._pivot.rotation_degrees.y=0
		await frames(2)
		await shot(output,"blink")
	quit()

func frames(count: int)->void:
	for index: int in range(count):await process_frame

func shot(output: String,id: String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(id+".png"))
