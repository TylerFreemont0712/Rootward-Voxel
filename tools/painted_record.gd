extends SceneTree
## Record selected diagonal animations at a bounded, known cadence for visual review.

func _initialize() -> void:
	Engine.max_fps = 32
	_record.call_deferred()


func _record() -> void:
	root.add_child(load("res://tools/painted_study.tscn").instantiate())
	var idle_review: bool = OS.get_environment("VOXEL_IDLE_REVIEW") == "1"
	var directory: String = ProjectSettings.globalize_path("res://.cache/painted-idle" if idle_review else "res://.cache/painted-motion")
	DirAccess.make_dir_recursive_absolute(directory)
	for _warmup: int in range(8):
		await process_frame
	var closed: Dictionary = {"se": false, "sw": false}
	var blink_seen: Dictionary = {"se": false, "sw": false}
	var frame_count := 256 if idle_review else 64
	var captured := 0
	for index: int in range(frame_count):
		await process_frame
		await RenderingServer.frame_post_draw
		if not idle_review or index % 2 == 0:
			root.get_texture().get_image().save_png(directory.path_join("frame-%03d.png" % captured))
			captured += 1
		if idle_review:
			for node: Node in get_nodes_in_group("painted_review_actors"):
				var actor := node as SpriteAdventurer
				var direction: String = actor.animation_name.trim_prefix("idle_")
				if direction in closed:
					var blinking: bool = actor.sprite.frame == 1
					if blinking and not closed[direction]:
						blink_seen[direction] = true
						root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://evidence/painted-idle.png"))
					closed[direction] = blinking
	if not idle_review:
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://evidence/painted-directions.png"))
	print("Recorded selected painted animation: ", captured, " frames; idle review=", idle_review, "; visible front blinks=", blink_seen)
	quit(0 if not idle_review or (blink_seen.se and blink_seen.sw) else 1)
