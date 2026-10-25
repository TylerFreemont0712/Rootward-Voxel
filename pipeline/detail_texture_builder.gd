extends RefCounted
## Offline normalization for the selected painted material library. Never alters native paintings.


static func prepare(spec: Dictionary) -> bool:
	if spec.is_empty():
		return true
	var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(spec.provenance)))
	if FileAccess.get_sha256(str(spec.library)) != str(record.get("library_sha256", "")):
		push_error("Detail texture design/prompt record changed. Author a new source version.")
		return false
	for path: String in record.get("reference_sha256", {}):
		if FileAccess.get_sha256("res://"+path) != str(record.reference_sha256[path]):
			push_error("Detail texture reference changed: "+path+". Preserve the authored reference or version the handoff.")
			return false
	var manifest: Dictionary = {"schema":1, "version":spec.get("version", "v2-detail"), "normalization":"Lush: Lanczos to 128; solid: Lanczos to 64 then nearest to 128. Opposite edge pixels paired to make a periodic boundary. Native paintings preserved.", "materials":{}}
	for item: Dictionary in record.materials:
		var source: String = "res://" + str(item.source)
		if FileAccess.get_sha256(source) != str(item.sha256):
			push_error("Detail texture native changed: " + str(item.id))
			return false
		var native := Image.load_from_file(ProjectSettings.globalize_path(source))
		if native == null or native.is_empty():
			return false
		var outputs: Dictionary = {}
		for style: String in ["lush", "solid"]:
			var image := native.duplicate() as Image
			image.convert(Image.FORMAT_RGB8)
			image.resize(128 if style == "lush" else 64, 128 if style == "lush" else 64, Image.INTERPOLATE_LANCZOS)
			if style == "solid":
				image.resize(128,128,Image.INTERPOLATE_NEAREST)
			for index: int in range(128):
				var horizontal: Color = image.get_pixel(0,index).lerp(image.get_pixel(127,index),0.5)
				image.set_pixel(0,index,horizontal)
				image.set_pixel(127,index,horizontal)
			for index: int in range(128):
				var vertical: Color = image.get_pixel(index,0).lerp(image.get_pixel(index,127),0.5)
				image.set_pixel(index,0,vertical)
				image.set_pixel(index,127,vertical)
			var path: String = "res://assets/world/textures/%s/%s.png" % [style,item.id]
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
			if image.save_png(ProjectSettings.globalize_path(path)) != OK:
				return false
			outputs[style] = {"path":path, "sha256":FileAccess.get_sha256(path), "size":[128,128]}
		manifest.materials[item.id] = {"source":source, "source_sha256":item.sha256, "outputs":outputs}
	var file := FileAccess.open(str(spec.manifest),FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(manifest,"  ")+"\n")
	print("Prepared ",manifest.materials.size()," new detail textures in lush/solid sets.")
	return true


static func configure(spec: Dictionary) -> bool:
	if spec.is_empty(): return true
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(spec.manifest)))
	for entry: Dictionary in manifest.materials.values():
		for output: Dictionary in entry.outputs.values():
			var path: String = str(output.path)+".import"
			var config := ConfigFile.new()
			if config.load(path) != OK: return false
			config.set_value("params","compress/mode",0)
			config.set_value("params","mipmaps/generate",true)
			config.set_value("params","detect_3d/compress_to",0)
			if config.save(path) != OK: return false
	return true
