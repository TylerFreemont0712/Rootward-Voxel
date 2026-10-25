extends "res://scenes/clearing_view.gd"
## Render the actual generated assets at review size with the same materials and lighting.


func _ready() -> void:
	_make_materials()
	_make_lighting()
	var house: bool = OS.get_environment("VOXEL_ART_STUDY") in ["house", "seed_house"]
	if house:
		if OS.get_environment("VOXEL_ART_STUDY") == "seed_house" or not _try_world_asset("cottage", Vector3.ZERO):
			_make_house(Vector3.ZERO, false)
		_block(Vector3(0, -0.08, 0), Vector3(4.5, 0.16, 4.6), "grass")
		for index: int in range(6):
			_block(Vector3(-0.35 + float(index % 2) * 0.7, 0.015, 1.75 + float(index / 2) * 0.5), Vector3(0.66, 0.05, 0.46), "path")
		camera.size = 5.3
		camera.position = Vector3(6.0, 5.0, 8.0)
		camera.look_at(Vector3(0, 1.7, 0))
	else:
		_make_player()
		_player.position = Vector3.ZERO
		_block(Vector3(0, -0.06, 0), Vector3(1.7, 0.12, 1.7), "path")
		camera.size = 2.2
		camera.position = Vector3(2.5, 1.95, 4.8)
		camera.look_at(Vector3(0, 0.71, 0))
	_flush_batches()
