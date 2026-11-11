extends "res://test/test_square.gd"
## The layout studio as a player uses it in Rootward Square: B opens it, the mouse places, moves, turns and paints, undo
## and redo walk the history, Done exports a snapshot, Continue rebuilds it all, and the stairs still work afterwards.
## Scratch campaign and layout exports never touch the user's draft. Optional -- <directory> captures it at 1600x1000.
var builder: BuildMode
func go() -> void:
 OS.set_environment("VOXEL_LAB_FRESH","1")
 var args:=OS.get_cmdline_user_args()
 output=args[0] if not args.is_empty() else ""
 if not output.is_empty() and DisplayServer.get_name()!="headless":root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1600,1000);root.content_scale_size=root.size
 SaveStore.save_path="user://layout_review_%d.json" % OS.get_process_id()
 SaveStore.profile_path="user://layout_profile_%d.json" % OS.get_process_id()
 SaveStore.force_enabled=true
 game=(load("res://scenes/game.tscn") as PackedScene).instantiate();root.add_child(game)
 game.layout_export_override="res://.cache/layout-studio/review-layout.json"
 await process_frame
 await game.start_new_game("sparks-and-machines")
 _check(DevelopmentMode.jump(game,"square"),"Development jump reaches the revised square")
 SaveStore.development=false
 game._dialogue_read["workshop-scenes"]=game._story.scenes.keys();game._dismissed_scenes=game._story.scenes.keys()
 game._pop_all_modals();game.close_notebook(true)
 game.session.set_physics_process(false)
 await walk(Vector2i(13,12))
 game.session.request_step(Vector2i(-1,0));game.session.advance_walk(LabWorld.STEP_SECONDS)
 game.session.request_step(Vector2i(-1,0))
 while game._flow_busy:await process_frame
 _check(game.area.id=="haverlund-lane","The westward boundary still returns to the lane")
 await walk(Vector2i(12,26));game.session.request_step(Vector2i(0,1))
 while game._flow_busy:await process_frame
 await settle();game._pop_all_modals()
 _check(game.area.id=="haverlund-square" and game.session.player_cell()==Vector2i(15,11),"The lane loads four cells farther west")
 game.view.focus_on(Vector2(16,10),true);await shot("01-restored-arrival")
 game.view.focus_on(Vector2(11,28),true);await shot("02-restored-plots")
 await _tap(KEY_B);builder=game.builder
 _check(builder.active and not game.session.input_enabled,"B opens the layout builder in Sparks")
 _check(game.view.ground_skin!=null and game.view.ground_skin.get_child_count()==0,"An unpainted terrace adds no ground overlay draw calls")
 _check(builder.hud.visible_items().size()==14 and not builder.hud._tab_buttons.has("houses") and builder.hud._tab_buttons.has("walls"),"The shelf offers the fourteen park and barrier pieces, and a Walls tab")
 _check(not builder.hud._paint_tabs.Terrain.visible and not builder.hud._paint_tabs.Water.visible,"Authored terrain shaping is hidden")
 await shot("03-layout-builder")
 builder.choose_item("lane-bench")
 await _point(Vector2(7,5));await _mouse(true);await _mouse(false)
 var id: String = "prop-1"
 _check(not game.area.prop(id).is_empty() and game.view.building_node(id)!=null,"The mouse places a park bench")
 _check(not game.session.rules.is_walkable(game.session.state,Vector2i(7,5)),"The visible bench blocks walking")
 await _tap(KEY_1);await _point(Vector2(7,5));await _mouse(true);await _mouse(false)
 _check(builder.selected.get("id")==id,"Move selects the bench")
 await _tap(KEY_R)
 _check(game.area.prop(id).facing=="E","R turns the selected bench")
 await shot("04-placed-bench")
 await _tap(KEY_Z,true)
 _check(game.area.prop(id).facing=="S","Ctrl+Z restores its former orientation")
 await _tap(KEY_Y,true)
 _check(game.area.prop(id).facing=="E","Ctrl+Y reapplies the turn")
 # Walls: a garden wall drawn with one drag along the grid blocks the edges it runs along; Delete takes it down.
 builder.choose_item("wall-garden")
 await _point(Vector2(8.5,1.5));await _mouse(true)
 await _point(Vector2(8.6,4.4));await _mouse(false)
 _check(game.area.walls.size()==1 and game.area.walls[0].from==Vector2(8.5,1.5) and game.area.walls[0].to==Vector2(8.5,4.5),"One drag draws a garden wall along the grid")
 _check(game.session.rules.find_path(game.session.state,Vector2i(9,3),Vector2i(8,3)).size()>1 and game.view.find_child("DrawnWalls",true,false)!=null,"The wall stands in the picture and blocks the way across it")
 await shot("04b-drawn-wall")
 await _tap(KEY_2);await _point(Vector2(8.5,3.0));await _mouse(true);await _mouse(false)
 _check(game.area.walls.is_empty(),"Delete takes the wall down")
 await _tap(KEY_Z,true)
 _check(game.area.walls.size()==1,"Undo puts it back")
 await _tap(KEY_1)
 # Authored scenery: the Move tool chooses a lamp standard in the square, lifts it and sets it down; its lamp and light go with it.
 game.session.state.lamp_programs["lamp-ring-1"]={"day":false,"night":true}
 await _point(Vector2(66.87,27.67));await _mouse(true);await _mouse(false)
 _check(builder.selected.get("kind")=="scenery" and builder.selected.get("id")=="lamp-ring-1","Move chooses an authored lamp standard")
 await _mouse(true);await _mouse(false)
 await _point(Vector2(68.37,27.67));await _mouse(true);await _mouse(false)
 var lamp_node: Node3D=game.view.building_node("lamp-ring-1")
 _check(game.area.lamp("lamp-ring-1").at.distance_to(Vector2(68.37,27.67))<.3 and lamp_node!=null and lamp_node.visible and absf(lamp_node.position.x-game.area.lamp("lamp-ring-1").at.x)<.01,"The lamp standard and its lamp move together")
 _check(game.session.state.lamp_programs.get("lamp-ring-1",{}).get("night")==true,"A moved lamp keeps its program")
 await _tap(KEY_Z,true)
 _check(game.area.lamp("lamp-ring-1").at.is_equal_approx(Vector2(66.87,27.67)) and absf(game.view.building_node("lamp-ring-1").position.x-66.87)<.01,"Undo puts the lamp back")
 await _tap(KEY_ESCAPE)
 await _tap(KEY_4);builder.choose_paint("limestone_flags");builder.set_brush_size(2)
 await _point(Vector2(8,7));await _mouse(true)
 await _point(Vector2(12,7));await _mouse(false)
 _check(game.ledger.edits.back().op=="paint" and not game.area.paint.is_empty(),"A dragged path commits one paint stroke")
 _check(game.view.ground_skin.get_child_count()>0,"Only painted chunks acquire overlay meshes")
 await shot("05-painted-path")
 var painted: int=game.ledger.edits.size()
 await _point(Vector2(10,6));await _mouse(true);await _tap(KEY_ESCAPE);await _mouse(false)
 _check(game.ledger.edits.size()==painted,"Escape cancels the live paint proposal")
 await _tap(KEY_Z,true)
 _check(game.view.ground_skin.get_child_count()==0,"Undo clears all paint geometry and reveals the original surface")
 await _tap(KEY_Y,true)
 game.close_build()
 _check(not builder.active and game.session.input_enabled,"Done returns control to the traveller")
 var exported: Variant=JSON.parse_string(FileAccess.get_file_as_string(game.layout_export_override))
 _check(exported is Dictionary and exported.area=="haverlund-square" and exported.edits.size()==game.ledger.edits.size(),"Done exports a readable layout snapshot")
 game.session.state.memory={"layout_kept":53};game.save_now()
 await game._return_to_title();await game.continue_game("sparks-and-machines");game._pop_all_modals()
 _check(game.area.id=="haverlund-square" and game.session.state.memory.get("layout_kept")==53,"Continue preserves the campaign and program memory")
 _check(not game.area.prop(id).is_empty() and game.area.prop(id).facing=="E" and game.view.building_node(id)!=null and game.view.ground_skin.get_child_count()>0,"Continue reconstructs props and paint through the asynchronous loader")
 game.view.focus_on(Vector2(10,6),true);await shot("06-layout-continued")
 await walk(Vector2i(19,7))
 for n: int in range(9):game.session.request_step(Vector2i(1,0));game.session.advance_walk(LabWorld.STEP_SECONDS)
 _check(game.session.player_cell()==Vector2i(28,7) and game.view.player_node().position.y<.2,"Both stair flights remain walkable after editing")
 await shot("07-stairs-preserved")
 for issue: String in failures:printerr("FAIL: ",issue)
 print("Square layout flow: %d checks, %d failures." % [checks,failures.size()])
 SaveStore.delete("sparks-and-machines")
 quit(0 if failures.is_empty() else 1)
func _tap(key: Key, ctrl: bool=false) -> void:
 var e:=InputEventKey.new();e.keycode=key;e.physical_keycode=key;e.pressed=true;e.ctrl_pressed=ctrl
 game._unhandled_key_input(e)
 for n: int in range(3):await process_frame
func _point(at: Vector2) -> void:
 game.view.focus_on(at,true)
 await process_frame
 var on_screen: Vector2=game.view.camera.unproject_position(Vector3(at.x,game.view.ground_y(at),-at.y))*game.surface.size/Vector2(game.world_viewport.size)
 var e:=InputEventMouseMotion.new();e.position=on_screen
 game._on_world_input(e)
 for n: int in range(4):await process_frame
 await create_timer(.16).timeout
 for n: int in range(2):await process_frame
func _mouse(down: bool) -> void:
 var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=game.builder._pointer
 game._on_world_input(e)
 for n: int in range(4):await process_frame

func walk(target: Vector2i) -> void:
 game.session.set_physics_process(false)
 if game.session.is_walking():game.session.advance_walk(LabWorld.STEP_SECONDS)
 if game.view.residents!=null:game.view.residents.set_physics_process(false);game.view.residents.set_process(false)
 game.session._cancel_route()
 var route: Array[Vector2i]=game.session.rules.find_path(game.session.state,target,game.session.player_cell(),game.view.resident_cells())
 _check(target==game.session.player_cell() or not route.is_empty(),"A walkable route reaches "+str(target))
 for next: Vector2i in route:
  var moved: bool=game.session.request_step(next-game.session.player_cell())
  if not moved:
   print("REVIEW WALK REFUSED ",game.area.id," from ",game.session.player_cell()," to ",next," waiting ",game.session._waiting_for_stop," people ",game.view.resident_cells().has(next));break
  game.session.advance_walk(LabWorld.STEP_SECONDS)
  await process_frame
 _check(game.session.player_cell()==target,"The traveller finishes at "+str(target))
