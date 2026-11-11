extends SceneTree
## Guarded source adapter for new shared-frame cast paintings. Normal builds remain scripts/art.sh.
## references extracts the neutral/crop; assemble mirrors complete cells and composites generated eye patches.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size()!=4 or args[0]!="--source" or args[2]!="--stage" or args[3] not in ["references","assemble"] or not args[1].begins_with("res://art/source/characters/") or ".." in args[1]:
		_fail("Usage: -- --source res://art/source/characters/<id>/<new-version> --stage references|assemble")
		return
	var directory: String=args[1].trim_suffix("/")+"/"
	if FileAccess.file_exists(directory+"sheet.png") or FileAccess.file_exists(directory+"provenance.json"):
		_fail("Prepared source already exists; use a NEW version directory.")
		return
	var front := _source(directory+"SE.png")
	if front==null:return
	if args[3]=="references":
		for name: String in ["idle-se.png","blink-reference.png"]:
			if FileAccess.file_exists(directory+name):
				_fail("Reference already exists; preserve the authored source.")
				return
		var idle := front.get_region(Rect2i(836,836,418,418))
		idle.save_png(ProjectSettings.globalize_path(directory+"idle-se.png"))
		idle.get_region(Rect2i(90,35,250,250)).save_png(ProjectSettings.globalize_path(directory+"blink-reference.png"))
		print("Prepared neutral and blink reference: ",directory)
		quit(0)
		return
	var rear := _source(directory+"NE.png")
	if rear==null:return
	for name: String in ["SW.png","NW.png","blink-se.png","blink-sw.png","authoring.json"]:
		if FileAccess.file_exists(directory+name):
			_fail("Assembled source already exists; preserve the authored source.")
			return
	var spec: Variant=JSON.parse_string(FileAccess.get_file_as_string(directory+"blink-assembly.json"))
	if not spec is Dictionary or not spec.get("eyes") is Array or spec.eyes.size()!=2:
		_fail("A blink assembly needs exactly two eye rectangles in the 250-square reference crop.")
		return
	var eyes: Array[Rect2]=[]
	for raw: Variant in spec.eyes:
		if not raw is Array or raw.size()!=4 or not raw.all(func(v:Variant)->bool:return v is float or v is int):
			_fail("Eye rectangles must be numeric [x,y,w,h].")
			return
		var eye:=Rect2(float(raw[0]),float(raw[1]),float(raw[2]),float(raw[3]))
		if eye.size.x<=0 or eye.size.y<=0 or eye.position.x<0 or eye.position.y<0 or eye.end.x>250 or eye.end.y>250:
			_fail("Keep eye rectangles inside the blink reference crop.")
			return
		eyes.append(eye)
	var generated:=Image.load_from_file(ProjectSettings.globalize_path(directory+"blink-generated.png"))
	if generated==null:
		_fail("Generate the closed-eye crop before assembling.")
		return
	generated.convert(Image.FORMAT_RGBA8)
	generated.resize(250,250,Image.INTERPOLATE_LANCZOS)
	var blink:=front.get_region(Rect2i(836,836,418,418))
	for y: int in range(250):
		for x: int in range(250):
			for eye: Rect2 in eyes:
				var radius: float=((Vector2(x,y)-eye.get_center())/(eye.size*.5)).length()
				if radius>=1.0:continue
				var original:=blink.get_pixel(x+90,y+35)
				var painted:=generated.get_pixel(x,y)
				painted.a=original.a
				blink.set_pixel(x+90,y+35,original.lerp(painted,smoothstep(1.0,.82,radius)))
	blink.save_png(ProjectSettings.globalize_path(directory+"blink-se.png"))
	blink.flip_x()
	blink.save_png(ProjectSettings.globalize_path(directory+"blink-sw.png"))
	for pair: Array in [[front,"SW"],[rear,"NW"]]:
		var mirror:=Image.create(1254,1254,false,Image.FORMAT_RGBA8)
		for index: int in range(9):
			var region:=Rect2i((index%3)*418,(index/3)*418,418,418)
			var pose: Image=(pair[0] as Image).get_region(region)
			pose.flip_x()
			mirror.blit_rect(pose,Rect2i(0,0,418,418),region.position)
		mirror.save_png(ProjectSettings.globalize_path(directory+str(pair[1])+".png"))
	var record: Dictionary={"tool":"built-in image_gen.imagegen", "model":"not exposed", "source_adapter":"pipeline/prepare_cast_source.gd", "source_adapter_sha256":FileAccess.get_sha256("res://pipeline/prepare_cast_source.gd"), "method":"Original 1254-square paintings; exact per-cell left mirrors; only two feathered eye ellipses composited from generated blink, original alpha and other neutral pixels preserved. Use existing integer-registration packer next.", "blink_crop":[90,35,250,250], "eye_rectangles":spec.eyes, "inputs":{}}
	for name: String in ["SE.png","NE.png","SW.png","NW.png","idle-se.png","blink-reference.png","blink-generated.png","blink-assembly.json","blink-se.png","blink-sw.png"]:
		record.inputs[name]=FileAccess.get_sha256(directory+name)
	var file:=FileAccess.open(directory+"authoring.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(record,"  ")+"\n")
	print("Assembled shared-frame cast source: ",directory)
	quit(0)

func _source(path:String)->Image:
	var source:=Image.load_from_file(ProjectSettings.globalize_path(path))
	if source==null or source.get_size()!=Vector2i(1254,1254) or not source.detect_alpha():
		_fail("Expected a transparent 1254-square nine-pose painting: "+path)
		return null
	source.convert(Image.FORMAT_RGBA8)
	return source

func _fail(message:String)->void:
	printerr(message)
	quit(1)
