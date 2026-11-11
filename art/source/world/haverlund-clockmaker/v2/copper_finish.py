"""Deliberate edit of the saved original v2: standing-seam patinated copper, not the shared ceramic roof painting."""
from pathlib import Path
import math,json,hashlib
import bpy
from mathutils import Vector
P=Path(__file__).with_name('model.blend')
bpy.ops.wm.open_mainfile(filepath=str(P))
if bpy.context.scene.get('copper_finish'):raise RuntimeError('Copper finish already applied; inspect the master.')
before=hashlib.sha256(P.read_bytes()).hexdigest()
def linear(x):return x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4
def material(name,h):
 m=bpy.data.materials.new(name);m.use_nodes=True;c=[linear(int(h[n:n+2],16)/255) for n in (0,2,4)]
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*c,1);bs.inputs['Roughness'].default_value=.72;bs.inputs['Metallic'].default_value=.18;m.diffuse_color=(*c,1);return m
mats=[material('clock_patinated_copper_'+str(i),h) for i,h in enumerate(['62837c','718e86','58776f','7d9990'])]
for o in bpy.context.scene.objects:
 if o.type!='MESH':continue
 indices=[i for i,m in enumerate(o.data.materials) if m and m.name=='clock_copper']
 if not indices:continue
 start=len(o.data.materials)
 for m in mats:o.data.materials.append(m)
 for p in o.data.polygons:
  if p.material_index in indices:
   c=p.center;p.material_index=start+(abs(round(c.x*3)+round(c.y*2))%4 if p.area>.04 else 2)
# Low-profile sheet panels lie just above the pitched roof and read as wide copper sheets in close views.
mat=mats[0]
verts=[];faces=[];colors=[]
for side in [-1,1]:
 for n in range(14):
  x0=-3.92+n*.56+.018;x1=x0+.52
  for row in range(3):
   t0=row/3;t1=(row+1)/3;y0=side*2.72*(1-t0);y1=side*2.72*(1-t1);z0=6.18+2*t0+.009;z1=6.18+2*t1+.009
   pts=[(x0,y0,z0),(x1,y0,z0),(x1,y1,z1),(x0,y1,z1)]
   if side>0:pts.reverse()
   base=len(verts);verts.extend(pts);faces.append(tuple(range(base,base+4)));colors.append((n+row*2)%4)
mesh=bpy.data.meshes.new('copper_sheet_panels');mesh.from_pydata(verts,[],faces)
for m in mats:mesh.materials.append(m)
for p,c in zip(mesh.polygons,colors):p.material_index=c
mesh.uv_layers.new(name='UVMap');mesh.update();o=bpy.data.objects.new(mesh.name,mesh);bpy.context.scene.collection.objects.link(o)
root=next(o for o in bpy.context.scene.objects if o.parent is None and o.type=='EMPTY');o.parent=root
bpy.context.scene['copper_finish']=True;bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(P))
P.with_name('copper-finish.json').write_text(json.dumps({'previous_sha256':before,'record':'art/source/world/haverlund-clockmaker/v2/copper_finish.py','change':'Replace shared ceramic picture with patinated copper sheet materials and raised sheet panels; retain bespoke roof geometry and seams.'},indent=2))
