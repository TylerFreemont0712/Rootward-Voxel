extends "res://scenes/clearing_view.gd"
## All four views of the approved default and Mira using identical shared frames.

func _ready() -> void:
	_make_materials()
	_make_lighting()
	camera.size = 6.5
	camera.position = Vector3(6, 5, 8)
	camera.look_at(Vector3(0, 0.65, 0))
	var across := Vector3(0.8, 0, -0.6)
	var back := Vector3(-0.6, 0, -0.8)
	var ids: Array[String] = ["adventurer", "mira"]
	var directions := [Vector2(1, 0.5), Vector2(-1, 0.5), Vector2(1, -0.5), Vector2(-1, -0.5)]
	var names := ["SE", "SW", "NE", "NW"]
	for row: int in range(ids.size()):
		for column: int in range(directions.size()):
			var at := across * (-3.3 + float(column) * 2.2) + back * (2.6 if row == 0 else -2.6)
			_block(at + Vector3(0, -0.07, 0), Vector3(1.4, 0.14, 1.4), "path")
			var actor := SpriteAdventurer.new()
			actor.skin_id = ids[row]
			add_child(actor)
			actor.position = at
			actor.set_screen_motion(directions[column])
			actor.add_to_group("skin_review_actors")
			var label := Label3D.new()
			label.text = ("Original" if row == 0 else "Mira") + " · " + names[column]
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.font_size = 32
			label.pixel_size = 0.006
			label.position = at + Vector3(0, 1.85, 0)
			label.outline_size = 3
			add_child(label)
	_flush_batches()
	# The game's follow-camera update must not replace this study composition.
	set_process(false)
