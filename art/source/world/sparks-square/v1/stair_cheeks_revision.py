"""Replace the new square's over-high stair cheeks with coursed stone that follows each flight.
Deliberately edits its adopted master; keeps a source backup and a hash record.
"""
from pathlib import Path
import hashlib
import json
import shutil
import sys
import bpy
import bmesh
ROOT=Path(__file__).resolve().parents[5]
sys.path.insert(0,str(ROOT/'art/source/world/sparks-lane/v1'));import lane_kit as k
folder=ROOT/'art/source/world/haverlund-square-set/v1';src=folder/'model.blend';note=folder/'stair-cheeks-revision.json'
if note.exists():raise RuntimeError('Stair revision already applied')
shutil.copy2(src,folder/'model.pre-stair-cheeks.blend');before=hashlib.sha256(src.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(src));bpy.context.preferences.filepaths.save_version=0
k.M.clear()
for name in ['limestone','limestone_pale','limestone_warm']:
 k.M[name]=next(m for m in bpy.data.materials if m.name=='square_'+name)
k.h.PARENT=next(o for o in bpy.context.scene.objects if o.type=='EMPTY')
count=0
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH' or obj.data.materials[0].name not in ['square_limestone','square_limestone_pale']:continue
 bm=bmesh.new();bm.from_mesh(obj.data);unseen=set(bm.verts)
 while unseen:
  seed=unseen.pop();island=[seed];cursor=0
  while cursor<len(island):
   v=island[cursor];cursor+=1
   for e in v.link_edges:
    other=e.other_vert(v)
    if other in unseen:unseen.remove(other);island.append(other)
  coords=[obj.matrix_world@v.co for v in island]
  if all(25.4<p.y<29.6 and (27.0<p.x<27.7 or 30.3<p.x<31.0) for p in coords) and max(p.z for p in coords)>1.95:
   count+=1;bmesh.ops.delete(bm,geom=island,context='VERTS')
 bm.to_mesh(obj.data);bm.free()
if count!=4:raise RuntimeError('Expected four old cheek pieces; got '+str(count))
b=k.Batch()
for x in (27.62,30.38):
 for i in range(16):
  y=25.5+(i+.5)*.25
  # A landing between flights, one additional rise per tread, then an upper landing.
  if i<4:h=(i+1)*.25
  elif i<8:h=1.0
  elif i<12:h=1+(i-7)*.25
  else:h=2.0
  top=h+.35
  for j in range(max(1,round(top/.3))):
   n=max(1,round(top/.3));z=(j+.5)*top/n
   b.box('limestone_warm' if (i+j)%4==0 else 'limestone',(x,y,z),(.28,.245,top/n-.008),.012)
  b.box('limestone_pale',(x,y,top+.035),(.36,.25,.07),.012)
b.finish();bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(src))
note.write_text(json.dumps({'record':'art/source/world/sparks-square/v1/stair_cheeks_revision.py','before_sha256':before,'after_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'removed_components':count},indent=2)+'\n')
print('Stepped stone cheeks saved')
