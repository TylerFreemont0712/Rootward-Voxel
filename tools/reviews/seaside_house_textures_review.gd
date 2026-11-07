extends SceneTree
## Actual built texture pixels, tiled 2x2 for seam and colour review. No world/model changes.

const SOURCE: String="res://art/source/world/seaside-background-houses/v1/textures/library.json"
const MANIFEST: String="res://assets/world/textures/seaside-houses/manifest.json"

func _initialize()->void:
	_run.call_deferred()

func _run()->void:
	root.content_scale_size=root.size
	var library: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var output:=ProjectSettings.globalize_path("res://evidence/seaside-house-textures/2026-10-29")
	DirAccess.make_dir_recursive_absolute(output)
	for style: String in ["lush","solid"]:
		var background:=ColorRect.new()
		background.color=Color("24363d")
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(background)
		var heading:=Label.new()
		heading.text="Seaside houses · 5 surfaces × 3 colours · "+style+" · each sample repeats 2 × 2"
		heading.position=Vector2(24,16)
		heading.add_theme_font_size_override("font_size",25)
		background.add_child(heading)
		for colour: int in range(3):
			for family: int in range(5):
				var item: Dictionary=library.materials[family*3+colour]
				var label:=Label.new()
				label.text=item.title
				label.add_theme_font_size_override("font_size",18)
				label.position=Vector2(24+family*310,60+colour*300)
				background.add_child(label)
				var tile:=TextureRect.new()
				tile.position=label.position+Vector2(0,28)
				tile.size=Vector2(256,256)
				tile.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
				tile.stretch_mode=TextureRect.STRETCH_TILE
				tile.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
				tile.texture=load(manifest.materials[item.id].outputs[style].path)
				background.add_child(tile)
		for _index: int in range(4):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(style+".png"))
		background.queue_free()
		await process_frame
	print("Seaside house textures: 15 built maps in two styles reviewed at 2x2 repetition.")
	quit()
