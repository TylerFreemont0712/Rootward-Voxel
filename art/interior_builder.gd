class_name InteriorBuilder
extends RefCounted
## A furnished cutaway room from its area document. Furniture collision belongs to LabWorld.


static func build(area: AreaDef, block: Callable) -> void:
	var palette: Dictionary = area.interior.get("materials", {}).duplicate(true)
	palette.merge(area.interior.get("finishes", {}), true)
	var w: float = float(area.width)
	var h: float = float(area.height)
	var middle := Vector3((w - 1.0) * 0.5, -0.12, -(h - 1.0) * 0.5)
	block.call(middle, Vector3(w, 0.28, h), str(palette.get("timber", "wood_dark")))
	# Long boards and narrow joints keep the painted floor at the existing world texture scale.
	if palette.has("floor"):
		block.call(Vector3((w-1.0)*0.5, 0.017, -(h-1.0)*0.5), Vector3(w, 0.045, h), str(palette.floor))
	else:
		for x: int in range(area.width):
			block.call(Vector3(x, 0.017, -(h - 1.0) * 0.5), Vector3(0.97, 0.045, h), "wood_light" if x % 4 else "oak")
	# Far walls are full height; near walls are cut away so the camera never hides the apprentice.
	for spec: Array in [[Vector3(-0.45, 1.45, -(h - 1.0) * 0.5), Vector3(0.24, 2.9, h)], [Vector3((w - 1.0) * 0.5, 1.45, -h + 0.45), Vector3(w, 2.9, 0.24)]]:
		block.call(spec[0], spec[1], str(palette.get("walls", "plaster")))
	for x: float in [-0.3, w - 0.7]:
		block.call(Vector3(x, 0.2, -(h - 1.0) * 0.5), Vector3(0.18, 0.35, h), str(palette.get("timber", "wood_dark")))
	for y: float in [-0.3, h - 0.7]:
		block.call(Vector3((w - 1.0) * 0.5, 0.2, -y), Vector3(w, 0.35, 0.18), str(palette.get("timber", "wood_dark")))
	for x: int in range(1, area.width, 3):
		block.call(Vector3(x, 1.5, -h + 0.65), Vector3(0.14, 3.0, 0.14), str(palette.get("timber", "wood_dark")))
	for y: int in range(1, area.height, 3):
		block.call(Vector3(-0.3, 1.5, -y), Vector3(0.14, 3.0, 0.14), str(palette.get("timber", "wood_dark")))
	for x: float in [w * 0.33, w * 0.7]:
		block.call(Vector3(x, 1.85, -h + 0.7), Vector3(1.5, 1.1, 0.08), "window_warm")
		block.call(Vector3(x, 1.85, -h + 0.77), Vector3(0.07, 1.2, 0.07), str(palette.get("timber", "wood_dark")))
		block.call(Vector3(x, 1.85, -h + 0.77), Vector3(1.6, 0.07, 0.07), str(palette.get("timber", "wood_dark")))
	for furniture: Dictionary in area.interior.furniture:
		_furniture(furniture, block, palette)
	var exit: Array = area.interior.exit
	block.call(Vector3(exit[0], 0.065, -float(exit[1])), Vector3(1.2, 0.035, 1.5), str(palette.get("cloth", "cloth")))
	block.call(Vector3(exit[0], 0.09, -float(exit[1]) + 0.65), Vector3(1.3, 0.04, 0.12), "gold")
	# An open door frame at the cutaway edge makes walking out legible.
	for side: float in [-1.0, 1.0]:
		block.call(Vector3(float(exit[0]) + side * 0.75, 1.22, -float(exit[1]) + 0.65), Vector3(0.18, 2.35, 0.22), str(palette.get("timber", "wood_dark")))
	block.call(Vector3(exit[0], 2.40, -float(exit[1]) + 0.65), Vector3(1.68, 0.22, 0.24), str(palette.get("timber", "wood_dark")))


static func _furniture(item: Dictionary, block: Callable, palette: Dictionary = {}) -> void:
	var at := Vector3(item.at.x, 0.0, -item.at.y)
	var size: Vector2 = item.size
	match str(item.kind):
		"rug":
			block.call(at + Vector3(0, 0.064, 0), Vector3(size.x, 0.025, size.y), str(palette.get("rug", "cloth_dark")))
			block.call(at + Vector3(0, 0.079, 0), Vector3(size.x - 0.22, 0.012, size.y - 0.22), str(palette.get("rug", str(palette.get("cloth", "cloth")))))
		"bed":
			block.call(at + Vector3(0, 0.3, 0), Vector3(size.x, 0.5, size.y), str(palette.get("timber", "wood_dark")))
			block.call(at + Vector3(0, 0.62, 0), Vector3(size.x - 0.18, 0.18, size.y - 0.15), "cream")
			block.call(at + Vector3(0, 0.75, 0.3), Vector3(size.x - 0.14, 0.12, size.y - 0.7), str(palette.get("cloth", "cloth")))
			block.call(at + Vector3(0, 0.77, -size.y * 0.33), Vector3(size.x * 0.7, 0.25, 0.6), str(palette.get("cloth", "cloth_light")))
			block.call(at + Vector3(0, 0.8, -size.y * 0.5), Vector3(size.x, 1.25, 0.16), str(palette.get("timber", "wood")))
		"hearth":
			block.call(at + Vector3(0, 0.18, 0), Vector3(size.x, 0.35, size.y), str(palette.get("hearth", "stone")))
			block.call(at + Vector3(0, 0.62, -0.35), Vector3(size.x, 1.2, 0.4), str(palette.get("hearth", "stone_dark")))
			block.call(at + Vector3(0, 0.33, 0.05), Vector3(size.x * 0.55, 0.26, 0.5), "window_glow")
			for x: float in [-0.35, 0.35]:
				block.call(at + Vector3(x, 0.42, 0.05), Vector3(0.15, 0.4, 0.55), "wood_dark", Vector3(0, x, 0.3))
		"shelf":
			block.call(at + Vector3(0, 1.05, 0), Vector3(size.x, 2.1, size.y), str(palette.get("timber", "wood_dark")))
			for level: float in [0.45, 1.0, 1.55]:
				block.call(at + Vector3(0, level, size.y * 0.4), Vector3(size.x + 0.08, 0.1, size.y + 0.1), str(palette.get("timber", "oak_light")))
				for book: int in range(7):
					block.call(at + Vector3(-size.x * 0.4 + float(book) * size.x * 0.12, level + 0.22, size.y * 0.43), Vector3(0.18, 0.32 + float(book % 3) * 0.05, 0.32), ["roof", "teal", "cream", "wood_light"][book % 4])
		_:
			var height: float = 0.53 if item.kind in ["bench", "chair"] else 0.95
			block.call(at + Vector3(0, height, 0), Vector3(size.x, 0.15, size.y), str(palette.get("timber", "oak_light")))
			for x: float in [-0.35, 0.35]:
				for y: float in [-0.33, 0.33]:
					block.call(at + Vector3(size.x * x, height * 0.5, size.y * y), Vector3(0.15, height, 0.15), str(palette.get("timber", "wood_dark")))
			if item.kind == "chair":
				block.call(at + Vector3(0, 0.92, -size.y * 0.4), Vector3(size.x, 0.7, 0.1), str(palette.get("timber", "wood")))
