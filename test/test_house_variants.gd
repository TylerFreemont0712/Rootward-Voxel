extends SceneTree
## Modular seaside houses: each declared variant part exists in the built model, a placement always shows one complete
## look, seeds give deterministic variety, instances never share overrides, and the showcase can present them.

const WorldAssets := preload("res://art/world_assets.gd")
const HOUSES: Array[String] = ["seaside-rosewash-house", "seaside-saltwind-house", "seaside-lantern-row-house",
		"seaside-shingle-court-cottage", "seaside-eaveside-terrace"]
# The user retained the detailed foliage on 2026-10-30 pending their in-game
# review. Keep an explicit ceiling per model, roughly 10% above this revision.
const TRIANGLE_BUDGETS := {
	"seaside-rosewash-house": 160000,
	"seaside-saltwind-house": 175000,
	"seaside-lantern-row-house": 205000,
	"seaside-shingle-court-cottage": 145000,
	"seaside-eaveside-terrace": 280000,
}
var checks: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()


func _run() -> void:
	_textures()
	for id: String in HOUSES:
		_house(id)
	await _showcase()
	if failures.is_empty():
		print("Modular house variants: %d checks passed." % checks)
		quit()
	else:
		for failure: String in failures:
			printerr(failure)
		quit(1)


func _textures() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/textures/seaside-houses/manifest.json"))
	_check(HouseVariants.palettes().keys().size() == 3, "The library's three curated palettes travel with the runtime manifest")
	for id: String in manifest.materials:
		var output: Dictionary = manifest.materials[id].outputs.get("detail", {})
		_check(str(output.get("path", "")).begins_with("res://assets/world/textures/seaside-houses/detail/") and FileAccess.get_sha256(str(output.path)) == str(output.get("sha256", "")), id + " has its built 512 detail painting")
		var image := Image.load_from_file(ProjectSettings.globalize_path(str(output.path)))
		var periodic: bool = image.get_size() == Vector2i(512, 512)
		for i: int in range(0, 512, 7):
			periodic = periodic and image.get_pixel(0, i) == image.get_pixel(511, i) and image.get_pixel(i, 0) == image.get_pixel(i, 511)
		_check(periodic, id + " detail painting tiles with paired edges")
		var config := ConfigFile.new()
		config.load(str(output.path) + ".import")
		_check(config.get_value("params", "compress/mode") == 0 and config.get_value("params", "mipmaps/generate"), id + " detail painting imports lossless with mipmaps")
		_check(HouseVariants.texture(id) != null, id + " loads for runtime swaps")


func _house(id: String) -> void:
	var spec: Dictionary = WorldAssets.entry(id)
	var block: Dictionary = spec.get("variants", {})
	_check(spec.get("status", "") == "showcase_only" and HouseVariants.offers(spec), id + " is catalogued for the showcase with variants")
	_check(not block.details.has("paving"), id + " brings no paving or sidewalk of its own")
	var model: Node3D = WorldAssets.instantiate(id)
	_check(model != null, id + " instantiates from its built model")
	if model == null:
		return
	var nodes: Dictionary = {}
	var materials: Dictionary = {}
	_collect(model, nodes, materials)
	for slot: String in block.surfaces:
		var surface: Dictionary = block.surfaces[slot]
		for material: String in surface.materials:
			_check(materials.has(material), "%s carries the %s material %s" % [id, slot, material])
		_check(str(surface.authored) in surface.choices and surface.choices.size() == 3, "%s %s offers its authored and two other paintings" % [id, slot])
	for name: String in nodes:
		if name.begins_with("detail_") or name.begins_with("alt_"):
			_check(HouseVariants._shown(name, block, HouseVariants.authored(spec)) != null, "%s declares its optional part %s" % [id, name])
	for detail: String in block.details:
		_check(nodes.has("detail_" + detail), "%s has the %s dressing" % [id, detail])
	for group: String in block.alternates:
		for option: String in block.alternates[group]:
			_check(nodes.has("alt_%s_%s" % [group, option]), "%s has the %s %s alternative" % [id, option, group])
	# Authored look: first option of each alternative, every detail, no painting overrides.
	var authored_ok: bool = true
	for name: String in nodes:
		var node: Node3D = nodes[name]
		for group: String in block.alternates:
			for option: String in block.alternates[group]:
				if name.trim_suffix("_glass") == "alt_%s_%s" % [group, option]:
					authored_ok = authored_ok and node.visible == (option == block.alternates[group][0])
		if name.begins_with("detail_"):
			authored_ok = authored_ok and node.visible
	_check(authored_ok and _overrides(model) == 0, id + " without a variant shows exactly its authored look")
	# Seeds: deterministic, and over a street's worth of houses every choice turns up.
	_check(HouseVariants.pick(spec, 41) == HouseVariants.pick(spec, 41), id + " picks the same look for the same seed")
	var seen: Dictionary = {}
	for seed: int in range(80):
		var look: Dictionary = HouseVariants.pick(spec, seed)
		for slot: String in look.surfaces:
			seen["%s=%s" % [slot, look.surfaces[slot]]] = true
		for name: String in look.details:
			seen["%s=%s" % [name, look.details[name]]] = true
		for group: String in look.alternates:
			seen["%s=%s" % [group, look.alternates[group]]] = true
	var missing: Array[String] = []
	for slot: String in block.surfaces:
		for choice: String in block.surfaces[slot].choices:
			if not seen.has("%s=%s" % [slot, choice]):missing.append(slot + " " + choice)
	for group: String in block.alternates:
		for option: String in block.alternates[group]:
			if not seen.has("%s=%s" % [group, option]):missing.append(group + " " + option)
	for name: String in block.details:
		if float(block.details[name]) < 1.0 and not (seen.has(name + "=true") and seen.has(name + "=false")):missing.append(name)
	_check(missing.is_empty(), "%s: 80 seeds reach every painting, alternative and detail state %s" % [id, missing])
	# A placed variant swaps paintings on its own instance only and hides what it leaves out.
	var look: Dictionary = HouseVariants.pick(spec, 3)
	look.surfaces.plaster = block.surfaces.plaster.choices[0] if block.surfaces.plaster.authored != block.surfaces.plaster.choices[0] else block.surfaces.plaster.choices[1]
	look.details[block.details.keys()[0]] = false
	var other: Node3D = WorldAssets.instantiate(id, ResourceLoader.CACHE_MODE_REUSE, look)
	var plaster: Texture2D = _texture(other, "seaside_plaster")
	_check(plaster == HouseVariants.texture(str(look.surfaces.plaster)), id + " shows the variant's plaster painting")
	_check(_texture(model, "seaside_plaster") != plaster and _original_texture(other, "seaside_plaster") == _original_texture(model, "seaside_plaster"), id + " leaves the shared imported material and other instances untouched")
	var hidden: Node3D = other.find_child("detail_" + str(block.details.keys()[0]), true, false)
	_check(hidden != null and not hidden.visible, id + " hides dressing the variant leaves out")
	HouseVariants.apply(other, spec, HouseVariants.authored(spec))
	_check(_overrides(other) == 0 and hidden.visible, id + " returns to its authored look when re-dressed")
	var warm: Dictionary = HouseVariants.with_palette(spec, "warm_lane")
	_check(warm.surfaces.plaster == "seaside_plaster_cream" and warm.surfaces.roof == "seaside_roof_terracotta", id + " takes a curated palette")
	_check(not HouseVariants.summary(spec, look).is_empty(), id + " names its look in one line")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://" + str(spec.runtime).get_base_dir() + "/manifest.json"))
	# A joined pair counts as two homes.
	var homes: int = 2 if block.surfaces.has("plaster_2") else 1
	var triangle_budget: int = int(TRIANGLE_BUDGETS[id])
	_check(int(manifest.audit.triangles) <= triangle_budget, "%s stays within its foliage review budget (%d / %d triangles)" % [id, int(manifest.audit.triangles), triangle_budget])
	_check(_surfaces(model) <= 32 + 10 * homes, "%s shares one palette material for its plain colours (%d surfaces)" % [id, _surfaces(model)])
	if homes == 2:
		var pair: Dictionary = HouseVariants.authored(spec)
		_check(pair.surfaces.plaster != pair.surfaces.plaster_2 and HouseVariants.with_palette(spec, "warm_lane").surfaces.plaster_2 == pair.surfaces.plaster_2, id + " paints its second home on its own, outside the curated palettes")
		_check(HouseVariants.summary(spec, pair).contains("next door"), id + " names the second home's look")
	model.free()
	other.free()


func _showcase() -> void:
	var screen := AssetShowcase.new()
	screen.setup()
	root.add_child(screen)
	await process_frame
	_check(screen.show_asset("seaside-rosewash-house") and screen.variant_row.visible, "The showcase offers looks for a modular house")
	var first: String = screen._variant_note.text
	screen.shuffle_variant()
	_check(screen.variant_mode.selected == screen.variant_mode.item_count - 1 and screen.variant.seed == screen.variant_seed, "Shuffle shows a seeded look")
	screen.variant_mode.select(1)
	screen._choose_look()
	_check(screen._variant_note.text != first or screen.variant != HouseVariants.authored(WorldAssets.entry("seaside-rosewash-house")), "A curated palette changes the look on show")
	screen.street.button_pressed = true
	await process_frame
	var row: Node = screen.stage._pivot.find_child("Street", true, false) if screen.stage.get("_pivot") != null else null
	_check(row != null and row.get_child_count() == 3, "Street of three stands two shuffled neighbours beside it")
	screen.street.button_pressed = false
	_check(screen.show_asset("seaside-saltwind-house") and screen.variant_mode.selected == 0, "Another house starts from its authored look")
	_check(screen.show_asset("lane-bench") and not screen.variant_row.visible, "Ordinary models show no look controls")
	screen.queue_free()
	await process_frame


func _collect(node: Node, nodes: Dictionary, materials: Dictionary) -> void:
	if node is Node3D:
		nodes[str(node.name)] = node
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		for index: int in range((node as MeshInstance3D).mesh.get_surface_count()):
			var material: Material = (node as MeshInstance3D).mesh.surface_get_material(index)
			if material != null:
				materials[material.resource_name] = true
	for child: Node in node.get_children():
		_collect(child, nodes, materials)


func _surfaces(node: Node) -> int:
	var count: int = 0
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null and node.name != &"IllustratedOutline":
		count += (node as MeshInstance3D).mesh.get_surface_count()
	for child: Node in node.get_children():
		count += _surfaces(child)
	return count


func _overrides(node: Node) -> int:
	var count: int = 0
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		for index: int in range((node as MeshInstance3D).mesh.get_surface_count()):
			if (node as MeshInstance3D).get_surface_override_material(index) != null:
				count += 1
	for child: Node in node.get_children():
		count += _overrides(child)
	return count


func _texture(node: Node, material_name: String) -> Texture2D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		for index: int in range((node as MeshInstance3D).mesh.get_surface_count()):
			var original: Material = (node as MeshInstance3D).mesh.surface_get_material(index)
			if original != null and original.resource_name == material_name:
				return ((node as MeshInstance3D).get_active_material(index) as BaseMaterial3D).albedo_texture
	for child: Node in node.get_children():
		var found: Texture2D = _texture(child, material_name)
		if found != null:
			return found
	return null


func _original_texture(node: Node, material_name: String) -> Texture2D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		for index: int in range((node as MeshInstance3D).mesh.get_surface_count()):
			var original := (node as MeshInstance3D).mesh.surface_get_material(index) as BaseMaterial3D
			if original != null and original.resource_name == material_name:
				return original.albedo_texture
	for child: Node in node.get_children():
		var found: Texture2D = _original_texture(child, material_name)
		if found != null:
			return found
	return null


func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
