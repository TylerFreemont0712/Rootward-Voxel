"""Seat the inlay on the full tread width, including the bevelled seam at a stair's center."""
import bpy,sys
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from pathlib import Path
ROOT=Path(__file__).resolve().parents[5]
p=ROOT/'art/source/world/haverlund-square-ground/v1/model.blend';bpy.ops.wm.open_mainfile(filepath=str(p))
stone=bpy.data.objects['seaside_stone'];v=[stone.matrix_world @ x.co for x in stone.data.vertices];f=[tuple(x.vertices) for x in stone.data.polygons];bvh=BVHTree.FromPolygons(v,f)
changed=0
for name,offset in [('grid_glass',.006),('grid_bronze',.009),('grid_bed',-.012)]:
 o=bpy.data.objects[name]
 for face in o.data.polygons:
  if face.normal.z<.99:continue
  pts=[o.data.vertices[i].co for i in face.vertices];cx=sum(p.x for p in pts)/len(pts);cy=sum(p.y for p in pts)/len(pts)
  stair=(58<cx<64 and -24.5<cy<-.5) or (12<cx<18 and 55.5<cy<56.5) or (6-.5<cx<6+.5 and 6<cy<11) or (11-.5<cx<11+.5 and 6<cy<11)
  if not stair:continue
  across=0 if cy<-.5 or cy>55 else 1
  hits=[]
  for d in [0,-.10,.10]:
   q=Vector((cx,cy,20));q[across]+=d;hit=bvh.ray_cast(q,Vector((0,0,-1)),50)[0]
   if hit is not None:hits.append(hit.z)
  if hits:
   top=max(hits)
   if abs(top-pts[0].z)<.06:
    for pt in pts:pt.z=top+offset
    changed+=1
 o.data.update()
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(p));print('SEATED',changed)
