extends SceneTree
## Before/after at the approved camera heading; review only, no session or saves.
## -- <output folder>

const Geometry := preload("res://pipeline/world_geometry.gd")
const WorldAssets := preload("res://art/world_assets.gd")
const Models := ["loft-floor-plant", "loft-shelf", "workshop-shop-doors", "lane-planter",
	"town-planter-bench", "lane-tree", "lane-cypress", "seaside-rosewash-house", "rootwell-beacon"]

func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	run.call_deferred()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("Use an output folder")
		quit(2)
		return
	var output: String = args[0]
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size = root.size
	var page := VBoxContainer.new()
	page.theme = UITheme.theme()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(page)
	var heading := UI.heading("Plant forms", 24)
	page.add_child(heading)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(row)
	var panels: Array[AssetShowcaseStage] = []
	for title: String in ["Before", "Pointed leaves and stems"]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		column.add_child(UI.heading(title, 20))
		var stage := AssetShowcaseStage.new()
		stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.add_child(stage)
		stage.set_guide(false)
		stage.spinning = false
		panels.append(stage)
	await process_frame
	for id: String in Models:
		heading.text = id.replace("-", " ").capitalize()
		var previous := ProjectSettings.globalize_path("res://.cache/world-art/%s/previous.glb" % id)
		if id == "loft-floor-plant":
			previous = ProjectSettings.globalize_path("res://.cache/plant-style/floor-before.glb")
		if id == "town-planter-bench":
			previous = ProjectSettings.globalize_path("res://.cache/plant-style/bench-before.glb")
		var old := Geometry.read_glb(previous)
		if old == null:
			printerr("Missing previous model: ", id)
			quit(1)
			return
		if WorldAssets.entry(id).get("illustrated_edges", false):
			IllustratedEdges.apply(old)
		WorldAssets.light_power(old)
		if HouseVariants.offers(WorldAssets.entry(id)):
			HouseVariants.apply(old, WorldAssets.entry(id), {})
		panels[0].display(old)
		panels[1].display(WorldAssets.instantiate(id))
		for angle: int in [0, 180]:
			for panel: AssetShowcaseStage in panels:
				panel._pivot.rotation_degrees.y = angle
				panel._angle = angle
				panel._target = angle
			var camera_size: float = maxf(panels[0]._fit_size, panels[1]._fit_size)
			for panel: AssetShowcaseStage in panels:
				panel._camera.size = camera_size
			for frame: int in range(6):
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("%s-%d.png" % [id, angle]))
		print("Reviewed front/rear: ", id)
	quit(0)
