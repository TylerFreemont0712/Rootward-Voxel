"""Bounded saved-master edit: recess only the clockmaker plot into the restored higher rear land.
Keeps its entrance visible from the lane rather than hidden behind the foreground market roof.
"""
from pathlib import Path
import bpy,bmesh,hashlib,json,math
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5];path=ROOT/'art/source/world/haverlund-square-ground/v5/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('clockmaker_plot_fitted'):raise RuntimeError('Plot fitted; edit saved source.')
before=hashlib.sha256(path.read_bytes()).hexdigest();removed=0
x0,x1,y0,y1=9.3,15.5,15.5,24.5
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH':continue
 pts=[obj.matrix_world@Vector(v) for v in obj.bound_box]
 if max(p.x for p in pts)<x0 or min(p.x for p in pts)>x1 or max(p.y for p in pts)<y0 or min(p.y for p in pts)>y1:continue
 bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.transform(bm,matrix=obj.matrix_world,verts=list(bm.verts))
 for axis,cuts in [(0,[x0,x1]),(1,[y0,y1])]:
  for value in cuts:
   n=Vector((int(axis==0),int(axis==1),0));bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=n*value,plane_no=n)
 faces=[f for f in bm.faces if x0-.00001<f.calc_center_median().x<x1+.00001 and y0-.00001<f.calc_center_median().y<y1+.00001 and f.calc_center_median().z>1.99]
 removed+=len(faces)
 if faces:bmesh.ops.delete(bm,geom=faces,context='FACES')
 if not bm.faces:bm.free();bpy.data.objects.remove(obj,do_unlink=True);continue
 bm.to_mesh(obj.data);bm.free();obj.matrix_world.identity();obj.data.update()
# Separate short surfaces retain bounded local-light influence and existing paintings.
def surface(name,points,mat,axes,scale):
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(points,[],[tuple(range(len(points)))]);mesh.materials.append(bpy.data.materials[mat]);mesh.update();uv=mesh.uv_layers.new(name='UVMap')
 for poly in mesh.polygons:
  for li in poly.loop_indices:
   v=mesh.vertices[mesh.loops[li].vertex_index].co;uv.data[li].uv=(v[axes[0]]/scale,v[axes[1]]/scale)
 obj=bpy.data.objects.new(name,mesh);bpy.context.scene.collection.objects.link(obj);obj['ground_chunk']=True
for a in [x0,12.0]:
 b=12.0 if a==x0 else x1
 for c in [y0,18.5,21.5]:
  d=min(c+3,y1);surface(f'clock_plot_floor_{a}_{c}',[(a,c,2),(b,c,2),(b,d,2),(a,d,2)],'ground_flags',(0,1),3)
for c in [y0,18.5,21.5]:
 d=min(c+3,y1);surface(f'clock_plot_rear_{c}',[(x0,c,2),(x0,d,2),(x0,d,4),(x0,c,4)],'seaside_stone',(1,2),1.9)
for y,reverse in [(y0,False),(y1,True)]:
 for a,b in [(x0,12),(12,x1)]:
  pts=[(a,y,2),(b,y,2),(b,y,4),(a,y,4)]
  if reverse:pts.reverse()
  surface(f'clock_plot_cheek_{y}_{a}',pts,'seaside_stone',(0,2),1.9)
bpy.context.scene['clockmaker_plot_fitted']=True;bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path))
path.with_name('clockmaker-plot.json').write_text(json.dumps({'previous_sha256':before,'removed_faces':removed,'rect':[x0,y0,x1-x0,y1-y0],'record':str(Path(__file__).relative_to(ROOT))},indent=2)+'\n')
