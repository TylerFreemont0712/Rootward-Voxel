extends SceneTree
## Asset boundary checks for the asymmetric, independently painted robot movement candidates.

var checks: int=0
var failures: Array[String]=[]

func _initialize()->void:
	for id: String in ["wick","tender"]:
		var directory: String="res://art/source/robots/v0.72/"+id+"/movement-v1/"
		var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(directory+"movement.json"))
		if not data is Dictionary:
			_check(false,id+" movement registration exists")
			continue
		var record: Dictionary=data
		_check(record.independent_directions and not record.horizontal_flips,id+" explicitly uses independently painted physical sides")
		_check(record.directions==["SE","SW","NE","NW"] and record.frames_per_direction==4,id+" has four rolling keys in all four game views")
		var atlas:=Image.load_from_file(ProjectSettings.globalize_path(record.output))
		_check(atlas!=null and atlas.get_size()==Vector2i(2816,2816),id+" candidate atlas preserves high-resolution cells")
		_check(FileAccess.get_sha256(record.output)==record.output_sha256,id+" atlas matches its registered provenance")
		var sources: Dictionary={}
		for direction: String in record.directions:
			var path:=directory+direction+"-generated.png"
			_check(record.sources.has(path) and FileAccess.get_sha256(path)==record.sources[path],id+" "+direction+" generated master is unchanged")
			var generation: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(directory+direction+"-generated.generation.json"))
			var refs_ok: bool=generation.output_sha256==FileAccess.get_sha256(path)
			for ref: String in generation.reference_sha256:
				refs_ok=refs_ok and FileAccess.get_sha256("res://"+ref)==generation.reference_sha256[ref]
			_check(refs_ok,id+" "+direction+" retains the exact generation inputs and output")
			var source:=Image.load_from_file(ProjectSettings.globalize_path(path))
			sources[direction]=source
			var row: int=record.directions.find(direction)
			for phase: int in range(4):
				var spec: Dictionary=record.poses[direction][phase]
				var rect: Array=spec.source_rect
				var translation: Array=spec.translation
				var painting:=source.get_region(Rect2i(int(rect[0]),int(rect[1]),int(rect[2]),int(rect[3])))
				var expected:=Image.create(704,704,false,Image.FORMAT_RGBA8)
				expected.blit_rect(painting,Rect2i(Vector2i.ZERO,painting.get_size()),Vector2i(int(translation[0]),int(translation[1])))
				var frame:=atlas.get_region(Rect2i(phase*704,row*704,704,704))
				_check(frame.get_data()==expected.get_data(),id+" "+direction+" key preserves painted pixels with integer registration")
				var original:=_stats(painting)
				var registered:=_stats(frame)
				_check(original.pixels==registered.pixels and registered.pixels>10000,id+" "+direction+" complete silhouette survives registration")
				var bounds: Rect2i=registered.bounds
				_check(bounds.position.x>=16 and bounds.end.x<=688 and bounds.position.y>=16 and bounds.end.y==660,id+" "+direction+" wheels and tools have padding at the shared contact origin")
		for pair: Array in [["SE","SW"],["NE","NW"]]:
			var mirror: Image=sources[pair[0]].duplicate()
			var size:=mirror.get_width()/2
			var mirrored:=Image.create(mirror.get_width(),mirror.get_height(),false,Image.FORMAT_RGBA8)
			for phase: int in range(4):
				var rect:=Rect2i((phase%2)*size,(phase/2)*size,size,size)
				var figure:=mirror.get_region(rect)
				figure.flip_x()
				mirrored.blit_rect(figure,Rect2i(Vector2i.ZERO,figure.get_size()),rect.position)
			_check(mirrored.get_data()!=(sources[pair[1]] as Image).get_data(),id+" "+pair[1]+" is independently painted rather than a per-cell x-flip")
	if failures.is_empty():
		print("Asymmetric robot movement art: %d checks passed."%checks)
		quit()
	else:
		for failure: String in failures:printerr(failure)
		quit(1)

func _stats(picture: Image)->Dictionary:
	var first:=picture.get_size()
	var last:=Vector2i(-1,-1)
	var count: int=0
	for y: int in range(picture.get_height()):
		for x: int in range(picture.get_width()):
			if picture.get_pixel(x,y).a>0.25:
				count+=1
				first=first.min(Vector2i(x,y))
				last=last.max(Vector2i(x,y))
	return {"pixels":count,"bounds":Rect2i(first,last-first+Vector2i.ONE)}

func _check(value: bool,message: String)->void:
	checks+=1
	if not value:failures.append(message)
