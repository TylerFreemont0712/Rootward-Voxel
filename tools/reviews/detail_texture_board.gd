extends SceneTree
## Native Godot UI review of the runtime pictures, repeated 2×2. No source image editing.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var output: String = args[0] if not args.is_empty() else ".cache/detail-materials/boards"
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/source/world/textures/v2-detail/library.json"))
	for style: String in ["lush","solid"]:
		WorldTextures.use_set(style)
		var backdrop := ColorRect.new()
		backdrop.color = Color("202d30")
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(backdrop)
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side: String in ["left","top","right","bottom"]:margin.add_theme_constant_override("margin_"+side,20)
		backdrop.add_child(margin)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation",8)
		margin.add_child(column)
		var heading := Label.new()
		heading.text = "Rootward · 15 detail materials · "+style+" · each swatch repeats 2 × 2"
		heading.add_theme_font_size_override("font_size",24)
		column.add_child(heading)
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation",12)
		grid.add_theme_constant_override("v_separation",10)
		column.add_child(grid)
		for item: Dictionary in spec.materials:
			var card := VBoxContainer.new()
			card.custom_minimum_size.x = 300
			grid.add_child(card)
			var label := Label.new()
			label.text = str(item.title)
			label.add_theme_font_size_override("font_size",18)
			card.add_child(label)
			var picture := TextureRect.new()
			picture.custom_minimum_size = Vector2(256,256)
			picture.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode = TextureRect.STRETCH_TILE
			picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			picture.texture = WorldTextures.texture(str(item.id))
			card.add_child(picture)
		for frame: int in range(3):await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(output)
		root.get_texture().get_image().save_png(output.path_join(style+".png"))
		backdrop.queue_free()
		await process_frame
	print("Detail texture board: 15 runtime paintings in both styles.")
	quit()
