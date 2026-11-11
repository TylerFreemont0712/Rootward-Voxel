"""Bounded edit of the adopted clockmaker v3: entrance between clock displays and a raised stone plinth."""
from pathlib import Path
import sys,hashlib,json
import bpy,bmesh
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
sys.path.insert(0,str(ROOT/'art/source/world/haverlund-clockmaker/v3'))
from edit_support import k,bind_materials,discard_components
source=ROOT/'art/source/world/haverlund-clockmaker/v3/model.blend'
target=ROOT/'art/source/world/haverlund-clockmaker/v4/model.blend'
if target.exists():raise RuntimeError('Source exists; edit the saved master.')
bpy.ops.wm.open_mainfile(filepath=str(source));bind_materials();root=bpy.data.objects['haverlund_clockmaker']
for obj in bpy.context.scene.objects:
 if obj.name.startswith('door_leaf'):
  obj.name=obj.name.replace('door_leaf_clockmaker','residence_door')
  for key in ['part','swing']:
   if key in obj:del obj[key]
# Remove the fixed central infill, glass and hardware, preserving jambs, fanlight and both displays.
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH' or not obj.name.startswith('refined_frontage'):continue
 discard_components(obj,lambda lo,hi,c:lo.x>.59 and hi.x<1.66 and lo.z>.07 and hi.z<2.56 and lo.y<-2.20)
p=k.Parts(110401);cx=1.12;y=-2.45;hinge=Vector((.64,y,.14))
with p.into('door_leaf_clockmaker'):
 for x in [cx-.44,cx+.44]:p.box('timber',(x,y,1.32),(.10,.11,2.30),bevel=.012)
 for z in [.22,.82,2.44]:p.box('timber',(cx,y,z),(.98,.12,.11),bevel=.013)
 for x in [cx-.22,cx+.22]:
  p.box('timber',(x,y,.50),(.35,.10,.46),bevel=.015)
  p.box('clock_fascia',(x,y-.061,.50),(.25,.018,.33),bevel=.01)
 p.box('timber',(cx,y,1.62),(.035,.09,1.50),bevel=.005)
 p.pane('clock_clear_glass',(cx,y,1.62),.80,1.50,(0,-1))
 p.box('clock_watch_gold',(cx+.32,y-.075,1.12),(.06,.035,.24),bevel=.01)
 p.cylinder('clock_watch_gold',(cx+.32,y-.075,1.12),(cx+.32,y-.145,1.12),.035,12)
p.finish(root)
for obj in bpy.context.scene.objects:
 if obj.name.startswith('door_leaf_clockmaker'):
  for v in obj.data.vertices:v.co-=hinge
  obj.location=hinge;obj['swing']=-100;obj['part']='shop_entrance'
p=k.Parts(110402)
p.box('stone',(0,0,-.08),(7.60,5.60,.16),bevel=.025,uv=('blocks',))
p.box('stone',(cx,-2.80,-.025),(1.28,.82,.11),bevel=.022,uv=('blocks',))
p.finish(root)
for obj in list(bpy.context.scene.objects):
 if obj.type=='MESH' and not obj.data.polygons:bpy.data.objects.remove(obj,do_unlink=True)
target.parent.mkdir(parents=True,exist_ok=True);bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(target))
target.with_name('entrance.json').write_text(json.dumps({'previous_source':str(source.relative_to(ROOT)),'previous_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'entrance_center':[cx,y],'hinge':list(hinge),'placement_raise':.16,'record':str(Path(__file__).relative_to(ROOT))},indent=2)+'\n')
