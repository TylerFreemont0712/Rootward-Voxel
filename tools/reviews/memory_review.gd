extends SceneTree
## Repeatable live memory/adapter baseline; isolated saves and no user layout exports.
var game:Game
var records:Array=[]
func _initialize()->void:_run.call_deferred()
func _run()->void:
 OS.set_environment("VOXEL_LAB_FRESH","1")
 root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1600,1000);root.content_scale_size=root.size
 SaveStore.save_path="user://memory_review_%d.json"%OS.get_process_id()
 SaveStore.profile_path="user://memory_profile_%d.json"%OS.get_process_id();SaveStore.force_enabled=true
 game=(load("res://scenes/game.tscn") as PackedScene).instantiate();root.add_child(game)
 game.layout_export_override="res://.cache/memory-gpu/layout.json"
 await _sample("title")
 await game.start_new_game("sparks-and-machines")
 await _sample("loft")
 game._dialogue_read["workshop-scenes"]=game._story.scenes.keys();game._dismissed_scenes=game._story.scenes.keys()
 for target:String in ["haverlund-lane","haverlund-square","shop-clockmaker","haverlund-square","haverlund-lane","workshop-loft"]:
  await game._activate_journey_room_async(AreaStore.read_source(target),{})
  game.world_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
  game._pop_all_modals()
  await _sample(target)
 await game._return_to_title()
 await _sample("title-return")
 var args:=OS.get_cmdline_user_args()
 var output:String=args[0] if not args.is_empty() else "res://.cache/memory-gpu/memory.json"
 var f:=FileAccess.open(output,FileAccess.WRITE);f.store_string(JSON.stringify({"adapter":RenderingServer.get_video_adapter_name(),"vendor":RenderingServer.get_video_adapter_vendor(),"renderer":RenderingServer.get_current_rendering_method(),"os":OS.get_name(),"samples":records},"  "))
 SaveStore.delete("sparks-and-machines");quit()
func _sample(label:String)->void:
 for i:int in range(20):await process_frame
 var rss:int=-1
 if OS.get_name()=="Linux":
  var result:Array=[]
  if OS.execute("ps",["-o","rss=","-p",str(OS.get_process_id())],result)==0:rss=str(result[0]).strip_edges().to_int()*1024
 var row:Dictionary={"area":label,"rss":rss,"tracked_ram":OS.get_static_memory_usage(),"texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),"buffer_bytes":int(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)),"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"outline_entries":IllustratedEdges._meshes.size(),"frame_entries":load("res://art/frame_skin.gd")._frame_cache.size(),"pinned_story_atlases":load("res://art/world_assets.gd")._story_atlases.size()}
 records.append(row);print("MEMORY ",JSON.stringify(row))
