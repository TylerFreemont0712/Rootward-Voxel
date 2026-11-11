"""Keep quarter marks on small display clocks so their dials remain readable at the approved gameplay scale."""
from pathlib import Path
import sys,hashlib
import bpy,bmesh
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent));from edit_support import *
path=Path(__file__).with_name('model.blend');bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('clock_readability'):raise RuntimeError('Already reviewed for readability.')
before=hashlib.sha256(path.read_bytes()).hexdigest();obj=bpy.data.objects['refined_frontage_dial_details']
bm=bmesh.new();bm.from_mesh(obj.data);seen=set();groups=[];centers=[]
for seed in bm.verts:
 if seed in seen:continue
 stack=[seed];seen.add(seed);group=[]
 while stack:
  v=stack.pop();group.append(v)
  for e in v.link_edges:
   q=e.other_vert(v)
   if q not in seen:seen.add(q);stack.append(q)
 lo=Vector(tuple(min(v.co[i] for v in group) for i in range(3)));hi=Vector(tuple(max(v.co[i] for v in group) for i in range(3)));c=(lo+hi)*.5
 mats={obj.data.materials[f.material_index].name for v in group for f in v.link_faces}
 groups.append((group,lo,hi,c,mats))
 if mats=={'clock_ivory_dial'}:centers.append(c)
remove=[]
for group,lo,hi,c,mats in groups:
 if mats!={'clock_bronze_dark'} or max(hi-lo)>.05 or not centers:continue
 center=min(centers,key=lambda p:(p-c).length_squared)
 if abs(c.x-center.x)>.015 and abs(c.z-center.z)>.015:remove.extend(group)
if remove:bmesh.ops.delete(bm,geom=remove,context='VERTS');bm.to_mesh(obj.data);obj.data.update()
bm.free();bpy.context.scene['clock_readability']=True
save_record(path,'readability_finish',before)
print('DISPLAY TICK VERTICES SIMPLIFIED',len(remove))
