extends SceneTree
## Guarded source registration for independently painted robot views; normal game art build is unchanged.

const CELL:=Vector2i(704,704)
const ANCHOR:=Vector2i(352,660)
const DIRECTIONS: Array[String]=["SE","SW","NE","NW"]

func _initialize()->void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=2 or args[0]!="--source" or not args[1].begins_with("res://art/source/robots/") or ".." in args[1]:
		_fail("Usage: -- --source res://art/source/robots/<version>/<id>/<NEW-movement-version>")
		return
	var directory: String=args[1].trim_suffix("/")+"/"
	for name: String in ["movement-atlas.png","movement.json"]:
		if FileAccess.file_exists(directory+name):
			_fail("Registered movement source already exists; use a NEW version directory.")
			return
	var atlas:=Image.create(CELL.x*4,CELL.y*4,false,Image.FORMAT_RGBA8)
	var record: Dictionary={"schema":1,"status":"registered sprite movement candidate; current runtime robot models unchanged","cell_size":[CELL.x,CELL.y],"anchor":[ANCHOR.x,ANCHOR.y],"directions":DIRECTIONS,"frames_per_direction":4,"preview_fps":8,"independent_directions":true,"horizontal_flips":false,"method":"Each physical direction separately painted with imagegen; integer translation only for registration, no resampling or mirrored views.","source_adapter":"pipeline/prepare_robot_movement.gd","source_adapter_sha256":FileAccess.get_sha256("res://pipeline/prepare_robot_movement.gd"),"sources":{},"poses":{},"opaque_height":0}
	for row: int in range(4):
		var direction:=DIRECTIONS[row]
		var path:=directory+direction+"-generated.png"
		var source:=Image.load_from_file(ProjectSettings.globalize_path(path))
		if source==null or source.get_width()!=source.get_height() or source.get_width()%2!=0 or not source.detect_alpha():
			_fail("Expected a transparent square 2x2 painting for every physical direction: "+path)
			return
		source.convert(Image.FORMAT_RGBA8)
		record.sources[path]=FileAccess.get_sha256(path)
		var size:=source.get_width()/2
		var phases: Array=[]
		for phase: int in range(4):
			var region:=Rect2i((phase%2)*size,(phase/2)*size,size,size)
			var figure:=source.get_region(region)
			var bounds:=_bounds(figure)
			if bounds.size.x<=0 or bounds.size.y<=0 or bounds.position.x<2 or bounds.position.y<2 or bounds.end.x>size-2 or bounds.end.y>size-2:
				_fail("A rolling key is empty or touches its source-cell edge: "+path)
				return
			# The rolling contact footprint, rather than the asymmetric tool, owns horizontal origin.
			var lower:=figure.get_region(Rect2i(0,maxi(0,bounds.end.y-96),size,mini(96,bounds.end.y)))
			var chassis:=_bounds(lower)
			var offset:=Vector2i(ANCHOR.x-chassis.get_center().x,ANCHOR.y-bounds.end.y)
			if bounds.position.x+offset.x<16 or bounds.end.x+offset.x>CELL.x-16 or bounds.position.y+offset.y<16:
				_fail("Complete robot/tool would clip its registered cell; review the source: "+path)
				return
			var frame:=Image.create(CELL.x,CELL.y,false,Image.FORMAT_RGBA8)
			frame.blit_rect(figure,Rect2i(0,0,size,size),offset)
			atlas.blit_rect(frame,Rect2i(Vector2i.ZERO,CELL),Vector2i(phase*CELL.x,row*CELL.y))
			phases.append({"source_rect":[region.position.x,region.position.y,region.size.x,region.size.y],"translation":[offset.x,offset.y],"opaque_bounds":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y]})
			record.opaque_height=maxi(int(record.opaque_height),bounds.size.y)
		record.poses[direction]=phases
	var output:=directory+"movement-atlas.png"
	atlas.save_png(ProjectSettings.globalize_path(output))
	record.output=output
	record.output_sha256=FileAccess.get_sha256(output)
	var file:=FileAccess.open(directory+"movement.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(record,"  ")+"\n")
	print("Registered 16 independently painted robot keys, complete tools and fixed wheel origins: ",directory)
	quit()

func _bounds(picture: Image)->Rect2i:
	var first:=picture.get_size()
	var last:=Vector2i(-1,-1)
	for y: int in range(picture.get_height()):
		for x: int in range(picture.get_width()):
			if picture.get_pixel(x,y).a>0.25:
				first=first.min(Vector2i(x,y))
				last=last.max(Vector2i(x,y))
	return Rect2i(first,last-first+Vector2i.ONE)

func _fail(message: String)->void:
	printerr(message)
	quit(1)
