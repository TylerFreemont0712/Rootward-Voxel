extends SceneTree
## The authored square reuses paint/prop history without changing campaign progress or its base document.
var checks: int = 0
var failures: Array[String] = []
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
 var source := AreaStore.read_source("haverlund-square")
 var ledger := BuildLedger.new(source.document, source.assets, source.quests, AreaStore.read_build_catalog(), [], "studio", AreaStore.ground_materials())
 var state := ledger.rules.initial_state()
 var original: String = JSON.stringify(source.document)
 _check(ledger.area.level_at(Vector2i(19,3))==2 and ledger.area.level_at(Vector2i(24,3))==0,"The smaller raised garden and original lower terrace retain distinct levels")
 _check(ledger.area.level_at(Vector2i(12,40))==2 and ledger.area.level_at(Vector2i(18,30))==2 and not ledger.rules.is_walkable(state,Vector2i(8,40)),"The shop plots and physic garden join the high promenade; nothing past the rear wall is ground")
 var sketch:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://content/areas/archive/haverlund-square-v7-layout-sketch.json"))
 var migrated:=BuildLedger.new(source.document,source.assets,source.quests,AreaStore.read_build_catalog(),sketch.edits,"studio",AreaStore.ground_materials())
 _check(migrated.edits.is_empty() and migrated.archived_layouts.size()==1 and migrated.archived_layouts[0].edits==sketch.edits,"Restoration archives the player's former sketch without applying it to different terrain")
 var again:=BuildLedger.new(source.document,source.assets,source.quests,AreaStore.read_build_catalog(),migrated.saved_edits(),"studio",AreaStore.ground_materials())
 _check(again.archived_layouts==migrated.archived_layouts and again.edits.is_empty(),"Continue preserves the archived sketch exactly once")
 var steps := RoomLinks.find(ledger.area,"uphill-steps")
 var at_foot := state.duplicate(true); at_foot.player=[6,8,0]
 _check(not ledger.rules.is_walkable(state,Vector2i(5,8)) and str(steps.get("to",""))=="haverlund-lane" and RoomLinks.crossing(ledger.area,at_foot,Vector2i.LEFT).get("id","")=="uphill-steps","Walking onto the foot of Spindle Steps climbs to the lane; the flight itself is not floor")
 var link := RoomLinks.find(ledger.area,"uphill")
 _check(Vector2i(int(link.at[0]),int(link.at[1])) == Vector2i(12,12) and ledger.area.spawn == Vector2i(13,12),"Loading is four cells west of the former boundary after the 16-cell rebase")
 var old_doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/areas/archive/haverlund-square-v6.json"))
 var old := AreaDef.parse(old_doc,source.assets)
 _check(old.ok,"Previous authored map remains valid")
 if old.ok:
  var old_rules := LabWorld.new(old.area)
  var saved := old_rules.initial_state()
  saved.erase("map_offset") # Real v6 saves predate the offset marker.
  saved.player=[35,17,0];saved.memory={"kept":42};saved.items=["field-tablet"]
  saved.lamp_programs={"well-west":{"day":false,"night":true}}
  var restored := ledger.rules.normalize_state(saved)
  _check(not restored.is_empty() and restored.player==[51,17,0] and restored.memory==saved.memory and restored.items==saved.items and restored.lamp_programs==saved.lamp_programs,"Rebasing migrates saved feet and retains memory, inventory and routines")
  _check(ledger.rules.normalize_state(restored).player==restored.player,"Continue never applies the coordinate migration twice")
 _check(not ledger.check_item("house-hollow",Vector2(20,2),"S",state).ok,"The layout shelf rejects unrelated houses")
 _check(ledger.check_item("lane-bench",Vector2(50,10),"S",state).ok and not ledger.check_item("lane-bench",Vector2(2,30),"S",state).ok,"The whole square is open to the layout; its walls are the frame and stay put")
 _check(not ledger.check_item("town-railing",Vector2(12,12),"E",state).ok,"The loading entrance stays clear")
 _check(not ledger.check_item("lane-bench",Vector2(22,8),"S",state).ok,"The retained stair bay stays clear")
 var painted := ledger.paint("limestone_flags",[[40,4],[8,60]],state)
 _check(painted.ok and painted.edit.cells==[[40,4]],"Paint lies on open ground, never on the walls")
 _check(GroundPaint.override_at(ledger.area,Vector2i(40,4))=="limestone_flags","Paint is part of the area edit layer")
 _check(ledger.undo(state).ok and GroundPaint.override_at(ledger.area,Vector2i(40,4))=="","Paint undo reveals the original authored floor")
 _check(ledger.redo(state).ok,"Paint redo restores the stroke")
 var added := ledger.place("lane-bench",Vector2(20,2),"S",state)
 _check(added.ok,"A bench can be placed in the restored garden: "+str(added.get("reason","")))
 if added.ok:
  var id: String=added.edit.id
  _check(not ledger.rules.is_walkable(state,Vector2i(20,2)),"Placed park objects have real collision")
  _check(ledger.move_prop(id,Vector2(20,3),"E",state).ok,"Park objects can move and rotate")
  _check(ledger.remove_prop(id,state).ok and ledger.rules.is_walkable(state,Vector2i(20,3)),"Removing a park object removes its collision")
  _check(ledger.undo(state).ok and not ledger.rules.is_walkable(state,Vector2i(20,3)),"Undo restores its placement and collision")
  _check(ledger.remove_prop(id,state).ok,"The temporary bench can be cleared before moving existing furniture")
 _check(ledger.move_prop("spindle-park-bench",Vector2(20,2),"E",state).ok,"Existing park doodads use the same move tool")
 # Authored scenery moves with what belongs to it: a lamp keeps its id, its light, its stand and its collision.
 var lamp_post: Dictionary = ledger.area.scenery_item("lamp-ring-1")
 _check(not lamp_post.is_empty() and lamp_post.lamps==["lamp-ring-1"],"A square lamp standard is movable scenery carrying its lamp")
 var lamp_was: Dictionary = ledger.area.lamp("lamp-ring-1")
 var moved_lamp := ledger.move_scenery("lamp-ring-1",lamp_post.at+Vector2(1.5,0),float(lamp_post.turn),state)
 _check(moved_lamp.ok and ledger.area.lamp("lamp-ring-1").at==lamp_was.at+Vector2(1.5,0) and ledger.area.lamp("lamp-ring-1").stand==[int(lamp_was.stand[0])+2,int(lamp_was.stand[1])],"Moving a lamp standard moves its lamp and the cell it is worked from: "+str(moved_lamp.get("reason","")))
 _check(not ledger.rules.is_walkable(state,Vector2i(roundi(lamp_post.at.x+1.5),roundi(lamp_post.at.y))) or ledger.area.scenery_item("lamp-ring-1").rect.has_point(lamp_post.at+Vector2(1.5,0)),"The standard's collision travels with it")
 _check(not ledger.check_move_scenery("lamp-ring-1",Vector2(22,8),0.0,state).ok,"Scenery stays off the stairs")
 var turned_bench: Dictionary = {}
 for item: Dictionary in ledger.area.scenery:
  if item.asset=="lane-bench" and turned_bench.is_empty() and ledger.turn_scenery(str(item.id),float(item.turn)+90.0,state).ok: turned_bench=item
 _check(not turned_bench.is_empty(),"An authored bench can be turned on the spot")
 if not turned_bench.is_empty(): _check(ledger.undo(state).ok,"Turning scenery undoes")
 # Walls drawn along the grid: one level, off the stairs and entrances, blocking the edges they run along.
 _check(not ledger.check_wall(Vector2(6.5,0.5),Vector2(9.5,3.5),"garden",state).ok and not ledger.check_wall(Vector2(21.5,6.5),Vector2(21.5,9.5),"garden",state).ok and not ledger.check_wall(Vector2(11.5,9.5),Vector2(11.5,14.5),"railing",state).ok,"Walls run straight, stay off the stairs and keep the travel entrance clear")
 var drawn := ledger.add_wall(Vector2(6.5,0.5),Vector2(12.5,0.5),"garden",state)
 _check(drawn.ok and ledger.rules.find_path(state,Vector2i(9,1),Vector2i(9,0)).size()>1 and AreaBuild.wall_pieces(ledger.area.walls).size()==5,"A six-metre garden wall is two bays and three piers, and blocks the edge it runs along")
 _check(not ledger.check_wall(Vector2(8.5,0.5),Vector2(10.5,0.5),"railing",state).ok,"A wall cannot be drawn over another")
 _check(ledger.remove_wall(str(drawn.edit.id),state).ok and ledger.undo(state).ok and ledger.area.walls.size()==1,"Walls come down and go back up with undo")
 # Town ground: the square's own flags and cobbles plus setts, brick, gravel, bed and lawn, every one an atlas picture.
 var town: Array = ["town_flags","town_cobbles","town_setts","town_brick","town_gravel","town_bed","town_lawn"]
 _check(town.all(func(id: String) -> bool: return AreaStore.ground_materials().has(id) and GroundSkin.PICTURES.has(str(WorldTextures.entry(id).texture))),"The town ground family is paintable and pictured")
 _check(ledger.paint("town_bed",[[30,22],[31,22]],state).ok and GroundPaint.override_at(ledger.area,Vector2i(30,22))=="town_bed","A planting bed paints onto the terrace")
 _check(ledger.undo(state).ok,"Town paint undoes")
 # Code: in the studio a program reads the square's doodads (scenery included), turns them and moves them, under the
 # builder's own rules, and a lamp standard says which lamp it carries.
 var code_state: Dictionary = state.duplicate(true)
 for spot: Vector2i in [Vector2i(63,27),Vector2i(63,26),Vector2i(62,27),Vector2i(64,25),Vector2i(62,24)]:
  if ledger.rules.is_walkable(state,spot): code_state.player=[spot.x,spot.y,0]; break
 var abilities: Array[String] = ["read","turn","move"]
 var seen: Dictionary = CodeBuild.snapshot(ledger,code_state,abilities)
 var listed: Array = (seen.doodads as Array).filter(func(d: Dictionary) -> bool: return d.id=="lamp-ring-1")
 _check(not listed.is_empty() and listed[0].lamps==["lamp-ring-1"],"world.doodads lists a lamp standard with its lamp")
 var standard: Dictionary = ledger.area.scenery_item("lamp-ring-1")
 var moved_by_code: Dictionary = CodeBuild.propose(ledger,code_state,[{"op":"relocate","entity_id":"lamp-ring-1","at":[standard.at.x+1.5,standard.at.y]},{"op":"rotate","entity_id":"lamp-ring-1","facing":"E"}],abilities)
 _check(moved_by_code.ok and (moved_by_code.edits as Array).size()==2,"A program moves and turns a lamp standard: "+str(moved_by_code.get("reason","")))
 _check(not CodeBuild.propose(ledger,code_state,[{"op":"relocate","entity_id":"lamp-ring-1","at":[22,8]}],abilities).ok,"Code is refused where the mouse would be (the stairs)")
 _check(not CodeBuild.propose(ledger,code_state,[{"op":"relocate","entity_id":"lamp-ring-1","at":[standard.at.x-1.0,standard.at.y]}],["read","turn"]).ok,"Moving needs the move ability")
 if Sandbox.is_available(SandboxJob.PYTHON):
  var snap: Dictionary = ledger.rules.snapshot(code_state); snap["build"]=seen
  var run: Dictionary = preload("res://sandbox/lab_program.gd").run("def program(world):\n    post = world.doodad('lamp-ring-1')\n    post.move_to(post.at[0] + 1.5, post.at[1])\n    print(post.lamps, post.at)\n",snap)
  _check(run.ok and run.commands[0].op=="relocate" and CodeBuild.propose(ledger,code_state,run.commands,abilities).ok and str(run.stdout).contains("lamp-ring-1"),"Real Python moves a lamp standard: "+str(run.get("reason","")))
 var saved_ledger := BuildLedger.new(source.document,source.assets,source.quests,AreaStore.read_build_catalog(),ledger.saved_edits(),"studio",AreaStore.ground_materials())
 _check(saved_ledger.problems.is_empty() and saved_ledger.area.scenery_item("lamp-ring-1").at==lamp_post.at+Vector2(1.5,0) and saved_ledger.area.walls.size()==1 and saved_ledger.area.prop("spindle-park-bench").at==Vector2(20,2) and GroundPaint.override_at(saved_ledger.area,Vector2i(40,4))=="limestone_flags","Saved layout edits reconstruct both paint and existing placements")
 _check(JSON.stringify(source.document)==original,"Editing leaves the authored area document unchanged")
 _check(ledger.land_reason("raise",Vector2i(20,2),2,state)!="","Terrain shaping stays disabled on authored terraces")
 for broken: Variant in [{"rect":[0,0,-2,3],"items":["lane-bench"]},{"rect":[0,0,4,4],"items":4},{"rect":[0,0,999,4],"items":["lane-bench"]}]:
  var doc: Dictionary=source.document.duplicate(true);doc.interior.layout=broken
  _check(not AreaDef.parse(doc,source.assets).ok,"Malformed layout bounds and shelf declarations are rejected")
 for issue: String in failures: printerr("FAIL: ",issue)
 print("Square layout: %d checks, %d failures." % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
func _check(ok: bool, message: String) -> void:
 checks+=1
 if not ok: failures.append(message)
