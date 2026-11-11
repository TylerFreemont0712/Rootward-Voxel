extends SceneTree
## One-time registration for generated sheets whose painted rows drift across cell edges.
## Preserves generated masters without resampling. Normal builds use scripts/art.sh.

func _initialize()->void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=4 or args[0]!="--source" or args[2]!="--output" or not _valid_path(args[1]) or not _valid_path(args[3]):
		_fail("Usage: -- --source res://art/source/characters/<id>/<old-version> --output res://art/source/characters/<id>/<NEW-version>")
		return
	var source: String=args[1].trim_suffix("/")+"/"
	var output: String=args[3].trim_suffix("/")+"/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)):
		_fail("Output already exists; preserve the authored source and use a NEW version directory.")
		return
	var images: Dictionary={}
	var registrations: Dictionary={}
	for direction: String in ["SE","NE"]:
		var master:=Image.load_from_file(ProjectSettings.globalize_path(source+direction+".png"))
		if master==null or master.get_size()!=Vector2i(1254,1254):
			_fail("Expected the complete 1254-square generated master.")
			return
		master.convert(Image.FORMAT_RGBA8)
		var result:=Image.create(1254,1254,false,Image.FORMAT_RGBA8)
		var poses: Array=[]
		poses.resize(9)
		for column: int in range(3):
			var runs: Array[Vector2i]=[]
			var beginning: int=-1
			for y: int in range(1255):
				var count: int=0
				if y<1254:
					for x: int in range(column*418,(column+1)*418):
						if master.get_pixel(x,y).a>0.25:count+=1
				if count>2 and beginning<0:beginning=y
				if count<=2 and beginning>=0:
					runs.append(Vector2i(beginning,y))
					beginning=-1
			if runs.size()!=3:
				_fail("Expected three separated whole figures in each column; review the generated master.")
				return
			for row: int in range(3):
				var start: int=0 if row==0 else (runs[row-1].y+runs[row].x)/2
				var end: int=1254 if row==2 else (runs[row].y+runs[row+1].x)/2
				var band:=master.get_region(Rect2i(column*418,start,418,end-start))
				var bounds:=_bounds(band)
				var top:=maxi(0,bounds.position.y-2)
				var bottom:=mini(band.get_height(),bounds.end.y+2)
				var height:=bottom-top
				if height>404:
					_fail("Whole figure is too tall for an unchanged 418-square source cell.")
					return
				var crop:=Rect2i(column*418,start+top,418,height)
				var destination:=Vector2i(column*418,row*418+408-height)
				result.blit_rect(master,crop,destination)
				poses[row*3+column]={"source_rect":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"destination":[destination.x,destination.y],"vertical_translation":destination.y-crop.position.y}
		images[direction]=result
		registrations[direction]=poses
	var neutral: Image=images.SE.get_region(Rect2i(836,836,418,418))
	var old_neutral:=Image.load_from_file(ProjectSettings.globalize_path(source+"idle-se.png"))
	var old_blink:=Image.load_from_file(ProjectSettings.globalize_path(source+"blink-se.png"))
	if old_neutral==null or old_blink==null:
		_fail("Keep the original complete neutral and eye-only blink beside the paintings.")
		return
	var blink:=Image.create_from_data(418,418,false,Image.FORMAT_RGBA8,neutral.get_data())
	var shift: int=registrations.SE[8].vertical_translation
	for y: int in range(418):
		for x: int in range(418):
			if old_blink.get_pixel(x,y)!=old_neutral.get_pixel(x,y):
				if y+shift<0 or y+shift>=418 or old_blink.get_pixel(x,y).a!=neutral.get_pixel(x,y+shift).a:
					_fail("Registered blink would change the full silhouette.")
					return
				blink.set_pixel(x,y+shift,old_blink.get_pixel(x,y))
	var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source+"authoring.json"))
	var eyes: Array=previous.eye_rectangles.duplicate(true)
	for rect: Array in eyes:rect[1]+=shift
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for direction: String in ["SE","NE"]:
		_save(images[direction],output+direction+".png")
		var mirror:=Image.create(1254,1254,false,Image.FORMAT_RGBA8)
		for pose: int in range(9):
			var region:=Rect2i((pose%3)*418,(pose/3)*418,418,418)
			var figure: Image=images[direction].get_region(region)
			figure.flip_x()
			mirror.blit_rect(figure,Rect2i(0,0,418,418),region.position)
		_save(mirror,output+("SW" if direction=="SE" else "NW")+".png")
	_save(neutral,output+"idle-se.png")
	_save(blink,output+"blink-se.png")
	blink.flip_x()
	_save(blink,output+"blink-sw.png")
	var record: Dictionary={"method":"Whole figures recovered from uneven generated rows; integer translations only, no resampling. Existing eye-only blink differences translated onto the recovered complete neutral. Original paintings retained in source_version.","source_version":source,"source_adapter":"pipeline/reflow_cast_source.gd","source_adapter_sha256":FileAccess.get_sha256("res://pipeline/reflow_cast_source.gd"),"registrations":registrations,"eye_rectangles":eyes,"inputs":{},"outputs":{}}
	for name: String in ["SE.png","NE.png","idle-se.png","blink-se.png","authoring.json"]:
		record.inputs[source+name]=FileAccess.get_sha256(source+name)
	for name: String in ["SE.png","NE.png","SW.png","NW.png","idle-se.png","blink-se.png","blink-sw.png"]:
		record.outputs[name]=FileAccess.get_sha256(output+name)
	var file:=FileAccess.open(output+"authoring.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(record,"  ")+"\n")
	print("Registered complete painted cast figures without resampling: ",output)
	quit()

func _valid_path(path: String)->bool:
	return path.begins_with("res://art/source/characters/") and ".." not in path

func _bounds(picture: Image)->Rect2i:
	var first:=picture.get_size()
	var last:=Vector2i(-1,-1)
	for y: int in range(picture.get_height()):
		for x: int in range(picture.get_width()):
			if picture.get_pixel(x,y).a>0.25:
				first=first.min(Vector2i(x,y))
				last=last.max(Vector2i(x,y))
	return Rect2i(first,last-first+Vector2i.ONE)

func _save(picture: Image,path: String)->void:
	picture.save_png(ProjectSettings.globalize_path(path))

func _fail(message: String)->void:
	printerr(message)
	quit(1)
