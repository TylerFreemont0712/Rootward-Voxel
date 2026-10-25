class_name VillageBoundary
extends RefCounted
## Land continues beyond the logical bounds: the player sees a forest horizon, never a slab underside.


static func build(parent: Node3D, area: AreaDef, material: Material, tree: Callable) -> void:
	if area.boundary.is_empty():
		return
	var apron: float = float(area.boundary.apron)
	var w: float = float(area.width)
	var h: float = float(area.height)
	# Four strips leave the river and the whole playable surface open underneath.
	for spec: Array in [[Vector2(-0.5 - apron * 0.5, -(h - 1) * 0.5), Vector2(apron, h)], [Vector2(w - 0.5 + apron * 0.5, -(h - 1) * 0.5), Vector2(apron, h)], [Vector2((w - 1) * 0.5, 0.5 + apron * 0.5), Vector2(w + apron * 2, apron)], [Vector2((w - 1) * 0.5, -h + 0.5 - apron * 0.5), Vector2(w + apron * 2, apron)]]:
		var ground := MeshInstance3D.new()
		ground.name = "DistantGround"
		var plane := PlaneMesh.new()
		plane.size = spec[1]
		ground.mesh = plane
		ground.material_override = material
		ground.position = Vector3(spec[0].x, 0.014, spec[0].y)
		ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(ground)
	# These are scenic trees outside the playable document, so they never create collision/quests.
	if area.boundary.get("forest", true):
		for x: int in range(-12, area.width + 12, 3):
			for row: int in range(3):
				var offset: float = float(GroundPaint.hash_xy(x, row) % 9) * 0.1
				tree.call(Vector3(x + offset, -0.12, 2.2 + row * 3.3), 1.0 + offset * 0.25, absi(x * 71 + row * 19))
				tree.call(Vector3(x - offset, -0.12, -h - 2.0 - row * 3.3), 1.0 + offset * 0.25, absi(x * 71 + row * 19 + 73))
		for y: int in range(0, area.height, 3):
			for row: int in range(3):
				tree.call(Vector3(-2.4 - row * 3.2, -0.12, -y), 1.05, y * 31 + row)
				tree.call(Vector3(w + 1.4 + row * 3.2, -0.12, -y), 1.05, y * 31 + row + 37)
	if not area.boundary.get("mist", true):
		return
	var mist := ShaderMaterial.new()
	mist.shader = preload("res://art/boundary.gdshader")
	for spec: Array in [[Vector3((w - 1) * 0.5, 1.5, 0.58), w, 0.0], [Vector3((w - 1) * 0.5, 1.5, -h + 0.42), w, 0.0], [Vector3(-0.58, 1.5, -(h - 1) * 0.5), h, PI * 0.5], [Vector3(w - 0.42, 1.5, -(h - 1) * 0.5), h, PI * 0.5]]:
		var wall := MeshInstance3D.new()
		wall.name = "WoodlandVeil"
		var quad := QuadMesh.new()
		quad.size = Vector2(float(spec[1]), 3.0)
		wall.mesh = quad
		wall.material_override = mist
		wall.position = spec[0]
		wall.rotation.y = float(spec[2])
		wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(wall)
