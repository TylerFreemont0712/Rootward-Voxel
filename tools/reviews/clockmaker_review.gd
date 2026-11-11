extends "res://tools/reviews/square_layout_review.gd"
## Original concept model, actual shared-time hands, real hinged entry and saved empty room.
func go() -> void:
 OS.set_environment("VOXEL_LAB_FRESH","1")
 var args:=OS.get_cmdline_user_args()
 output=args[0] if not args.is_empty() else "res://evidence/clockmaker"
 root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1600,1000);root.content_scale_size=root.size
 SaveStore.save_path="user://clockmaker_review_%d.json" % OS.get_process_id()
 SaveStore.profile_path="user://clockmaker_profile_%d.json" % OS.get_process_id();SaveStore.force_enabled=true
 game=(load("res://scenes/game.tscn") as PackedScene).instantiate();root.add_child(game)
 game.layout_export_override="res://.cache/clockmaker/review-layout.json"
 await process_frame;await game.start_new_game("sparks-and-machines")
 _check(DevelopmentMode.jump(game,"square"),"The original clockmaker loads in the campaign")
 SaveStore.development=false
 game._dialogue_read["workshop-scenes"]=game._story.scenes.keys();game._dismissed_scenes=game._story.scenes.keys()
 game._pop_all_modals();game.close_notebook(true)
 await walk(Vector2i(19,3))
 game.view.focus_on(Vector2(22,6),true);await shot("06-restored-terraces")
 game.view.focus_on(Vector2(21,0),true);await shot("07-mist-day")
 CityCycle.at_hour(game.session.cycle,23.0);game.session.sync_cycle()
 await shot("08-mist-night")
 CityCycle.at_hour(game.session.cycle,9.25);game.session.sync_cycle()
 await walk(Vector2i(18,20))
 var model:=game.view.building_node("clockmaker")
 _check(model!=null and DoorSwing.leaves(model).size()==2,"Both exported parts of the working oak door are present")
 game.view.set_camera_mode(WorldView.CameraMode.FREE)
 game.view.focus_on(Vector2(13,21),true)
 game.view._focus.y+=3.0;game.view._place_camera();await shot("00-full-building")
 game.view.set_camera_mode(WorldView.CameraMode.FOLLOW)
 game.view.focus_on(Vector2(13,21),true);await shot("01-original-shop-on-strip")
 var hands: Array[Node]=model.find_children("clock_*_hand*","Node3D",true,false)
 var time:=CityCycle.time(game.session.cycle)
 time.hour=3.5;game.view.set_city_cycle(time,CityCycle.power(game.session.cycle))
 var positions: Array[Transform3D]=[]
 for hand: Node3D in hands:positions.append(hand.transform)
 time.hour=9.25;game.view.set_city_cycle(time,CityCycle.power(game.session.cycle))
 _check(hands.size()==2 and not (hands[0] as Node3D).transform.is_equal_approx(positions[0]),"The facade clock follows town time in the live view")
 await walk(Vector2i(16,21));game.view.focus_on(Vector2(14,21),true);await shot("02-central-shop-door")
 _check(game.session.request_step(Vector2i.LEFT),"A normal step starts entry through the original facade")
 var seen_open: bool=false
 while game._flow_busy:
  if is_instance_valid(model):seen_open=seen_open or DoorSwing.is_open(model)
  await process_frame
 await settle();game._pop_all_modals()
 _check(seen_open,"The door actually swings while entering")
 _check(game.area.id=="shop-clockmaker","The working door opens the separate clockmaker room")
 _check(game.area.interior.shell=="clockshop-shell" and game.area.interior.inspections.size()>=14,"The new collection furnishes the room")
 game.session.state.memory={"clockmaker_kept":99};game.save_now()
 await shot("03-furnished-room")
 var old_zoom:float=game.view.zoom()
 game.view.set_camera_mode(WorldView.CameraMode.FREE)
 game.view.focus_on(Vector2(6.5,7),true)
 game.view.set_zoom(16);game.view.camera.size=16
 await shot("09-room-overview")
 game.view.set_zoom(old_zoom);game.view.camera.size=old_zoom
 game.view.set_camera_mode(WorldView.CameraMode.FOLLOW)
 for item:Dictionary in game.area.interior.inspections:
  await walk(Vector2i(item.at[0],item.at[1]))
  game._pop_all_modals();game.interact()
  _check(game.session.state.inspections_read.has(item.id),"F reads the custom object: "+str(item.id))
  if item.id=="planetary-orrery":await shot("10-orrery-inspection")
  if item.id=="clock-repairs":await shot("11-repair-corner")
 game.save_now()
 await game._return_to_title();await game.continue_game("sparks-and-machines");game._pop_all_modals()
 _check(game.area.id=="shop-clockmaker" and game.session.state.memory.get("clockmaker_kept")==99,"Continue inside the shop retains its own program memory")
 _check(game.session.state.inspections_read.size()>=14,"Continue keeps the inspected collection")
 await walk(Vector2i(6,0))
 _check(game.session.request_step(Vector2i(0,-1)),"The interior doorway starts the return")
 while game._flow_busy:await process_frame
 await settle();game._pop_all_modals()
 _check(game.area.id=="haverlund-square" and game.session.player_cell()==Vector2i(17,21),"The room returns beside the matching clockmaker facade")
 model=game.view.building_node("clockmaker")
 await create_timer(DoorSwing.OPEN_SECONDS+.1).timeout
 _check(model!=null and not DoorSwing.is_open(model),"The exterior door closes after return")
 _check(game._journey_rooms["shop-clockmaker"].state.memory.get("clockmaker_kept")==99,"Shop progress stays independent of square memory")
 game.view.focus_on(Vector2(13,21),true);await shot("04-return-to-strip")
 # Light the real frontage fitting during the shared evening to inspect the shop at normal scale.
 CityCycle.at_hour(game.session.cycle,19.25)
 game.session.sync_cycle()
 await shot("05-evening-frontage")
 for issue: String in failures:printerr("FAIL: ",issue)
 print("Clockmaker native review: %d checks, %d failures." % [checks,failures.size()])
 SaveStore.delete("sparks-and-machines")
 quit(0 if failures.is_empty() else 1)
