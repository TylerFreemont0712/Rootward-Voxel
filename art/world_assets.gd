extends RefCounted
## Rendering-only asset selection. Logical footprints come from the world catalog and the area documents; core/ owns traversal.

const CATALOG: String = "res://pipeline/world-catalog.json"


static func entry(id: String) -> Dictionary:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	return catalog.assets.get(id, {})


static func is_blender(id: String) -> bool:
	return entry(id).get("authority", "procedural_test") == "blender"


static func area_presentation(id: String) -> Dictionary:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	return (catalog.get("areas", {}).get(id, {}) as Dictionary).get("presentation", {})


## `variant` dresses a modular house (see HouseVariants); such a house always shows one complete look, the authored
## one when no variant is given.
static func instantiate(id: String,cache_mode: int=ResourceLoader.CACHE_MODE_REUSE,variant: Dictionary={}) -> Node3D:
	var spec: Dictionary = entry(id)
	var path: String = "res://" + str(spec.get("runtime", ""))
	if not ResourceLoader.exists(path):
		push_error("Selected Blender asset missing: " + path + ". Build it with scripts/world-art.sh.")
		return null
	var scene: PackedScene = ResourceLoader.load(path,"PackedScene",cache_mode) as PackedScene
	var model: Node3D=scene.instantiate() as Node3D if scene != null else null
	if model!=null and spec.get("presentation","")=="rootward-presence":
		var presence:=RootwardPresence.new()
		presence.name="RootwardPresence"
		model.add_child(presence)
	if model != null and spec.get("illustrated_edges", false):
		IllustratedEdges.apply(model)
	if model != null:
		light_power(model)
	if model != null and spec.get("spark_blink",false):
		var blink:=RobotBlink.new()
		blink.name="SparkBlink"
		blink.setup(model)
		model.add_child(blink)
	if model != null and not spec.get("casts_shadow", true):
		_stop_casting(model)
	if model != null and HouseVariants.offers(spec):
		HouseVariants.apply(model, spec, variant)
	return model


## The city's power: any part flagged `power_grid` (conduit glass), `power_column` (a pillar's glowing shaft) or
## `power_pillar` (the older carved pilasters) gets its moving-light shader. Presentation only.
static func light_power(model: Node) -> void:
	var glow: ShaderMaterial = null
	var column: ShaderMaterial = null
	for part: Node in model.find_children("*", "MeshInstance3D", true, false):
		if WorldAssetMeta.value(part, "power_grid", false):
			if glow == null:
				glow = ShaderMaterial.new()
				glow.shader = load("res://art/power_grid.gdshader")
			(part as MeshInstance3D).material_override = glow
		elif WorldAssetMeta.value(part, "power_column", false):
			if column == null:
				column = ShaderMaterial.new()
				column.shader = load("res://art/power_column.gdshader")
			(part as MeshInstance3D).material_override = column
		elif WorldAssetMeta.value(part, "power_pillar", false):
			var pillar := ShaderMaterial.new()
			pillar.shader = load("res://art/power_pillar.gdshader")
			var stone := (part as MeshInstance3D).mesh.surface_get_material(0) as StandardMaterial3D
			if stone != null:
				pillar.set_shader_parameter("stone_texture", stone.albedo_texture)
			(part as MeshInstance3D).material_override = pillar


## A rug is a hand's breadth thick and lies on the floor, which casts nothing either. Letting it cast makes its own
## surface fight the shadow map, which shows as a hatched shadow on the weave that grows as the view pulls back.
static func _stop_casting(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_stop_casting(child)
