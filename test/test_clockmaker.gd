extends SceneTree
var failures: Array[String]=[]
var checks: int=0
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
 var source:=AreaStore.read_source("haverlund-square")
 var area: AreaDef=AreaStore.load_area("haverlund-square")
 var rules:=LabWorld.new(area);var state:=rules.initial_state()
 var entry: Dictionary=source.assets["haverlund-clockmaker"]
 _check(entry.source=="art/source/world/haverlund-clockmaker/v4/model.blend" and MediaLock.exists("res://art/source/world/haverlund-clockmaker/v3/model.blend"),"The raised shop preserves its previous adopted master")
 var link:=RoomLinks.find(area,"clockmaker")
 _check(not link.is_empty() and link.to=="shop-clockmaker" and link.doors=="clockmaker","The original shop has a real room link and door binding")
 var approach:=Vector2i(int(link.at[0]),int(link.at[1]))
 _check(not rules.find_path(state,approach,area.spawn).is_empty(),"The recessed entrance is reachable from the loading boundary")
 _check(not rules.is_walkable(state,Vector2i(12,20)) and rules.is_walkable(state,approach),"The new building blocks walking while its entrance remains clear")
 _check(RoomLinks.crossing(area,{"player":[approach.x,approach.y,0]},Vector2i.LEFT).id=="clockmaker","Walking toward the visible door selects the shop transition")
 var inside: AreaDef=AreaStore.load_area("shop-clockmaker")
 _check(inside.width==14 and inside.height==14 and inside.interior.shell=="clockshop-shell" and inside.interior.inspections.size()>=14 and inside.interior.assets.size()>=50 and (inside.interior.assets as Array).all(func(a:Dictionary)->bool:return str(a.asset).begins_with("clockshop-")),"The larger room has extensive custom furnishing and inspection points")
 _check(approach==Vector2i(16,21),"The entrance aligns with the central door between the display bays")
 var room_rules:=LabWorld.new(inside)
 _check(not room_rules.find_path(room_rules.initial_state(),Vector2i(6,0),inside.spawn).is_empty(),"The furnished room keeps a clear exit")
 for item:Dictionary in inside.interior.inspections:
  _check(not room_rules.find_path(room_rules.initial_state(),Vector2i(item.at[0],item.at[1]),inside.spawn).is_empty(),"Customers can reach "+str(item.id))
 _check(not room_rules.is_walkable(room_rules.initial_state(),Vector2i(9,5)),"The glazed counter has real collision")
 var workspace_open:bool=true
 for x:int in range(5,8):
  for y:int in range(7,10):workspace_open=workspace_open and room_rules.is_walkable(room_rules.initial_state(),Vector2i(x,y)) and not room_rules.find_path(room_rules.initial_state(),Vector2i(x,y),inside.spawn).is_empty()
 _check(workspace_open,"The larger collection leaves a connected three-by-three workspace for a future quest")
 for item:Dictionary in inside.interior.inspections:
  _check(RoomLinks.nearest(inside,Vector2(item.at[0],item.at[1]),"inspections").id==item.id,"Nearby inspection prompts select their own object: "+str(item.id))
 var old_room_state:=room_rules.initial_state();old_room_state.player=[9,5,0];old_room_state.memory={"repair_notes":23}
 var room_recovered:=room_rules.normalize_state(old_room_state)
 _check(not room_recovered.is_empty() and room_recovered.memory==old_room_state.memory and room_rules.is_walkable(room_recovered,Vector2i(room_recovered.player[0],room_recovered.player[1])),"A save in the former empty room preserves notes when new furniture covers its feet")
 var shell:Node3D=load("res://art/world_assets.gd").instantiate("clockshop-shell")
 var support_clear:bool=true
 var support_points:int=0
 for part:MeshInstance3D in shell.find_children("clockshop_darkwood","MeshInstance3D",true,false):
  for surface:int in range(part.mesh.get_surface_count()):
   var points:PackedVector3Array=part.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
   for point:Vector3 in points:
    if point.y<.2:
     support_points+=1;support_clear=support_clear and point.y<-.025
 _check(support_points>0 and support_clear,"The subfloor cap stays below the parquet, preventing coplanar floor flicker")
 shell.free()
 var back:=RoomLinks.find(inside,"square")
 _check(Vector2i(int(back.arrival[0]),int(back.arrival[1]))==approach and back.facing=="E","The room returns beside its own facade")
 var model: Node3D=load("res://art/world_assets.gd").instantiate("haverlund-clockmaker")
 _check(model!=null,"The audited original GLB loads")
 root.add_child(model)
 var clear_nodes: Array[MeshInstance3D]=[]
 var lamp_nodes: Array[MeshInstance3D]=[]
 var clear_materials: Dictionary={}
 var timber_ok: bool=false
 var copper_ok: bool=false
 var authored_ink_exclusions: int=0
 for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
  if mesh.name==&"IllustratedOutline":continue
  if not bool(WorldAssetMeta.value(mesh,"illustrated_edges",true)):
   authored_ink_exclusions+=1
   _check(not mesh.has_node("IllustratedOutline"),"Fine authored roof and dial pieces retain their own rims without expanded ink")
  var has_clear: bool=false
  var has_lamp: bool=false
  for n: int in range(mesh.mesh.get_surface_count()):
   var mat:=mesh.get_active_material(n) as StandardMaterial3D
   if mat==null:continue
   if mat.resource_name=="clock_clear_glass":has_clear=true
   if mat.resource_name.ends_with("lamp_glass"):has_lamp=true
   if mat.resource_name=="seaside_timber":timber_ok=mat.albedo_color.r<.9 and mat.albedo_texture!=null
   if mat.resource_name=="clock_copper_painted":copper_ok=mat.albedo_color.r<.8 and mat.albedo_texture!=null
  _check(not (has_clear and has_lamp),"Window glazing never shares an emitting fixture mesh")
  if has_clear:
   clear_nodes.append(mesh)
   clear_materials[mesh]=[]
   for n: int in range(mesh.mesh.get_surface_count()):clear_materials[mesh].append(mesh.get_active_material(n))
  if has_lamp:lamp_nodes.append(mesh)
 _check(clear_nodes.size()>=3,"Storefront, pendulum and door export actual clear glazing")
 _check(lamp_nodes.size()==1,"All three authored lamps share one isolated fixture glass mesh")
 _check(authored_ink_exclusions>=4,"The refined asset explicitly controls ink on its nested clock and roof details")
 _check(timber_ok and copper_ok,"The runtime export retains painted oak and copper color factors")
 _check(MechanismBuilder.bind_fixture(model,{"range":4.3,"energy":.65}),"The refined lamp glass binds to its existing circuit")
 var glass_unchanged: bool=true
 for mesh: MeshInstance3D in clear_nodes:
  glass_unchanged=glass_unchanged and mesh.material_override==null
  for n: int in range(mesh.mesh.get_surface_count()):
   var mat:=mesh.get_active_material(n) as StandardMaterial3D
   if mat!=null and mat.resource_name=="clock_clear_glass":glass_unchanged=glass_unchanged and mat==clear_materials[mesh][n] and mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED and mat.albedo_color.a<.1
 _check(glass_unchanged,"Power binding preserves the windows' transparency and original materials")
 var leaves:=DoorSwing.leaves(model)
 _check(leaves.size()==2 and leaves[0].position.x>0,"Only the shop door and its glazing share the central hinge")
 var resting: Array[Transform3D]=[]
 for leaf: Node3D in leaves:resting.append(leaf.transform)
 DoorSwing.set_open(model,true,0)
 _check(DoorSwing.is_open(model),"The actual exported door opens")
 for n: int in range(leaves.size()):_check(leaves[n].position.is_equal_approx(resting[n].origin),"Opening preserves each hinge position")
 DoorSwing.set_open(model,false,0)
 _check(not DoorSwing.is_open(model),"The actual door closes")
 var hands: Array[Node]=model.find_children("clock_*_hand*","Node3D",true,false)
 _check(hands.size()==2,"Two independent clock hands are exported")
 for hand: MeshInstance3D in hands:_check(hand.get_aabb().size.x>.09 and hand.get_aabb().size.y>.5,"The hand has visible width and length after export")
 CityInstruments.update_clock(model,3.5)
 var first: Array[Transform3D]=[]
 for hand: Node3D in hands:first.append(hand.transform)
 CityInstruments.update_clock(model,9.25)
 for n: int in range(hands.size()):_check(not hands[n].transform.is_equal_approx(first[n]) and hands[n].position.is_equal_approx(first[n].origin),"The town clock changes hands without moving their pivots")
 _check(model.find_children("clock_pendulum*","Node3D",true,false).size()==1,"The tall pendulum remains an independent semantic part for later work")
 # Old strip saves at the newly occupied plot recover only their feet.
 state.player=[12,20,0];state.memory={"kept":87}
 var restored:=rules.normalize_state(state)
 _check(not restored.is_empty() and restored.memory==state.memory and rules.is_walkable(restored,Vector2i(restored.player[0],restored.player[1])),"A prior save in the new building plot keeps progress and relocates safely")
 for issue: String in failures:printerr("FAIL: ",issue)
 print("Original clockmaker: %d checks, %d failures." % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
func _check(ok: bool, message: String) -> void:
 checks+=1
 if not ok:failures.append(message)
