extends SceneTree
## Small A/B frame-cost sample for the height-fog pass on the actual square.
func _initialize()->void:_run.call_deferred()
func _run()->void:
 root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1600,1000);root.content_scale_size=root.size
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
 var view:=WorldView.new();root.add_child(view);await process_frame
 view.setup(AreaStore.load_area("haverlund-square"))
 view.set_camera_mode(WorldView.CameraMode.FIXED);view.focus_on(Vector2(21,0),true)
 var state:=LabWorld.new(view.area).initial_state()
 for id:String in state.lamps:state.lamps[id]=true
 view.apply_state(state)
 var cycle:=CityCycle.fresh();CityCycle.at_hour(cycle,23);view.set_city_cycle(CityCycle.time(cycle),CityCycle.power(cycle))
 var overlay:=view._content.get_node("LowerTownMist") as MeshInstance3D
 var results:Array=[]
 for enabled:bool in [false,true,true,false]:
  overlay.visible=enabled
  for i:int in range(20):await process_frame
  var times:Array[float]=[]
  for i:int in range(90):
   var start:int=Time.get_ticks_usec()
   await process_frame
   await RenderingServer.frame_post_draw
   times.append((Time.get_ticks_usec()-start)/1000.0)
  times.sort()
  results.append({"mist":enabled,"median_ms":times[45],"p95_ms":times[85]})
 print("Depth mist native frame samples: ",JSON.stringify(results))
 quit()
