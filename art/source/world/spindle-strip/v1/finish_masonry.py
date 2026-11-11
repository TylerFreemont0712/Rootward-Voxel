"""Paint the new retaining faces with the existing ashlar atlas's individual stone samples."""
from pathlib import Path
import sys,random,json
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
sys.path.insert(0,str(ROOT/'art/source/world/seaside-houses/v1'))
import house_kit as k
path=ROOT/'art/source/world/haverlund-square-ground/v3/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(path))
frontages='--frontages' in sys.argv
flag='frontage_masonry_finish' if frontages else 'strip_masonry_finish'
if bpy.context.scene.get(flag):raise RuntimeError('Already finished')
rng=random.Random(1103)
for o in bpy.context.scene.objects:
 if o.type!='MESH' or not o.name.startswith('frontage_seaside_stone_' if frontages else 'spindle_seaside_stone_'):continue
 old=o.data;verts=[];faces=[];uvs=[]
 for f in old.polygons:
  points=[old.vertices[i].co for i in f.vertices];axis=0 if abs(f.normal.x)>.9 else 1;along=1-axis
  aa=min(p[along] for p in points);bb=max(p[along] for p in points);z0=min(p.z for p in points);z1=max(p.z for p in points);plane=points[0][axis]
  rows=max(1,round((z1-z0)/.25));cols=max(1,round((bb-aa)/.5))
  for row in range(rows):
   low=z0+(z1-z0)*row/rows;high=z0+(z1-z0)*(row+1)/rows
   for col in range(cols):
    a=aa+(bb-aa)*col/cols;b=aa+(bb-aa)*(col+1)/cols
    pts=[]
    for v,z in [(a,low),(b,low),(b,high),(a,high)]:
     p=Vector((0,0,z));p[axis]=plane;p[along]=v;pts.append(p)
    if (pts[1]-pts[0]).cross(pts[2]-pts[0]).dot(f.normal)<0:pts.reverse()
    base=len(verts);verts.extend([tuple(p) for p in pts]);faces.append(tuple(range(base,base+4)))
    x0,x1,y0,y1=rng.choice(k.STONE_BLOCKS)
    uvs.append([(x0/512,1-y1/512),(x1/512,1-y1/512),(x1/512,1-y0/512),(x0/512,1-y0/512)])
 mesh=bpy.data.meshes.new(o.name+' bricks');mesh.from_pydata(verts,[],faces);mesh.materials.append(old.materials[0]);layer=mesh.uv_layers.new(name='UVMap')
 for p,coords in zip(mesh.polygons,uvs):
  for li,uv in zip(p.loop_indices,coords):layer.data[li].uv=uv
 mesh.update();o.data=mesh
bpy.context.scene[flag]=True;bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(path))
