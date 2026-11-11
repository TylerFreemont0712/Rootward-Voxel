extends SceneTree
## Live instances share expensive resources, but caches must not keep departed scenes alive.
var checks:int=0
var failures:Array[String]=[]
func _initialize()->void:_run.call_deferred()
func _run()->void:
 var mesh:BoxMesh=BoxMesh.new();mesh.material=StandardMaterial3D.new()
 var a:=MeshInstance3D.new();a.mesh=mesh;root.add_child(a)
 var b:=MeshInstance3D.new();b.mesh=mesh;root.add_child(b)
 IllustratedEdges.apply(a);IllustratedEdges.apply(b)
 var hull:Mesh=(a.get_node("IllustratedOutline") as MeshInstance3D).mesh
 _check((b.get_node("IllustratedOutline") as MeshInstance3D).mesh==hull,"Live copies share one outline mesh")
 var source_ref:WeakRef=weakref(mesh);var hull_ref:WeakRef=weakref(hull)
 a.free();_check(hull_ref.get_ref()!=null,"A remaining instance keeps its outline alive")
 b.free();mesh=null;hull=null
 IllustratedEdges.prune_cache()
 _check(source_ref.get_ref()==null and hull_ref.get_ref()==null,"Outline cache releases source geometry, materials and hull after the last instance")
 var skins:Script=load("res://art/frame_skin.gd")
 var template:=SpriteFrames.new();template.add_animation("walk_se")
 var original:=ImageTexture.create_from_image(Image.create(8,8,false,Image.FORMAT_RGBA8))
 var frame:=AtlasTexture.new();frame.atlas=original;frame.region=Rect2(0,0,8,8)
 template.add_frame("walk_se",frame)
 var atlas:Texture2D=ImageTexture.create_from_image(Image.create(8,8,false,Image.FORMAT_RGBA8))
 var changed:SpriteFrames=skins.frames_for(template,atlas)
 _check(changed==skins.frames_for(template,atlas),"Live actors share their frame skin")
 var frames_ref:WeakRef=weakref(changed);var atlas_ref:WeakRef=weakref(atlas)
 changed=null;atlas=null;skins.prune_cache()
 _check(frames_ref.get_ref()==null and atlas_ref.get_ref()==null,"Unused frame skins and their atlases are released")
 _check(Sandbox.binary_name("Windows")=="wasmtime.exe" and Sandbox.binary_name("Linux")=="wasmtime","Native sandbox executable matches the desktop platform")
 _check(Sandbox.runtime_folder("Windows")!=Sandbox.runtime_folder("Linux"),"Windows and Linux never share native precompiled Python caches")
 var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/art-catalog.json"))
 _check(catalog.phantoms.texture_compression=="vram","Crowd masks use the GPU compression profile")
 var config:=ConfigFile.new();config.load("res://assets/characters/adventurer/sheet.png.import")
 _check(config.get_value("params","compress/mode")==0,"Approved player art remains lossless")
 config.load("res://assets/characters/phantoms/man.png.import")
 _check(config.get_value("params","compress/mode")==2,"The actual crowd import uses VRAM compression")
 var assets:Script=load("res://art/world_assets.gd")
 var id:String="seaside-eaveside-terrace"
 var look:Dictionary=HouseVariants.look(assets.entry(id),{"seed":17,"plain":true})
 var full:Node3D=assets.instantiate(id,ResourceLoader.CACHE_MODE_REUSE,look)
 var trimmed:Node3D=assets.instantiate(id,ResourceLoader.CACHE_MODE_REUSE,look,true)
 root.add_child(full);root.add_child(trimmed)
 _check(_visible_meshes(full)==_visible_meshes(trimmed),"Static trimming preserves the selected visible house and outline geometry")
 _check(trimmed.find_children("*","Node",true,false).size()<full.find_children("*","Node",true,false).size(),"Immutable scenery releases hidden alternative geometry")
 full.free();trimmed.free()
 for issue:String in failures:printerr("FAIL: ",issue)
 print("Render lifetime/platform: %d checks, %d failures."%[checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
func _check(ok:bool,words:String)->void:
 checks+=1
 if not ok:failures.append(words)
func _visible_meshes(model:Node3D)->Dictionary:
 var result:Dictionary={}
 for part:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
  if part.is_visible_in_tree():result[str(model.get_path_to(part))]=part.mesh.get_instance_id()
 return result
