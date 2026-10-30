extends SceneTree
## Candidate sprite art review only. Does not replace the adopted in-world robot models.

const IDS: Array[String]=["wick","tender"]
const DIRS: Array[String]=["SE","SW","NE","NW"]
const MOTIONS: Array[Vector2]=[Vector2(1,.5),Vector2(-1,.5),Vector2(1,-.5),Vector2(-1,-.5)]
const CELL:=704
const OUT: String="res://docs/concept/v0.72/art/wick-tender/"
var records: Dictionary={}
var atlases: Dictionary={}
var sprites: Array[AnimatedSprite3D]=[]
var native_output: String

func _initialize()->void:
	Engine.max_fps=32
	_run.call_deferred()

func _run()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var cache:=ProjectSettings.globalize_path("res://.cache/wick-tender-preview")
	DirAccess.make_dir_recursive_absolute(cache)
	var comparison:=_canvas(1408,704)
	var native: bool=DisplayServer.get_name()!="headless"
	for index: int in range(IDS.size()):
		var id:=IDS[index]
		var directory: String="res://art/source/robots/v0.72/"+id+"/movement-v1/"
		if not FileAccess.file_exists(directory+"movement.json") or not FileAccess.file_exists(directory+"movement-atlas.png"):
			printerr("Register both robot movement sources before reviewing: ",directory)
			quit(1)
			return
		records[id]=JSON.parse_string(FileAccess.get_file_as_string(directory+"movement.json"))
		atlases[id]=Image.load_from_file(ProjectSettings.globalize_path(directory+"movement-atlas.png"))
		if native:continue
		var contact: Image=atlases[id].duplicate()
		contact.resize(1408,1408,Image.INTERPOLATE_LANCZOS)
		var sheet:=_canvas(1408,1408)
		sheet.blend_rect(contact,Rect2i(0,0,1408,1408),Vector2i.ZERO)
		sheet.save_png(ProjectSettings.globalize_path(OUT+id+"-movement.png"))
		for direction: int in range(4):
			var pose:=_pose(id,direction,0)
			comparison.blend_rect(pose,Rect2i(0,0,352,352),Vector2i(direction*352,index*352))
		for phase: int in range(4):
			var frame:=_canvas(704,704)
			for direction: int in range(4):
				frame.blend_rect(_pose(id,direction,phase),Rect2i(0,0,352,352),Vector2i((direction%2)*352,(direction/2)*352))
			frame.save_png(cache.path_join(id+"-%02d.png"%phase))
	if not native:comparison.save_png(ProjectSettings.globalize_path(OUT+"four-views.png"))
	if DisplayServer.get_name()=="headless":
		print("Wick/Tender registered movement sheets and four-view GIF inputs exported.")
		quit()
		return
	await _native()

func _native()->void:
	native_output=ProjectSettings.globalize_path("res://.cache/wick-tender-native-%dx%d"%[root.size.x,root.size.y])
	DirAccess.make_dir_recursive_absolute(native_output.path_join("roll"))
	var view:=ClearingView.new()
	root.add_child(view)
	view.set_process(false)
	view.camera.size=16
	view.camera.look_at_from_position(Vector3(21,17.8,21),Vector3(0,.5,0))
	var across:=Vector3(.7071,0,-.7071)
	var back:=Vector3(-.7071,0,-.7071)
	for row: int in range(3):
		for column: int in range(4):
			var at:=across*(-5.25+column*3.5)+back*(5.0-row*5.0)
			view._block(at+Vector3(0,-.07,0),Vector3(1.6,.14,1.6),"path")
			if row==0:
				var boy:=SpriteAdventurer.new()
				view.add_child(boy)
				boy.position=at
				boy.face_screen_direction(MOTIONS[column])
			else:
				var id:=IDS[row-1]
				var upright:=Node3D.new()
				view.add_child(upright)
				upright.position=at
				upright.scale.y=1.0/cos(SpriteAdventurer.CAMERA_ELEVATION)
				var sprite:=AnimatedSprite3D.new()
				upright.add_child(sprite)
				sprite.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y
				sprite.shaded=false
				sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
				sprite.alpha_scissor_threshold=.18
				sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				sprite.pixel_size=(1.85 if id=="wick" else .95)/float(records[id].opaque_height)
				sprite.offset=Vector2(0,308)
				sprite.flip_h=false
				var picture: Image=atlases[id].duplicate()
				picture.generate_mipmaps()
				var texture:=ImageTexture.create_from_image(picture)
				var frames:=SpriteFrames.new()
				frames.set_animation_speed("default",8)
				for phase: int in range(4):
					var frame:=AtlasTexture.new()
					frame.atlas=texture
					frame.region=Rect2(phase*CELL,column*CELL,CELL,CELL)
					frames.add_frame("default",frame)
				sprite.sprite_frames=frames
				sprite.play()
				sprites.append(sprite)
			var label:=Label3D.new()
			label.text=("Boy" if row==0 else IDS[row-1].capitalize())+" · "+DIRS[column]
			label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			label.font_size=32
			label.pixel_size=.006
			label.position=at+Vector3(0,2.15 if row==1 else 1.7,0)
			view.add_child(label)
	view._flush_batches()
	await _frames(20)
	for sprite: AnimatedSprite3D in sprites:
		sprite.pause()
		sprite.frame=0
	await _shot("directions")
	for sprite: AnimatedSprite3D in sprites:sprite.play()
	var seen: Dictionary={}
	for index: int in range(32):
		await _frames(2)
		for sprite: AnimatedSprite3D in sprites:seen[sprite.frame]=true
		await _shot("roll/frame-%02d"%index)
	view.camera.size=10
	await _shot("detail")
	print("Wick/Tender native review: 8 independent direction sprites, no horizontal flips; ",seen.size()," rolling phases played. Approved boy shown for scale.")
	quit(0 if seen.size()==4 else 1)

func _pose(id: String,direction: int,phase: int)->Image:
	var pose: Image=atlases[id].get_region(Rect2i(phase*CELL,direction*CELL,CELL,CELL))
	pose.resize(352,352,Image.INTERPOLATE_LANCZOS)
	return pose

func _canvas(width: int,height: int)->Image:
	var picture:=Image.create(width,height,false,Image.FORMAT_RGBA8)
	picture.fill(Color("24363d"))
	return picture

func _frames(count: int)->void:
	for _index: int in range(count):await process_frame

func _shot(id: String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(native_output.path_join(id+".png"))
