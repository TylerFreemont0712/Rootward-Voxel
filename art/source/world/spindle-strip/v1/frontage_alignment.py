"""Deliberate follow-up on the v3 master: put frontages west of a visible central walk."""
from pathlib import Path
import json,math
import bpy,bmesh
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5];path=ROOT/'art/source/world/haverlund-square-ground/v3/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('frontage_alignment'):raise RuntimeError('Already aligned')
flags=bpy.data.materials['ground_flags'];cobbles=bpy.data.materials['ground_cobbles'];grass=bpy.data.materials['ground_grass'];stone=bpy.data.materials['seaside_stone']
for o in list(bpy.context.scene.objects):
 if o.type!='MESH':continue
 pts=[o.matrix_world@Vector(p) for p in o.bound_box]
 if max(p.x for p in pts)<-6.6 or min(p.x for p in pts)>11.6 or max(p.y for p in pts)<14.5 or min(p.y for p in pts)>54.5:continue
 bm=bmesh.new();bm.from_mesh(o.data)
 for axis,cuts in [(0,[-6.5,-.5,11.5]),(1,[14.5,54.5])]:
  for at in cuts:
   normal=Vector((int(axis==0),int(axis==1),0));bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=normal*at,plane_no=normal,clear_inner=False,clear_outer=False)
 fs=[]
 for f in bm.faces:
  c=f.calc_center_median()
  if -6.50001<c.x<-.49999 and 14.50001<c.y<54.49999 and c.z>1.95:fs.append(f)
  elif -.50001<c.x<11.50001 and 14.50001<c.y<54.49999 and abs(c.z-2)<.025 and f.normal.z>.9:fs.append(f)
 if fs:bmesh.ops.delete(bm,geom=fs,context='FACES')
 if not bm.faces:bm.free();bpy.data.objects.remove(o,do_unlink=True);continue
 bm.to_mesh(o.data);bm.free();o.data.update()
buckets={}
def face(mat,points):
 c=sum((Vector(p) for p in points),Vector())/len(points);buckets.setdefault((mat.name,math.floor(c.x/4),math.floor(c.y/4)),[]).append(points)
for x in range(-6,12):
 for y in range(15,55):
  if x<0:mat=flags if any(a<=y<=b for a,b in [(16,23),(26,34),(37,43),(46,51)]) else grass
  elif x<=4:mat=cobbles if 1<=x<=3 else flags
  else:mat=flags if y in [22,23,40,41,52,53,54] else grass
  face(mat,[(x-.5,y-.5,2),(x+.5,y-.5,2),(x+.5,y+.5,2),(x-.5,y+.5,2)])
# New western retaining face behind the future stores. Geometry ends at the old grade.
for y in range(15,55):face(stone,[(-6.5,y-.5,2),(-6.5,y+.5,2),(-6.5,y+.5,4),(-6.5,y-.5,4)])
for x in range(-6,0):face(stone,[(x-.5,54.5,2),(x+.5,54.5,2),(x+.5,54.5,4),(x-.5,54.5,4)])
for (mat,cx,cy),faces in buckets.items():
 verts=[];polys=[]
 for pts in faces:base=len(verts);verts.extend(pts);polys.append(tuple(range(base,len(verts))))
 name=f'frontage_{mat}_{cx}_{cy}';mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],polys);mesh.materials.append(bpy.data.materials[mat]);mesh.update();layer=mesh.uv_layers.new(name='UVMap')
 for p in mesh.polygons:
  axis=max(range(3),key=lambda i:abs(p.normal[i]));a,b=[(1,2),(0,2),(0,1)][axis]
  for li in p.loop_indices:
   v=mesh.vertices[mesh.loops[li].vertex_index].co;layer.data[li].uv=(v[a]/(8 if mat=='ground_grass' else 3),v[b]/(8 if mat=='ground_grass' else 3))
 o=bpy.data.objects.new(name,mesh);bpy.context.scene.collection.objects.link(o);o['ground_chunk']=True
bpy.context.scene['frontage_alignment']=True;bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(path))
