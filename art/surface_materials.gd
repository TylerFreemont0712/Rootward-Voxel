extends RefCounted
## Shared painted pictures and deterministic fallback patterns for editable world geometry.
## Runtime pictures are supplied assets; no authoring tools or network services are required to play.

const TEXTURE_SIZE: int = 64


## `world_space` picks how a repeating picture is placed. True (the default) pins it to the world, so a
## picture tile is the same size and lines up across every block of a batched MultiMesh. False pins it to
## the mesh instead, which is right for parts that move (a gate, the wheel).
static func build(palette: Dictionary, world_space: bool = true) -> Dictionary:
	var result: Dictionary = {}
	for id: String in palette:
		var color: Color = palette[id]
		if WorldTextures.has(id):
			result[id] = painted(id, color, world_space)
			continue
		var material := StandardMaterial3D.new()
		var style: String = _style_for(id)
		material.roughness = 0.94
		if style == "plain":
			material.albedo_color = color
		else:
			material.albedo_color = Color.WHITE
			material.albedo_texture = _texture(color, style)
			# LEARN: mipmaps keep tiny patterned surfaces calm when the fixed camera pulls back.
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		result[id] = material
	result["face"] = _face_material(palette["skin"])
	return result


## A palette material wearing its painted picture from the texture catalog. A missing picture is reported
## and the flat palette colour stands in, so the game stays playable.
static func painted(id: String, color: Color, world_space: bool = true) -> StandardMaterial3D:
	var entry: Dictionary = WorldTextures.entry(id)
	var material := StandardMaterial3D.new()
	material.roughness = float(entry.get("roughness", 0.94))
	material.metallic = float(entry.get("metallic", 0.0))
	var picture: Texture2D = WorldTextures.texture(str(entry.texture))
	if picture == null:
		material.albedo_color = color
		return material
	var tint: float = float(entry.tint)
	material.albedo_color = Color(tint, tint, tint)
	material.albedo_texture = picture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	if str(entry.mode) != "face":
		material.uv1_triplanar = true
		material.uv1_world_triplanar = world_space
		# LEARN: Godot weights the projections by the instance's scale, so a high sharpness underflows to black on a thin slab. Boxes are axis-aligned, so a low value costs nothing.
		material.uv1_triplanar_sharpness = 4.0
		material.uv1_scale = Vector3.ONE / float(entry.tile)
	if float(entry.emission) > 0.0:
		material.emission_enabled = true
		material.emission_texture = picture
		material.emission_energy_multiplier = float(entry.emission)
	return material


static func _style_for(id: String) -> String:
	if id.begins_with("grass"):
		return "grass"
	if id.begins_with("dirt"):
		return "dirt"
	if id.begins_with("wood") or id.begins_with("oak"):
		return "grain"
	if id.begins_with("roof") or id.begins_with("teal"):
		return "tile"
	if id.begins_with("stone") or id.begins_with("path"):
		return "stone"
	if id.begins_with("plaster"):
		return "plaster"
	if id.begins_with("cloth") or id == "scarf":
		return "weave"
	if id.begins_with("leather"):
		return "leather"
	if id.begins_with("hair"):
		return "hair"
	if id.begins_with("leaf"):
		return "leaf"
	return "plain"


static func _texture(base: Color, style: String) -> ImageTexture:
	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	for y: int in range(TEXTURE_SIZE):
		for x: int in range(TEXTURE_SIZE):
			var patch: int = _hash(x / 4, y / 4)
			var pixel: int = _hash(x, y)
			var shift: float = (float(patch % 9) - 4.0) * 0.009
			match style:
				"grain":
					var band: int = (x + int(sin(float(y) * 0.15 + float(x / 11)) * 1.7)) % 11
					shift += -0.13 if band < 2 else (0.08 if band == 3 else 0.0)
					if pixel % 37 == 0:
						shift -= 0.07
				"tile":
					shift += 0.035 * float(y) / 64.0
					if y >= 58:
						shift += 0.12
					elif y < 4 or x < 3 or x > 60:
						shift -= 0.12
					if pixel % 61 == 0:
						shift += 0.06
				"stone":
					shift = (float(_hash(x / 7, y / 6) % 11) - 5.0) * 0.012
					if pixel % 29 == 0:
						shift -= 0.06
					if y == 3 or x == 3:
						shift += 0.06
				"plaster":
					shift *= 0.7
					if pixel % 71 == 0:
						shift -= 0.045
				"weave":
					shift = 0.028 if (x / 2 + y / 2) % 2 == 0 else -0.028
					if x % 16 == 0:
						shift -= 0.05
				"leather":
					if x < 3 or x > 60 or y < 3 or y > 60:
						shift -= 0.16
					elif (x == 5 or x == 58) and y % 7 < 3:
						shift += 0.24
				"hair":
					shift += -0.09 if (x + y / 5) % 13 < 3 else 0.03
				"grass":
					shift = (float(_hash(x / 5, y / 5) % 9) - 4.0) * 0.012
					if pixel % 19 == 0:
						shift += 0.04
				"leaf":
					shift = (float(_hash(x / 8, y / 8) % 7) - 3.0) * 0.014
				"dirt":
					shift = (float(_hash(x / 3, y / 3) % 9) - 4.0) * 0.014
					if pixel % 23 == 0:
						shift += 0.07
					elif pixel % 31 == 0:
						shift -= 0.06
			image.set_pixel(x, y, base.lightened(shift) if shift > 0.0 else base.darkened(-shift))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _hash(x: int, y: int) -> int:
	return absi((x * 374761393 + y * 668265263 + 19) ^ ((x + y * 57) * 1274126177))


static func _face_material(skin: Color) -> StandardMaterial3D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(skin)
	# The face is painted on the head, rather than lots of tiny floating eye/skin cubes.
	image.fill_rect(Rect2i(0, 23, 32, 9), skin.darkened(0.05))
	image.fill_rect(Rect2i(0, 0, 3, 32), skin.darkened(0.1))
	image.fill_rect(Rect2i(29, 0, 3, 32), skin.darkened(0.1))
	for x: int in [7, 21]:
		image.fill_rect(Rect2i(x, 10, 5, 2), Color("68402e"))
		image.fill_rect(Rect2i(x, 14, 5, 7), Color("302c2d"))
		image.fill_rect(Rect2i(x + 1, 14, 2, 2), Color("fff4dc"))
		image.fill_rect(Rect2i(x - 2, 22, 5, 2), Color("d59479"))
	image.fill_rect(Rect2i(15, 21, 2, 3), skin.darkened(0.15))
	image.fill_rect(Rect2i(14, 27, 5, 1), Color("a96b57"))
	image.generate_mipmaps()
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	material.roughness = 1.0
	return material
