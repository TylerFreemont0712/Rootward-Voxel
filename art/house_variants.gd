class_name HouseVariants
extends RefCounted
## Per-placement variety for modular houses, so a street of the same model is not a row of copies. Rendering only:
## a variant swaps each surface family's painting (one shared material per family, `seaside_<slot>`) and shows or
## hides the model's optional dressing (`detail_<name>`) and alternatives (`alt_<group>_<option>`). Footprint,
## collision and doors never change. The catalog's `variants` block names what an asset offers:
##   surfaces:   slot -> {materials, authored, choices[, follows]}   paintings from the texture manifest; a joined
##               building's second home has its own slots ending `_2`, left out of the curated palettes
##   details:    name -> chance of being shown when a variant is picked from a seed
##   alternates: group -> [options]; the first is the authored one
## A variant is {"surfaces": {slot: id}, "details": {name: bool}, "alternates": {group: option}, "seed": n}; any key
## left out keeps the authored choice.

static var _manifest: Dictionary = {}
static var _textures: Dictionary = {}
static var _materials: Dictionary = {}

const FAMILY_WORDS: Dictionary = {"plaster": "limewash", "roof": "roof", "ridge": "ridge tiles", "stone": "stone", "timber": "timber", "shutter": "shutters"}


static func offers(spec: Dictionary) -> bool:
	return spec.get("variants", {}) is Dictionary and not (spec.get("variants", {}) as Dictionary).is_empty()


## The authored look: every authored painting, all dressing shown, each alternative's first option.
static func authored(spec: Dictionary) -> Dictionary:
	var block: Dictionary = spec.get("variants", {})
	var result: Dictionary = {"surfaces": {}, "details": {}, "alternates": {}, "seed": 0}
	for slot: String in block.get("surfaces", {}):
		result.surfaces[slot] = str(block.surfaces[slot].authored)
	for name: String in block.get("details", {}):
		result.details[name] = true
	for group: String in block.get("alternates", {}):
		result.alternates[group] = str(block.alternates[group][0])
	return result


## The curated palettes from the texture library (family -> painting id), by name.
static func palettes() -> Dictionary:
	return _library().get("presets", {})


## A placement's `look`: a seed (HouseVariants.pick), a curated palette name, "authored", or
## {seed | palette, plain} where plain hides all the dressing (for houses that are only glimpsed).
static func look(spec: Dictionary, value: Variant) -> Dictionary:
	if not offers(spec):
		return {}
	var result: Dictionary = authored(spec)
	var settings: Dictionary = value if value is Dictionary else {}
	var choice: Variant = settings.get("seed", settings.get("palette", null)) if value is Dictionary else value
	if choice is int or choice is float:
		result = pick(spec, int(choice))
	elif choice is String and choice != "authored":
		result = with_palette(spec, choice)
	if bool(settings.get("plain", false)):
		for name: String in result.details:
			result.details[name] = false
	return result


## The authored look recoloured with one curated palette.
static func with_palette(spec: Dictionary, palette: String) -> Dictionary:
	var result: Dictionary = authored(spec)
	var colours: Dictionary = palettes().get(palette, {})
	var block: Dictionary = spec.get("variants", {}).get("surfaces", {})
	for slot: String in block:
		var family: String = str(block[slot].get("follows", slot))
		if colours.has(family) and str(colours[family]) in block[slot].choices:
			result.surfaces[slot] = str(colours[family])
	return result


## A deterministic variant from a seed: often the authored or a curated palette, sometimes each family on its own;
## ridge tiles usually match the roof; each detail shown by its chance; alternatives evenly.
static func pick(spec: Dictionary, seed: int) -> Dictionary:
	var block: Dictionary = spec.get("variants", {})
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("house-variant:%d" % seed)
	var result: Dictionary = authored(spec)
	result.seed = seed
	var roll: float = rng.randf()
	var names: Array = palettes().keys()
	names.sort()
	if roll >= 0.2 and roll < 0.55 and not names.is_empty():
		result.surfaces = with_palette(spec, str(names[rng.randi_range(0, names.size() - 1)])).surfaces
	elif roll >= 0.55:
		for slot: String in block.get("surfaces", {}):
			var choices: Array = block.surfaces[slot].choices
			result.surfaces[slot] = str(choices[rng.randi_range(0, choices.size() - 1)])
	for slot: String in block.get("surfaces", {}):
		var leader: String = str(block.surfaces[slot].get("follows", ""))
		if not leader.is_empty() and rng.randf() < 0.6 and result.surfaces[leader] in block.surfaces[slot].choices:
			result.surfaces[slot] = result.surfaces[leader]
	var details: Array = block.get("details", {}).keys()
	details.sort()
	for name: String in details:
		result.details[name] = rng.randf() < float(block.details[name])
	var groups: Array = block.get("alternates", {}).keys()
	groups.sort()
	for group: String in groups:
		var options: Array = block.alternates[group]
		result.alternates[group] = str(options[rng.randi_range(0, options.size() - 1)])
	return result


## Presents `variant` on an instantiated model. Re-applying is safe: originals are read from the imported meshes.
static func apply(model: Node, spec: Dictionary, variant: Dictionary) -> void:
	var block: Dictionary = spec.get("variants", {})
	var look: Dictionary = authored(spec)
	for key: String in ["surfaces", "details", "alternates"]:
		(look[key] as Dictionary).merge(variant.get(key, {}), true)
	var slots: Dictionary = {}
	for slot: String in block.get("surfaces", {}):
		for material_name: String in block.surfaces[slot].materials:
			slots[material_name] = slot
	_apply_node(model, block, look, slots)


static func _apply_node(node: Node, block: Dictionary, look: Dictionary, slots: Dictionary) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var instance := node as MeshInstance3D
		for index: int in range(instance.mesh.get_surface_count()):
			var original := instance.mesh.surface_get_material(index) as BaseMaterial3D
			if original == null or not slots.has(original.resource_name):
				continue
			var slot: String = slots[original.resource_name]
			var choice: String = str(look.surfaces.get(slot, ""))
			var unchanged: bool = choice.is_empty() or choice == str(block.surfaces[slot].authored)
			instance.set_surface_override_material(index, null if unchanged else _swapped(original, choice))
	if node is Node3D:
		var shown: Variant = _shown(str(node.name), block, look)
		if shown != null:
			(node as Node3D).visible = shown
	for child: Node in node.get_children():
		_apply_node(child, block, look, slots)


## Whether a node is a detail or an alternative, and if so whether this look shows it (null for ordinary nodes).
static func _shown(name: String, block: Dictionary, look: Dictionary) -> Variant:
	var plain: String = name.trim_suffix("_glass")
	if plain.begins_with("detail_"):
		var detail: String = plain.trim_prefix("detail_")
		if block.get("details", {}).has(detail):
			return bool(look.details.get(detail, true))
	elif plain.begins_with("alt_"):
		for group: String in block.get("alternates", {}):
			for option: String in block.alternates[group]:
				if plain == "alt_%s_%s" % [group, option]:
					return str(look.alternates.get(group, "")) == option
	return null


static func _swapped(original: BaseMaterial3D, choice: String) -> BaseMaterial3D:
	var key: String = "%d|%s" % [original.get_instance_id(), choice]
	if not _materials.has(key):
		var material := original.duplicate() as BaseMaterial3D
		material.albedo_texture = texture(choice)
		material.resource_name = original.resource_name
		_materials[key] = material
	return _materials[key]


## The sharp runtime painting for a library id (assets/world/textures/seaside-houses/detail/).
static func texture(id: String) -> Texture2D:
	if not _textures.has(id):
		var entry: Dictionary = _library().get("materials", {}).get(id, {})
		var path: String = str(entry.get("outputs", {}).get("detail", {}).get("path", ""))
		_textures[id] = load(path) if not path.is_empty() and ResourceLoader.exists(path) else null
		if _textures[id] == null:
			push_error("House painting missing: %s. Build it with scripts/art.sh." % id)
	return _textures[id]


static func _library() -> Dictionary:
	if _manifest.is_empty():
		var text: String = FileAccess.get_file_as_string("res://assets/world/textures/seaside-houses/manifest.json")
		_manifest = JSON.parse_string(text) if not text.is_empty() else {}
	return _manifest


## One line naming the look: "rose limewash · terracotta roof · … · laundry, vines · stone chimney".
static func summary(spec: Dictionary, variant: Dictionary) -> String:
	var block: Dictionary = spec.get("variants", {})
	var look: Dictionary = authored(spec)
	for key: String in ["surfaces", "details", "alternates"]:
		(look[key] as Dictionary).merge(variant.get(key, {}), true)
	var words: Array[String] = []
	var next_door: Array[String] = []
	for slot: String in ["plaster", "roof", "ridge", "stone", "timber", "shutter"]:
		for suffix: String in ["", "_2"]:
			if look.surfaces.has(slot + suffix):
				var colour: String = str(look.surfaces[slot + suffix]).get_slice("_", 2)
				(next_door if suffix else words).append("%s %s" % [colour, FAMILY_WORDS.get(slot, slot)])
	if not next_door.is_empty():
		words.append("next door " + ", ".join(next_door))
	var shown: Array[String] = []
	var details: Array = block.get("details", {}).keys()
	details.sort()
	for name: String in details:
		if look.details.get(name, true):
			shown.append(name.replace("_", " "))
	var parts: Array[String] = [" · ".join(words)]
	parts.append(", ".join(shown) if not shown.is_empty() else "no dressing")
	var groups: Array = block.get("alternates", {}).keys()
	groups.sort()
	for group: String in groups:
		parts.append("%s %s" % [str(look.alternates[group]).replace("_", " "), group.replace("_", " ")])
	return " · ".join(parts)
