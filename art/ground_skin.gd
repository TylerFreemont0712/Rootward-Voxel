class_name GroundSkin
extends Node3D
## Presentation only: continuous world-space pictures over a pure half-cell control map.
## All chunks share one material and texture. Paint changes bytes, never meshes or world rules.

const SHADER: Shader = preload("res://art/ground.gdshader")
const PICTURES: Array[String] = ["grass", "dirt_path", "cobble", "soil", "pebbles", "rock", "herringbone_oak", "terracotta_tile", "encaustic_tile", "limestone_flags"]
const CHUNK: int = 16
const HEIGHT: float = 0.02
static var _atlases: Dictionary = {}
static var _warp: ImageTexture

var area: AreaDef
var material: ShaderMaterial
var control_image: Image
var control_texture: ImageTexture
var ids: Array[String] = []
var changed_texels: int = 0
var _set: String = ""
var _previewing: bool = false


func build(definition: AreaDef) -> bool:
	area = definition
	name = "GroundSkin"
	material = ShaderMaterial.new()
	material.shader = SHADER
	if not _bind_pictures():
		return false
	var bytes: PackedByteArray = GroundPaint.control(area)
	control_image = Image.create_from_data(area.width * 2, area.height * 2, false, Image.FORMAT_R8, bytes)
	control_texture = ImageTexture.create_from_image(control_image)
	material.set_shader_parameter("control_map", control_texture)
	material.set_shader_parameter("control_size", Vector2i(area.width * 2, area.height * 2))
	_build_chunks()
	_write_levels()
	return true


## After the land was shaped: the chunk meshes are made again at the new heights (stairs have no skin of their
## own, and new water none), and the control map follows the new terrain.
func rebuild_mesh(definition: AreaDef) -> void:
	area = definition
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_build_chunks()
	_write_levels()
	_write_control()


## The shader's level map, one texel per cell (level × 64), for the contour along terrace edges. A flight of stairs
## counts as the level it climbs to, so the ground at its top has no contour where the steps arrive.
func _write_levels() -> void:
	var image := Image.create(area.width, area.height, false, Image.FORMAT_R8)
	for y: int in range(area.height):
		for x: int in range(area.width):
			var cell := Vector2i(x, y)
			var level: int = area.level_at(cell) + (0 if area.stair_at(cell).is_empty() else 1)
			image.set_pixel(x, y, Color(float(level * 64) / 255.0, 0.0, 0.0))
	material.set_shader_parameter("level_map", ImageTexture.create_from_image(image))
	material.set_shader_parameter("level_size", Vector2i(area.width, area.height))


## One flat mesh per chunk, each cell's square at the height of its land level.
func _build_chunks() -> void:
	for cy: int in range(0, area.height, CHUNK):
		for cx: int in range(0, area.width, CHUNK):
			var vertices := PackedVector3Array()
			var normals := PackedVector3Array()
			for y: int in range(cy, mini(cy + CHUNK, area.height)):
				for x: int in range(cx, mini(cx + CHUNK, area.width)):
					if not GroundPaint.is_ground(area, Vector2i(x * 2, y * 2)) or not area.stair_at(Vector2i(x, y)).is_empty():
						continue
					var a := Vector3(x - 0.5, HEIGHT + float(area.level_at(Vector2i(x, y))) * TerrainBuilder.LEVEL_RISE, -y + 0.5)
					var b := a + Vector3(1, 0, 0)
					var c := a + Vector3(1, 0, -1)
					var d := a + Vector3(0, 0, -1)
					# Clockwise from above, like Godot's PlaneMesh.
					vertices.append_array(PackedVector3Array([a, c, b, a, d, c]))
					for k: int in range(6):
						normals.append(Vector3.UP)
			if vertices.is_empty():
				continue
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_NORMAL] = normals
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var chunk := MeshInstance3D.new()
			chunk.name = "Ground_%d_%d" % [cx, cy]
			chunk.mesh = mesh
			chunk.material_override = material
			chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(chunk)


## A committed edit, undo or cancel. Only different pixels are written; the image/texture and chunks live on.
func update_area(definition: AreaDef) -> void:
	var unchanged: bool = area.paint == definition.paint and area.terrain == definition.terrain and not _previewing and _set == WorldTextures.active_set()
	area = definition
	if unchanged:
		return
	_write_control()


## Writes the control map for the current area, touching only the texels that differ.
func _write_control() -> void:
	_previewing = false
	var wanted_ids: Array[String] = GroundPaint.palette(area)
	if wanted_ids != ids or _set != WorldTextures.active_set():
		if not _bind_pictures():
			return
	var next: PackedByteArray = GroundPaint.control(area)
	var previous: PackedByteArray = control_image.get_data()
	changed_texels = 0
	for index: int in range(next.size()):
		if next[index] != previous[index]:
			control_image.set_pixel(index % control_image.get_width(), index / control_image.get_width(), Color(float(next[index]) / 255.0, 0, 0))
			changed_texels += 1
	if changed_texels > 0:
		control_texture.update(control_image)


## Live stroke proposal. No ledger or area mutation; cancel calls update_area with the committed area.
func preview(material_id: String, cells: Array) -> void:
	_previewing = true
	var index: int = ids.find(material_id)
	var touched: bool = false
	for cell: Vector2i in cells:
		if not GroundPaint.is_ground(area, cell):
			continue
		var value: int = index
		if material_id == "":
			value = ids.find(GroundPaint.derived(area, cell))
		if value < 0:
			continue
		control_image.set_pixel(cell.x, cell.y, Color(float(value) / 255.0, 0, 0))
		touched = true
	if touched:
		control_texture.update(control_image)


func _bind_pictures() -> bool:
	_set = WorldTextures.active_set()
	var atlas: Texture2DArray = _atlas(_set)
	if atlas == null:
		push_error("Ground skin could not load its pictures; using the old ground slabs.")
		return false
	ids = GroundPaint.palette(area)
	var layers := PackedInt32Array()
	var tints := PackedColorArray()
	var tiles := PackedFloat32Array()
	layers.resize(64)
	tints.resize(64)
	tiles.resize(64)
	for index: int in range(ids.size()):
		var entry: Dictionary = WorldTextures.entry(ids[index])
		var layer: int = PICTURES.find(str(entry.get("texture", "")))
		if layer < 0:
			push_error("Ground material '%s' needs an atlas picture." % ids[index])
			return false
		layers[index] = layer
		var tint: float = float(entry.get("tint", 1.0))
		tints[index] = Color(tint, tint, tint)
		tiles[index] = float(entry.get("tile", 1.0))
	material.set_shader_parameter("ground_albedo", atlas)
	material.set_shader_parameter("layer_of", layers)
	material.set_shader_parameter("tint_of", tints)
	material.set_shader_parameter("tile_of", tiles)
	material.set_shader_parameter("warp_noise", _warp_texture())
	return true


static func _atlas(set_name: String) -> Texture2DArray:
	if _atlases.has(set_name):
		return _atlases[set_name]
	var images: Array[Image] = []
	for picture: String in PICTURES:
		var texture: Texture2D = WorldTextures.texture(picture)
		if texture == null:
			return null
		var image: Image = texture.get_image()
		if image.is_compressed():
			image.decompress()
		image.clear_mipmaps()
		image.convert(Image.FORMAT_RGBA8)
		var height_path: String = "res://assets/world/ground/height/" + picture + ".png"
		# Authored heights are aligned to lush. Other sets use their own luminance fallback.
		var height: Image
		if set_name == "lush" and ResourceLoader.exists(height_path):
			height = (load(height_path) as Texture2D).get_image()
			if height.is_compressed():
				height.decompress()
			height.clear_mipmaps()
			height.convert(Image.FORMAT_L8)
		else:
			height = fallback_height(image)
		if height == null or height.get_size() != image.get_size():
			height = fallback_height(image)
		var bytes: PackedByteArray = image.get_data()
		var height_bytes: PackedByteArray = height.get_data() if height.get_format() == Image.FORMAT_L8 else PackedByteArray()
		for y: int in range(image.get_height()):
			for x: int in range(image.get_width()):
				bytes[(y * image.get_width() + x) * 4 + 3] = height_bytes[y * image.get_width() + x] if not height_bytes.is_empty() else roundi(height.get_pixel(x, y).r * 255.0)
		image = Image.create_from_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, bytes)
		image.generate_mipmaps()
		images.append(image)
	var atlas := Texture2DArray.new()
	if atlas.create_from_images(images) != OK:
		return null
	_atlases[set_name] = atlas
	return atlas


## Periodic one-pixel box blur of albedo luminance followed by min/max contrast stretch.
static func fallback_height(albedo: Image) -> Image:
	var width: int = albedo.get_width()
	var height: int = albedo.get_height()
	var luminance := PackedFloat32Array()
	var horizontal := PackedFloat32Array()
	var blurred := PackedFloat32Array()
	luminance.resize(width * height)
	horizontal.resize(width * height)
	blurred.resize(width * height)
	var rgba: Image = albedo.duplicate()
	rgba.clear_mipmaps()
	rgba.convert(Image.FORMAT_RGBA8)
	var pixels: PackedByteArray = rgba.get_data()
	for y: int in range(height):
		for x: int in range(width):
			var offset: int = (y * width + x) * 4
			luminance[y * width + x] = (float(pixels[offset]) * 0.2126 + float(pixels[offset + 1]) * 0.7152 + float(pixels[offset + 2]) * 0.0722) / 255.0
	for y: int in range(height):
		for x: int in range(width):
			horizontal[y * width + x] = (luminance[y * width + posmod(x - 1, width)] + luminance[y * width + x] + luminance[y * width + posmod(x + 1, width)]) / 3.0
	var low: float = 1.0
	var high: float = 0.0
	for y: int in range(height):
		for x: int in range(width):
			var value: float = (horizontal[posmod(y - 1, height) * width + x] + horizontal[y * width + x] + horizontal[posmod(y + 1, height) * width + x]) / 3.0
			blurred[y * width + x] = value
			low = minf(low, value)
			high = maxf(high, value)
	var bytes := PackedByteArray()
	bytes.resize(width * height)
	for index: int in range(bytes.size()):
		bytes[index] = roundi(clampf((blurred[index] - low) / maxf(high - low, 0.001), 0.0, 1.0) * 255.0)
	return Image.create_from_data(width, height, false, Image.FORMAT_L8, bytes)


## Exact periodic two-channel value noise. No authoring service or random state.
static func _warp_texture() -> ImageTexture:
	if _warp != null:
		return _warp
	var image := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y: int in range(64):
		for x: int in range(64):
			image.set_pixel(x, y, Color(_periodic_noise(float(x) / 8.0, float(y) / 8.0, 0), _periodic_noise(float(x) / 8.0, float(y) / 8.0, 83), 0))
	_warp = ImageTexture.create_from_image(image)
	return _warp


static func _periodic_noise(x: float, y: float, seed: int) -> float:
	var ix: int = floori(x)
	var iy: int = floori(y)
	var fx: float = smoothstep(0.0, 1.0, x - float(ix))
	var fy: float = smoothstep(0.0, 1.0, y - float(iy))
	var a: float = float(GroundPaint.hash_xy(posmod(ix, 8) + seed, posmod(iy, 8)) % 1024) / 1023.0
	var b: float = float(GroundPaint.hash_xy(posmod(ix + 1, 8) + seed, posmod(iy, 8)) % 1024) / 1023.0
	var c: float = float(GroundPaint.hash_xy(posmod(ix, 8) + seed, posmod(iy + 1, 8)) % 1024) / 1023.0
	var d: float = float(GroundPaint.hash_xy(posmod(ix + 1, 8) + seed, posmod(iy + 1, 8)) % 1024) / 1023.0
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


func _process(_delta: float) -> void:
	if _set != WorldTextures.active_set():
		_bind_pictures()
