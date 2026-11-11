"""Correct the adopted square buildings' gable orientation to match their roof ridges. Preserves masters as backups."""
from pathlib import Path
import hashlib
import json
import bpy
import shutil
ROOT=Path(__file__).resolve().parents[5]
for asset,w,d,eave in [('square-town-hall',8.4,5.5,4.0),('square-bakery',5.4,5.8,5.3),('square-bookshop',5.4,5.8,5.3),('square-grocer',5.4,5.8,5.3)]:
 folder=ROOT/'art/source/world'/asset/'v1'; src=folder/'model.blend'; note=folder/'roof-gables-revision.json'
 if note.exists():raise RuntimeError('Revision already applied: '+asset)
 shutil.copy2(src,folder/'model.pre-gable-revision.blend');before=hashlib.sha256(src.read_bytes()).hexdigest()
 bpy.ops.wm.open_mainfile(filepath=str(src));bpy.context.preferences.filepaths.save_version=0
 count=0
 for obj in bpy.context.scene.objects:
  if obj.type!='MESH':continue
  mat=obj.data.materials[0].name
  if not any(m in mat for m in ['plaster','salmon']):continue
  mesh=obj.data; adj={v.index:[] for v in mesh.vertices}
  for edge in mesh.edges:
   a,b=edge.vertices;adj[a].append(b);adj[b].append(a)
  unseen=set(adj)
  while unseen:
   seed=unseen.pop();island=[seed];cursor=0
   while cursor<len(island):
    v=island[cursor];cursor+=1
    for n in adj[v]:
     if n in unseen:unseen.remove(n);island.append(n)
   coords=[obj.matrix_world@mesh.vertices[i].co for i in island]
   if not any(p.z>eave+.08 for p in coords):continue
   # The clock tower has a separate stone material, so only the two wrong gables qualify.
   if not all(abs(abs(p.y)-d/2)<.25 for p in coords):continue
   for i in island:
    p=obj.matrix_world@mesh.vertices[i].co
    oldx,oldy=p.x,p.y;p.x=-oldy*w/d;p.y=oldx*d/w
    mesh.vertices[i].co=obj.matrix_world.inverted()@p;count+=1
 if count<6:raise RuntimeError('Gables not found: '+asset)
 bpy.ops.wm.save_as_mainfile(filepath=str(src))
 note.write_text(json.dumps({'record':'art/source/world/sparks-square/v1/roof_gables_revision.py','vertices':count,'before_sha256':before,'after_sha256':hashlib.sha256(src.read_bytes()).hexdigest()},indent=2)+'\n')
 print('Corrected',asset,count,flush=True)
