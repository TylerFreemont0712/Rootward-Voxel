extends SceneTree
## New library stays in its own folder and uses the existing offline material build/import contract.

var checks: int=0
var failures: Array[String]=[]

func _initialize()->void:
	var directory: String="res://art/source/world/seaside-background-houses/v1/textures/"
	var library: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(directory+"library.json"))
	var record: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(directory+"generation.json"))
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/world/textures/seaside-houses/manifest.json"))
	_check(library.materials.size()==15 and manifest.materials.size()==15,"Five house surfaces have three colour variants each")
	_check(FileAccess.get_sha256(directory+"library.json")==record.library_sha256,"Exact material design and colour prompts preserved")
	var groups: Dictionary={}
	var hashes: Dictionary={}
	var colours: Dictionary={}
	for item: Dictionary in library.materials:
		var source: String="res://"+item.source
		var painting:=Image.load_from_file(ProjectSettings.globalize_path(source))
		_check(painting!=null and painting.get_width()==painting.get_height() and painting.get_width()>=1024,item.id+" has a full-resolution square painting")
		_check(FileAccess.get_sha256(source)==manifest.materials[item.id].source_sha256 and not hashes.has(FileAccess.get_sha256(source)),item.id+" preserves a distinct source")
		hashes[FileAccess.get_sha256(source)]=true
		groups[item.family]=int(groups.get(item.family,0))+1
		_check(float(item.tile)>0 and float(item.roughness)>0 and float(item.roughness)<=1,item.id+" declares usable material settings")
		var generation: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source.get_basename()+".generation.json"))
		var inputs_ok: bool=generation.output_sha256==FileAccess.get_sha256(source)
		for path: String in generation.reference_sha256:
			inputs_ok=inputs_ok and FileAccess.get_sha256("res://"+path)==generation.reference_sha256[path]
		_check(inputs_ok,item.id+" generation inputs and output match their hashes")
		for style: String in ["lush","solid"]:
			var output: Dictionary=manifest.materials[item.id].outputs[style]
			_check(str(output.path).begins_with("res://assets/world/textures/seaside-houses/"+style+"/"),item.id+" output remains in the dedicated house folder")
			_check(FileAccess.get_sha256(output.path)==output.sha256,item.id+" runtime image matches its build manifest")
			var image:=Image.load_from_file(ProjectSettings.globalize_path(output.path))
			_check(image.get_size()==Vector2i(128,128) and image.detect_alpha()==Image.ALPHA_NONE,item.id+" is an opaque 128-square runtime tile")
			var periodic: bool=true
			for i: int in range(128):periodic=periodic and image.get_pixel(0,i)==image.get_pixel(127,i) and image.get_pixel(i,0)==image.get_pixel(i,127)
			_check(periodic,item.id+" has matching opposite boundary pixels")
			var config:=ConfigFile.new()
			config.load(str(output.path)+".import")
			_check(config.get_value("params","compress/mode")==0 and config.get_value("params","mipmaps/generate"),item.id+" uses lossless mipmapped import")
			if style=="lush":
				var mean:=Color(0,0,0)
				for y: int in range(128):
					for x: int in range(128):mean+=image.get_pixel(x,y)/16384.0
				if not colours.has(item.family):colours[item.family]=[]
				colours[item.family].append(mean)
	_check(groups.size()==5,"Exactly five surface families are supplied")
	for family: String in groups:
		_check(groups[family]==3,family+" has three choices")
		var distinct: bool=true
		for a: int in range(3):
			for b: int in range(a+1,3):
				var ca: Color=colours[family][a]
				var cb: Color=colours[family][b]
				distinct=distinct and Vector3(ca.r-cb.r,ca.g-cb.g,ca.b-cb.b).length()>.025
		_check(distinct,family+" colour choices remain visibly different after normalization")
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/art-catalog.json"))
	_check(catalog.building_texture_libraries.any(func(spec: Dictionary)->bool:return spec.get("output_root","")=="res://assets/world/textures/seaside-houses"),"The normal scripts/art.sh build owns this library")
	if failures.is_empty():
		print("Seaside house materials: %d checks passed."%checks)
		quit()
	else:
		for failure: String in failures:printerr(failure)
		quit(1)

func _check(value: bool,message: String)->void:
	checks+=1
	if not value:failures.append(message)
