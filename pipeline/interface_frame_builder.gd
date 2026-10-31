extends RefCounted
## Offline preparation of painted interface frames (Nell's field slate) for nine-slice use. The authored PNG is never
## changed: the build crops away its empty margin, clears the matte colour from fully transparent pixels, fills the
## screen window with exact opaque black (the generator left it uneven), scales it, and writes a manifest of the
## measured slice margins, window, jack and lamp in runtime pixels. Measurements live in the art catalog, in cropped
## source pixels, and are checked here so a later source cannot silently misplace them.

const OUTPUT_ROOT: String = "res://assets/ui/"


static func prepare(frames: Dictionary) -> bool:
	for id: String in frames:
		if not _prepare_one(id, frames[id]):
			return false
	return true


static func _prepare_one(id: String, spec: Dictionary) -> bool:
	var runtime: String = str(spec.runtime)
	var manifest_path: String = str(spec.manifest)
	if ".." in runtime or not runtime.begins_with(OUTPUT_ROOT) or not manifest_path.begins_with(OUTPUT_ROOT):
		push_error("Interface frame outputs must stay inside assets/ui.")
		return false
	if FileAccess.get_sha256(str(spec.source)) != str(spec.source_sha256):
		push_error("Interface frame source changed: %s. Author a new version and update the art catalog." % id)
		return false
	var source := Image.load_from_file(ProjectSettings.globalize_path(str(spec.source)))
	if source == null or source.is_empty() or not source.detect_alpha():
		push_error("Interface frame source must be an RGBA PNG with transparency: " + id)
		return false
	source.convert(Image.FORMAT_RGBA8)
	var crop := Rect2i(int(spec.crop[0]), int(spec.crop[1]), int(spec.crop[2]), int(spec.crop[3]))
	if not Rect2i(Vector2i.ZERO, source.get_size()).encloses(crop):
		push_error("Interface frame crop lies outside its source: " + id)
		return false
	var image: Image = source.get_region(crop)
	var window := Rect2i(int(spec.window[0]), int(spec.window[1]), int(spec.window[2]), int(spec.window[3]))
	var slice: Array = spec.slice
	if not _fits(image.get_size(), window, slice, spec):
		push_error("Interface frame measurements do not fit its slices: " + id)
		return false
	var screen: Rect2i = window.grow(-2)
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var pixel: Color = image.get_pixel(x, y)
			# The generated screen is uneven in both colour and alpha; inside the window, dark or see-through is black.
			if screen.has_point(Vector2i(x, y)) and (pixel.a < 0.5 or maxf(pixel.r, maxf(pixel.g, pixel.b)) < 0.25):
				image.set_pixel(x, y, Color(0, 0, 0, 1))
			elif pixel.a < 0.03:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	var scale: float = float(spec.scale)
	var size := Vector2i(roundi(image.get_width() * scale), roundi(image.get_height() * scale))
	image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(runtime.get_base_dir()))
	if image.save_png(ProjectSettings.globalize_path(runtime)) != OK:
		return false
	var scaled := func(values: Array) -> Array: return values.map(func(value: Variant) -> float: return snappedf(float(value) * scale, 0.5))
	var manifest: Dictionary = {
		"schema": 1, "id": id, "version": spec.version,
		"source": spec.source, "source_sha256": spec.source_sha256,
		"runtime": runtime, "runtime_sha256": FileAccess.get_sha256(runtime), "size": [size.x, size.y], "scale": scale,
		"slice": slice.map(func(value: Variant) -> int: return roundi(float(value) * scale)),
		"window": scaled.call(spec.window), "jack": scaled.call(spec.jack), "lamp": scaled.call(spec.lamp),
		"normalization": "Cropped to the casing; transparent matte cleared; screen window filled with opaque #000000; Lanczos to %d%%." % roundi(scale * 100.0),
	}
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	print("Built interface frame: ", runtime)
	return true


## The window and the painted jack and lamp must sit inside the fixed border slices, so stretching moves none of them.
static func _fits(size: Vector2i, window: Rect2i, slice: Array, spec: Dictionary) -> bool:
	var left: int = int(slice[0])
	var top: int = int(slice[1])
	var right: int = int(slice[2])
	var bottom: int = int(slice[3])
	if left + right >= size.x or top + bottom >= size.y:
		return false
	if window.position.x > left or window.position.y > top or size.x - window.end.x > right or size.y - window.end.y > bottom:
		return false
	for key: String in ["jack", "lamp"]:
		var circle: Array = spec[key]
		if float(circle[0]) + float(circle[2]) > left or float(circle[1]) + float(circle[2]) > top:
			return false
	return true


static func configure(frames: Dictionary) -> bool:
	for spec: Dictionary in frames.values():
		var path: String = str(spec.runtime) + ".import"
		var config := ConfigFile.new()
		if config.load(path) != OK:
			push_error("Import the interface frame before configuring it: " + path)
			return false
		# Drawn at its own size, so no mipmaps; lossless, with the transparent edge repaired.
		config.set_value("params", "compress/mode", 0)
		config.set_value("params", "mipmaps/generate", false)
		config.set_value("params", "process/fix_alpha_border", true)
		config.set_value("params", "detect_3d/compress_to", 0)
		if config.save(path) != OK:
			return false
	return true
