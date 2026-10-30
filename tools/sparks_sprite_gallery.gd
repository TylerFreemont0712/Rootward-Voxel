extends SceneTree
## Derived review pictures only. Paintings/compiled atlases are never modified.

const CAST: Array[String] = ["nell", "mira", "rowan", "bram", "tessa"]
const ROBOTS: Array[String] = ["pip", "trowel", "wick", "heron", "tender", "tally"]
const OUT := "res://docs/concept/v0.72/art/"
const BG := Color("24363d")

func _initialize() -> void:
	for folder: String in ["cast", "robots"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.path_join(folder)))
	var cache := ProjectSettings.globalize_path("res://.cache/sparks-v072-gallery")
	DirAccess.make_dir_recursive_absolute(cache)
	var atlases: Array[Image] = []
	for id: String in CAST:
		var atlas := Image.load_from_file(ProjectSettings.globalize_path("res://assets/characters/skins/sparks_"+id+".png"))
		atlases.append(atlas)
		var sheet := _canvas(1920,896)
		for direction: int in range(4):
			for phase: int in range(10 if direction<2 else 9):
				var pose := _cast_pose(atlas,direction,phase)
				_put(sheet,pose,Vector2i(phase*192,direction*224))
		_save(sheet,OUT+"cast/"+id+"-movement.png")
	var idle := _canvas(960,224)
	var blink := _canvas(960,224)
	for index: int in range(CAST.size()):
		_put(idle,_cast_pose(atlases[index],0,8),Vector2i(index*192,0))
		_put(blink,_cast_pose(atlases[index],0,9),Vector2i(index*192,0))
	_save(idle,OUT+"cast/full-body-neutral.png")
	_save(blink,OUT+"cast/full-body-blink.png")
	for phase: int in range(8):
		var frame := _canvas(960,896)
		for index: int in range(CAST.size()):
			for direction: int in range(4):
				_put(frame,_cast_pose(atlases[index],direction,phase),Vector2i(index*192,direction*224))
		frame.save_png(cache.path_join("cast-%02d.png"%phase))
	var machines: Array[Image] = []
	for id: String in ROBOTS:
		var sheet := Image.load_from_file(ProjectSettings.globalize_path("res://art/source/robots/v0.72/"+id+"/sheet-generated.png"))
		machines.append(sheet)
		_save(sheet,OUT+"robots/"+id+"-sheet.png")
	var lineup := _canvas(1152,896)
	for index: int in range(ROBOTS.size()):
		_put(lineup,_robot_pose(machines[index],ROBOTS[index],0,0),Vector2i((index%3)*384,(index/3)*448))
	_save(lineup,OUT+"robots/lineup.png")
	for phase: int in range(4):
		var frame := _canvas(1152,896)
		for index: int in range(ROBOTS.size()):
			_put(frame,_robot_pose(machines[index],ROBOTS[index],1,phase),Vector2i((index%3)*384,(index/3)*448))
		frame.save_png(cache.path_join("robots-%02d.png"%phase))
	print("Sparks cast movement sheets, full-body blinks and six robot sheets exported. GIF inputs: ",cache)
	quit()

func _cast_pose(atlas: Image,direction: int,phase: int)->Image:
	var pose := atlas.get_region(Rect2i((phase%4)*384,(direction*3+phase/4)*448,384,448))
	pose.resize(192,224,Image.INTERPOLATE_LANCZOS)
	return pose

func _robot_pose(sheet: Image,id: String,row: int,phase: int)->Image:
	# Generated concept rows are not production atlas cells. Review uses authored cuts,
	# with padding and wheel registration; raw concepts stay unchanged beside their prompts.
	var cuts: Dictionary={"pip":[0,354,680],"trowel":[0,335,645],"wick":[0,400,680],"heron":[0,367,666],"tender":[0,350,660],"tally":[0,342,675]}
	var start: int=cuts[id][row]
	var end: int=cuts[id][row+1]
	var pose:=sheet.get_region(Rect2i(phase*384,start,384,end-start))
	# Wick's raised work-pole reaches upward into the unused lower-right of its roll row.
	if id=="wick" and row==1:
		pose.fill_rect(Rect2i(250,250,134,30),Color.TRANSPARENT)
	var bounds:=_opaque_bounds(pose)
	pose=pose.get_region(bounds)
	var factor:=minf(340.0/pose.get_width(),400.0/pose.get_height())
	pose.resize(roundi(pose.get_width()*factor),roundi(pose.get_height()*factor),Image.INTERPOLATE_LANCZOS)
	var result:=Image.create(384,448,false,Image.FORMAT_RGBA8)
	result.blit_rect(pose,Rect2i(Vector2i.ZERO,pose.get_size()),Vector2i((384-pose.get_width())/2,424-pose.get_height()))
	return result

func _opaque_bounds(picture: Image)->Rect2i:
	var first:=picture.get_size()
	var last:=Vector2i(-1,-1)
	for y: int in range(picture.get_height()):
		for x: int in range(picture.get_width()):
			if picture.get_pixel(x,y).a>0.25:
				first=first.min(Vector2i(x,y))
				last=last.max(Vector2i(x,y))
	return Rect2i(first,last-first+Vector2i.ONE)

func _canvas(width: int,height: int)->Image:
	var result := Image.create(width,height,false,Image.FORMAT_RGBA8)
	result.fill(BG)
	return result

func _put(target: Image,source: Image,at: Vector2i)->void:
	target.blend_rect(source,Rect2i(Vector2i.ZERO,source.get_size()),at)

func _save(picture: Image,path: String)->void:
	picture.save_png(ProjectSettings.globalize_path(path))
