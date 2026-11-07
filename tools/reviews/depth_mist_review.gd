extends SceneTree
## GPU proof that real surface heights fade continuously in both day and night.
var failures:Array[String]=[]
var checks:int=0
var output:String="res://evidence/clockshop-expansion"
func _initialize()->void:_run.call_deferred()
func _run()->void:
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():output=args[0]
 root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1000,1000);root.content_scale_size=root.size
 var wall:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(12,12,.1)
 wall.mesh=box;wall.position=Vector3(0,-6,0)
 var white:=StandardMaterial3D.new();white.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;white.albedo_color=Color.WHITE
 wall.material_override=white;root.add_child(wall)
 var camera:=Camera3D.new();root.add_child(camera);camera.position=Vector3(0,-4,20)
 camera.look_at(Vector3(0,-4,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=14;camera.current=true
 var overlay:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(2,2)
 overlay.mesh=quad;overlay.extra_cull_margin=16384;root.add_child(overlay)
 var material:=ShaderMaterial.new();material.shader=load("res://art/depth_mist.gdshader");material.render_priority=127
 overlay.material_override=material
 for day:float in [0.0,1.0]:
  material.set_shader_parameter("daylight",day)
  for n:int in range(8):await process_frame
  await RenderingServer.frame_post_draw
  var result:=root.get_texture().get_image()
  var samples:Array[float]=[]
  for h:float in [-1.0,-3.5,-5.0,-6.5,-8.0]:
   var pixel:=camera.unproject_position(Vector3(0,h,.06))
   samples.append(result.get_pixelv(Vector2i(pixel)).get_luminance())
  _check(samples[0]>.95,"Mist leaves the rim unchanged")
  _check(samples[0]>samples[1]+.01 and samples[1]>samples[2]+.01 and samples[2]>samples[3]+.01,"Actual wall pixels fade gradually through several depths")
  if day==0:
   _check(samples[1]>.65 and samples[4]<.08,"Night keeps the nearer wall visible and hides the bottom at twice the old depth")
  else:_check(samples[4]>.45,"Daylight has fog rather than a black bottom")
  print("Depth mist pixels daylight=",day,": ",samples)
  DirAccess.make_dir_recursive_absolute(output)
  result.save_png(output.path_join("gradient-%s.png" % ("night" if day==0 else "day")))
 for issue:String in failures:printerr("FAIL: ",issue)
 print("Depth mist GPU review: %d checks, %d failures." % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
func _check(ok:bool,words:String)->void:
 checks+=1
 if not ok:failures.append(words)
