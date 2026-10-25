extends "res://scenes/clearing_view.gd"
## Actual selected whole-body actors. No alternate illustration or cutout stand-in.

func _ready() -> void:
	_make_materials()
	_make_lighting()
	camera.size = 6.1
	camera.position = Vector3(6, 5, 8)
	camera.look_at(Vector3(0, 0.65, 0))
	var directions: Dictionary = {"se": Vector2(1, 0.5), "sw": Vector2(-1, 0.5), "ne": Vector2(1, -0.5), "nw": Vector2(-1, -0.5)}
	var index: int = 0
	var idle_review: bool = OS.get_environment("VOXEL_IDLE_REVIEW") == "1"
	var across := Vector3(0.8, 0, -0.6)
	var back := Vector3(-0.6, 0, -0.8)
	for direction: String in directions:
		var position_3d: Vector3 = across * (-1.25 if index % 2 == 0 else 1.25) + back * (2.0 if index < 2 else -2.0)
		_block(position_3d + Vector3(0, -0.07, 0), Vector3(1.2, 0.14, 1.2), "path")
		var actor := SpriteAdventurer.new()
		add_child(actor)
		actor.position = position_3d
		actor.set_screen_motion(directions[direction])
		actor.add_to_group("painted_review_actors")
		if idle_review:
			actor.set_screen_motion(Vector2.ZERO)
		index += 1
	_flush_batches()
