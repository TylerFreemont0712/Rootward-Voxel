extends SceneTree

func _initialize() -> void:
	_record.call_deferred()

func _record() -> void:
	root.add_child((load("res://tools/cutout_study.tscn") as PackedScene).instantiate())
	var directory: String = ProjectSettings.globalize_path("res://.cache/cutout-review")
	DirAccess.make_dir_recursive_absolute(directory)
	var captured: int = 0
	for frame: int in range(120):
		await physics_frame
		await RenderingServer.frame_post_draw
		if frame % 3 == 0:
			root.get_texture().get_image().save_png(directory.path_join("frame-%03d.png" % captured))
			captured += 1
	print("Native cutout review recorded: ", captured, " frames at 20 FPS.")
	quit(0)
